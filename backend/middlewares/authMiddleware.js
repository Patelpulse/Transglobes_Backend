const admin = require('../config/firebase');
const jwt = require('jsonwebtoken');

console.log("!!! AUTH MIDDLEWARE LOADED !!!");

const isExplicitDevBypassEnabled = () =>
    process.env.NODE_ENV !== 'production' &&
    process.env.ALLOW_DEV_AUTH_BYPASS === 'true';

// ─── Attach role from DB (User or Driver) ────────────────
const attachRoleFromDB = async (uid) => {
    try {
        const User = require('../models/User');
        const Driver = require('../models/Driver');

        const user = await User.findOne({ uid });
        if (user) return { dbUser: user, role: user.role || 'user', collection: 'user' };

        const driver = await Driver.findOne({ $or: [{ uid }, { firebaseId: uid }] });
        if (driver) return { dbUser: driver, role: 'driver', collection: 'driver' };
    } catch (e) {
        console.warn('[AUTH] DB role lookup failed:', e.message);
    }
    return { dbUser: null, role: 'user', collection: null };
};

// ─── Track device & session info ─────────────────────────
const trackDevice = async (uid, req, collection) => {
    try {
        const deviceInfo = {
            model: req.headers['x-device-model'] || 'Unknown',
            platform: req.headers['x-device-platform'] || req.headers['user-agent'] || 'Unknown',
            version: req.headers['x-app-version'] || '0',
        };
        const now = new Date();

        if (collection === 'user') {
            const User = require('../models/User');
            await User.updateOne({ uid }, { $set: { deviceInfo, lastActive: now, lastLoginAt: now } });
        } else if (collection === 'driver') {
            const Driver = require('../models/Driver');
            await Driver.updateOne(
                { $or: [{ uid }, { firebaseId: uid }] },
                { $set: { deviceInfo, lastLoginAt: now } }
            );
        }
    } catch (e) {
        // Non-critical — don't block request
        console.warn('[AUTH] Device tracking failed:', e.message);
    }
};

const verifyToken = async (req, res, next) => {
    let token = req.headers.authorization;
    if (token && token.startsWith('Bearer ')) {
        token = token.split(' ')[1];
    }

    if (!token) {
        return res.status(401).json({ message: 'No token provided' });
    }

    // Dev Bypass
    const normalizedToken = (token || '').toString().toLowerCase().trim();
    const isDevToken = normalizedToken.includes('dev-token-bypass');

    if (isDevToken && isExplicitDevBypassEnabled()) {
        console.log(`[AUTH-DEBUG] >>> Dev Bypass Triggered`);
        const devUid = req.headers['x-dev-uid'] || req.headers['x-dev-id'];
        req.user = { uid: devUid || 'dev-user-uid', email: 'dev@example.com', role: 'driver' };
        return next();
    }

    try {
        let uid = null;
        let decoded = null;

        // 1. Try Firebase Token
        try {
            decoded = await admin.auth().verifyIdToken(token);
            uid = decoded.uid;
            req.user = decoded;
        } catch (firebaseErr) {
            console.log('[AUTH] Firebase verify failed, trying local JWT...');
        }

        // 2. Try Local JWT
        if (!uid) {
            try {
                const localDecoded = jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key');
                uid = localDecoded.uid || localDecoded.id;
                req.user = {
                    uid,
                    email: localDecoded.email,
                    role: localDecoded.role,
                    ...localDecoded,
                };
            } catch (jwtErr) {
                if (isExplicitDevBypassEnabled()) {
                    console.warn('[AUTH-DEV] Explicit development auth bypass enabled.');
                    req.user = {
                        uid: req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid',
                        email: 'dev@example.com',
                        role: 'driver',
                    };
                    return next();
                }
                return res.status(401).json({ message: 'Unauthorized', error: 'Invalid token' });
            }
        }

        // 3. Attach role from DB + track device (non-blocking)
        if (uid) {
            const { dbUser, role, collection } = await attachRoleFromDB(uid);
            if (dbUser) {
                req.user.role = role;
                req.user.dbUser = dbUser;
            }
            // Fire and forget — don't await
            trackDevice(uid, req, collection).catch(() => {});
        }

        return next();
    } catch (error) {
        console.error('Core auth error:', error);
        res.status(500).json({ message: 'Auth logic error' });
    }
};

module.exports = { verifyToken };
