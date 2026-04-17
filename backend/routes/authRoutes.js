const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const adminSignupController = require('../controllers/adminsigup');
const adminController = require('../controllers/adminController');
const corporateController = require('../controllers/corporateController');
const { verifyToken } = require('../middlewares/authMiddleware');
const { verifyAdminToken } = require('../middlewares/authMiddlewareAdmin');

// User auth/profile compatibility routes
router.post('/send-otp', userController.registerPhone);
router.post('/verify-otp', userController.registerPhone);
router.post('/refresh', (req, res) => {
  return res.status(200).json({ success: true, message: 'Token refresh not required for current auth flow.' });
});
router.post('/logout', (req, res) => {
  return res.status(200).json({ success: true, message: 'Logged out.' });
});
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.post('/register-phone', userController.registerPhone);

// Admin auth compatibility routes
router.post('/admin/login', adminSignupController.login);
router.post('/admin/register', adminSignupController.signup);
router.post('/admin/sync', adminController.syncAdminData);
router.post('/admin/logout', verifyAdminToken, adminSignupController.logout);
router.get('/admin/profile', verifyAdminToken, adminSignupController.getProfile);

// Corporate auth compatibility routes
router.post('/corporate/login', corporateController.login);
router.post('/corporate/google-sync', corporateController.googleSync);
router.get('/corporate/profile', verifyToken, corporateController.getProfile);

module.exports = router;
