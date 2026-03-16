/* eslint-disable max-len */
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
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
