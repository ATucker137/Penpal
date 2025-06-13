//
//  index.js
//  Penpal
//
//  Created by Austin William Tucker on 4/8/25.
//

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateUserStatus = functions.https.onCall((data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  const { isOnline } = data;
  return admin.firestore().collection('users').doc(uid).update({
    isOnline,
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
  });
});
