const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
    driverId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Driver'
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'ServiceCategory',
        required: true
    },
    make: String,
    model: String,
    year: String,
    numberPlate: {
        type: String,
        required: true,
        unique: true
    },
    status: {
        type: String,
        enum: ['active', 'inactive', 'maintenance'],
        default: 'inactive'
    },
    documents: {
        rc: { url: String, verified: { type: Boolean, default: false } },
        insurance: { url: String, verified: { type: Boolean, default: false } },
        fitness: { url: String, verified: { type: Boolean, default: false } }
    },
    currentLocation: {
        lat: { type: Number, default: 0 },
        lng: { type: Number, default: 0 },
        lastUpdated: { type: Date, default: Date.now }
    }
}, { timestamps: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);
