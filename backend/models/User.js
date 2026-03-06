const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    uid: {
        type: String,
        required: false, // Make optional if using custom registration
        unique: true,
        sparse: true
    },
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    password: {
        type: String,
        required: true
    },
    aadharCard: {
        type: String,
        required: true
    },
    panCard: {
        type: String,
        required: true
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

// Pre-save hook to hash password
userSchema.pre('save', async function () {
    if (!this.isModified('password')) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
