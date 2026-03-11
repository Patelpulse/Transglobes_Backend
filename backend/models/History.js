const mongoose = require("mongoose");

const locationPointSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ["pickup", "dropoff", "stop"],
        required: true
    },
    title: String,
    address: String,
    latitude: {
        type: Number,
        required: true
    },
    longitude: {
        type: Number,
        required: true
    }
}, { _id: false });

const historySchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    mobileNumber: {
        type: String,
        required: true
    },
    locations: [locationPointSchema],
    rideMode: {
        type: String,
        required: true
    },
    paymentMode: {
        type: String,
        default: "cash"
    },
    distance: {
        type: String,
    },
    fare: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ["pending", "accepted", "ongoing", "completed", "cancelled", "rejected", "arrived"],
        default: "pending"
    },
    otp: {
        type: String
    },
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Driver"
    },
    driverSnapshot: {
        type: new mongoose.Schema({
            driver_id: mongoose.Schema.Types.ObjectId,
            name: String,
            phone: String,
            vichle_number: String
        }, { _id: false }),
        default: null
    },
    driverActionAt: {
        type: Date
    }
}, { timestamps: true });

module.exports = mongoose.model("History", historySchema);
