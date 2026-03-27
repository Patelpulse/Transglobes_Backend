const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { verifyToken } = require('../middlewares/authMiddleware');

// ─── Razorpay ─────────────────────────────────────────────
// POST /api/payment/create-order   → create Razorpay order
router.post('/create-order', verifyToken, paymentController.createOrder);

// POST /api/payment/verify         → verify payment signature
router.post('/verify', verifyToken, paymentController.verifyPayment);

// ─── Wallet ───────────────────────────────────────────────
// POST /api/payment/wallet/add     → add funds
router.post('/wallet/add', verifyToken, paymentController.walletAdd);

// POST /api/payment/wallet/deduct  → deduct funds (pay booking)
router.post('/wallet/deduct', verifyToken, paymentController.walletDeduct);

// GET  /api/payment/wallet/balance → get current balance
router.get('/wallet/balance', verifyToken, paymentController.getWalletBalance);

// ─── Driver Earnings ──────────────────────────────────────
// GET  /api/payment/driver/earnings/:driverId
router.get('/driver/earnings/:driverId', verifyToken, paymentController.getDriverEarnings);

// ─── Invoice ──────────────────────────────────────────────
// GET  /api/payment/invoice/:bookingId → GST invoice JSON
router.get('/invoice/:bookingId', verifyToken, paymentController.getInvoice);

module.exports = router;
