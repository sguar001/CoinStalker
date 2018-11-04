const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const createProfile = (user) => {
  return db.collection('profiles').doc(user.uid)
    .set({
      trackedSymbols: [],
    })
    .catch(console.error);
};

const deleteProfile = (user) => {
  return db.collection('profiles').doc(user.uid)
    .delete()
    .catch(console.error);
};

module.exports = {
  authOnCreate: functions.auth.user().onCreate(createProfile),
  authOnDelete: functions.auth.user().onDelete(deleteProfile),
};
