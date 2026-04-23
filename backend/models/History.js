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
        enum: ["pending", "accepted", "on_the_way", "ongoing", "completed", "cancelled", "rejected", "arrived"],
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
            vehicle_number: String,
            vehicle_name: String,
            photo: String
        }, { _id: false }),
        default: null
    },
    driverActionAt: {
        type: Date
    },
    rejectedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: "Driver"
    }],
    paymentStatus: {
        type: String,
        enum: ["unpaid", "paid"],
        default: "unpaid"
    },
    vehicleType: {
        type: String
    },
    typeOfGood: {
        type: String
    },
    helperCount: {
        type: Number,
        default: 0
    },
    logisticItems: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'LogisticGood'
    }],
    // Fare breakdown for transparency
    fareBreakdown: {
        configId: { type: mongoose.Schema.Types.ObjectId, ref: 'PricingConfig' },
        configName: { type: String },
        baseFare: { type: Number, default: 0 },
        distanceCharge: { type: Number, default: 0 },
        weightCharge: { type: Number, default: 0 },
        volumeCharge: { type: Number, default: 0 },
        helperCharge: { type: Number, default: 0 },
        fragileCharge: { type: Number, default: 0 },
        bulkyCharge: { type: Number, default: 0 },
        modeMultiplier: { type: Number, default: 1.0 },
        nightSurcharge: { type: Number, default: 0 },
        tollCharges: { type: Number, default: 0 },
        platformFee: { type: Number, default: 0 },
        gstAmount: { type: Number, default: 0 },
        subtotal: { type: Number, default: 0 },
        totalFare: { type: Number, default: 0 },
    },
}, { timestamps: true });


module.exports = mongoose.model("History", historySchema);
