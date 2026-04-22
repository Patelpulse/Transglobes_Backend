const jwt = require('jsonwebtoken');
const Corporate = require('../models/Corporate');
const LogisticsBooking = require('../models/LogisticsBooking');
const admin = require('../config/firebase');

const normalizeEmail = (email) =>
    typeof email === 'string' ? email.toLowerCase().trim() : '';

const generateSecurePassword = () =>
    `google_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

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

exports.signup = async (req, res) => {
    try {
        const { companyName, gstin, email, contactPhone, address, password } = req.body;

        if (!companyName || !gstin || !email || !contactPhone || !address || !password) {
            return res.status(400).json({
                success: false,
                message: 'companyName, gstin, email, contactPhone, address and password are required.'
            });
        }

        const safeEmail = normalizeEmail(email);
        const existing = await Corporate.findOne({
            $or: [
                { email: safeEmail },
                { companyName: companyName.trim() },
                { gstin: gstin.trim() },
            ]
        });

        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Corporate account already exists with provided email/companyName/gstin.'
            });
        }

        const corporate = await Corporate.create({
            companyName: companyName.trim(),
            gstin: gstin.trim(),
            email: safeEmail,
            contactPhone: String(contactPhone).trim(),
            address: address.trim(),
            password,
            role: 'corporate',
        });

        const token = createToken(corporate);
        return res.status(201).json({
            success: true,
            message: 'Corporate account created successfully.',
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                email: corporate.email,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                role: corporate.role,
                status: corporate.status,
            },
        });
    } catch (error) {
        console.error('Corporate signup error:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern || {})[0] || 'field';
            return res.status(400).json({ success: false, message: `${field} already exists.` });
        }
        return res.status(500).json({ success: false, message: 'Failed to create corporate account.' });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password are required.' });
        }

        let corporate = await Corporate.findOne({ email: normalizeEmail(email) });
        if (!corporate) {
            corporate = await ensureDemoCorporate(email.trim(), password);
        }

        if (!corporate) {
            return res.status(401).json({ success: false, message: 'Invalid corporate credentials.' });
        }

        if (!corporate.password) {
            return res.status(400).json({ success: false, message: 'This account uses Google sign-in. Please continue with Google.' });
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

// Google Sign-In for corporate signup/login
exports.googleAuth = async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'No token provided.' });
        }
        const idToken = authHeader.split(' ')[1];
        const decoded = await admin.auth().verifyIdToken(idToken);
        const { email, name, uid } = decoded;

        const safeEmail = normalizeEmail(email);
        if (!safeEmail) return res.status(400).json({ success: false, message: 'Email not found in Google account.' });

        let corporate = await Corporate.findOne({ email: safeEmail });
        let isNewCorporate = false;

        if (!corporate) {
            const { companyName, gstin, contactPhone, address } = req.body;
            if (!companyName || !gstin || !contactPhone || !address) {
                return res.status(400).json({
                    success: false,
                    message: 'For first-time Google signup, companyName, gstin, contactPhone and address are required.'
                });
            }

            isNewCorporate = true;
            corporate = await Corporate.create({
                companyName: companyName.trim(),
                gstin: gstin.trim(),
                email: safeEmail,
                googleId: uid,
                contactPhone: String(contactPhone).trim(),
                address: address.trim(),
                password: generateSecurePassword(),
                role: 'corporate',
            });
        } else {
            if (!corporate.googleId) corporate.googleId = uid;
            await corporate.save();
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            message: isNewCorporate ? 'Corporate Google signup successful' : 'Corporate Google login successful',
            isNewCorporate,
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

exports.googleSync = exports.googleAuth;

// Mobile Number + Password Signup for Corporate
exports.mobileSignup = async (req, res) => {
    try {
        const { companyName, gstin, mobileNumber, contactPhone, address, password } = req.body;

        if (!companyName || !gstin || !mobileNumber || !contactPhone || !address || !password) {
            return res.status(400).json({
                success: false,
                message: 'companyName, gstin, mobileNumber, contactPhone, address and password are required.'
            });
        }

        const safeMobile = String(mobileNumber).trim();
        
        // Check if mobile number already exists
        const existing = await Corporate.findOne({
            $or: [
                { mobileNumber: safeMobile },
                { companyName: companyName.trim() },
                { gstin: gstin.trim() },
            ]
        });

        if (existing) {
            return res.status(400).json({
                success: false,
                message: 'Corporate account already exists with provided mobile number, company name, or GSTIN.'
            });
        }

        // Create corporate with mobile number
        const corporate = await Corporate.create({
            companyName: companyName.trim(),
            gstin: gstin.trim(),
            email: `${safeMobile}@transglobe.temp`, // Temporary email for mobile-only signup
            mobileNumber: safeMobile,
            contactPhone: String(contactPhone).trim(),
            address: address.trim(),
            password,
            role: 'corporate',
        });

        const token = createToken(corporate);
        return res.status(201).json({
            success: true,
            message: 'Corporate account created successfully with mobile number',
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                mobileNumber: corporate.mobileNumber,
                contactPhone: corporate.contactPhone,
                address: corporate.address,
                gstin: corporate.gstin,
                role: corporate.role,
                status: corporate.status,
            },
        });
    } catch (error) {
        console.error('Corporate mobile signup error:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern || {})[0] || 'field';
            return res.status(400).json({ 
                success: false, 
                message: `${field} already exists.` 
            });
        }
        return res.status(500).json({ 
            success: false, 
            message: 'Failed to create corporate account.', 
            error: error.message 
        });
    }
};

// Mobile Number + Password Login for Corporate
exports.mobileLogin = async (req, res) => {
    try {
        const { mobileNumber, password } = req.body;

        if (!mobileNumber || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'mobileNumber and password are required.' 
            });
        }

        const safeMobile = String(mobileNumber).trim();
        const corporate = await Corporate.findOne({ mobileNumber: safeMobile });
        
        if (!corporate) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid corporate credentials.' 
            });
        }

        if (!corporate.password) {
            return res.status(400).json({ 
                success: false, 
                message: 'This account uses Google sign-in or has no password set. Please use appropriate login method.' 
            });
        }

        const isMatch = await corporate.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid corporate credentials.' 
            });
        }

        const token = createToken(corporate);
        return res.status(200).json({
            success: true,
            message: 'Login successful',
            token,
            corporate: {
                id: corporate._id,
                companyName: corporate.companyName,
                mobileNumber: corporate.mobileNumber,
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
        console.error('Corporate mobile login error:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Failed to log in corporate account.', 
            error: error.message 
        });
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
