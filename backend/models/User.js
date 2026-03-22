const mongoose = require('mongoose');

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
        required: true,
        unique: true,
        index: true
    },
    // optional email (may be null). mark sparse so multiple nulls allowed
    email: {
        type: String,
        unique: true,
        sparse: true
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
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
