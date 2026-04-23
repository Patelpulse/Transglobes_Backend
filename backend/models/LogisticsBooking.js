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
    weight:   { type: Number, default: 0 }, // Weight in kg
    quantity: { type: Number, default: 1 }, // Quantity of this item
}, { _id: false });

const addressSchema = new mongoose.Schema({
    type:        { type: String, enum: ['pickup', 'received'], default: null },
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
    
    // Estimates
    estimatedTime: { type: String, default: "" }, // e.g. "2 Days", "10:30 AM"
    estimatedDate: { type: String, default: "" }, // e.g. "2024-03-28"

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
        enum: ['pending', 'pending_for_driver', 'processing', 'confirmed', 'in_transit', 'delivered', 'cancelled'],
        default: 'pending',
    },

    // Assigned Driver
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        default: null,
    },

    // ─── Multi-Segment Roadmap (Supervisor Controlled) ─────
    segments: [{
        start:           { type: locationSchema },
        end:             { type: locationSchema },
        mode:            { type: String, enum: ['Road', 'Train', 'Flight', 'Sea Cargo'], default: 'Road' },
        distanceKm:      { type: Number, default: 0 },
        driverId:        { type: mongoose.Schema.Types.ObjectId, ref: 'Driver', default: null },
        transportName:   { type: String },   // e.g. Train Name
        transportNumber: { type: String },   // e.g. Train Number
        estimatedTime:   { type: String },   // e.g. "10:30 AM" or "3 Hours"
        estimatedDate:   { type: String },   // e.g. "2024-03-28"
        status: { 
            type: String, 
            enum: ['pending', 'processing', 'completed'], 
            default: 'pending' 
        },
        price:           { type: Number, default: 0 }
      }],

    // Railway Station for Train Mode
    railwayStation: {
        type: String,
        default: null,
    },

    // Transport Details (Dynamic based on mode)
    transportName: {
        type: String,
        default: null,
    },
    transportNumber: {
        type: String,
        default: null,
    },

    // Cancellation charge (if cancelled after free window)
    cancellationCharge: { type: Number, default: 0 },

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

module.exports = mongoose.model('LogisticsBooking', logisticsBookingSchema);
