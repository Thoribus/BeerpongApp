/* eslint-disable */
/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
admin.initializeApp();

// Runs every minute and sets old "pending" invites to "declined".
exports.declineOldInvitations =
    onSchedule("every 1 minutes", async (context) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        const timezoneOffset = 1 * 60 * 60 * 1000; // Offset in milliseconds (1 hour)
        // cutoff time = now minus 60 seconds
        const cutoff = new Date(now.toMillis() - 60000 + timezoneOffset);
        console.log(`Declining invitations older than ${cutoff}`);

        // Query invitations where status == "pending" and timestamp <= cutoff
        const querySnapshot = await db
            .collection("invitations")
            .where("status", "==", "pending")
            .where("createdAt", "<=", cutoff)
            .get();


        if (querySnapshot.empty) {
            console.log("No pending invitations older than 1 minute.");
            return null;
        }

        console.log(`Found ${querySnapshot.size} old invitations. Declining...`);


        // Use a batch or a loop
        const batch = db.batch();
        querySnapshot.forEach((doc) => {
            const ref = doc.ref;
            batch.update(ref, { status: "declined" });
        });

        await batch.commit();
        console.log("Auto-declined all old invitations successfully.");
        return null;
    });

