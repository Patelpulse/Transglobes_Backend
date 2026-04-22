const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Email/Password + Google auth
router.post('/signup', userController.signup);
router.post('/login', userController.login);
router.post('/google-auth', userController.googleAuth);

// Public routes for OTP-based registration
router.post('/register-phone', userController.registerPhone);
router.post('/save-name', userController.saveName);
router.post('/location', userController.saveSavedLocation);

// Profile routes (by phone number)
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.get('/profile/:mobileNumber', userController.getProfile);
router.put('/profile/:mobileNumber', userController.updateProfile);
router.post('/fcm-token', userController.updateFCMToken);

module.exports = router;
