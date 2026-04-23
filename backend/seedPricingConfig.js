const mongoose = require('mongoose');
const PricingConfig = require('./models/PricingConfig');
require('dotenv').config();

const seedPricingConfig = async () => {
    try {
        // Connect to MongoDB
        const dbUri = process.env.MONGO_URI || 'mongodb://localhost:27017/transglobes';
        await mongoose.connect(dbUri);
        console.log('✅ Connected to MongoDB');

        // Check if a default config already exists
        const existingConfig = await PricingConfig.findOne({ name: 'Default' });
        
        if (existingConfig) {
            console.log('⚠️  Default pricing config already exists. Skipping seed.');
            console.log('Config ID:', existingConfig._id);
            process.exit(0);
        }

        // Create default pricing configuration
        const defaultConfig = new PricingConfig({
            name: 'Default',
            city: 'All',
            isActive: true,

            // ─── Base Fare Components ────────────────────────────
            baseFare: 50,              // ₹50 base charge
            perKmCharge: 10,           // ₹10 per km
            perMinuteCharge: 2,        // ₹2 per minute
            minimumFare: 100,          // ₹100 minimum fare

            // ─── Wait & Extra Charges ────────────────────────────
            waitingChargePerMin: 2,
            freeWaitingMinutes: 5,

            // ─── Time-based Surcharges ───────────────────────────
            nightChargeMultiplier: 1.25,  // 25% night surcharge
            nightStartHour: 22,            // 10 PM
            nightEndHour: 6,               // 6 AM
            peakHourMultiplier: 1.5,       // 50% surge pricing
            peakHours: [
                { start: '08:00', end: '10:00' },
                { start: '17:00', end: '20:00' }
            ],

            // ─── Additional Charges ──────────────────────────────
            tollCharges: 0,
            platformFeePercent: 5,     // 5% platform fee
            gstPercent: 18,            // 18% GST

            // ─── Logistics-specific Pricing ─────────────────────
            logistics: {
                baseFare: 100,
                perKmCharge: 15,
                helperCostPerPerson: 150,

                // Weight-based tiers (₹ per kg)
                weightTiers: [
                    { minKg: 0, maxKg: 10, ratePerKg: 5 },
                    { minKg: 10, maxKg: 50, ratePerKg: 4 },
                    { minKg: 50, maxKg: 100, ratePerKg: 3 },
                    { minKg: 100, maxKg: 500, ratePerKg: 2 },
                    { minKg: 500, maxKg: 10000, ratePerKg: 1.5 },
                ],

                // Volume-based (₹ per cubic cm)
                volumeRatePerCubicCm: 0.001,

                // Transport mode multipliers
                modeMultipliers: {
                    Road: 1.0,
                    Train: 0.8,
                    Flight: 2.5,
                    'Sea Cargo': 0.7,
                },

                // Handling charges
                fragileHandlingCharge: 200,
                bulkyItemSurcharge: 300,
            },

            // ─── Commission ──────────────────────────────────────
            driverCommissionPercent: 80,    // 80% to driver
            platformCommissionPercent: 20,  // 20% to platform
        });

        await defaultConfig.save();
        console.log('✅ Default pricing config seeded successfully!');
        console.log('Config ID:', defaultConfig._id);
        console.log('Config Name:', defaultConfig.name);

    } catch (error) {
        console.error('❌ Error seeding pricing config:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB');
        process.exit(0);
    }
};

seedPricingConfig();
