const express = require('express');
const router = express.Router();
const {
    syncDriverData,
    getDriverProfile,
    uploadDocuments,
    getDriverStatus,
    updateDriverProfile,
    sendOTP,
    verifyOTP
} = require('../controllers/driverController');
const { verifyToken } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// POST /api/driver/otp/send - Send OTP to email
router.post('/otp/send', sendOTP);

// POST /api/driver/otp/verify - Verify OTP and mark email as verified
router.post('/otp/verify', verifyToken, verifyOTP);

// POST /api/driver/sync - To sync driver basic data to DB
router.post('/sync', syncDriverData);

// GET /api/driver/status - Check driver onboarding status
router.get('/status', verifyToken, getDriverStatus);

// GET /api/driver/profile - Gets driver profile authenticated by Firebase token
router.get('/profile', verifyToken, getDriverProfile);

// PUT /api/driver/profile/update - Updates driver profile
router.put('/profile/update', verifyToken, updateDriverProfile);

// POST /api/driver/upload - Uploads driver documents
router.post('/upload', verifyToken, upload.fields([
    { name: 'photo', maxCount: 1 },
    { name: 'aadharCard', maxCount: 1 },
    { name: 'drivingLicense', maxCount: 1 },
    { name: 'signature', maxCount: 1 }
]), uploadDocuments);

module.exports = router;
