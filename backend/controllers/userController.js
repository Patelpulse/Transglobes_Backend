const User = require('../models/User');
const Location = require('../models/Location');
const jwt = require('jsonwebtoken');
const admin = require('../config/firebase');

const normalizeMobile = (num) => {
    if (!num) return num;
    const trimmed = String(num).trim();
    const hasPlus = trimmed.startsWith('+');
    const digits = trimmed.replace(/[^\d]/g, '');
    return hasPlus ? `+${digits}` : digits;
};

const normalizeEmail = (email) =>
    typeof email === 'string' ? email.toLowerCase().trim() : '';

const generateSecurePassword = () =>
    `google_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;

const createUserToken = (user) => jwt.sign(
    {
        id: user._id.toString(),
        uid: user.uid || user._id.toString(),
        email: user.email,
        role: user.role || 'user',
    },
    process.env.JWT_SECRET || 'your_secret_key',
    { expiresIn: '7d' }
);

const mapUserResponse = (user) => ({
    id: user._id,
    uid: user.uid,
    name: user.name,
    email: user.email,
    mobileNumber: user.mobileNumber,
    role: user.role,
});

exports.signup = async (req, res) => {
    try {
        const { name, email, password, mobileNumber } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({ message: 'name, email and password are required' });
        }

        const safeEmail = normalizeEmail(email);
        const existing = await User.findOne({ email: safeEmail });
        if (existing) {
            return res.status(400).json({ message: 'Email already registered' });
        }

        const user = await User.create({
            uid: `usr_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`,
            name: name.trim(),
            email: safeEmail,
            password,
            mobileNumber: mobileNumber ? normalizeMobile(mobileNumber) : undefined,
            role: 'user',
        });

        const token = createUserToken(user);
        return res.status(201).json({
            success: true,
            message: 'User registered successfully',
            token,
            user: mapUserResponse(user),
        });
    } catch (error) {
        console.error('User signup error:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern || {})[0] || 'field';
            return res.status(400).json({ message: `${field} already exists` });
        }
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'email and password are required' });
        }

        const safeEmail = normalizeEmail(email);
        const user = await User.findOne({ email: safeEmail });
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = createUserToken(user);
        return res.status(200).json({
            success: true,
            message: 'Login successful',
            token,
            user: mapUserResponse(user),
        });
    } catch (error) {
        console.error('User login error:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.googleAuth = async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'No Google token provided' });
        }

        const idToken = authHeader.split(' ')[1];
        const decoded = await admin.auth().verifyIdToken(idToken);
        const safeEmail = normalizeEmail(decoded.email);

        if (!safeEmail) {
            return res.status(400).json({ message: 'Google account email not found' });
        }

        let user = await User.findOne({ email: safeEmail });
        let isNewUser = false;

        if (!user) {
            isNewUser = true;
            user = await User.create({
                uid: decoded.uid,
                googleId: decoded.uid,
                name: decoded.name || safeEmail.split('@')[0],
                email: safeEmail,
                password: generateSecurePassword(),
                mobileNumber: req.body.mobileNumber ? normalizeMobile(req.body.mobileNumber) : undefined,
                role: 'user',
            });
        } else {
            if (!user.googleId) user.googleId = decoded.uid;
            if (!user.uid) user.uid = decoded.uid;
            if (!user.name && decoded.name) user.name = decoded.name;
            await user.save();
        }

        const token = createUserToken(user);
        return res.status(200).json({
            success: true,
            message: isNewUser ? 'Google signup successful' : 'Google login successful',
            isNewUser,
            token,
            user: mapUserResponse(user),
        });
    } catch (error) {
        console.error('User Google auth error:', error);
        return res.status(401).json({ message: 'Invalid or expired Google token' });
    }
};

// Mobile Number + Password Signup
exports.mobileSignup = async (req, res) => {
    try {
        const { name, mobileNumber, password } = req.body;

        if (!name || !mobileNumber || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'name, mobileNumber and password are required' 
            });
        }

        const safeMobile = normalizeMobile(mobileNumber);
        
        // Check if mobile number already exists
        const existing = await User.findOne({ mobileNumber: safeMobile });
        if (existing) {
            return res.status(400).json({ 
                success: false, 
                message: 'Mobile number already registered' 
            });
        }

        // Create user with mobile number
        const user = await User.create({
            uid: `usr_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`,
            name: name.trim(),
            mobileNumber: safeMobile,
            password,
            role: 'user',
        });

        const token = createUserToken(user);
        return res.status(201).json({
            success: true,
            message: 'User registered successfully with mobile number',
            token,
            user: mapUserResponse(user),
        });
    } catch (error) {
        console.error('User mobile signup error:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern || {})[0] || 'field';
            return res.status(400).json({ 
                success: false, 
                message: `${field} already exists` 
            });
        }
        return res.status(500).json({ 
            success: false, 
            message: 'Server error', 
            error: error.message 
        });
    }
};

// Mobile Number + Password Login
exports.mobileLogin = async (req, res) => {
    try {
        const { mobileNumber, password } = req.body;

        if (!mobileNumber || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'mobileNumber and password are required' 
            });
        }

        const safeMobile = normalizeMobile(mobileNumber);
        const user = await User.findOne({ mobileNumber: safeMobile });
        
        if (!user) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid credentials' 
            });
        }

        if (!user.password) {
            return res.status(400).json({ 
                success: false, 
                message: 'This account uses Google sign-in or has no password set. Please use appropriate login method.' 
            });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid credentials' 
            });
        }

        const token = createUserToken(user);
        return res.status(200).json({
            success: true,
            message: 'Login successful',
            token,
            user: mapUserResponse(user),
        });
    } catch (error) {
        console.error('User mobile login error:', error);
        return res.status(500).json({ 
            success: false, 
            message: 'Server error', 
            error: error.message 
        });
    }
};

const registerOrUpdatePhoneUser = async ({ mobileNumber, uid }) => {
    const normalizedMobile = normalizeMobile(mobileNumber);

    // Check if user already exists with this phone number.
    let user = await User.findOne({ mobileNumber: normalizedMobile });
    if (user) {
        user.lastActive = Date.now();
        if (uid) user.uid = uid;
        await user.save();
        return { user, isNewUser: false };
    }

    user = new User({ mobileNumber: normalizedMobile, uid });
    await user.save();
    return { user, isNewUser: true };
};

// Save specific location (Home, Office, Pin, etc.)
exports.saveSavedLocation = async (req, res) => {
    try {
        let { mobileNumber, title, address, latitude, longitude, type } = req.body;

        if (!mobileNumber || !address || !latitude || !longitude) {
            return res.status(400).json({ message: 'mobileNumber, address, latitude, and longitude are required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);

        // Find the user to get their ID
        const user = await User.findOne({ mobileNumber });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Create new location entry
        const locationEntry = new Location({
            userId: user._id,
            mobileNumber: user.mobileNumber,
            title: title || address.split(',')[0], // Use first part of address if no title
            address: address,
            latitude: latitude,
            longitude: longitude,
            type: type || 'pickup'
        });

        await locationEntry.save();

        res.status(201).json({
            message: 'Location saved successfully',
            location: locationEntry
        });
    } catch (error) {
        console.error('Error saving search history:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Step 0: Start OTP flow (actual OTP is handled by Firebase on client apps)
exports.sendOtp = async (req, res) => {
    try {
        let { mobileNumber } = req.body;
        if (!mobileNumber) {
            return res.status(400).json({ message: 'mobileNumber is required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);
        return res.status(200).json({
            message: 'OTP flow initiated. Verify OTP on client and call verify-otp endpoint.',
            mobileNumber,
        });
    } catch (error) {
        console.error('Error in sendOtp:', error);
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Step 1: Save phone number to DB after OTP verification
exports.verifyOtp = async (req, res) => {
    try {
        const { mobileNumber, uid } = req.body;

        if (!mobileNumber) {
            return res.status(400).json({ message: 'mobileNumber is required' });
        }

        const { user, isNewUser } = await registerOrUpdatePhoneUser({ mobileNumber, uid });

        return res.status(isNewUser ? 201 : 200).json({
            message: isNewUser ? 'Phone number verified and registered successfully' : 'User already exists',
            user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
            isNewUser,
        });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern || {})[0];
            return res.status(400).json({ message: `${field || 'Field'} already exists` });
        }
        return res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Compatibility endpoint: register phone directly after OTP verification
exports.registerPhone = async (req, res) => {
    try {
        const { mobileNumber, uid } = req.body;

        if (!mobileNumber) {
            return res.status(400).json({ message: 'mobileNumber is required' });
        }

        const { user, isNewUser } = await registerOrUpdatePhoneUser({ mobileNumber, uid });
        return res.status(isNewUser ? 201 : 200).json({
            message: isNewUser ? 'Phone number registered successfully' : 'User already exists',
            user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
            isNewUser,
        });
    } catch (error) {
        console.error('Error registering phone:', error);
        if (error.code === 11000) {
            // duplicate key, likely due to unique index on email or mobile
            const field = Object.keys(error.keyPattern || {})[0];
            return res.status(400).json({ message: `${field || 'Field'} already exists` });
        }
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Step 2: Save user name after OTP verification
exports.saveName = async (req, res) => {
    try {
        let { mobileNumber, name } = req.body;

        if (!mobileNumber || !name) {
            return res.status(400).json({ message: 'mobileNumber and name are required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);
        const user = await User.findOne({ mobileNumber });

        if (!user) {
            return res.status(404).json({ message: 'User not found. Please register phone first.' });
        }

        user.name = name;
        user.lastActive = Date.now();
        await user.save();

        return res.status(200).json({
            message: 'Name saved successfully',
            user: { id: user._id, name: user.name, mobileNumber: user.mobileNumber }
        });
    } catch (error) {
        console.error('Error saving name:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Get user profile by phone number
exports.getProfile = async (req, res) => {
    try {
        let { mobileNumber } = req.params;
        const { uid } = req.query;
        const tokenUid = req.user?.uid;

        mobileNumber = normalizeMobile(mobileNumber);

        if (!mobileNumber && !uid && !tokenUid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const effectiveUid = uid || tokenUid;

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(effectiveUid ? [{ uid: effectiveUid }] : []),
            ],
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ user });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update user profile by phone number
exports.updateProfile = async (req, res) => {
    try {
        let { mobileNumber } = req.params;
        const {
            name,
            mobileNumber: newMobile,
            currentMobileNumber,
            uid,
            email,
        } = req.body;
        const tokenUid = req.user?.uid;

        mobileNumber = normalizeMobile(mobileNumber || currentMobileNumber || newMobile);

        if (!mobileNumber && !uid && !tokenUid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const effectiveUid = uid || tokenUid;

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(effectiveUid ? [{ uid: effectiveUid }] : []),
            ],
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // if a new mobile number is provided, ensure it's not taken
        if (newMobile && newMobile !== user.mobileNumber) {
            const normNew = normalizeMobile(newMobile);
            const existing = await User.findOne({ mobileNumber: normNew });
            if (existing && existing._id.toString() !== user._id.toString()) {
                return res.status(400).json({ message: 'Mobile number already in use' });
            }
            user.mobileNumber = normNew;
        }

        if (name) user.name = name;
        if (effectiveUid) user.uid = effectiveUid;
        if (email !== undefined) user.email = email || undefined;
        user.lastActive = Date.now();
        await user.save();

        res.status(200).json({
            message: 'Profile updated successfully',
            user: {
                id: user._id,
                uid: user.uid,
                name: user.name,
                mobileNumber: user.mobileNumber,
                email: user.email,
            }
        });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.updateFCMToken = async (req, res) => {
    try {
        const { userId, fcmToken } = req.body;
        if (!userId || !fcmToken) {
            return res.status(400).json({ message: 'userId and fcmToken are required' });
        }
        await User.findByIdAndUpdate(userId, { fcmToken });
        res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
    } catch (error) {
        console.error('Error updating FCM Token:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
