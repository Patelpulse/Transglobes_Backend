const PricingConfig = require('../models/PricingConfig');
const { calculateDynamicFare } = require('../utils/pricingCalculator');

// ─── GET /api/admin/pricing ──────────────────────────────
// Get all pricing configs
exports.getAllConfigs = async (req, res) => {
    try {
        const configs = await PricingConfig.find().sort({ createdAt: -1 });
        return res.status(200).json({ success: true, data: configs });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── GET /api/admin/pricing/active ───────────────────────
// Get the active pricing config (used by booking engine)
exports.getActiveConfig = async (req, res) => {
    try {
        const config = await PricingConfig.findOne({ isActive: true, city: req.query.city || 'All' });
        if (!config) {
            return res.status(404).json({ success: false, message: 'No active pricing config found.' });
        }
        return res.status(200).json({ success: true, data: config });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/admin/pricing ─────────────────────────────
// Create a new pricing config
exports.createConfig = async (req, res) => {
    try {
        const config = new PricingConfig(req.body);
        await config.save();
        return res.status(201).json({ success: true, message: 'Pricing config created.', data: config });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── PUT /api/admin/pricing/:id ──────────────────────────
// Update a pricing config
exports.updateConfig = async (req, res) => {
    try {
        const config = await PricingConfig.findByIdAndUpdate(
            req.params.id,
            { $set: req.body },
            { new: true, runValidators: true }
        );
        if (!config) {
            return res.status(404).json({ success: false, message: 'Config not found.' });
        }
        return res.status(200).json({ success: true, message: 'Pricing config updated.', data: config });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── DELETE /api/admin/pricing/:id ───────────────────────
exports.deleteConfig = async (req, res) => {
    try {
        await PricingConfig.findByIdAndDelete(req.params.id);
        return res.status(200).json({ success: true, message: 'Pricing config deleted.' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ─── POST /api/admin/pricing/calculate ───────────────────
// Calculate fare for a given trip (distance, mode, weight, helpers, etc.)
exports.calculateFare = async (req, res) => {
    try {
        const {
            distanceKm = 0,
            durationMin = 0,
            mode = 'Road',         // Road, Train, Flight, Sea Cargo
            weightKg = 0,
            volumeCubicCm = 0,
            helperCount = 0,
            isFragile = false,
            isBulky = false,
            city = 'All',
            bookingType = 'logistics', // 'logistics' or 'ride'
        } = req.body;

        // Use the centralized pricing calculator utility
        const fareBreakdown = await calculateDynamicFare({
            distanceKm,
            durationMin,
            mode,
            weightKg,
            volumeCubicCm,
            helperCount,
            isFragile,
            isBulky,
            city,
            bookingType,
        });

        return res.status(200).json({
            success: true,
            data: fareBreakdown
        });
    } catch (error) {
        return res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
};
