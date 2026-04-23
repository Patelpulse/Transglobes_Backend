const PricingConfig = require('../models/PricingConfig');

/**
 * Calculate fare dynamically based on active pricing configuration
 * @param {Object} params - Booking parameters
 * @param {Number} params.distanceKm - Distance in kilometers
 * @param {Number} params.durationMin - Duration in minutes (optional)
 * @param {String} params.mode - Transport mode ('Road', 'Train', 'Flight', 'Sea Cargo')
 * @param {Number} params.weightKg - Total weight in kg (for logistics)
 * @param {Number} params.volumeCubicCm - Total volume in cubic cm (for logistics)
 * @param {Number} params.helperCount - Number of helpers
 * @param {Boolean} params.isFragile - Whether cargo is fragile
 * @param {Boolean} params.isBulky - Whether cargo is bulky
 * @param {String} params.city - City name for city-specific pricing
 * @param {String} params.bookingType - 'logistics' or 'ride'
 * @returns {Object} Calculated fare breakdown
 */
async function calculateDynamicFare(params) {
    const {
        distanceKm = 0,
        durationMin = 0,
        mode = 'Road',
        weightKg = 0,
        volumeCubicCm = 0,
        helperCount = 0,
        isFragile = false,
        isBulky = false,
        city,
        bookingType,
    } = params;

    // Find active config (city-specific or default)
    let config = await PricingConfig.findOne({ isActive: true, city });
    if (!config) {
        config = await PricingConfig.findOne({ isActive: true, city: 'All' });
    }
    
    if (!config) {
        throw new Error('No active pricing configuration found. Please contact administrator.');
    }

    let baseFare = 0;
    let distanceCharge = 0;
    let helperCharge = 0;
    let weightCharge = 0;
    let volumeCharge = 0;
    let modeMultiplier = 1.0;
    let fragileCharge = 0;
    let bulkyCharge = 0;
    let nightSurcharge = 0;
    let tollCharges = 0;
    let platformFee = 0;
    let gstAmount = 0;

    if (bookingType === 'logistics') {
        const lp = config.logistics;

        // 1. Base + distance
        baseFare = lp.baseFare || 0;
        distanceCharge = distanceKm * (lp.perKmCharge || 0);

        // 2. Weight-based pricing
        if (weightKg > 0 && lp.weightTiers?.length > 0) {
            const tier = lp.weightTiers.find(t => weightKg >= t.minKg && weightKg <= t.maxKg);
            if (tier) {
                weightCharge = weightKg * tier.ratePerKg;
            }
        }

        // 3. Volume-based
        if (volumeCubicCm > 0) {
            volumeCharge = volumeCubicCm * (lp.volumeRatePerCubicCm || 0);
        }

        // 4. Mode multiplier
        const modeKey = mode;
        modeMultiplier = lp.modeMultipliers?.[modeKey] ?? 1.0;

        // 5. Helpers
        helperCharge = helperCount * (lp.helperCostPerPerson || 0);

        // 6. Fragile / bulky
        if (isFragile) fragileCharge = lp.fragileHandlingCharge || 0;
        if (isBulky) bulkyCharge = lp.bulkyItemSurcharge || 0;
    } else {
        // Regular ride pricing
        baseFare = config.baseFare || 0;
        distanceCharge = distanceKm * (config.perKmCharge || 0);
        
        // Duration-based charge
        if (durationMin > 0) {
            distanceCharge += durationMin * (config.perMinuteCharge || 0);
        }
    }

    // Calculate subtotal before multipliers
    let subtotal = baseFare + distanceCharge + weightCharge + volumeCharge + helperCharge + fragileCharge + bulkyCharge;

    // Apply mode multiplier for logistics
    if (bookingType === 'logistics') {
        subtotal *= modeMultiplier;
    }

    // 7. Night charge (applies to both)
    const hour = new Date().getHours();
    const isNight = hour >= config.nightStartHour || hour < config.nightEndHour;
    if (isNight && config.nightChargeMultiplier > 1) {
        nightSurcharge = subtotal * (config.nightChargeMultiplier - 1);
        subtotal += nightSurcharge;
    }

    // 8. Toll
    tollCharges = config.tollCharges || 0;
    subtotal += tollCharges;

    // 9. Platform fee
    platformFee = subtotal * ((config.platformFeePercent || 0) / 100);
    subtotal += platformFee;

    // 10. GST
    gstAmount = subtotal * ((config.gstPercent || 0) / 100);

    // Apply minimum fare check
    const minimumFare = bookingType === 'logistics' 
        ? (config.logistics?.baseFare || config.minimumFare || 0)
        : (config.minimumFare || 0);
    
    if (subtotal < minimumFare) {
        subtotal = minimumFare;
    }

    const totalFare = subtotal + gstAmount;

    return {
        configId: config._id,
        configName: config.name,
        baseFare: Math.round(baseFare),
        distanceCharge: Math.round(distanceCharge),
        weightCharge: Math.round(weightCharge),
        volumeCharge: Math.round(volumeCharge),
        helperCharge: Math.round(helperCharge),
        fragileCharge: Math.round(fragileCharge),
        bulkyCharge: Math.round(bulkyCharge),
        modeMultiplier,
        nightSurcharge: Math.round(nightSurcharge),
        tollCharges: Math.round(tollCharges),
        platformFee: Math.round(platformFee),
        gstAmount: Math.round(gstAmount),
        subtotal: Math.round(subtotal),
        totalFare: Math.round(totalFare),
    };
}

/**
 * Calculate total weight from items array
 * @param {Array} items - Array of items with weight property
 * @returns {Number} Total weight in kg
 */
function calculateTotalWeight(items = []) {
    if (!Array.isArray(items)) return 0;
    return items.reduce((total, item) => {
        const weight = Number(item?.weight || 0);
        const quantity = Number(item?.quantity || 1);
        return total + (weight * quantity);
    }, 0);
}

/**
 * Calculate total volume from items array
 * @param {Array} items - Array of items with dimensions (length, width, height)
 * @returns {Number} Total volume in cubic cm
 */
function calculateTotalVolume(items = []) {
    if (!Array.isArray(items)) return 0;
    return items.reduce((total, item) => {
        const length = Number(item?.length || 0);
        const width = Number(item?.width || 0);
        const height = Number(item?.height || 0);
        const quantity = Number(item?.quantity || 1);
        return total + (length * width * height * quantity);
    }, 0);
}

/**
 * Check if any item is fragile
 * @param {Array} items - Array of items
 * @returns {Boolean}
 */
function hasFragileItems(items = []) {
    if (!Array.isArray(items)) return false;
    return items.some(item => {
        const type = String(item?.type || '').toLowerCase();
        const itemName = String(item?.itemName || '').toLowerCase();
        return type.includes('fragile') || itemName.includes('fragile') || itemName.includes('glass');
    });
}

/**
 * Check if any item is bulky (based on dimensions)
 * @param {Array} items - Array of items
 * @param {Number} bulkyThreshold - Threshold for bulky items (default 100,000 cubic cm = 0.1 cubic meter)
 * @returns {Boolean}
 */
function hasBulkyItems(items = [], bulkyThreshold = 100000) {
    if (!Array.isArray(items)) return false;
    return items.some(item => {
        const length = Number(item?.length || 0);
        const width = Number(item?.width || 0);
        const height = Number(item?.height || 0);
        const volume = length * width * height;
        return volume > bulkyThreshold;
    });
}

module.exports = {
    calculateDynamicFare,
    calculateTotalWeight,
    calculateTotalVolume,
    hasFragileItems,
    hasBulkyItems,
};
