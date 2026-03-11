const RideType = require("../models/RideType");
const History = require("../models/History");
const User = require("../models/User"); // used for populating name

exports.getRideTypes = async (req, res) => {
    try {
        const rides = await RideType.find({ status: true });

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
        // Find all rides that are not cancelled
        const bookings = await History.find({
            status: { $ne: 'cancelled' }
        }).populate('userId', 'name').sort({ createdAt: -1 });

        res.json({
            success: true,
            bookings: bookings.map(b => ({
                _id: b._id,
                userName: b.userId?.name || 'Customer',
                userPhone: b.mobileNumber,
                pickupAddress: b.locations[0]?.address || '',
                dropAddress: b.locations[1]?.address || '',
                fare: b.fare,
                distanceKm: parseFloat(b.distance) || 0,
                status: b.status,
                otp: b.otp,
                rideMode: b.rideMode,
                createdAt: b.createdAt,
                userId: b.userId?._id || b.userId,
                pickupLat: b.locations[0]?.latitude,
                pickupLng: b.locations[0]?.longitude,
                dropLat: b.locations[1]?.latitude,
                dropLng: b.locations[1]?.longitude,
            }))
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
        const { mobileNumber, locations, rideMode, paymentMode, fare, distance } = req.body;

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
                id: newRide._id,
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
                otp: newRide.otp,
                userId: newRide.userId
            });
            console.log(`Socket emitted: new_ride for ${newRide._id}`);
        }

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
        const { driverId } = req.body;
        const ride = await History.findById(rideId);
        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        ride.status = 'accepted';
        ride.driverActionAt = new Date();

        // populate snapshot if we know driverId
        if (driverId) {
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate _id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate _id');
            }
            if (driver) {
                ride.driverId = driver._id;
                ride.driverSnapshot = {
                    driver_id: driver._id,
                    name: driver.name,
                    phone: driver.mobileNumber,
                    vichle_number: driver.vehicleNumberPlate || ''
                };
            }
        }

        await ride.save();

        if (req.io) {
            req.io.to(ride.userId.toString()).emit("ride_accepted", {
                rideId: ride._id,
                status: ride.status,
                driver: ride.driverSnapshot
            });
            // Also notify other drivers that this ride is taken
            req.io.emit("ride_assigned", { rideId: ride._id });
        }

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
        const ride = await History.findById(rideId);
        if (!ride) return res.status(404).json({ message: 'Ride not found' });

        ride.status = 'rejected';
        ride.driverActionAt = new Date();

        if (driverId) {
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate _id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate _id');
            }
            if (driver) {
                ride.driverSnapshot = {
                    driver_id: driver._id,
                    name: driver.name,
                    phone: driver.mobileNumber,
                    vichle_number: driver.vehicleNumberPlate || ''
                };
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
        const ride = await History.findById(rideId);
        if (!ride) return res.status(404).json({ message: 'Ride not found' });
        if (status) ride.status = status;
        if (delayReason) ride.delayReason = delayReason;
        if (actualFare != null) ride.actualFare = actualFare;

        // record which driver made the change; driverId may be passed
        if (driverId) {
            ride.driverActionAt = new Date();
            const Driver = require('../models/Driver');
            const mongoose = require('mongoose');
            let driver;
            if (mongoose.Types.ObjectId.isValid(driverId)) {
                driver = await Driver.findById(driverId).select('name mobileNumber vehicleNumberPlate _id');
            } else {
                driver = await Driver.findOne({ uid: driverId }).select('name mobileNumber vehicleNumberPlate _id');
            }
            if (driver) {
                ride.driverId = driver._id;              // ensure link
                ride.driverSnapshot = {
                    driver_id: driver._id,
                    name: driver.name,
                    phone: driver.mobileNumber,
                    vichle_number: driver.vehicleNumberPlate || ''
                };
            }
        }

        await ride.save();

        if (req.io) {
            req.io.to(ride.userId.toString()).emit("ride_status_update", {
                rideId: ride._id,
                status: ride.status,
                driver: ride.driverSnapshot
            });
        }

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
            return res.status(404).json({ success: false, message: 'Ride not found' });
        }

        if (String(ride.otp) !== String(otp)) {
            return res.status(400).json({ success: false, message: 'Invalid OTP' });
        }

        ride.status = 'ongoing';
        await ride.save();

        if (req.io) {
            req.io.to(ride.userId.toString()).emit("ride_status_update", {
                rideId: ride._id,
                status: ride.status,
                driver: ride.driverSnapshot
            });
        }

        res.json({ success: true, message: 'Ride started successfully', ride });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};
