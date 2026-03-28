const User = require('../models/User');
const Location = require('../models/Location');

// Save specific location (Home, Office, Pin, etc.)
exports.saveSavedLocation = async (req, res) => {
    try {
        const { mobileNumber, title, address, latitude, longitude, type } = req.body;

        if (!mobileNumber || !address || !latitude || !longitude) {
            return res.status(400).json({ message: 'mobileNumber, address, latitude, and longitude are required' });
        }

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

// Step 1: Save phone number to DB after OTP verification
exports.registerPhone = async (req, res) => {
    try {
        let { mobileNumber, uid } = req.body;

        if (!mobileNumber) {
            return res.status(400).json({ message: 'mobileNumber is required' });
        }

        mobileNumber = normalizeMobile(mobileNumber);

        // Check if user already exists with this phone number
        let user = await User.findOne({ mobileNumber });

        if (user) {
            // User already exists, update lastActive and return
            user.lastActive = Date.now();
            if (uid) user.uid = uid; // Save/update Firebase UID
            await user.save();
            return res.status(200).json({
                message: 'User already exists',
                user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
                isNewUser: false
            });
        }

        // Create new user with phone number and optional uid
        user = new User({ mobileNumber, uid });

        await user.save();
        return res.status(201).json({
            message: 'Phone number registered successfully',
            user: { id: user._id, uid: user.uid, name: user.name, mobileNumber: user.mobileNumber },
            isNewUser: true
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

// helper to normalise mobile numbers while preserving leading plus
function normalizeMobile(num) {
    if (!num) return num;
    const trimmed = String(num).trim();
    const hasPlus = trimmed.startsWith('+');
    const digits = trimmed.replace(/[^\d]/g, '');
    return hasPlus ? `+${digits}` : digits;
}

// Get user profile by phone number
exports.getProfile = async (req, res) => {
    try {
        let { mobileNumber } = req.params;
        const { uid } = req.query;

        mobileNumber = normalizeMobile(mobileNumber);

        if (!mobileNumber && !uid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(uid ? [{ uid }] : []),
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

        mobileNumber = normalizeMobile(mobileNumber || currentMobileNumber || newMobile);

        if (!mobileNumber && !uid) {
            return res.status(400).json({ message: 'mobileNumber or uid is required' });
        }

        const user = await User.findOne({
            $or: [
                ...(mobileNumber ? [{ mobileNumber }] : []),
                ...(uid ? [{ uid }] : []),
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
        if (uid) user.uid = uid;
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
