const admin = require('../config/firebase');
const jwt = require('jsonwebtoken');

const verifyToken = async (req, res, next) => {
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) {
        token = token.split(' ')[1];
    }

    if (!token) {
        return res.status(401).json({ message: 'No token provided' });
    }

    // Dev Bypass
    if (token === 'dev-token-bypass') {
        req.user = { uid: 'dev-user-uid', email: 'dev@example.com' };
        return next();
    }

    try {
        // 1. Try Firebase Token first
        try {
            const decodedToken = await admin.auth().verifyIdToken(token);
            req.user = decodedToken;
            return next();
        } catch (firebaseErr) {
            // If Firebase fails, we proceed to check local JWT
            console.log('[AUTH] Firebase verify failed, trying local JWT...');
        }

        // 2. Try Local JWT
        try {
            const localDecoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
            // Normalize the user object (Firebase uses 'uid', custom uses 'id')
            req.user = {
                uid: localDecoded.uid || localDecoded.id, // Support both
                email: localDecoded.email,
                ...(localDecoded)
            };
            next();
        } catch (jwtErr) {
            console.error('[AUTH] All token verification methods failed:', jwtErr.message);
            return res.status(401).json({ message: 'Unauthorized', error: 'Invalid token' });
        }
    } catch (error) {
        console.error('Core auth error:', error);
        res.status(500).json({ message: 'Auth logic error' });
    }
};

module.exports = { verifyToken };
