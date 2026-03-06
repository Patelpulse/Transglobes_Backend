const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middlewares/authMiddleware');

// Public or User App Synced Route
router.post('/sync', userController.syncUser);
router.post('/register', userController.register);
router.post('/login', userController.login);

// Protected routes (requires user to be logged in via firebase)
router.use(verifyToken);
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);

module.exports = router;
