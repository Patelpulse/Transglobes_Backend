const LogisticsBooking = require('../models/LogisticsBooking');
const { validateTransition, calculateCancellationCharge } = require('../utils/bookingLifecycle');

const normalizeLocation = (location, fallbackName, fallbackAddress) => {
    if (!location && !fallbackName && !fallbackAddress) {
        return null;
    }

    return {
        name: location?.name ?? fallbackName ?? fallbackAddress ?? 'Location',
        address: location?.address ?? fallbackAddress ?? fallbackName ?? 'Location',
        lat: Number(location?.lat ?? location?.latitude ?? 0),
        lng: Number(location?.lng ?? location?.longitude ?? 0),
    };
};

const normalizeDimension = (value, fallback = 1) => {
    const parsed = Number(value);
    if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
    return parsed;
};

const normalizeItems = (items = [], fallbackWeight = 0) => {
    if (!Array.isArray(items)) return [];

    return items
        .map((item) => ({
            itemName: item?.itemName ?? item?.name ?? item?.goodsType ?? 'General Goods',
            type: item?.type ?? 'General',
            length: normalizeDimension(item?.length, 1),
            height: normalizeDimension(item?.height, 1),
            width: normalizeDimension(item?.width, 1),
            unit: item?.unit ?? 'cm',
            weight: normalizeDimension(item?.weight ?? fallbackWeight, Math.max(Number(fallbackWeight) || 1, 1)),
            quantity: Math.max(Number(item?.quantity ?? 1) || 1, 1),
        }))
        .filter((item) => item.itemName);
};

const normalizeAddressDetails = (address, fallbackLocation, expectedType) => {
    if (!address) return null;

    return {
        type: expectedType,
        label: address?.label ?? fallbackLocation?.name ?? expectedType,
        fullAddress: fallbackLocation?.address ?? address?.fullAddress ?? address?.label ?? '',
        houseNumber: address?.houseNumber ?? '',
        floorNumber: address?.floorNumber ?? '',
        landmark: address?.landmark ?? '',
        city: address?.city ?? '',
        pincode: address?.pincode ?? '',
        phone: address?.phone ?? '',
        email: address?.email ?? '',
    };
};

const validateItems = (items = []) => {
    if (!Array.isArray(items) || items.length === 0) {
        return 'At least one item is required.';
    }

    for (const item of items) {
        const itemName = item?.itemName ?? item?.name ?? item?.goodsType;
        if (!itemName || !String(itemName).trim()) {
            return 'Each item must have a valid item name.';
        }

        const length = Number(item?.length ?? 0);
        const width = Number(item?.width ?? 0);
        const height = Number(item?.height ?? 0);

        if (length <= 0 || width <= 0 || height <= 0) {
            return 'Each item must have length, width, and height greater than zero.';
        }
    }

    return null;
};

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
            segments,
            pickupName,
            dropName,
            modeOfTravel,
            price,
            weight,
        } = req.body;

        const normalizedPickup = normalizeLocation(pickup, pickupName, pickupName);
        const normalizedDropoff = normalizeLocation(dropoff, dropName, dropName);
        const normalizedVehicleType = vehicleType ?? modeOfTravel;
        const normalizedItems = normalizeItems(items, weight);
        const normalizedVehiclePrice = Number(vehiclePrice ?? price ?? totalPrice ?? 0);
        const normalizedTotalPrice = Number(totalPrice ?? price ?? vehiclePrice ?? 0);
        const normalizedPickupAddress = normalizeAddressDetails(pickupAddress, normalizedPickup, 'pickup');
        const normalizedReceivedAddress = normalizeAddressDetails(receivedAddress, normalizedDropoff, 'received');

        // Basic validation
        if (!userId || !normalizedPickup || !normalizedDropoff || !normalizedVehicleType) {
            console.warn('[LOGISTICS] Booking validation failed: missing required fields', {
                userId,
                hasPickup: !!normalizedPickup,
                hasDropoff: !!normalizedDropoff,
                vehicleType: normalizedVehicleType,
            });
            return res.status(400).json({
                success: false,
                message: 'userId, pickup, dropoff, and vehicleType are required.',
            });
        }

        if (
            String(normalizedPickup.address || '').trim().toLowerCase() ===
            String(normalizedDropoff.address || '').trim().toLowerCase()
        ) {
            console.warn('[LOGISTICS] Booking validation failed: pickup/dropoff identical', {
                userId,
                pickup: normalizedPickup.address,
                dropoff: normalizedDropoff.address,
            });
            return res.status(400).json({
                success: false,
                message: 'Pickup and drop locations must be different.',
            });
        }

        const itemsValidationError = validateItems(normalizedItems);
        if (itemsValidationError) {
            console.warn('[LOGISTICS] Booking validation failed: invalid items', {
                userId,
                vehicleType: normalizedVehicleType,
                error: itemsValidationError,
                items: normalizedItems,
            });
            return res.status(400).json({
                success: false,
                message: itemsValidationError,
            });
        }

        const booking = new LogisticsBooking({
            userId,
            userName:       userName       ?? "Guest User",
            userPhone:      userPhone      ?? "",
            pickup:         normalizedPickup,
            dropoff:        normalizedDropoff,
            distanceKm:     distanceKm     ?? 0,
            vehicleType:    normalizedVehicleType,
            vehiclePrice:   normalizedVehiclePrice,
            items:          normalizedItems,
            helperCount:    helperCount    ?? 0,
            helperCost:     helperCost     ?? 0,
            additionalCharges: additionalCharges ?? 0,
            discountAmount: discountAmount ?? 0,
            totalPrice:     normalizedTotalPrice,
            appliedCoupon:  appliedCoupon  ?? null,
            pickupAddress:  normalizedPickupAddress,
            receivedAddress: normalizedReceivedAddress,
            segments:       segments       ?? [],
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
        const { status, adminOverride = false } = req.body;
        const allowed = ['pending', 'pending_for_driver', 'confirmed', 'processing', 'in_transit', 'delivered', 'cancelled'];
        if (!allowed.includes(status)) {
            return res.status(400).json({ success: false, message: 'Invalid status value.' });
        }

        // Fetch current booking for lifecycle validation
        const existing = await LogisticsBooking.findById(req.params.id);
        if (!existing) return res.status(404).json({ success: false, message: 'Booking not found.' });

        // Enforce lifecycle transitions
        const { allowed: canTransition, reason } = validateTransition(
            existing.status, status, 'logistics', adminOverride
        );
        if (!canTransition) {
            return res.status(422).json({ success: false, message: reason });
        }

        // Calculate cancellation charge if applicable
        let cancellationCharge = 0;
        if (status === 'cancelled') {
            const { charge } = calculateCancellationCharge(existing.createdAt, existing.totalPrice, 'logistics');
            cancellationCharge = charge;
        }

        const booking = await LogisticsBooking.findByIdAndUpdate(
            req.params.id,
            { status, ...(cancellationCharge > 0 && { cancellationCharge }) },
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
        const { driverId, transportName, transportNumber, estimatedTime, estimatedDate, bookingId: bodyId } = req.body;
        const bookingId = req.params.id || bodyId;

        console.log(`[LOGISTICS-DISPATCH] Request for booking ${bookingId} with target: ${driverId}`);

        if (!bookingId) {
            return res.status(400).json({ success: false, message: 'Booking ID is required.' });
        }

        if (!driverId) {
            return res.status(400).json({ success: false, message: 'Assign target (driverId or "all") is required.' });
        }

        let updateData = {};
        if (driverId === 'all') {
            // General Dispatch
            updateData = { 
                driverId: null,
                status: 'pending_for_driver' 
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
        if (estimatedTime) updateData.estimatedTime = estimatedTime;
        if (estimatedDate) updateData.estimatedDate = estimatedDate;

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
                fare: booking.totalPrice || booking.vehiclePrice || 0,
                rideMode: booking.vehicleType || 'flatbed',
                status: booking.status,
                userId: booking.userId?.toString(),
                type: 'LOGISTICS',
                railwayStation: booking.railwayStation,
                transportName: booking.transportName,
                transportNumber: booking.transportNumber,
                estimatedTime: booking.estimatedTime,
                estimatedDate: booking.estimatedDate
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

// ─── PATCH /api/logistics-bookings/:id/roadmap ──────────
// Update the entire roadmap (Multi-segment journey)
exports.updateRoadmap = async (req, res) => {
    try {
        const { segments } = req.body;
        const bookingId = req.params.id;

        if (!segments || !Array.isArray(segments)) {
            return res.status(400).json({ success: false, message: 'Valid segments array is required.' });
        }

        const booking = await LogisticsBooking.findByIdAndUpdate(
            bookingId,
            { segments },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Notify User via Socket
        if (req.io) {
            req.io.to(booking.userId.toString()).emit("roadmap_updated", {
                rideId: bookingId,
                segments: booking.segments
            });
        }

        // Notify User via Push
        const { notifyUser } = require('../utils/notificationService');
        notifyUser(booking.userId, {
            title: "Journey Updated",
            body: "A supervisor has updated your shipment roadmap. Check the app for details.",
            data: {
                bookingId: booking._id.toString(),
                type: 'ROADMAP_UPDATE'
            }
        });

        return res.status(200).json({ 
            success: true, 
            message: 'Roadmap updated successfully.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error updating roadmap:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/logistics-bookings/:id/segment/:segmentId/assign ──────────
// Assign a driver to a specific segment
exports.assignSegmentDriver = async (req, res) => {
    try {
        const { driverId } = req.body;
        const { id: bookingId, segmentId } = req.params;

        const booking = await LogisticsBooking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        const segment = booking.segments.id(segmentId);
        if (!segment) {
            return res.status(404).json({ success: false, message: 'Segment not found.' });
        }

        segment.driverId = driverId;
        segment.status = 'processing';
        await booking.save();

        if (req.io) {
            if (driverId !== 'all') {
                req.io.to(driverId.toString()).emit("new_ride", {
                    id: booking._id.toString(),
                    segmentId: segmentId,
                    userName: booking.userName,
                    pick: segment.start.address,
                    drop: segment.end.address,
                    type: 'LOGISTICS_SEGMENT'
                });
            }
            // Also notify the user to update the roadmap timeline
            req.io.to(booking.userId.toString()).emit("roadmap_updated", {
                rideId: bookingId,
                segments: booking.segments
            });
        }

        return res.status(200).json({ 
            success: true, 
            message: 'Segment driver assigned.', 
            data: booking 
        });
    } catch (error) {
        console.error('Error assigning segment driver:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/driver/pending-bookings ──────────────────
exports.getDriverPendingBookings = async (req, res) => {
    try {
        let query = { status: 'pending_for_driver' };

        // If authenticated, exclude bookings this driver already rejected
        if (req.user) {
            const driverId = req.user.uid || req.user.id;
            const mongoose = require('mongoose');
            const Driver = require('../models/Driver');

            let mongoDriverId = driverId;
            if (driverId && !mongoose.Types.ObjectId.isValid(driverId)) {
                const d = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
                if (d) mongoDriverId = d._id;
            }

            if (mongoDriverId) {
                query.rejectedBy = { $ne: mongoDriverId };
            }
        }

        const bookings = await LogisticsBooking.find(query).sort({ createdAt: -1 });
        console.log(`[PENDING-BOOKINGS] Found ${bookings.length} bookings (auth: ${req.user ? 'yes' : 'no'})`);
        return res.status(200).json({ success: true, bookings });
    } catch (error) {
        console.error('Error fetching driver pending bookings:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};


// ─── PATCH /api/booking/:id/accept ─────────────────────
exports.acceptBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const driverId = req.user.uid || req.user.id;
        const mongoose = require('mongoose');
        const Driver = require('../models/Driver');

        let mongoDriverId = driverId;
        let driver;
        if (!mongoose.Types.ObjectId.isValid(driverId)) {
            driver = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
            if (driver) mongoDriverId = driver._id;
        } else {
            driver = await Driver.findById(driverId);
        }

        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        const booking = await LogisticsBooking.findByIdAndUpdate(
            id,
            { 
                status: 'confirmed', 
                driverId: mongoDriverId,
                otp: otp
            },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        // Emit socket events
        if (req.io) {
            // Signal to user
            req.io.to(booking.userId.toString()).emit("ride_accepted", {
                rideId: booking._id.toString(),
                status: 'confirmed',
                otp: booking.otp,
                type: 'LOGISTICS',
                driver: driver ? {
                    name: driver.name,
                    phone: driver.mobileNumber,
                    vehicle_number: driver.vehicleNumberPlate,
                    vehicle_name: driver.vehicleModel
                } : null
            });
            // Signal to other drivers to remove it
            req.io.emit("ride_assigned", { rideId: booking._id.toString() });
        }

        return res.status(200).json({ success: true, message: 'Booking accepted.', data: booking });
    } catch (error) {
        console.error('Error accepting booking:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PATCH /api/booking/:id/reject ─────────────────────
exports.rejectBooking = async (req, res) => {
    try {
        const { id } = req.params;
        const driverId = req.user.uid || req.user.id;
        const mongoose = require('mongoose');
        const Driver = require('../models/Driver');

        let mongoDriverId = driverId;
        if (!mongoose.Types.ObjectId.isValid(driverId)) {
            const d = await Driver.findOne({ $or: [{ uid: driverId }, { firebaseId: driverId }] });
            if (d) mongoDriverId = d._id;
        }

        const booking = await LogisticsBooking.findByIdAndUpdate(
            id,
            { $addToSet: { rejectedBy: mongoDriverId } },
            { new: true }
        );

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found.' });
        }

        return res.status(200).json({ success: true, message: 'Booking rejected.' });
    } catch (error) {
        console.error('Error rejecting booking:', error);
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
