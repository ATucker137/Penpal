//
//  index.js
//  Penpal
//
//  Created by Austin William Tucker on 4/8/25.
//

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

////////////////////////////////////////////////////////////////////////////////
// Penpal & Friend Requests
////////////////////////////////////////////////////////////////////////////////

exports.sendFriendRequestNotification = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    if (!requestData) return null;

    const receiverId = requestData.receiverId;
    if (!receiverId) return null;

    const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
    if (!userDoc.exists) return null;

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: 'New Friend Request',
        body: `${requestData.senderName} sent you a friend request.`,
        sound: 'default',
      },
      data: {
        deepLink: `penpal://friendRequest/${context.params.requestId}`,  // deep link to Friend Request screen
        friendRequestId: context.params.requestId,
      },
      apns: {
        payload: { aps: { 'content-available': 1 } },
      },
    };
      // TODO: Add analytics event (e.g. "friend_request_sent")
      // TODO: Send fallback email if user has no FCM token
      // TODO: Extend to handle bulk friend requests (batch notifications)

    try {
      await admin.messaging().sendToDevice(fcmToken, payload);
      console.log('Friend request notification sent');
    } catch (error) {
      console.error('Error sending friend request notification:', error);
    }

    return null;
  });

////////////////////////////////////////////////////////////////////////////////
// Messages
////////////////////////////////////////////////////////////////////////////////

exports.sendMessageNotification = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    if (!messageData) {
      console.log('No message data found');
      return null;
    }

    const receiverId = messageData.receiverId;
    if (!receiverId) {
      console.log('No receiverId in message data');
      return null;
    }

    // 1️⃣ Throttle check — skip if user got a notification too recently
    if (!(await canSendNotification(receiverId))) {
      console.log(`Throttled message notification for user ${receiverId}`);
      return null;
    }

    // 2️⃣ Load the recipient’s FCM token
    const userDoc = await admin.firestore().collection('users').doc(receiverId).get();
    if (!userDoc.exists) {
      console.log(`User ${receiverId} not found`);
      return null;
    }

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) {
      console.log(`No FCM token for user ${receiverId}`);
      return null;
    }

    // 3️⃣ Compose notification with deep link to chat conversation
    const payload = {
      notification: {
        title: 'New Message',
        body: messageData.text || 'You have a new message',
        sound: 'default',
      },
      data: {
        deepLink: `penpal://chat/${context.params.conversationId}`,  // deep link to conversation screen
        conversationId: context.params.conversationId,
        messageId: context.params.messageId,
      },
      apns: {
        payload: { aps: { 'content-available': 1 } },
      },
    };

    // 4️⃣ Send the push notification
    try {
      const response = await admin.messaging().sendToDevice(fcmToken, payload);
      // Handle invalid tokens cleanup
      response.results.forEach(async (result) => {
        if (result.error &&
            (result.error.code === 'messaging/invalid-registration-token' ||
             result.error.code === 'messaging/registration-token-not-registered')) {
          console.log(`Removing invalid token for user ${receiverId}`);
          await admin.firestore().collection('users').doc(receiverId).update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });
        }
      });
      console.log('Push notification sent successfully');
    } catch (error) {
      console.error('Error sending push notification:', error);
    }

    return null;
  });


////////////////////////////////////////////////////////////////////////////////
// User Status & Profile Updates
////////////////////////////////////////////////////////////////////////////////

exports.updateUserStatus = functions.https.onCall((data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

    // TODO: Validate `isOnline` field
      // TODO: Broadcast status change to other users (presence channel)
      // TODO: Write to Realtime Database for live presence display

  const { isOnline } = data;
  return admin.firestore().collection('users').doc(uid).update({
    isOnline,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
  });
});


exports.onUserProfileUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

      // TODO: If user changes language, re-run match generation (see TODO below)
          // TODO: Notify friends/penpals of profile changes
          // TODO: Sync profile updates to search index (if using Algolia, Elastic, etc.)

    if (beforeData.displayName !== afterData.displayName) {
      console.log(`User ${context.params.userId} changed name from ${beforeData.displayName} to ${afterData.displayName}`);
      // Could send notification or update related collections here
    }

    return null;
  });

////////////////////////////////////////////////////////////////////////////////
// Calendar & Meeting Events
////////////////////////////////////////////////////////////////////////////////

exports.sendMeetingNotification = functions.firestore
  .document('meetings/{meetingId}')
  .onWrite(async (change, context) => {
    const meetingData = change.after.exists ? change.after.data() : null;
    const beforeData = change.before.exists ? change.before.data() : null;

    // Example: Notify participants on meeting creation or update
    if (meetingData) {
      const participants = meetingData.participants || [];
      for (const userId of participants) {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) continue;

        // Determine if created or updated
        let title = 'Meeting Update';
        let body = `Meeting "${meetingData.title}" has been scheduled/updated.`;
        if (!beforeData) {
          title = 'New Meeting Scheduled';
          body = `You have a new meeting: "${meetingData.title}".`;
        } else if (change.after.exists && change.before.exists) {
          title = 'Meeting Updated';
          body = `Meeting "${meetingData.title}" was updated.`;
        } else if (!change.after.exists) {
          title = 'Meeting Cancelled';
          body = `Meeting "${beforeData.title}" was cancelled.`;
        }

        const payload = {
          notification: {
            title,
            body,
            sound: 'default',
          },
          data: {
            deepLink: `penpal://meeting/${context.params.meetingId}`, // deep link to meeting screen
            meetingId: context.params.meetingId,
          },
          apns: {
            payload: { aps: { 'content-available': 1 } },
          },
        };
          // TODO: Implement scheduling reminders (e.g., 30min before) via Cloud Scheduler
              // TODO: Exclude users who have muted meeting notifications
              // TODO: Add meeting location or link to payload for deep-linking

        try {
          await admin.messaging().sendToDevice(fcmToken, payload);
          console.log(`Meeting notification sent to user ${userId}`);
        } catch (error) {
          console.error(`Error sending meeting notification to user ${userId}:`, error);
        }
      }
    }

    return null;
  });

////////////////////////////////////////////////////////////////////////////////
// Helper: Throttle Notifications to avoid spam
////////////////////////////////////////////////////////////////////////////////

async function canSendNotification(userId) {
  const userRef = admin.firestore().collection('users').doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) return false;

  const lastNotificationSent = userDoc.data()?.lastNotificationSent?.toMillis() || 0;
  const now = Date.now();

  if (now - lastNotificationSent < 60 * 1000) { // 1 minute cooldown
    console.log(`Throttling notifications for user ${userId}`);
    return false;
  }

  await userRef.update({ lastNotificationSent: admin.firestore.Timestamp.now() });
  return true;
}

////////////////////////////////////////////////////////////////////////////////
// Scheduled / Background Tasks
////////////////////////////////////////////////////////////////////////////////

/**
 * 1) Recalculate penpal matches whenever a user’s profile changes.
 *    Also runs nightly at 2:00 AM to refresh everyone’s matches.
 */
exports.generatePenpalMatchesOnProfileChange = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    if (!change.after.exists) return null;           // skip deletes
    const userData = change.after.data();

    // Fetch all other users
    const allUsersSnap = await admin.firestore().collection('users').get();
    const matches = [];

    allUsersSnap.forEach(doc => {
      if (doc.id === userId) return;
      const other = doc.data();
      const score = computeMatchScore(userData, other);
      matches.push({ id: doc.id, score });
    });

    // Sort & pick top 10
    matches.sort((a, b) => b.score - a.score);
    const top10 = matches.slice(0, 10);

    // Write to /potentialMatches subcollection
    const batch = admin.firestore().batch();
    const pmRef = admin.firestore()
      .collection('users').doc(userId)
      .collection('potentialMatches');

    // Overwrite existing matches
    top10.forEach(match => {
      const ref = pmRef.doc(match.id);
      batch.set(ref, {
        matchScore: match.score,
        matchedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();
    console.log(`Matches recalculated for ${userId}`);
    return null;
  });

exports.generatePenpalMatchesDaily = functions.pubsub
  .schedule('0 2 * * *')               // every day at 2am
  .timeZone('America/Chicago')
  .onRun(async () => {
    const usersSnap = await admin.firestore().collection('users').get();
    const promises = usersSnap.docs.map(doc =>
      exports.generatePenpalMatchesOnProfileChange.run({ params: { userId: doc.id } })
    );
    await Promise.all(promises);
    console.log('Daily penpal match generation complete');
    return null;
  });

/**
 * 2) Send daily study reminders at 8:00 AM to users whose lastStudyAt is over 24h ago.
 *    Assumes each user document has a Timestamp field `lastStudyAt`.
 */
exports.sendStudyReminders = functions.pubsub
  .schedule('0 8 * * *')
  .timeZone('America/Chicago')
  .onRun(async () => {
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
    const snap = await admin.firestore()
      .collection('users')
      .where('lastStudyAt', '<=', cutoff)
      .get();

    const sends = snap.docs.map(async doc => {
      const { fcmToken } = doc.data();
      if (!fcmToken) return;
      const payload = {
        notification: {
          title: 'Time to Study!',
          body: 'It’s been over a day since your last lesson—let’s get back to it.',
          sound: 'default'
        },
        data: { deepLink: 'penpal://study/home' }
      };
      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
      } catch (e) {
        console.error(`Reminder failed for ${doc.id}:`, e);
      }
    });

    await Promise.all(sends);
    console.log(`Sent study reminders to ${snap.size} users`);
    return null;
  });

/**
 * 3) Clean up stale friend requests and meetings older than 7 days.
 *    Assumes `createdAt` Timestamp field on both collections.
 */
exports.cleanupStaleRequests = functions.pubsub
  .schedule('0 0 * * *')               // every midnight
  .timeZone('America/Chicago')
  .onRun(async () => {
    const ttl = 7 * 24 * 60 * 60 * 1000;
    const cutoff = admin.firestore.Timestamp.fromMillis(Date.now() - ttl);

    // Friend requests
    const frSnap = await admin.firestore()
      .collection('friendRequests')
      .where('createdAt', '<=', cutoff)
      .get();
    const frBatch = admin.firestore().batch();
    frSnap.docs.forEach(doc => frBatch.delete(doc.ref));
    await frBatch.commit();
    console.log(`Deleted ${frSnap.size} stale friend requests`);

    // Meetings
    const mSnap = await admin.firestore()
      .collection('meetings')
      .where('createdAt', '<=', cutoff)
      .get();
    const mBatch = admin.firestore().batch();
    mSnap.docs.forEach(doc => mBatch.delete(doc.ref));
    await mBatch.commit();
    console.log(`Deleted ${mSnap.size} stale meetings`);

    return null;
  });

////////////////////////////////////////////////////////////////////////////////
// Helper: Compute Match Score
////////////////////////////////////////////////////////////////////////////////

function computeMatchScore(userA, userB) {
  let score = 0;
  // 1. Same target language
  if (userA.language === userB.language) score += 2;
  // 2. Shared interests (assumes arrays `interests`)
  const common = (userA.interests || []).filter(i => (userB.interests || []).includes(i));
  score += common.length;
  // 3. Similar proficiency level
  if (userA.proficiency === userB.proficiency) score += 1;
  // ... add more criteria as needed
  return score;
}

////////////////////////////////////////////////////////////////////////////////
// TODOs for Scaling & Reliability
////////////////////////////////////////////////////////////////////////////////

// TODO: Use FCM Topics for high‑fan‑out notifications
//   - On the client, subscribe users to topics (e.g. "meeting_<meetingId>")
//   - In your functions, use `admin.messaging().sendToTopic(...)` instead of iterating tokens

// TODO: Batch Firestore reads when fetching multiple tokens
//   - Use a single `.getAll()` or a query to fetch all participant tokens in one call
//   - Or maintain a `/meetings/{id}/tokens` doc with an array of tokens

// TODO: Pin critical functions to a specific region
//   - e.g. `functions.region('us-central1').firestore.document(...)`
//   - Reduces latency and cold‑start overhead

// TODO: Add retry logic for FCM calls
//   - Retry on transient errors (e.g. "messaging/internal-error")
//   - Drop permanently invalid tokens only after retries have failed

// TODO: Implement structured logging & error reporting
//   - Use `console.log(JSON.stringify({...}))` for key fields
//   - Integrate with Stackdriver Error Reporting for alerts

// TODO: Monitor function concurrency and execution time
//   - Check Firebase Console → Functions → Monitoring
//   - Adjust memory/timeout settings or split heavy logic into separate functions

// TODO: Set up Cloud Scheduler for rate‑limited or batch operations
//   - Offload non‑urgent tasks (e.g. bulk emails, analytics exports) to scheduled jobs

// TODO: Enforce and validate input data in Firestore triggers
//   - Make sure required fields (e.g. `createdAt`, `lastStudyAt`) are always present
//   - Avoid runtime errors due to missing data

// TODO: Review billing & Firestore quotas regularly
//   - Watch for spikes in reads/writes from your functions
//   - Optimize indexes and queries to lower costs

// TODO: Harden security via Firestore Rules
//   - Ensure only authenticated users can write to `friendRequests`, `meetings`, etc.
//   - Deny any unauthorized writes that could trigger unwanted functions
