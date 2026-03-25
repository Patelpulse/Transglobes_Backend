const mongoose = require('mongoose');

// ─── Sub-schemas ────────────────────────────────────────
const locationSchema = new mongoose.Schema({
    name:    { type: String },
    address: { type: String },
    lat:     { type: Number },
    lng:     { type: Number },
}, { _id: false });

const itemSchema = new mongoose.Schema({
    itemName: { type: String, required: true },
    type:     { type: String, default: 'General' }, // Furniture, Electronics, etc.
    length:   { type: Number, default: 0 },
    height:   { type: Number, default: 0 },
    width:    { type: Number, default: 0 },
    unit:     { type: String, default: 'cm' },
}, { _id: false });

const addressSchema = new mongoose.Schema({
    label:       { type: String },
    fullAddress: { type: String },
    houseNumber: { type: String },
    floorNumber: { type: String },
    landmark:    { type: String },
    city:        { type: String },
    pincode:     { type: String },
    phone:       { type: String },
    email:       { type: String },
}, { _id: false });

// ─── Main Logistics Booking Schema ──────────────────────
const logisticsBookingSchema = new mongoose.Schema({

    // Who booked
    userId: {
        type: String,
        required: true,
        index: true,
    },
    userName: {
        type: String,
        default: "",
    },
    userPhone: {
        type: String,
        default: "",
    },

    // Pickup & Drop locations (from map search)
    pickup: { type: locationSchema, required: true },
    dropoff: { type: locationSchema, required: true },

    // Distance & estimated price
    distanceKm:    { type: Number, default: 0 },
    vehiclePrice:  { type: Number, default: 0 },
    helperCost:    { type: Number, default: 0 },
    additionalCharges: { type: Number, default: 0 },
    discountAmount:{ type: Number, default: 0 },
    totalPrice:    { type: Number, default: 0 },
    appliedCoupon: { type: String, default: null },

    // Vehicle
    vehicleType: { type: String, required: true }, // Train, Flight, Sea Cargo, etc.

    // List of items being transported
    items: {
        type: [itemSchema],
        default: [],
    },

    // Helpers
    helperCount: { type: Number, default: 0 },

    // Saved addresses (from address book)
    pickupAddress:   { type: addressSchema, default: null },
    receivedAddress: { type: addressSchema, default: null }, // delivery address

    // Status
    status: {
        type: String,
        enum: ['pending', 'processing', 'confirmed', 'in_transit', 'delivered', 'cancelled'],
        default: 'pending',
    },

    // Assigned Driver
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        default: null,
    },

    // Railway Station for Train Mode
    railwayStation: {
        type: String,
        default: null,
    },

    // OTP for Hand-off Verification
    otp: {
        type: String,
        default: null,
    },

    // Track drivers who rejected this booking
    rejectedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
    }],

}, { timestamps: true });

module.exports = mongoose.model('LogisticsBooking', logisticsBookingSchema);
