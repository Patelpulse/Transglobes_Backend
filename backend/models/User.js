const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
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
    type: {
        type: String,
        enum: ['personal', 'business'],
        default: 'personal'
    },
    status: {
        type: String,
        enum: ['active', 'inactive', 'suspended'],
        default: 'active'
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    imageUrl: {
        type: String,
        default: 'https://i.pravatar.cc/150?u=user'
    },
    lastActive: {
        type: Date,
        default: Date.now
    },
    isFraudulent: {
        type: Boolean,
        default: false
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
