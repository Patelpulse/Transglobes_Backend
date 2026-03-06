const admin = require('firebase-admin');

// Ensure that newlines in the private key are handled properly
let privateKey = process.env.FIREBASE_PRIVATE_KEY;
if (privateKey) {
    // If wrapped in quotes, remove them
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
    }
    // Replace literal '\n' strings with actual newlines
    privateKey = privateKey.replace(/\\n/g, '\n');
}

admin.initializeApp({
    credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey,
    }),
    databaseURL: process.env.FIREBASE_DATABASE_URL
});

module.exports = admin;
