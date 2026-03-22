const LogisticsBooking = require('../models/LogisticsBooking');

// ─── POST /api/logistics-bookings  ──────────────────────
// Create a new logistics booking with all details
exports.createBooking = async (req, res) => {
    try {
        const {
            userId,
            userName,
            userPhone,
            pickup,
            dropoff,
            distanceKm,
            vehicleType,
            vehiclePrice,
            items,
            helperCount,
            helperCost,
            discountAmount,
            totalPrice,
            appliedCoupon,
            pickupAddress,
            receivedAddress,
        } = req.body;

        // Basic validation
        if (!userId || !pickup || !dropoff || !vehicleType) {
            return res.status(400).json({
                success: false,
                message: 'userId, pickup, dropoff, and vehicleType are required.',
            });
        }

        const booking = new LogisticsBooking({
            userId,
            userName:       userName       ?? "Guest User",
            userPhone:      userPhone      ?? "",
            pickup,
            dropoff,
            distanceKm:     distanceKm     ?? 0,
            vehicleType,
            vehiclePrice:   vehiclePrice   ?? 0,
            items:          items          ?? [],
            helperCount:    helperCount    ?? 0,
            helperCost:     helperCost     ?? 0,
            discountAmount: discountAmount ?? 0,
            totalPrice:     totalPrice     ?? 0,
            appliedCoupon:  appliedCoupon  ?? null,
            pickupAddress:  pickupAddress  ?? null,
            receivedAddress: receivedAddress ?? null,
            status: 'pending',
        });

        await booking.save();

        return res.status(201).json({
            success: true,
            message: 'Logistics booking created successfully!',
            bookingId: booking._id,
            data: booking,
        });

    } catch (error) {
        console.error('Error creating logistics booking:', error);
        return res.status(500).json({
            success: false,
            message: 'Server error while creating booking.',
            error: error.message,
        });
    }
};

// ─── GET /api/logistics-bookings/user/:userId  ──────────
// Get all bookings for a specific user
exports.getUserBookings = async (req, res) => {
    try {
        const { userId } = req.params;
        const bookings = await LogisticsBooking.find({ userId }).sort({ createdAt: -1 });
        return res.status(200).json({ success: true, data: bookings });
    } catch (error) {
        console.error('Error fetching user bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/logistics-bookings  ───────────────────────
// Get all bookings (Admin)
exports.getAllBookings = async (req, res) => {
    try {
        // Use aggregation to join with the User collection
        // Since userId is a string, we lookup in the User collection's _id or uid field
        const bookings = await LogisticsBooking.aggregate([
            {
                $lookup: {
                    from: 'users',
                    localField: 'userId',
                    foreignField: 'uid', // Match with Firebase UID
                    as: 'userInfo'
                }
            },
            {
                $addFields: {
                    userName: { 
                        $ifNull: [ 
                            { $arrayElemAt: ['$userInfo.name', 0] },
                            { $ifNull: [ "$userName", "$userId" ] }
                        ] 
                    },
                    userPhone: {
                        $ifNull: [
                            { $arrayElemAt: ['$userInfo.mobileNumber', 0] },
                            { $ifNull: [ "$userPhone", "" ] }
                        ]
                    }
                }
            },
            {
                $sort: { createdAt: -1 }
            },
            {
                $project: { userInfo: 0 } // remove temporary join data
            }
        ]);

        console.log(`[LOGISTICS] Backend found ${bookings.length} total bookings with enriched user names.`);
        return res.status(200).json({ success: true, data: bookings });
    } catch (error) {
        console.error('Error fetching all bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/logistics-bookings/:id  ───────────────────
// Get a single booking by ID
exports.getBookingById = async (req, res) => {
    try {
        const booking = await LogisticsBooking.findById(req.params.id);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }
        return res.status(200).json({ success: true, data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/logistics-bookings/:id/status  ──────────
// Update booking status (Admin / Driver)
exports.updateStatus = async (req, res) => {
    try {
        const { status } = req.body;
        const allowed = ['pending', 'confirmed', 'in_transit', 'delivered', 'cancelled'];
        if (!allowed.includes(status)) {
            return res.status(400).json({ success: false, message: 'Invalid status value.' });
        }
        const booking = await LogisticsBooking.findByIdAndUpdate(
            req.params.id,
            { status },
            { new: true }
        );
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }
        return res.status(200).json({ success: true, message: 'Status updated.', data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
