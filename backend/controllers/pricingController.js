const PricingConfig = require('../models/PricingConfig');

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
        } = req.body;

        // Find active config
        let config = await PricingConfig.findOne({ isActive: true, city });
        if (!config) config = await PricingConfig.findOne({ isActive: true, city: 'All' });
        if (!config) {
            return res.status(404).json({ success: false, message: 'No active pricing config found.' });
        }

        const lp = config.logistics;

        // 1. Base + distance
        let fare = (lp.baseFare || 0) + (distanceKm * (lp.perKmCharge || 0));

        // 2. Weight-based pricing
        if (weightKg > 0 && lp.weightTiers?.length > 0) {
            const tier = lp.weightTiers.find(t => weightKg >= t.minKg && weightKg <= t.maxKg);
            if (tier) fare += weightKg * tier.ratePerKg;
        }

        // 3. Volume-based
        if (volumeCubicCm > 0) {
            fare += volumeCubicCm * (lp.volumeRatePerCubicCm || 0);
        }

        // 4. Mode multiplier
        const modeKey = mode;
        const modeMultiplier = lp.modeMultipliers?.[modeKey] ?? 1.0;
        fare *= modeMultiplier;

        // 5. Helpers
        fare += helperCount * (lp.helperCostPerPerson || 0);

        // 6. Fragile / bulky
        if (isFragile) fare += (lp.fragileHandlingCharge || 0);
        if (isBulky) fare += (lp.bulkyItemSurcharge || 0);

        // 7. Night charge
        const hour = new Date().getHours();
        const isNight = hour >= config.nightStartHour || hour < config.nightEndHour;
        if (isNight && config.nightChargeMultiplier > 1) {
            fare *= config.nightChargeMultiplier;
        }

        // 8. Toll
        fare += (config.tollCharges || 0);

        // 9. Platform fee
        fare += fare * ((config.platformFeePercent || 0) / 100);

        // 10. GST
        const gstAmount = fare * ((config.gstPercent || 0) / 100);
        const totalFare = fare + gstAmount;

        return res.status(200).json({
            success: true,
            data: {
                baseFare: lp.baseFare,
                distanceCharge: distanceKm * (lp.perKmCharge || 0),
                helperCharge: helperCount * (lp.helperCostPerPerson || 0),
                modeMultiplier,
                nightSurcharge: isNight ? fare * (config.nightChargeMultiplier - 1) : 0,
                tollCharges: config.tollCharges,
                gstAmount: Math.round(gstAmount),
                subtotal: Math.round(fare),
                totalFare: Math.round(totalFare),
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
