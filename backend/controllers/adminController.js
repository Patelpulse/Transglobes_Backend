const Admin = require('../models/AdminSchema');
const AdminSignup = require('../models/adminSignup');
const Driver = require('../models/Driver');
const User = require('../models/User');
const Booking = require('../models/Booking');
const Complaint = require('../models/Complaint');
const Vehicle = require('../models/Vehicle');
const ServiceCategory = require('../models/ServiceCategory');
const Route = require('../models/Route');
const Review = require('../models/Review');
const DelayLog = require('../models/DelayLog');
const CMS = require('../models/CMS');
const Shift = require('../models/Shift');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Transaction = require('../models/Transaction');
const sendEmail = require('../utils/sendEmail');
const sendSMS = require('../utils/sendSMS');
const firebaseAdmin = require('../config/firebase');

// Controller for syncing admin data upon login
const syncAdminData = async (req, res) => {
    try {
        let token = req.headers.authorization;
        if (token && token.startsWith('Bearer ')) {
            token = token.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ message: 'No Google auth token provided.' });
        }

        const decoded = await firebaseAdmin.auth().verifyIdToken(token);
        const email = decoded.email?.toLowerCase().trim();
        const name = decoded.name || decoded.email || 'Admin';

        if (!email) {
            return res.status(400).json({ message: 'Google account email not found.' });
        }

        let admin = await AdminSignup.findOne({ email });
        if (!admin) {
            admin = await AdminSignup.create({
                name,
                email,
                password: `google_${decoded.uid}_${Date.now()}`,
                role: 'admin',
            });
        }

        const sessionToken = jwt.sign(
            { id: admin._id, email: admin.email, role: admin.role },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '1d' }
        );

        admin.name = admin.name || name;
        admin.token = sessionToken;
        await admin.save();

        res.status(200).json({
            success: true,
            message: 'Admin synced successfully',
            token: sessionToken,
            admin: {
                id: admin._id,
                name: admin.name,
                email: admin.email,
                role: admin.role,
            }
        });
    } catch (error) {
        console.error('Error syncing admin:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Get all drivers for admin dashboard
const getAllDrivers = async (req, res) => {
    try {
        const drivers = await Driver.find().sort({ createdAt: -1 });
        res.status(200).json({ drivers });
    } catch (error) {
        console.error('Error fetching drivers:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update driver status (e.g., approve/verify)
const updateDriverStatus = async (req, res) => {
    try {
        const { driverId } = req.params;
        const { status } = req.body;

        if (!['pending', 'active', 'suspended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const driver = await Driver.findByIdAndUpdate(
            driverId,
            { status },
            { new: true }
        );

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        res.status(200).json({
            message: `Driver status updated to ${status}`,
            driver
        });
    } catch (error) {
        console.error('Error updating driver status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Warn a driver
const warnDriver = async (req, res) => {
    try {
        const { reason } = req.body;
        const driverId = req.params.driverId;

        const driver = await Driver.findById(driverId);
        if (!driver) return res.status(404).json({ message: "Driver not found" });

        driver.warningCount = (driver.warningCount || 0) + 1;
        driver.lastWarningReason = reason;
        driver.lastWarningDate = new Date();

        if (driver.warningCount >= 3) {
            driver.status = "suspended";
        }

        await driver.save();

        if (driver.email) {
            await sendEmail(driver.email, "Admin Warning Notice", reason);
        }
        if (driver.mobileNumber || driver.phone) {
            await sendSMS(driver.mobileNumber || driver.phone, reason);
        }

        res.json({ success: true, message: "Warning sent successfully" });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// --- USER MANAGEMENT ---

// Get all users
const getAllUsers = async (req, res) => {
    try {
        const users = await User.find().sort({ createdAt: -1 });
        res.status(200).json({ users });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Update user status (block/deactivate/activate)
const updateUserStatus = async (req, res) => {
    try {
        const { userId } = req.params;
        const { status } = req.body;

        if (!['active', 'inactive', 'suspended'].includes(status)) {
            return res.status(400).json({ message: 'Invalid status' });
        }

        const user = await User.findByIdAndUpdate(userId, { status }, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: `User status updated to ${status}`, user });
    } catch (error) {
        console.error('Error updating user status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Edit user profile
const updateUserProfile = async (req, res) => {
    try {
        const { userId } = req.params;
        const updates = req.body;

        const user = await User.findByIdAndUpdate(userId, updates, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: 'User profile updated', user });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Toggle Fraudulent status
const blacklistUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const { isFraudulent } = req.body;

        const user = await User.findByIdAndUpdate(userId, { isFraudulent }, { new: true });
        if (!user) return res.status(404).json({ message: 'User not found' });

        res.status(200).json({ message: `User fraudulent status set to ${isFraudulent}`, user });
    } catch (error) {
        console.error('Error blacklisting user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Delete driver record
const deleteDriver = async (req, res) => {
    try {
        const { driverId } = req.params;
        const driver = await Driver.findByIdAndDelete(driverId);

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        res.status(200).json({ message: 'Driver deleted successfully' });
    } catch (error) {
        console.error('Error deleting driver:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// Delete user record
const deleteUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const user = await User.findByIdAndDelete(userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error('Error deleting user:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- BOOKING HISTORY ---

// --- BOOKING MANAGEMENT ---

const getAllBookings = async (req, res) => {
    try {
        const bookings = await Booking.find().populate('userId driverId').sort({ createdAt: -1 });
        res.status(200).json({ bookings });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateBookingStatus = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { status } = req.body;
        const booking = await Booking.findByIdAndUpdate(bookingId, { status }, { new: true });
        res.status(200).json({ booking });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getUserBookings = async (req, res) => {
    try {
        const { userId } = req.params;
        const bookings = await Booking.find({ userId }).populate('driverId').sort({ createdAt: -1 });
        res.status(200).json({ bookings });
    } catch (error) {
        console.error('Error fetching user bookings:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- COMPLAINTS ---

const getAllComplaints = async (req, res) => {
    try {
        const complaints = await Complaint.find().populate('userId').sort({ createdAt: -1 });
        res.status(200).json({ complaints });
    } catch (error) {
        console.error('Error fetching complaints:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateComplaintStatus = async (req, res) => {
    try {
        const { complaintId } = req.params;
        const { status } = req.body;

        const complaint = await Complaint.findByIdAndUpdate(complaintId, { status }, { new: true });
        if (!complaint) return res.status(404).json({ message: 'Complaint not found' });

        res.status(200).json({ message: `Complaint status updated to ${status}`, complaint });
    } catch (error) {
        console.error('Error updating complaint status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- REVIEWS ---

const getAllReviews = async (req, res) => {
    try {
        const reviews = await Review.find().populate('fromId toId bookingId').sort({ createdAt: -1 });
        res.status(200).json({ reviews });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- VEHICLE MANAGEMENT ---

const getAllVehicles = async (req, res) => {
    try {
        const vehicles = await Vehicle.find().populate('driverId categoryId');
        res.status(200).json({ vehicles });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateVehicleStatus = async (req, res) => {
    try {
        const { vehicleId } = req.params;
        const { status } = req.body;
        const vehicle = await Vehicle.findByIdAndUpdate(vehicleId, { status }, { new: true });
        res.status(200).json({ vehicle });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- SERVICE CATEGORIES ---

const createServiceCategory = async (req, res) => {
    try {
        const category = new ServiceCategory(req.body);
        await category.save();
        res.status(201).json({ category });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getServiceCategories = async (req, res) => {
    try {
        const categories = await ServiceCategory.find();
        res.status(200).json({ categories });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- ROUTE MANAGEMENT ---

const createRoute = async (req, res) => {
    try {
        const route = new Route(req.body);
        await route.save();
        res.status(201).json({ route });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getAllRoutes = async (req, res) => {
    try {
        const routes = await Route.find();
        res.status(200).json({ routes });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- SETTLEMENTS & REPORTS ---

const getTransactionReports = async (req, res) => {
    try {
        const transactions = await Transaction.find().populate('userId driverId bookingId').sort({ createdAt: -1 });
        res.status(200).json({ transactions });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- CMS & NOTIFICATIONS ---

const updateCMSContent = async (req, res) => {
    try {
        const { key, value, type } = req.body;
        const content = await CMS.findOneAndUpdate({ key }, { value, type }, { upsert: true, new: true });
        res.status(200).json({ content });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getCMSContent = async (req, res) => {
    try {
        const { type } = req.query;
        const query = type ? { type } : {};
        const contents = await CMS.find(query);
        res.status(200).json({ contents });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

// --- DELAY MONITORING ---

const logDelay = async (req, res) => {
    try {
        const { bookingId, reason, delayMinutes, notes } = req.body;
        const delay = new DelayLog({
            bookingId,
            reason,
            delayMinutes,
            notes
        });
        await delay.save();
        res.status(201).json({ message: 'Delay logged successfully', delay });
    } catch (error) {
        console.error('Error logging delay:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getPlatformStats = async (req, res) => {
    try {
        const totalUsers = await User.countDocuments();
        const totalDrivers = await Driver.countDocuments();
        const totalVehicles = await Vehicle.countDocuments();
        res.status(200).json({
            totalFleets: totalVehicles,
            fleetGrowth: 0.15,
            supportTickets: 12,
            urgentTickets: 3,
            totalUsers,
            totalDrivers,
        });
    } catch (error) {
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

module.exports = {
    syncAdminData,
    getAllDrivers,
    updateDriverStatus,
    warnDriver,
    getAllUsers,
    updateUserStatus,
    updateUserProfile,
    blacklistUser,
    deleteDriver,
    deleteUser,
    getUserBookings,
    getAllComplaints,
    updateComplaintStatus,
    getAllVehicles,
    updateVehicleStatus,
    createServiceCategory,
    getServiceCategories,
    createRoute,
    getAllRoutes,
    getTransactionReports,
    updateCMSContent,
    getCMSContent,
    logDelay,
    getAllBookings,
    updateBookingStatus,
    getAllReviews,
    getPlatformStats,
    // Shift Management
    createShift: async (req, res) => {
        try {
            const shift = new Shift(req.body);
            await shift.save();
            res.status(201).json({ shift });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    },
    getAllShifts: async (req, res) => {
        try {
            const shifts = await Shift.find().populate('driverId vehicleId routeId');
            res.status(200).json({ shifts });
        } catch (error) {
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    }
};
