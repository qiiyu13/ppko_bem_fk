const admin = require('firebase-admin');

const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
  ? JSON.parse(Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT, 'base64').toString())
  : null;

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else if (process.env.NODE_ENV !== 'production') {
  console.warn('WARNING: FIREBASE_SERVICE_ACCOUNT not set. OTP verification will fail.');
}

async function verifyFirebaseToken(idToken) {
  if (!admin.apps.length) {
    throw Object.assign(new Error('Firebase not configured'), { statusCode: 500 });
  }
  return admin.auth().verifyIdToken(idToken);
}

module.exports = { admin, verifyFirebaseToken };
