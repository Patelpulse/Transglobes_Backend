const express = require('express');
const router = express.Router();
const {
    syncDriverData,
    register,
    login,
    getDriverProfile,
    uploadDocuments,
    getDriverStatus,
    updateDriverProfile,
    updateStatus,
    updateLocation,
    sendOTP,
    verifyOTP
} = require('../controllers/driverController');
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// POST /api/driver/otp/send - Send OTP to email
router.post('/otp/send', sendOTP);

// POST /api/driver/otp/verify - Verify OTP and mark email as verified
router.post('/otp/verify', verifyToken, verifyOTP);

// GET /api/driver/check-email - Check if email exists
router.get('/check-email', (req, res, next) => {
    const { checkEmailAvailability } = require('../controllers/driverController');
    checkEmailAvailability(req, res, next);
});

// POST /api/driver/sync - To sync driver basic data to DB
router.post('/sync', syncDriverData);
router.post('/register', register);
router.post('/login', login);

// GET /api/driver/status - Check driver onboarding status
router.get('/status', verifyToken, getDriverStatus);

// GET /api/driver/profile - Gets driver profile authenticated by Firebase token
router.get('/profile', verifyToken, getDriverProfile);

// PUT /api/driver/profile/update - Updates driver profile
router.put('/profile/update', verifyToken, updateDriverProfile);

// PUT /api/driver/status - Updates driver online/offline status
router.put('/status', verifyToken, updateStatus);

// PUT /api/driver/location - Updates driver GPS location
router.put('/location', verifyToken, updateLocation);

// POST /api/driver/upload - Uploads driver documents
router.post('/upload', (req, res, next) => {
    // Force bypass for dev/localhost troubleshooting
    if (req.hostname === 'localhost' || req.hostname === '127.0.0.1') {
        req.user = { uid: req.headers['x-dev-uid'] || req.headers['x-dev-id'] || 'dev-user-uid' };
        return next();
    }
    verifyToken(req, res, next);
}, upload.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'aadharCard', maxCount: 1 },
    { name: 'drivingLicense', maxCount: 1 },
    { name: 'signature', maxCount: 1 },
    { name: 'panCard', maxCount: 1 },
    { name: 'rcBook', maxCount: 1 },
    { name: 'insurance', maxCount: 1 }
]), uploadDocuments);

// POST /api/driver/fcm-token - Update FCM token
router.post('/fcm-token', verifyToken, (req, res, next) => {
    const { updateFCMToken } = require('../controllers/driverController');
    updateFCMToken(req, res, next);
});

module.exports = router;
