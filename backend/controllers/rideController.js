const RideType = require("../models/RideType");
const Booking = require("../models/Booking");

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

// To save user's "input fill" (Ride Request / Booking)
exports.createRideRequest = async (req, res) => {
    try {
        const { userId, from, to, when, rideType } = req.body;

        // Use existing Booking model or save to context
        // For now, let's create a new booking record
        const newBooking = await Booking.create({
            userId,
            pickupLocation: from,
            dropoffLocation: to,
            fare: 0, // Should be calculated
            status: 'pending'
        });

        res.status(201).json({
            success: true,
            message: "Ride request created successfully",
            data: newBooking
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};
