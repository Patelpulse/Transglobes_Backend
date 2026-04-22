const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    uid: {
        type: String,
        unique: true,
        sparse: true,
        index: true
    },
    name: {
        type: String,
        default: ''
    },
    mobileNumber: {
        type: String,
        unique: true,
        sparse: true,
        index: true
    },
    // optional email (may be null). mark sparse so multiple nulls allowed
    email: {
        type: String,
        unique: true,
        sparse: true
    },
    password: {
        type: String,
        required: false
    },
    googleId: {
        type: String,
        unique: true,
        sparse: true,
        index: true
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
    },
    fcmToken: {
        type: String,
        default: ''
    },
    role: {
        type: String,
        enum: ['user', 'corporate'],
        default: 'user'
    },
    lastLoginAt: {
        type: Date
    },
    deviceInfo: {
        model: String,
        platform: String,
        version: String
    }
}, { timestamps: true });

userSchema.pre('save', async function () {
    if (!this.password || !this.isModified('password')) return;
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

userSchema.methods.comparePassword = async function (candidatePassword) {
    if (!this.password) return false;
    return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
