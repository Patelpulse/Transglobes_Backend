const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
    uid: {
        type: String,
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    mobileNumber: {
        type: String,
        unique: true,
        sparse: true
    },
    status: {
        type: String,
        enum: ['pending', 'active', 'suspended'],
        default: 'pending'
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    photo: {
        type: String,
        default: ''
    },
    aadharCard: {
        type: String,
        default: ''
    },
    drivingLicense: {
        type: String,
        default: ''
    },
    aadharCardNumber: {
        type: String,
        default: ''
    },
    drivingLicenseNumber: {
        type: String,
        default: ''
    },
    panCardNumber: {
        type: String,
        default: ''
    },
    vehicleNumberPlate: {
        type: String,
        default: ''
    },
    vehicleModel: {
        type: String,
        default: ''
    },
    signature: {
        type: String,
        default: ''
    },
    vehicleYear: {
        type: String,
        default: ''
    },
    panVerified: {
        type: Boolean,
        default: false
    },
    aadharVerified: {
        type: Boolean,
        default: false
    },
    drivingLicenseVerified: {
        type: Boolean,
        default: false
    },
    isEmailVerified: {
        type: Boolean,
        default: false
    },
    dob: {
        type: Date
    },
    warningCount: {
        type: Number,
        default: 0
    },
    lastWarningReason: {
        type: String,
        default: ''
    },
    lastWarningDate: {
        type: Date
    }
}, { timestamps: true });

module.exports = mongoose.model('Driver', driverSchema);
