const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const adminSignupController = require('../controllers/adminsigup');
const adminController = require('../controllers/adminController');
const corporateController = require('../controllers/corporateController');
const driverController = require('../controllers/driverController');
const { verifyToken } = require('../middlewares/authMiddleware');
const { verifyAdminToken } = require('../middlewares/authMiddlewareAdmin');

// User auth/profile compatibility routes
router.post('/user/signup', userController.signup);
router.post('/user/login', userController.login);
router.post('/user/google-auth', userController.googleAuth);
router.post('/user/mobile-signup', userController.mobileSignup);
router.post('/user/mobile-login', userController.mobileLogin);
router.post('/send-otp', userController.sendOtp);
router.post('/verify-otp', userController.verifyOtp);
router.post('/refresh', (req, res) => {
  return res.status(200).json({ success: true, message: 'Token refresh not required for current auth flow.' });
});
router.post('/logout', (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out.' });
});
router.get('/profile', verifyToken, userController.getProfile);
router.put('/profile', verifyToken, userController.updateProfile);
router.post('/register-phone', userController.registerPhone);

// Admin auth compatibility routes
router.post('/admin/login', adminSignupController.login);
router.post('/admin/register', adminSignupController.signup);
router.post('/admin/sync', adminController.syncAdminData);
router.post('/admin/logout', verifyAdminToken, adminSignupController.logout);
router.get('/admin/profile', verifyAdminToken, adminSignupController.getProfile);

// Corporate auth compatibility routes
router.post('/corporate/signup', corporateController.signup);
router.post('/corporate/login', corporateController.login);
router.post('/corporate/google-auth', corporateController.googleAuth);
router.post('/corporate/google-sync', corporateController.googleSync);
router.post('/corporate/mobile-signup', corporateController.mobileSignup);
router.post('/corporate/mobile-login', corporateController.mobileLogin);
router.get('/corporate/profile', verifyToken, corporateController.getProfile);

// Driver auth compatibility routes
router.post('/driver/signup', driverController.register);
router.post('/driver/login', driverController.login);
router.post('/driver/google-auth', driverController.googleAuth);
router.post('/driver/mobile-signup', driverController.mobileSignup);
router.post('/driver/mobile-login', driverController.mobileLogin);

module.exports = router;
