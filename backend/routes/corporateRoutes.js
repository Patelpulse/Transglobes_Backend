const express = require('express');
const router = express.Router();
const corporateController = require('../controllers/corporateController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/login', corporateController.login);
router.post('/google-sync', corporateController.googleSync);
router.get('/profile', verifyToken, corporateController.getProfile);
router.get('/bookings', verifyToken, corporateController.getBookings);

module.exports = router;
