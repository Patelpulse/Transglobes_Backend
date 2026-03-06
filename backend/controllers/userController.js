const jwt = require('jsonwebtoken');
const User = require('../models/User');

exports.syncUser = async (req, res) => {
    try {
        const { uid, email, name, mobileNumber, imageUrl } = req.body;

        if (!uid) {
            return res.status(400).json({ message: 'uid is required' });
        }

        let user = await User.findOne({ uid });

        if (!user) {
            // Check if email already exists, if provided
            if (email) {
                const existingEmail = await User.findOne({ email });
                if (existingEmail) {
                    return res.status(400).json({ message: 'Email already registered' });
                }
            }

            user = new User({
                uid,
                email: email || `${uid}@guest.transglobal.com`,
                name: name || mobileNumber || 'Guest User',
                mobileNumber,
                imageUrl: imageUrl || 'https://i.pravatar.cc/150?u=user'
            });

            await user.save();
            return res.status(201).json({ message: 'User created successfully', user });
        } else {
            // Update existng user
            user.email = email;
            user.name = name;
            if (mobileNumber) user.mobileNumber = mobileNumber;
            if (imageUrl) user.imageUrl = imageUrl;
            user.lastActive = Date.now();

            await user.save();
            return res.status(200).json({ message: 'User synced successfully', user });
        }
    } catch (error) {
        console.error('Error syncing user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.getProfile = async (req, res) => {
    try {
        const uid = req.user.uid;
        const user = await User.findOne({ uid });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ user });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const uid = req.user.uid;
        const updates = req.body;

        // Disallow update of critical fields
        delete updates.uid;
        delete updates.isFraudulent;
        delete updates.walletBalance;

        const user = await User.findOneAndUpdate(
            { uid },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ message: 'Profile updated successfully', user });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

exports.register = async (req, res) => {
    try {
        const { name, email, password, aadharCard, panCard } = req.body;

        // check if email already exists
        const existingUser = await User.findOne({ email });

        if (existingUser) {
            return res.status(400).json({
                message: "Email already registered"
            });
        }

        const user = new User({
            name,
            email,
            password,
            aadharCard,
            panCard
        });

        await user.save();

        res.status(201).json({
            message: "User registered successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        // Generate Token
        const token = jwt.sign(
            { id: user._id, email: user.email },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        res.status(200).json({
            message: 'Login successful.',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};
