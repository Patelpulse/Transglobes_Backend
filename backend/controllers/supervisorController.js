const LogisticsBooking = require('../models/LogisticsBooking');
const User = require('../models/User');
const Driver = require('../models/Driver');

// ─── PATCH /api/admin/supervisor/bookings/:bookingId/goods
// Edit goods details for a logistics booking
exports.editGoodsDetails = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { items, helperCount, vehicleType } = req.body;

        const update = {};
        if (items !== undefined) update.items = items;
        if (helperCount !== undefined) update.helperCount = helperCount;
        if (vehicleType !== undefined) update.vehicleType = vehicleType;

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { $set: update },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Notify via socket if client is connected
        if (req.io) {
            req.io.to(booking.userId.toString()).emit('booking_updated', {
                bookingId: booking._id.toString(),
                type: 'GOODS_UPDATED',
            });
        }

        return res.status(200).json({ success: true, message: 'Goods details updated.', data: booking });
    } catch (error) {
        console.error('Error editing goods details:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/admin/supervisor/bookings/:bookingId/pricing-override
// Supervisor overrides pricing charges (toll, night, handling)
exports.overridePricing = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const {
            vehiclePrice,
            helperCost,
            additionalCharges,  // Includes toll + night charges
            discountAmount,
            totalPrice,
            tollCharges,
            nightCharges,
            handlingCharges,
        } = req.body;

        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Build combined additionalCharges if sub-fields provided
        let finalAdditional = additionalCharges;
        if (tollCharges !== undefined || nightCharges !== undefined || handlingCharges !== undefined) {
            finalAdditional = (tollCharges || 0) + (nightCharges || 0) + (handlingCharges || 0);
        }

        if (vehiclePrice !== undefined) booking.vehiclePrice = Number(vehiclePrice);
        if (helperCost !== undefined) booking.helperCost = Number(helperCost);
        if (finalAdditional !== undefined) booking.additionalCharges = Number(finalAdditional);
        if (discountAmount !== undefined) booking.discountAmount = Number(discountAmount);
        if (totalPrice !== undefined) {
            booking.totalPrice = Number(totalPrice);
        } else {
            booking.totalPrice = booking.vehiclePrice + booking.helperCost + booking.additionalCharges - booking.discountAmount;
        }

        await booking.save();

        if (req.io) {
            req.io.to(booking.userId.toString()).emit('booking_updated', {
                bookingId: booking._id.toString(),
                type: 'PRICING_UPDATED',
                totalPrice: booking.totalPrice,
            });
        }

        return res.status(200).json({ success: true, message: 'Pricing overridden successfully.', data: booking });
    } catch (error) {
        console.error('Error overriding pricing:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/admin/supervisor/bookings/:bookingId/approve
// Supervisor approves and finalizes a logistics booking
exports.approveBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { estimatedTime, estimatedDate } = req.body;

        const update = { status: 'confirmed' };
        if (estimatedTime) update.estimatedTime = estimatedTime;
        if (estimatedDate) update.estimatedDate = estimatedDate;

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            update,
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Push notification to user
        const { notifyUser } = require('../utils/notificationService');
        notifyUser(booking.userId, {
            title: 'Shipment Approved',
            body: 'Your logistics booking has been reviewed and approved by a supervisor.',
            data: {
                bookingId: booking._id.toString(),
                type: 'BOOKING_APPROVED',
            },
        });

        if (req.io) {
            req.io.to(booking.userId.toString()).emit('booking_approved', {
                bookingId: booking._id.toString(),
                status: 'confirmed',
            });
        }

        return res.status(200).json({ success: true, message: 'Booking approved.', data: booking });
    } catch (error) {
        console.error('Error approving booking:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/supervisor/stats
// Get supervisor dashboard statistics
exports.getSupervisorStats = async (req, res) => {
    try {
        const [pending, confirmed, inTransit, delivered, cancelled] = await Promise.all([
            LogisticsBooking.countDocuments({ status: 'pending' }),
            LogisticsBooking.countDocuments({ status: { $in: ['confirmed', 'processing'] } }),
            LogisticsBooking.countDocuments({ status: 'in_transit' }),
            LogisticsBooking.countDocuments({ status: 'delivered' }),
            LogisticsBooking.countDocuments({ status: 'cancelled' }),
        ]);

        // Revenue from delivered bookings (last 30 days)
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const revenueResult = await LogisticsBooking.aggregate([
            { $match: { status: 'delivered', createdAt: { $gte: thirtyDaysAgo } } },
            { $group: { _id: null, total: { $sum: '$totalPrice' } } },
        ]);
        const revenue = revenueResult[0]?.total || 0;

        return res.status(200).json({
            success: true,
            data: {
                pending,
                confirmed,
                inTransit,
                delivered,
                cancelled,
                totalActive: pending + confirmed + inTransit,
                last30DaysRevenue: revenue,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/admin/users/:userId/block
// Block or unblock a user
exports.blockUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const { block } = req.body; // true = block, false = unblock

        const user = await User.findOneAndUpdate(
            { $or: [{ uid: userId }, { _id: userId.match(/^[0-9a-fA-F]{24}$/) ? userId : undefined }] },
            { isFraudulent: block === true },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found.' });
        }

        return res.status(200).json({
            success: true,
            message: block ? 'User blocked successfully.' : 'User unblocked successfully.',
            data: user,
        });
    } catch (error) {
        console.error('Error blocking user:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/admin/drivers/:driverId/block
// Block (suspend) or unblock (activate) a driver
exports.blockDriver = async (req, res) => {
    try {
        const { driverId } = req.params;
        const { block } = req.body; // true = block, false = unblock

        const newStatus = block ? 'suspended' : 'active';
        const driver = await Driver.findByIdAndUpdate(
            driverId,
            { status: newStatus },
            { new: true }
        );

        if (!driver) {
            return res.status(404).json({ success: false, message: 'Driver not found.' });
        }

        return res.status(200).json({
            success: true,
            message: block ? 'Driver suspended.' : 'Driver activated.',
            data: driver,
        });
    } catch (error) {
        console.error('Error blocking driver:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/admin/drivers/:driverId/online
// Manually toggle a driver's online/offline status (Admin override)
exports.toggleDriverOnline = async (req, res) => {
    try {
        const { driverId } = req.params;
        const { isOnline } = req.body;

        const driver = await Driver.findByIdAndUpdate(
            driverId,
            { isOnline: isOnline === true },
            { new: true }
        );

        if (!driver) {
            return res.status(404).json({ success: false, message: 'Driver not found.' });
        }

        return res.status(200).json({
            success: true,
            message: `Driver is now ${isOnline ? 'online' : 'offline'}.`,
            data: driver,
        });
    } catch (error) {
        console.error('Error toggling driver online status:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
