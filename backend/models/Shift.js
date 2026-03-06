const mongoose = require('mongoose');

const shiftSchema = new mongoose.Schema({
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver',
        required: true
    },
    vehicleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Vehicle',
        required: true
    },
    routeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Route'
    },
    startTime: {
        type: Date,
        required: true
    },
    endTime: Date,
    status: {
        type: String,
        enum: ['active', 'completed', 'scheduled'],
        default: 'scheduled'
    }
}, { timestamps: true });

module.exports = mongoose.model('Shift', shiftSchema);
