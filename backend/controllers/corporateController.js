const jwt = require('jsonwebtoken');
const Corporate = require('../models/Corporate');
const LogisticsBooking = require('../models/LogisticsBooking');
const admin = require('../config/firebase');

const createToken = (corporate) => jwt.sign(
    {
        id: corporate._id.toString(),
        email: corporate.email,
        role: corporate.role || 'corporate',
        companyName: corporate.companyName,
    },
    process.env.JWT_SECRET || 'your_secret_key',
    { expiresIn: '7d' }
);

const ensureDemoCorporate = async (email, password) => {
    const demoEmail = process.env.CORPORATE_DEMO_EMAIL || 'demo@transglobe.com';
    const demoPassword = process.env.CORPORATE_DEMO_PASSWORD || 'demo1234';

    if (
        process.env.NODE_ENV === 'production' ||
        email.toLowerCase() !== demoEmail.toLowerCase() ||
        password !== demoPassword
    ) {
        return null;
    }

    let corporate = await Corporate.findOne({ email: demoEmail.toLowerCase() });
    if (corporate) return corporate;

    corporate = await Corporate.create({
        companyName: 'Transglobe Demo Corporate',
        gstin: '22AAAAA0000A1Z5',
        email: demoEmail.toLowerCase(),
        contactPhone: '9999999999',
        address: 'Demo Corporate Address',
        password: demoPassword,
        role: 'corporate',
    });

    return corporate;
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password are required.' });
        }

        let corporate = await Corporate.findOne({ email: email.toLowerCase().trim() });
        if (!corporate) {
            corporate = await ensureDemoCorporate(email.trim(), password);
        }

        if (!corporate) {
            return res.status(401).json({ success: false, message: 'Invalid corporate credentials.' });
        }

        const isMatch = await corporate.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Invalid corporate credentials.' });
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                email: corporate.email,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                status: corporate.status,
                creditLimit: corporate.creditLimit,
                currentBalance: corporate.currentBalance,
                role: corporate.role,
            },
        });
    } catch (error) {
        console.error('Corporate login error:', error);
        return res.status(500).json({ success: false, message: 'Failed to log in corporate account.' });
    }
};

// Google Sign-In sync for corporate panel
exports.googleSync = async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'No token provided.' });
        }
        const idToken = authHeader.split(' ')[1];
        const decoded = await admin.auth().verifyIdToken(idToken);
        const { email, name, uid } = decoded;

        if (!email) return res.status(400).json({ success: false, message: 'Email not found in Google account.' });

        let corporate = await Corporate.findOne({ email: email.toLowerCase() });
        if (!corporate) {
            return res.status(404).json({
                success: false,
                message: 'No corporate account found for this Google email. Please contact admin.',
            });
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                email: corporate.email,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                status: corporate.status,
                role: corporate.role,
            },
        });
    } catch (error) {
        console.error('Corporate Google sync error:', error);
        return res.status(401).json({ success: false, message: 'Invalid or expired Google token.' });
    }
};

exports.getProfile = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id).select('-password');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        return res.status(200).json({ success: true, corporate });
    } catch (error) {
        console.error('Corporate profile error:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch corporate profile.' });
    }
};

exports.getBookings = async (req, res) => {
    try {
        if (req.user.role !== 'corporate') {
            return res.status(403).json({ success: false, message: 'Corporate access required.' });
        }

        const corporate = await Corporate.findById(req.user.id).select('companyName email');
        if (!corporate) {
            return res.status(404).json({ success: false, message: 'Corporate account not found.' });
        }

        const bookings = await LogisticsBooking.find({
            $or: [
                { userId: corporate._id.toString() },
                { userName: corporate.companyName },
            ],
        }).sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            data: bookings,
        });
    } catch (error) {
        console.error('Corporate bookings error:', error);
        return res.status(500).json({ success: false, message: 'Failed to fetch corporate bookings.' });
    }
};
