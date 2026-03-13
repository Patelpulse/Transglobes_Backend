const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Public routes for OTP-based registration
router.post('/register-phone', userController.registerPhone);
router.post('/save-name', userController.saveName);
router.post('/location', userController.saveSavedLocation);

// Profile routes (by phone number)
router.get('/profile/:mobileNumber', userController.getProfile);
router.put('/profile/:mobileNumber', userController.updateProfile);
router.post('/fcm-token', userController.updateFCMToken);

module.exports = router;
