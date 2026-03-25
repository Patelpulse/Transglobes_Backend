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
            additionalCharges,
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
            additionalCharges: additionalCharges ?? 0,
            discountAmount: discountAmount ?? 0,
            totalPrice:     totalPrice     ?? 0,
            appliedCoupon:  appliedCoupon  ?? null,
            pickupAddress:  pickupAddress  ?? null,
            receivedAddress: receivedAddress ?? null,
            status: 'pending',
        });

        await booking.save();
        
        // --- Socket.io Notification (Real-time) ---
        if (req.io) {
            req.io.emit("new_ride", {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                pick: booking.pickup?.address || 'Pickup Location',
                drop: booking.dropoff?.address || 'Dropoff Location',
                pickupLat: booking.pickup?.latitude,
                pickupLng: booking.pickup?.longitude,
                dropLat: booking.dropoff?.latitude,
                dropLng: booking.dropoff?.longitude,
                distance: `${booking.distanceKm} km`,
                fare: booking.totalPrice || booking.price || 0,
                rideMode: booking.vehicleType || 'flatbed', // Maps to truck type in Driver App
                status: 'pending',
                userId: booking.userId?.toString(),
                type: 'LOGISTICS',
                vehiclePrice: booking.vehiclePrice || 0,
                helperCost: booking.helperCost || 0,
                additionalCharges: booking.additionalCharges || 0,
                discountAmount: booking.discountAmount || 0,
                totalPrice: booking.totalPrice || booking.price || 0,
            });
            console.log(`[LOGISTICS] Socket emitted: new_ride for ${booking._id}`);
        }

        // --- Push Notification To Drivers ---
        const { notifyAllDrivers } = require('../utils/notificationService');
        notifyAllDrivers({
            title: "New Logistics Shipment",
            body: `New ${vehicleType} Shipment available via ${pickup.address}.`,
            data: {
                bookingId: booking._id.toString(),
                type: 'NEW_LOGISTICS'
            }
        });

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

        // --- Push Notification To User ---
        const { notifyUser } = require('../utils/notificationService');
        let bodyText = `Your shipment is now: ${status.toUpperCase()}`;
        if (status === 'confirmed') bodyText = "Your shipment has been confirmed by our team.";
        if (status === 'in_transit') bodyText = "Your shipment is now in transit!";
        if (status === 'delivered') bodyText = "Your shipment has been delivered successfully. Thank you for using Transglobe!";
        if (status === 'cancelled') bodyText = "Your shipment has been cancelled.";

        notifyUser(booking.userId, {
            title: "Shipment Update",
            body: bodyText,
            data: {
                bookingId: booking._id.toString(),
                status: booking.status,
                type: 'SHIPMENT_UPDATE'
            }
        });

        return res.status(200).json({ success: true, message: 'Status updated.', data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/logistics-bookings/:id/assign ──────────
// Assign a driver to a logistics booking and notify them
exports.assignDriver = async (req, res) => {
    try {
        const { driverId, transportName, transportNumber } = req.body;
        const bookingId = req.params.id;

        console.log(`[LOGISTICS-DISPATCH] Request for booking ${bookingId} with target: ${driverId}`);

        if (!driverId) {
            return res.status(400).json({ success: false, message: 'Assign target (driverId or "all") is required.' });
        }

        let updateData = {};
        if (driverId === 'all') {
            // General Dispatch
            updateData = { 
                driverId: null,
                status: 'pending' 
            };
        } else {
            // Specific Assignment
            updateData = { 
                driverId: driverId,
                status: 'processing'
            };
        }

        // Add transport details if provided
        if (transportName) updateData.transportName = transportName;
        if (transportNumber) updateData.transportNumber = transportNumber;

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            updateData,
            { new: true }
        );

        if (!booking) {
            console.error(`[LOGISTICS-DISPATCH] Booking ${bookingId} not found!`);
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        console.log(`[LOGISTICS-DISPATCH] DB Updated. Status: ${booking.status}, Member: ${booking.driverId || 'ALL'}`);

        // Notify drivers via Socket.io
        if (req.io) {
            const socketData = {
                id: booking._id.toString(),
                userName: booking.userName || 'Customer',
                phone: booking.userPhone || '',
                pick: booking.pickup?.address || 'Pickup Location',
                drop: booking.dropoff?.address || 'Dropoff Location',
                pickupLat: booking.pickup?.latitude,
                pickupLng: booking.pickup?.longitude,
                dropLat: booking.dropoff?.latitude,
                dropLng: booking.dropoff?.longitude,
                distance: `${booking.distanceKm} km`,
                fare: booking.totalPrice || booking.price || 0,
                rideMode: booking.vehicleType || 'flatbed',
                status: booking.status,
                userId: booking.userId?.toString(),
                type: 'LOGISTICS',
                railwayStation: booking.railwayStation,
                transportName: booking.transportName,
                transportNumber: booking.transportNumber
            };

            if (driverId === 'all') {
                console.log(`[LOGISTICS-DISPATCH] Broadcasting to ALL drivers.`);
                req.io.emit("new_ride", socketData);
            } else {
                console.log(`[LOGISTICS-DISPATCH] Sending to specific driver ${driverId}.`);
                req.io.to(driverId.toString()).emit("new_ride", socketData);
                req.io.to(driverId.toString()).emit("ride_assigned", { 
                    bookingId: booking._id.toString(),
                    message: "You have been assigned a new logistics shipment."
                });
            }
        }

        return res.status(200).json({ 
            success: true, 
            message: driverId === 'all' ? 'Order dispatched successfully.' : 'Driver assigned and notified successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error assigning driver:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
// ─── PATCH /api/logistics-bookings/:id/railway-station ───
// Assign a railway station for train-based logistics (Admin)
exports.updateRailwayStation = async (req, res) => {
    try {
        const { stationName } = req.body;
        const bookingId = req.params.id;

        if (!stationName) {
            return res.status(400).json({ success: false, message: 'Station name is required.' });
        }

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { railwayStation: stationName },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        return res.status(200).json({ 
            success: true, 
            message: 'Railway station assigned successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error updating railway station:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PUT/PATCH /api/logistics-bookings/:id/billing ───
// Updates billing breakdown for a booking
exports.updateBilling = async (req, res) => {
    try {
        const { id } = req.params;
        const { 
            vehiclePrice, 
            helperCost, 
            additionalCharges, 
            discount,         // From user request
            discountAmount,   // Legacy/Existing
            totalPrice,       // Legacy/Existing
            totalAmount       // From user request
        } = req.body;

        const bookingId = id || req.params.id;
        console.log(`[BILLING-UPDATE] Processing request for: ${bookingId}`);

        // Fetch current booking
        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        // Restriction: Processing stage is read-only for admin
        if (booking.status === 'processing' || booking.status === 'confirmed') {
            console.warn(`[BILLING-UPDATE] Blocked: Booking ${bookingId} is in ${booking.status} state.`);
            return res.status(403).json({ 
                success: false, 
                message: 'Editing is disabled while the order is being processed by the driver.' 
            });
        }

        // Map fields safely (supporting both naming conventions)
        if (vehiclePrice !== undefined) booking.vehiclePrice = Number(vehiclePrice);
        if (helperCost !== undefined) booking.helperCost = Number(helperCost);
        if (additionalCharges !== undefined) booking.additionalCharges = Number(additionalCharges);
        
        // Handle discount/discountAmount
        if (discount !== undefined) booking.discountAmount = Number(discount);
        else if (discountAmount !== undefined) booking.discountAmount = Number(discountAmount);

        // Calculate or assign total
        if (totalAmount !== undefined) {
          booking.totalPrice = Number(totalAmount);
        } else if (totalPrice !== undefined) {
          booking.totalPrice = Number(totalPrice);
        } else {
          // Auto-calculate if not explicitly provided
          booking.totalPrice = booking.vehiclePrice + booking.helperCost + booking.additionalCharges - booking.discountAmount;
        }

        await booking.save();

        console.log(`[BILLING-UPDATE] Success. New Total: ₹${booking.totalPrice}`);

        return res.status(200).json({ 
            success: true, 
            message: 'Billing updated successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('[BILLING-UPDATE] Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
