/**
 * Payment Controller
 * Handles Razorpay order creation, webhook verification,
 * in-app wallet operations, driver earnings, and PDF invoice generation.
 *
 * Requires env vars:
 *   RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET
 */

const Transaction = require('../models/Transaction');
const LogisticsBooking = require('../models/LogisticsBooking');
const User = require('../models/User');
const Driver = require('../models/Driver');

// ─── Razorpay Setup (lazy-loaded so server starts without keys) ───
const getRazorpay = () => {
    const Razorpay = require('razorpay');
    return new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
};

// ─── POST /api/payment/create-order ──────────────────────
// Create a Razorpay order for a booking
exports.createOrder = async (req, res) => {
    try {
        const { bookingId, amount, currency = 'INR', bookingType = 'logistics' } = req.body;

        if (!bookingId || !amount) {
            return res.status(400).json({ success: false, message: 'bookingId and amount are required.' });
        }

        if (!process.env.RAZORPAY_KEY_ID) {
            return res.status(503).json({ success: false, message: 'Payment gateway not configured. Set RAZORPAY_KEY_ID env var.' });
        }

        const razorpay = getRazorpay();
        const order = await razorpay.orders.create({
            amount: Math.round(amount * 100), // paise
            currency,
            receipt: `receipt_${bookingId}_${Date.now()}`,
            notes: { bookingId, bookingType },
        });

        // Create pending transaction record
        await Transaction.create({
            bookingId,
            amount,
            type: 'payment',
            method: 'card',
            status: 'pending',
            metadata: { razorpayOrderId: order.id },
        });

        return res.status(200).json({
            success: true,
            data: {
                orderId: order.id,
                amount: order.amount,
                currency: order.currency,
                keyId: process.env.RAZORPAY_KEY_ID,
            },
        });
    } catch (error) {
        console.error('[PAYMENT] Create order error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/payment/verify ─────────────────────────────
// Verify Razorpay payment signature after client payment
exports.verifyPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature,
            bookingId,
            driverId,
        } = req.body;

        const crypto = require('crypto');
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
            .update(`${razorpay_order_id}|${razorpay_payment_id}`)
            .digest('hex');

        if (expectedSignature !== razorpay_signature) {
            return res.status(400).json({ success: false, message: 'Payment signature verification failed.' });
        }

        // Fetch booking to get amount and commission split
        const booking = await LogisticsBooking.findById(bookingId);
        const totalAmount = booking?.totalPrice || 0;

        // Commission split (80% driver, 20% platform — configurable via PricingConfig)
        const driverCommission = 0.80;
        const driverEarnings = Math.round(totalAmount * driverCommission);
        const adminCommission = totalAmount - driverEarnings;

        // Mark transaction as completed
        await Transaction.findOneAndUpdate(
            { bookingId, status: 'pending' },
            {
                status: 'completed',
                driverEarnings,
                adminCommission,
                metadata: { razorpay_order_id, razorpay_payment_id },
            }
        );

        // Credit driver wallet
        if (driverId) {
            await Driver.findByIdAndUpdate(driverId, {
                $inc: { walletBalance: driverEarnings },
            });
        }

        // Update booking status
        if (booking) {
            booking.status = 'confirmed';
            await booking.save();
        }

        return res.status(200).json({
            success: true,
            message: 'Payment verified and recorded.',
            data: { driverEarnings, adminCommission },
        });
    } catch (error) {
        console.error('[PAYMENT] Verify error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/payment/wallet/add ─────────────────────────
// Add funds to user/driver wallet
exports.walletAdd = async (req, res) => {
    try {
        const { userId, driverId, amount, method = 'upi' } = req.body;
        if (!amount || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Invalid amount.' });
        }

        let entity;
        let entityType;

        if (userId) {
            entity = await User.findOneAndUpdate(
                { $or: [{ uid: userId }, { _id: userId }] },
                { $inc: { walletBalance: amount } },
                { new: true }
            );
            entityType = 'user';
        } else if (driverId) {
            entity = await Driver.findByIdAndUpdate(
                driverId,
                { $inc: { walletBalance: amount } },
                { new: true }
            );
            entityType = 'driver';
        }

        if (!entity) return res.status(404).json({ success: false, message: 'User/Driver not found.' });

        await Transaction.create({
            userId: userId || undefined,
            driverId: driverId || undefined,
            amount,
            type: 'payment',
            method,
            status: 'completed',
        });

        return res.status(200).json({
            success: true,
            message: `₹${amount} added to ${entityType} wallet.`,
            newBalance: entity.walletBalance,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/payment/wallet/deduct ──────────────────────
// Deduct from wallet (for payments)
exports.walletDeduct = async (req, res) => {
    try {
        const { userId, driverId, amount, bookingId } = req.body;
        if (!amount || amount <= 0) {
            return res.status(400).json({ success: false, message: 'Invalid amount.' });
        }

        let entity;
        if (userId) {
            entity = await User.findOne({ $or: [{ uid: userId }, { _id: userId }] });
        } else if (driverId) {
            entity = await Driver.findById(driverId);
        }

        if (!entity) return res.status(404).json({ success: false, message: 'User/Driver not found.' });
        if ((entity.walletBalance || 0) < amount) {
            return res.status(400).json({ success: false, message: 'Insufficient wallet balance.' });
        }

        entity.walletBalance -= amount;
        await entity.save();

        await Transaction.create({
            userId: userId || undefined,
            driverId: driverId || undefined,
            bookingId: bookingId || undefined,
            amount,
            type: 'payment',
            method: 'wallet',
            status: 'completed',
        });

        return res.status(200).json({
            success: true,
            message: `₹${amount} deducted from wallet.`,
            newBalance: entity.walletBalance,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/payment/wallet/balance ──────────────────────
// Get wallet balance for user or driver
exports.getWalletBalance = async (req, res) => {
    try {
        const { userId, driverId } = req.query;
        let balance = 0;

        if (userId) {
            const user = await User.findOne({ $or: [{ uid: userId }, { _id: userId }] });
            balance = user?.walletBalance || 0;
        } else if (driverId) {
            const driver = await Driver.findById(driverId);
            balance = driver?.walletBalance || 0;
        }

        return res.status(200).json({ success: true, balance });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/payment/driver/earnings/:driverId ───────────
// Get driver earnings breakdown
exports.getDriverEarnings = async (req, res) => {
    try {
        const { driverId } = req.params;
        const driver = await Driver.findById(driverId);
        if (!driver) return res.status(404).json({ success: false, message: 'Driver not found.' });

        const now = new Date();
        const weekAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
        const monthAgo = new Date(now - 30 * 24 * 60 * 60 * 1000);

        const [weeklyTxns, monthlyTxns, allTxns] = await Promise.all([
            Transaction.find({ driverId, status: 'completed', createdAt: { $gte: weekAgo } }),
            Transaction.find({ driverId, status: 'completed', createdAt: { $gte: monthAgo } }),
            Transaction.find({ driverId, status: 'completed' }),
        ]);

        const sum = (txns) => txns.reduce((acc, t) => acc + (t.driverEarnings || t.amount || 0), 0);

        return res.status(200).json({
            success: true,
            data: {
                walletBalance: driver.walletBalance,
                weeklyEarnings: sum(weeklyTxns),
                monthlyEarnings: sum(monthlyTxns),
                totalEarnings: sum(allTxns),
                recentTransactions: monthlyTxns.slice(0, 20),
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/payment/invoice/:bookingId ──────────────────
// Generate GST-compliant invoice as JSON (client renders PDF)
exports.getInvoice = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found.' });

        const gstRate = 0.18;
        const subtotal = booking.vehiclePrice + booking.helperCost + booking.additionalCharges;
        const discount = booking.discountAmount || 0;
        const taxableAmount = subtotal - discount;
        const cgst = Math.round(taxableAmount * (gstRate / 2));
        const sgst = Math.round(taxableAmount * (gstRate / 2));
        const totalWithTax = taxableAmount + cgst + sgst;

        const invoice = {
            invoiceNumber: `TG-${bookingId.toString().slice(-8).toUpperCase()}`,
            invoiceDate: new Date().toISOString().split('T')[0],
            companyName: 'Transglobe Logistics Pvt. Ltd.',
            companyGST: process.env.COMPANY_GST || 'GSTIN-PENDING',
            companyAddress: process.env.COMPANY_ADDRESS || 'New Delhi, India',
            customer: {
                name: booking.userName,
                phone: booking.userPhone,
                address: booking.pickupAddress?.fullAddress || booking.pickup?.address,
            },
            delivery: {
                address: booking.receivedAddress?.fullAddress || booking.dropoff?.address,
            },
            items: [
                { description: `${booking.vehicleType} Transport Charge`, amount: booking.vehiclePrice },
                { description: `Helper Cost (${booking.helperCount} helpers)`, amount: booking.helperCost },
                { description: 'Additional Charges', amount: booking.additionalCharges },
            ].filter(i => i.amount > 0),
            discount,
            taxableAmount,
            cgst,
            sgst,
            totalWithTax,
            status: booking.status,
            paymentMethod: 'Wallet / UPI',
        };

        return res.status(200).json({ success: true, data: invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
