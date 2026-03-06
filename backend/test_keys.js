require('dotenv').config();
const admin = require('firebase-admin');

// Try with actual process.env parsing (what we do in firebase.js)
let privateKey = process.env.FIREBASE_PRIVATE_KEY;
if (privateKey) {
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
    }
    privateKey = privateKey.replace(/\\n/g, '\n');
}

try {
    admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey,
    });
    console.log('SUCCESS: Key is valid');
} catch (e) {
    console.error('ERROR:', e.message);

    // Try the other key user sent
    const alternativeKey = "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDhaLJ2MhXpXrlJ\njqLlHsgf4IdViJce1k+h2umPxEpzWwpOiJV+cA5WO3yTfSyAs4/8bK7nnfqdICzA\nRRgnaeiRgFTcvhGuFE36gVW60FGzdYRl7fRLtTPehKSlFWiPYB8f3behQlHtkbuV\nUMEyOdrDg/HLizplo8FNosxeWo6UWfDg5CGc49KwhpWcWuY0S/ASmFP8jBEkBVzc\nAbuyfbQl30a+m0c1eEG4VNCJlfwMvgqtMvqKBbbMqhfYxmm/EIzd2tjuvLy8aRys\nBD2dVE2YCxj2XIXC8AjjirktP3EqQgCkZUUFnM5FDGnSU1V8kkuARLr4PspUAr8s\nJdRylJVbAgMBAAECggEAUX7Hawlft7C6H9iUl28CHthQRcHtFUaZouShZgureTp0\npwElv4FnBZFbUH3ErcF98N8ge3g4CD/+PgOdIH7fiV+TDv4fKUeJC+Vf5/tyVoZJ\n+IpINWkNmElvt4nedFvl1OEWB5URRunWHr2EJBMbv22Aab1sPxwuAtI1vnVSMFsI\nkkj/C3nZr9SsUZlyP8FfnvjLe/I07cl4RO5FPWPKnEeGYBtyi5ccLTejzFzJeG7i\nVVj4Wy150K+ImYnBS/btn1F/NaCCOdBfA7xXU5D6cLF/trxsVeGqirdxpa8ZznZY\nVJa+x6uLL/yKOD56qAJlUvTzxUC9LnL/u7/tl6G6CQKBgQDxZzLXJ3RbnB9Nb/ts\nDDYB5KSW+j7pVVaoyM/GTpqx5v4UF5fkXFrcSLaoMzTw71heybvKFmmOAE94ffGt\n6VNL8h6lEERt7ZDYcF3CX1z1p+PjzR1++PPJTUdKG7vsQ3ba+CHw1DPLF2gZTfpu\nIg4cJL1m2LsWiYftGLQ+/AOuKQKBgQDvCerBOsOtO9h9+EnZS9BWJQBxzGLqn449\n2eUJR2rYMecCQ65uXAyXw4k1Q72szBd9SZxODFAactOgWnnchqqVQBUM9NUQPijM\nJgyD+9BwAgup0oDUJX3QKL8xJe+3xbyJZthhK3WA7C6jbkLoT1P6fSHQucVw7rs2\nLfX5iU7P4wKBgBqvyuoIHY/nEXrRD11heDL7YMqj/YJ0AbGFCZslo2pZW+tCtHL1\nVsIVc8PibU7ZVs6bxJvRoHenRyHN4oLUUXYK3SJoSvhQE/wpZ+QOAMvTdJkBWupn\ngSPW3DOwHzU+PAx28+GYw+UGwGZTvYShVSf9U8bj3MLgD1vBqGNyHsIJAoGBANiK\nqlBblLHU+fy7tOKVTGkNYga0+ZLD8c5UGqi6Oq8ZHcUuXND6sCm3aA+Ji0UDKfBE\ng8UsYFBlXxLvg19j2xoTkD5JeM4bEUhG26Wgs6UUJU61NCF6ySuODg1O6YcYKQBr\n227DONIOov1IQHJEkrXjL4PvFk6E5bFiF2bznSKzAoGASx8NIQi/MBBqEXtSzeK0\n6Jqsyt2AGsr3ZDJdCEtbzoUn3ZcCzlH5LX2BHKx5JkRLyheuPI4TIV1ZfSagHRdA\njWL5vmcfCjgGYjPen/VFULS43IjFRPskUbzj8QtvI8PB9BGxu3iYsQ9jC6Ai/EDu\nQwY6S5XDvPnkhu7AE2DhZLw=\n-----END PRIVATE KEY-----\n".replace(/\\n/g, '\n');

    try {
        admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey: alternativeKey,
        });
        console.log('SUCCESS: Alternative key is valid');
    } catch (e2) {
        console.error('ERROR alt key:', e2.message);
    }
}
