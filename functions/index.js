/* eslint-disable max-len */
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const https = require("https");
admin.initializeApp();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Returns the fcmTokens array stored on a user document, or [] if absent.
 * @param {string} userId - Firestore user document ID.
 * @return {Promise<string[]>} Array of FCM registration tokens.
 */
async function getTokensForUser(userId) {
  const db = admin.firestore();
  const snap = await db.collection("users").doc(userId).get();
  if (!snap.exists) return [];
  const data = snap.data();
  return Array.isArray(data.fcmTokens) ? data.fcmTokens : [];
}

/**
 * Sends an FCM multicast message to all tokens registered for a user.
 * Automatically removes any tokens that are no longer valid.
 * @param {string} userId - Firestore user document ID of the recipient.
 * @param {{title: string, body: string}} notification - Notification payload.
 * @param {Object} data - Data payload attached to the message.
 * @return {Promise<void>}
 */
async function sendToUser(userId, notification, data) {
  const tokens = await getTokensForUser(userId);
  if (tokens.length === 0) {
    console.log(`sendToUser: no tokens for user ${userId}`);
    return;
  }

  const message = {
    tokens,
    notification,
    data,
    android: {
      notification: {
        channelId: "beerpong_invitations",
        icon: "ic_notification",
        color: "#FF8C00",
      },
    },
    apns: {
      payload: {
        aps: {sound: "default", badge: 1},
      },
    },
  };

  const response = await admin.messaging().sendEachForMulticast(message);
  console.log(
      `sendToUser ${userId}: ${response.successCount} ok, ${response.failureCount} failed`,
  );

  // Prune tokens that the FCM service reports as invalid so stale entries
  // don't accumulate on the user document.
  const staleTokens = [];
  response.responses.forEach((resp, idx) => {
    if (!resp.success) {
      const code = resp.error && resp.error.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        staleTokens.push(tokens[idx]);
      }
    }
  });

  if (staleTokens.length > 0) {
    await admin.firestore().collection("users").doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
    });
    console.log(`Pruned ${staleTokens.length} stale token(s) for user ${userId}`);
  }
}

// ---------------------------------------------------------------------------
// Trigger: invitation created → notify recipient
// ---------------------------------------------------------------------------

exports.onInvitationCreated = onDocumentCreated(
    "invitations/{invitationId}",
    async (event) => {
      const inv = event.data.data();
      const {toUserId, fromUsername, gameType} = inv;

      const label = gameType === "tournament" ? "tournament game" : "game";
      const senderName = fromUsername || "Someone";

      await sendToUser(
          toUserId,
          {
            title: "Game Invitation",
            body: `${senderName} invited you to a ${label}!`,
          },
          {type: "game_invitation", invitationId: event.params.invitationId},
      );
    },
);

// ---------------------------------------------------------------------------
// Trigger: invitation updated → notify sender on accept / decline
// ---------------------------------------------------------------------------

exports.onInvitationUpdated = onDocumentUpdated(
    "invitations/{invitationId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.status === after.status) return; // nothing relevant changed

      const {fromUserId, toUserId} = after;

      // Fetch the recipient's display name to use in the notification body.
      const db = admin.firestore();
      const toSnap = await db.collection("users").doc(toUserId).get();
      const toUsername = (toSnap.exists && toSnap.data().username) || "Someone";

      if (after.status === "accepted") {
        await sendToUser(
            fromUserId,
            {
              title: "Invitation Accepted",
              body: `${toUsername} accepted your game invitation!`,
            },
            {type: "invitation_accepted", invitationId: event.params.invitationId},
        );
      } else if (after.status === "declined") {
        await sendToUser(
            fromUserId,
            {
              title: "Invitation Declined",
              body: `${toUsername} declined your game invitation.`,
            },
            {type: "invitation_declined", invitationId: event.params.invitationId},
        );
      }
    },
);

// ---------------------------------------------------------------------------
// Trigger: game started → notify accepted invitees
// ---------------------------------------------------------------------------

exports.onGameStarted = onDocumentUpdated(
    "games/{gameId}",
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      // Only fire on the false → true transition.
      if (before.started || !after.started) return;

      const invitationIds = after.invitations || [];
      if (invitationIds.length === 0) return;

      const db = admin.firestore();

      // Resolve each invitation doc to get the recipient's userId.
      const inviteSnaps = await Promise.all(
          invitationIds.map((id) => db.collection("invitations").doc(id).get()),
      );

      const toUserIds = inviteSnaps
          .filter((snap) => snap.exists)
          .map((snap) => snap.data().toUserId)
          .filter(Boolean);

      if (toUserIds.length === 0) return;

      // Derive host name from the first invitation's fromUsername.
      const firstInvite = inviteSnaps.find((s) => s.exists);
      const hostName =
        (firstInvite && firstInvite.data() && firstInvite.data().fromUsername) || "";

      await Promise.all(
          toUserIds.map((userId) =>
            sendToUser(
                userId,
                {title: "Game Starting!", body: "Your game is about to begin. Jump in!"},
                {type: "game_started", gameId: event.params.gameId, hostName},
            ),
          ),
      );
    },
);

// ---------------------------------------------------------------------------
// Scheduled: expire pending invitations every 30 minutes
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Callable: validate IAP receipt and credit stars
// ---------------------------------------------------------------------------

/** Star amounts per product ID. Must match the Flutter PurchaseService. */
const STAR_AMOUNTS = {
  "com.tecbreak.beerpongcompanion.stars_200": 200,
  "com.tecbreak.beerpongcompanion.stars_600": 600,
  "com.tecbreak.beerpongcompanion.stars_1500": 1500,
  "com.tecbreak.beerpongcompanion.supporter_pack": 300, // bonus stars included with pack
};

const SUPPORTER_PACK_ID = "com.tecbreak.beerpongcompanion.supporter_pack";

/**
 * Validates an Apple App Store receipt by posting to Apple's verifyReceipt endpoint.
 * Set the shared secret via: firebase functions:secrets:set APPLE_SHARED_SECRET
 * @param {string} receiptData - Base64-encoded App Store receipt.
 * @param {string} productId - Expected product ID.
 * @return {Promise<boolean>} True if the receipt is valid and contains the product.
 */
async function validateAppleReceipt(receiptData, productId) {
  const sharedSecret = process.env.APPLE_SHARED_SECRET;
  if (!sharedSecret) throw new HttpsError("internal", "Apple shared secret not configured");

  const body = JSON.stringify({
    "receipt-data": receiptData,
    "password": sharedSecret,
    "exclude-old-transactions": true,
  });

  const postToApple = (url) => new Promise((resolve, reject) => {
    const req = https.request(url, {method: "POST", headers: {"Content-Type": "application/json"}}, (res) => {
      let data = "";
      res.on("data", (chunk) => data += chunk);
      res.on("end", () => resolve(JSON.parse(data)));
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });

  // Try production first; fall back to sandbox (status 21007).
  let response = await postToApple("https://buy.itunes.apple.com/verifyReceipt");
  if (response.status === 21007) {
    response = await postToApple("https://sandbox.itunes.apple.com/verifyReceipt");
  }

  if (response.status !== 0) return false;

  const receipts = response.latest_receipt_info || [];
  return receipts.some((r) => r.product_id === productId);
}

/**
 * Validates a Google Play purchase token.
 * Requires a service account key stored as a secret:
 *   firebase functions:secrets:set GOOGLE_SERVICE_ACCOUNT_KEY
 * The value should be the full JSON key file stringified.
 * @param {string} purchaseToken - The purchase token from the client.
 * @param {string} productId - The product ID to validate against.
 * @return {Promise<boolean>} True if the purchase is valid.
 */
async function validateGooglePurchase(purchaseToken, productId) {
  // Uses the Google APIs Node.js client (googleapis) if available.
  // Add "googleapis": "^144.0.0" to functions/package.json to enable.
  try {
    // eslint-disable-next-line
    const {google} = require("googleapis");
    const keyJson = process.env.GOOGLE_SERVICE_ACCOUNT_KEY;
    if (!keyJson) throw new HttpsError("internal", "Google service account not configured");

    const key = JSON.parse(keyJson);
    const auth = new google.auth.GoogleAuth({
      credentials: key,
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const androidPublisher = google.androidpublisher({version: "v3", auth});
    const result = await androidPublisher.purchases.products.get({
      packageName: "com.tecbreak.beerpongcompanion",
      productId,
      token: purchaseToken,
    });
    // purchaseState 0 = Purchased, 1 = Cancelled, 2 = Pending
    return result.data.purchaseState === 0;
  } catch (e) {
    console.error("validateGooglePurchase error:", e.message);
    return false;
  }
}

exports.validatePurchase = onCall(async (request) => {
  // 1. Require authentication.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in to purchase");
  }

  const {productId, transactionId, receiptData, platform} = request.data;
  const userId = request.auth.uid;

  if (!productId || !transactionId || !receiptData || !platform) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  const stars = STAR_AMOUNTS[productId];
  if (!stars) {
    throw new HttpsError("invalid-argument", `Unknown product: ${productId}`);
  }

  const db = admin.firestore();

  // 2. Idempotency — prevent the same transaction from being credited twice.
  const processedRef = db.collection("processedPurchases").doc(
      `${platform}_${transactionId}`,
  );
  const processed = await processedRef.get();
  if (processed.exists) {
    console.log(`validatePurchase: already processed ${transactionId}`);
    return {success: true, starsAwarded: stars, alreadyProcessed: true};
  }

  // 3. Validate receipt with the appropriate store.
  let valid = false;
  if (platform === "ios") {
    valid = await validateAppleReceipt(receiptData, productId);
  } else if (platform === "android") {
    valid = await validateGooglePurchase(receiptData, productId);
  } else {
    throw new HttpsError("invalid-argument", `Unknown platform: ${platform}`);
  }

  if (!valid) {
    throw new HttpsError("invalid-argument", "Receipt validation failed");
  }

  // 4. Atomically credit stars (and set isSupporter for the Supporter Pack).
  const userUpdate = {
    stars: admin.firestore.FieldValue.increment(stars),
  };
  if (productId === SUPPORTER_PACK_ID) {
    userUpdate.isSupporter = true;
  }

  await db.runTransaction(async (tx) => {
    tx.set(processedRef, {
      userId,
      productId,
      platform,
      starsAwarded: stars,
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(db.collection("users").doc(userId), userUpdate);
  });

  console.log(`validatePurchase: credited ${stars} stars to ${userId} for ${productId}`);
  return {success: true, starsAwarded: stars, isSupporter: productId === SUPPORTER_PACK_ID};
});

// ---------------------------------------------------------------------------
// Scheduled: expire pending invitations every 30 minutes
// ---------------------------------------------------------------------------

exports.expireInvitations = onSchedule("every 30 minutes", async (_event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const snapshot = await db
      .collection("invitations")
      .where("status", "==", "pending")
      .where("expiresAt", "<=", now)
      .get();

  if (snapshot.empty) {
    console.log("expireInvitations: nothing to expire.");
    return;
  }

  console.log(`expireInvitations: expiring ${snapshot.size} invitation(s).`);

  const batch = db.batch();
  snapshot.forEach((doc) => batch.update(doc.ref, {status: "expired"}));
  await batch.commit();

  console.log("expireInvitations: batch committed.");
});
