const RideType = require("../models/RideType");
const History = require("../models/History");
const User = require("../models/User"); // used for populating name
const LogisticsBooking = require("../models/LogisticsBooking"); // Add this
const { notifyAllDrivers } = require('../utils/notificationService');

const Review = require("../models/Review");

exports.getRideTypes = async (req, res) => {
    try {
        let rides = await RideType.find({ status: true });
        
        // Only return Transglobe
        rides = rides.filter(r => r.name.toLowerCase().includes('transglobe'));

        res.status(200).json({
            success: true,
            data: rides
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

exports.getDriverBookings = async (req, res) => {
    try {
        const Driver = require("../models/Driver");
        let currentDriver;
        if (req.user && req.user.uid) {
            currentDriver = await Driver.findOne({ uid: req.user.uid });
        }


        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

        // Global filter: Only show rides from the last 24 hours
        // to keep the UI clean from old/stuck requests.
        const query = {
            createdAt: { $gte: oneDayAgo },
            $or: [
                { driverId: currentDriver?._id },
                { "driverSnapshot.driver_id": currentDriver?._id },
                { rejectedBy: currentDriver?._id },
                {
                    status: 'pending',
                    rejectedBy: { $ne: currentDriver?._id }
                }
            ]
        };

        const bookings = await History.find(query).populate('userId', 'name').sort({ createdAt: -1 });

        // Merge with Logistics Bookings assigned to this driver
        let logistics = [];
        if (currentDriver) {
            logistics = await LogisticsBooking.find({ 
                driverId: currentDriver._id,
                createdAt: { $gte: oneDayAgo }
            }).sort({ createdAt: -1 });
        }

        // Map logistics to a format the Driver App expects (BookingModel)
        const mappedLogistics = logistics.map(lb => ({
            _id: lb._id,
            userName: lb.userName || 'Customer',
            userPhone: lb.userPhone || '',
            pickupAddress: lb.pickup?.address || 'Pickup Location',
            dropAddress: lb.dropoff?.address || 'Dropoff Location',
            pickupLat: lb.pickup?.lat,
            pickupLng: lb.pickup?.lng,
            dropLat: lb.dropoff?.lat,
            dropLng: lb.dropoff?.lng,
            fare: lb.totalPrice || lb.vehiclePrice || 0,
            distanceKm: lb.distanceKm || 0,
            status: lb.status,
            createdAt: lb.createdAt,
            rideMode: 'truck', // This makes it show up in 'Logistics' tab in Driver App
            vehicleType: lb.vehicleType || 'truck',
            type: 'LOGISTICS'
        }));

        // Combine and sort
        const allBookings = [...bookings, ...mappedLogistics].sort((a, b) => 
            new Date(b.createdAt) - new Date(a.createdAt)
        );

        res.json({
            success: true,
            bookings: allBookings.map(b => {
                let displayStatus = b.status;
                // If I rejected it, show as 'rejected' for my personal history list
                if (currentDriver && b.rejectedBy && b.rejectedBy.includes(currentDriver._id)) {
                    displayStatus = 'rejected';
                }

                return {
                    _id: b._id,
                    userName: b.userId?.name || 'Customer',
                    userPhone: b.mobileNumber,
                    pickupAddress: b.locations[0]?.address || '',
                    dropAddress: b.locations[1]?.address || '',
                    fare: b.fare,
                    distanceKm: parseFloat(b.distance) || 0,
                    status: displayStatus,
                    rideMode: b.rideMode,
                    createdAt: b.createdAt,
                    userId: b.userId?._id || b.userId,
                    pickupLat: b.locations[0]?.latitude,
                    pickupLng: b.locations[0]?.longitude,
                    dropLat: b.locations[1]?.latitude,
                    dropLng: b.locations[1]?.longitude,
                };
            })
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};



// To save user's "input fill" (Ride Request / Booking)
exports.createRideRequest = async (req, res) => {
    try {
        const { mobileNumber, locations, rideMode, paymentMode, fare, distance, vehicleType, typeOfGood, helperCount, logisticItems } = req.body;

        // Verify we have required fields
        if (!locations || !locations.pickup || !locations.dropoff || !rideMode || !fare) {
            return res.status(400).json({
                success: false,
                message: "Missing required fields: locations, rideMode, and fare are mandatory"
            });
        }

        // Get mobile number and find user as before...
        let userPhone = mobileNumber || (req.user && req.user.phone_number);

        if (!userPhone) {
            return res.status(401).json({
                success: false,
                message: "User identity could not be verified"
            });
        }

        // Clean the phone number (remove spaces, dashes, etc.)
        userPhone = userPhone.toString().replace(/\s+/g, '');

        console.log(`Searching for user with phone: ${userPhone}`);

        // Try exact match first
        let user = await User.findOne({ mobileNumber: userPhone });

        // If not found and phone starts with +91, try without it
        if (!user && userPhone.startsWith('+91')) {
            const withoutCountryCode = userPhone.replace('+91', '');
            console.log(`Trying without country code: ${withoutCountryCode}`);
            user = await User.findOne({ mobileNumber: withoutCountryCode });
        }

        // If not found and phone doesn't have country code, try with it
        if (!user && !userPhone.startsWith('+')) {
            const withCountryCode = '+91' + userPhone;
            console.log(`Trying with country code: ${withCountryCode}`);
            user = await User.findOne({ mobileNumber: withCountryCode });
        }

        // If not found by phone, try finding by email from the token
        if (!user && req.user && req.user.email) {
            console.log(`Trying to find user by email: ${req.user.email}`);
            user = await User.findOne({ email: req.user.email });
        }

        if (!user) {
            console.log(`User not found in DB for authenticated phone ${userPhone}. Auto-registering user...`);
            try {
                user = await User.create({
                    mobileNumber: userPhone,
                    name: req.user?.name || '',
                    email: req.user?.email || undefined
                });
                console.log(`Auto-registered user: ${user._id}`);
            } catch (createError) {
                console.error('Failed to auto-register user:', createError);
                return res.status(500).json({
                    success: false,
                    message: "User record missing and auto-registration failed. Please register properly."
                });
            }
        }

        const otp = Math.floor(1000 + Math.random() * 9000).toString();

        const newRide = await History.create({
            userId: user._id,
            mobileNumber: user.mobileNumber,
            rideMode,
            paymentMode: paymentMode || "cash",
            distance: distance || "",
            fare: fare,
            otp,
            vehicleType,
            typeOfGood,
            helperCount: helperCount || 0,
            logisticItems: logisticItems || [],
            locations: [
                {
                    type: "pickup",
                    title: locations.pickup.title,
                    address: locations.pickup.address,
                    latitude: locations.pickup.latitude,
                    longitude: locations.pickup.longitude
                },
                {
                    type: "dropoff",
                    title: locations.dropoff.title,
                    address: locations.dropoff.address,
                    latitude: locations.dropoff.latitude,
                    longitude: locations.dropoff.longitude
                }
            ]
        });

        res.status(201).json({
            success: true,
            message: "Ride request created successfully",
            data: newRide
        });

        // Notify all drivers via Socket.io
        if (req.io) {
            req.io.emit("new_ride", {
                id: newRide._id.toString(),
                userName: user.name || 'Customer',
                phone: user.mobileNumber,
                pick: newRide.locations[0]?.address || '',
                drop: newRide.locations[1]?.address || '',
                pickupLat: newRide.locations[0]?.latitude,
                pickupLng: newRide.locations[0]?.longitude,
                dropLat: newRide.locations[1]?.latitude,
                dropLng: newRide.locations[1]?.longitude,
                distance: newRide.distance,
                fare: newRide.fare,
                paymentMode: newRide.paymentMode,
                rideMode: newRide.rideMode,
                status: newRide.status,
                userId: newRide.userId?.toString()
            });
            console.log(`Socket emitted: new_ride for ${newRide._id}`);
        }

        // Push Notification to all online drivers
        notifyAllDrivers({
            title: "New Ride Request",
            body: `New ${rideMode} ride available. Fare: ₹${fare}`,
            data: {
                rideId: newRide._id.toString(),
                type: 'NEW_RIDE'
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// ------------------------------------------------------------------
// Driver APIs
// ------------------------------------------------------------------

// generic list of all rides (could be filtered by status, driverId, etc.)
exports.getRideDetails = async (req, res) => {
    try {
        // optional query params for filtering
        const filter = {};
        if (req.query.status) filter.status = req.query.status;
        if (req.query.driverId) filter.driverId = req.query.driverId;

        const rides = await History.find(filter)
            .populate('userId', 'name')
            .select('mobileNumber locations distance fare paymentMode status');

        const response = rides.map((ride) => ({
            userName: ride.userId?.name,
            phoneNumber: ride.mobileNumber,
            pickup: ride.locations[0]?.address || '',
            drop: ride.locations[1]?.address || '',
            distance: ride.distance,
            price: ride.fare,
            paymentMode: ride.paymentMode,
            status: ride.status,
            rideId: ride._id,
        }));

        res.json({
            success: true,
            data: response,
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// return only pending rides (driver app uses this)
exports.getPendingRides = async (req, res) => {
    try {
        const rides = await History.find({ status: 'pending' })
            .populate('userId', 'name')
            .select('mobileNumber locations distance fare paymentMode status userId rideMode');

        const response = rides.map((ride) => ({
            id: ride._id,
            userName: ride.userId?.name || 'Unknown',
            phone: ride.mobileNumber,
            pick: ride.locations[0]?.address || '',
            drop: ride.locations[1]?.address || '',
            distance: ride.distance,
            fare: ride.fare,
            paymentMode: ride.paymentMode,
            rideMode: ride.rideMode,
            status: ride.status,
            userId: ride.userId?._id || ride.userId
        }));

        res.json({ success: true, data: response });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// assign ride to driver (used by driver_service.acceptRide)
exports.assignRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { driverId, fare } = req.body;
        const ride = await History.findById(rideId);
        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        ride.status = 'accepted';
        ride.driverActionAt = new Date();
        if (fare) ride.fare = fare;

        // populate snapshot if we know driverId
        if (driverId) {
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            }
            if (driver) {
                ride.driverId = driver._id;
                ride.driverSnapshot = {
                    driver_id: driver._id.toString(),
                    name: driver.name || 'Driver',
                    phone: driver.mobileNumber || '',
                    vehicle_number: driver.vehicleNumberPlate || 'N/A',
                    vehicle_name: driver.vehicleModel || 'Vehicle',
                    photo: driver.photo || ''
                };
            }
        }

        await ride.save();

        if (req.io) {
            // Emit to user's personal room AND the specific ride room
            req.io.to(ride.userId.toString()).to(ride._id.toString()).emit("ride_accepted", {
                rideId: ride._id.toString(),
                status: ride.status,
                driver: ride.driverSnapshot,
                fare: ride.fare
            });
            // Also notify other drivers that this ride is taken
            req.io.emit("ride_assigned", { rideId: ride._id.toString() });
        }

        const { notifyUser } = require('../utils/notificationService');
        notifyUser(ride.userId, {
            title: "Ride Accepted",
            body: `Your ride has been accepted by ${ride.driverSnapshot?.name || 'a driver'}.`,
            data: {
                rideId: ride._id.toString(),
                type: 'RIDE_ACCEPTED'
            }
        });

        res.json({ success: true, ride });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// reject ride (driver app)
exports.rejectRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { driverId } = req.body;

        let ride = await History.findById(rideId);
        let isLogistics = false;

        if (!ride) {
            ride = await LogisticsBooking.findById(rideId);
            if (ride) isLogistics = true;
        }

        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        if (isLogistics) {
            // Rejection for logistics clears the manual assignment so admin can search again
            ride.driverId = null;
            ride.status = 'pending';
            await ride.save();
            return res.json({ success: true, message: 'Logistics booking rejected and reset to pending' });
        }

        ride.driverActionAt = new Date();

        if (driverId) {
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('_id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('_id');
            }
            if (driver) {
                if (!ride.rejectedBy) ride.rejectedBy = [];
                if (!ride.rejectedBy.includes(driver._id)) {
                    ride.rejectedBy.push(driver._id);
                    // If assigned to me, clear assignment
                    if (ride.driverId && ride.driverId.toString() === driver._id.toString()) {
                        ride.driverId = null;
                        ride.status = 'pending';
                    }
                }
            }
        }


        await ride.save();
        res.json({ success: true, message: 'Ride rejected', ride });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};


// update ride status
exports.updateRideStatus = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { status, delayReason, actualFare, driverId } = req.body;
        
        // Try finding in standard rides
        let ride = await History.findById(rideId);
        let isLogistics = false;

        // Try finding in logistics if not found in standard rides
        if (!ride) {
            ride = await LogisticsBooking.findById(rideId);
            if (ride) isLogistics = true;
        }

        if (!ride) return res.status(404).json({ message: 'Ride or Booking not found' });
        
        // For logistics, 'accepted' maps to 'confirmed' status
        if (status) {
            if (isLogistics && status === 'accepted') {
                ride.status = 'confirmed';
            } else if (isLogistics && status === 'ongoing') {
                ride.status = 'in_transit';
            } else if (isLogistics && status === 'completed') {
                ride.status = 'delivered';
            } else {
                ride.status = status;
            }
        }
        if (delayReason) ride.delayReason = delayReason;
        if (actualFare != null) ride.actualFare = actualFare;

        // record which driver made the change; driverId may be passed
        if (driverId) {
            ride.driverActionAt = new Date();
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate vehicleModel photo _id');
            }
            if (driver) {
                ride.driverId = driver._id;              // ensure link
                ride.driverSnapshot = {
                    driver_id: driver._id.toString(),
                    name: driver.name || 'Driver',
                    phone: driver.mobileNumber || '',
                    vehicle_number: driver.vehicleNumberPlate || 'N/A',
                    vehicle_name: driver.vehicleModel || 'Vehicle',
                    photo: driver.photo || ''
                };
            }
        }

        await ride.save();

        if (req.io) {
            // Emit to user's personal room AND the specific ride room
            req.io.to(ride.userId.toString()).to(ride._id.toString()).emit("ride_status_update", {
                rideId: ride._id.toString(),
                status: ride.status,
                driver: ride.driverSnapshot
            });
        }

        // --- Push Notification to User ---
        const { notifyUser } = require('../utils/notificationService');
        let bodyText = `Your ride status is now: ${ride.status.toUpperCase()}`;
        if (status === 'arrived') bodyText = "Your driver has arrived at the pickup location!";
        if (status === 'completed') bodyText = "Your ride is complete. Thank you for riding with Transglobe!";
        if (status === 'cancelled') bodyText = "Your ride has been cancelled.";

        notifyUser(ride.userId, {
            title: "Ride Update",
            body: bodyText,
            data: {
                rideId: ride._id.toString(),
                status: ride.status,
                type: 'STATUS_UPDATE'
            }
        });

        res.json({ success: true, ride });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.verifyRideOtp = async (req, res) => {
    try {
        const { rideId } = req.params;
        const { otp } = req.body;

        const ride = await History.findById(rideId);
        if (!ride) {
            return res.status(404).json({ success: false, message: "Ride not found" });
        }

        if (ride.otp !== otp) {
            return res.status(400).json({ success: false, message: "Invalid OTP" });
        }

        ride.status = "ongoing";
        await ride.save();

        res.json({ success: true, message: "OTP verified correctly. Ride started." });

        // Socket notification to user
        if (req.io) {
            req.io.to(ride.userId.toString()).to(ride._id.toString()).emit("ride_status_update", {
                rideId: ride._id.toString(),
                status: "ongoing"
            });
        }

        // Push notification to user
        const { notifyUser } = require('../utils/notificationService');
        notifyUser(ride.userId, {
            title: "Ride Started",
            body: "OTP Verified. Your journey has begun!",
            data: {
                rideId: ride._id.toString(),
                status: "ongoing",
                type: 'STATUS_UPDATE'
            }
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

exports.updateFare = async (req, res) => {
    try {
        const { rideId, extraFare } = req.body;
        const ride = await History.findById(rideId);
        if (!ride) {
            return res.status(404).json({ success: false, message: "Ride not found" });
        }

        ride.fare += extraFare;
        await ride.save();

        res.json({ success: true, message: "Fare updated", fare: ride.fare });

        // Emit socket event to drivers
        if (req.io) {
            req.io.emit("fare_updated", {
                rideId: ride._id,
                newFare: ride.fare
            });
        }

        // Push notification to drivers
        const { notifyAllDrivers } = require('../utils/notificationService');
        notifyAllDrivers({
            title: "Fare Increased!",
            body: `Fare for ${ride.rideMode} ride increased to ₹${ride.fare}`,
            data: {
                rideId: ride._id.toString(),
                type: 'FARE_UPDATED'
            }
        });

    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.submitReview = async (req, res) => {
    try {
        const { bookingId, driverId, rating, comment } = req.body;
        const review = await Review.create({
            bookingId,
            fromId: req.user.id || req.user._id, // User ID from token
            toId: driverId,
            onModel: 'Driver',
            rating,
            comment
        });
        res.status(201).json({ success: true, data: review });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.payRide = async (req, res) => {
    try {
        const { rideId } = req.params;
        const ride = await History.findById(rideId);
        if (!ride) return res.status(404).json({ success: false, message: "Ride not found" });

        ride.paymentStatus = 'paid';
        await ride.save();

        if (req.io) {
            req.io.to(ride._id.toString()).emit("ride_status_update", {
                rideId: ride._id.toString(),
                paymentStatus: 'paid'
            });
        }

        res.json({ success: true, message: "Payment successful", ride });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
