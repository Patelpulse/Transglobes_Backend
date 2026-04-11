const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminSignupController = require('../controllers/adminsigup');
const pricingController = require('../controllers/pricingController');
const supervisorController = require('../controllers/supervisorController');
const analyticsController = require('../controllers/analyticsController');
const { verifyAdminToken, requireSupervisorRole, requireStrictAdmin } = require('../middlewares/authMiddlewareAdmin');
const upload = require('../middlewares/uploadMiddleware');

// Unprotected routes
router.post('/login', adminSignupController.login);
router.post('/register', adminSignupController.signup);
router.post('/auth', adminSignupController.auth);
router.post('/sync', adminController.syncAdminData);

// All admin routes below should be protected
router.use(verifyAdminToken);

// Admin sync/auth
router.post('/logout', adminSignupController.logout);

// Profile
router.get('/profile', adminSignupController.getProfile);
router.post('/profile/photo', upload.single('photo'), adminSignupController.updateProfilePhoto);
router.post('/profile/change-password', adminSignupController.changePassword);


// Driver management
router.get('/drivers', requireStrictAdmin, adminController.getAllDrivers);
router.put('/drivers/:driverId/status', requireStrictAdmin, adminController.updateDriverStatus);
router.put('/drivers/:driverId/warn', requireStrictAdmin, adminController.warnDriver);
router.delete('/drivers/:driverId', requireStrictAdmin, adminController.deleteDriver);

// User management
router.get('/users', requireStrictAdmin, adminController.getAllUsers);
router.put('/users/:userId/status', requireStrictAdmin, adminController.updateUserStatus);
router.put('/users/:userId/profile', requireStrictAdmin, adminController.updateUserProfile);
router.put('/users/:userId/fraud', requireStrictAdmin, adminController.blacklistUser);
router.delete('/users/:userId', requireStrictAdmin, adminController.deleteUser);
router.get('/users/:userId/bookings', requireStrictAdmin, adminController.getUserBookings);

// Booking management
router.get('/bookings', requireSupervisorRole, adminController.getAllBookings);
router.put('/bookings/:bookingId/status', requireSupervisorRole, adminController.updateBookingStatus);

// Complaint management
router.get('/complaints', requireStrictAdmin, adminController.getAllComplaints);
router.put('/complaints/:complaintId/status', requireStrictAdmin, adminController.updateComplaintStatus);

// Review management
router.get('/reviews', requireStrictAdmin, adminController.getAllReviews);

// Vehicle management
router.get('/vehicles', requireStrictAdmin, adminController.getAllVehicles);
router.put('/vehicles/:vehicleId/status', requireStrictAdmin, adminController.updateVehicleStatus);

// Service Categories
router.post('/categories', requireStrictAdmin, adminController.createServiceCategory);
router.get('/categories', requireStrictAdmin, adminController.getServiceCategories);

// Route Management
router.post('/routes', requireStrictAdmin, adminController.createRoute);
router.get('/routes', requireStrictAdmin, adminController.getAllRoutes);

// Shift Management
router.post('/shifts', requireStrictAdmin, adminController.createShift);
router.get('/shifts', requireStrictAdmin, adminController.getAllShifts);

// Settlements & Reports
router.get('/reports/transactions', requireStrictAdmin, adminController.getTransactionReports);
router.get('/stats', requireSupervisorRole, adminController.getPlatformStats);

// CMS & Notifications
router.post('/cms', requireStrictAdmin, adminController.updateCMSContent);
router.get('/cms', requireStrictAdmin, adminController.getCMSContent);

// Delay Logs
router.post('/delays', requireSupervisorRole, adminController.logDelay);

// ─── Analytics & Reports ─────────────────────────────────
router.get('/analytics/dashboard', requireSupervisorRole, analyticsController.getDashboard);
router.get('/analytics/revenue', requireSupervisorRole, analyticsController.getRevenueReport);
router.get('/analytics/driver/:driverId/performance', requireSupervisorRole, analyticsController.getDriverPerformance);
router.post('/analytics/delay-log', requireSupervisorRole, analyticsController.logDelay);
router.get('/analytics/delay-logs/:bookingId', requireSupervisorRole, analyticsController.getDelayLogs);

// ─── Pricing Configuration (Admin + Supervisor) ──────────
router.get('/pricing', requireSupervisorRole, pricingController.getAllConfigs);
router.get('/pricing/active', requireSupervisorRole, pricingController.getActiveConfig);
router.post('/pricing', requireStrictAdmin, pricingController.createConfig);
router.put('/pricing/:id', requireStrictAdmin, pricingController.updateConfig);
router.delete('/pricing/:id', requireStrictAdmin, pricingController.deleteConfig);
router.post('/pricing/calculate', requireSupervisorRole, pricingController.calculateFare);

// ─── Supervisor Panel Routes ─────────────────────────────
// Edit logistics booking goods details
router.patch('/supervisor/bookings/:bookingId/goods', requireSupervisorRole, supervisorController.editGoodsDetails);
// Override pricing charges for a booking
router.patch('/supervisor/bookings/:bookingId/pricing-override', requireSupervisorRole, supervisorController.overridePricing);
// Approve and finalize a booking (sets status to processing)
router.patch('/supervisor/bookings/:bookingId/approve', requireSupervisorRole, supervisorController.approveBooking);
// Get supervisor dashboard stats
router.get('/supervisor/stats', requireSupervisorRole, supervisorController.getSupervisorStats);
// Block/Unblock user
router.patch('/users/:userId/block', requireStrictAdmin, supervisorController.blockUser);
// Block/Unblock driver
router.patch('/drivers/:driverId/block', requireStrictAdmin, supervisorController.blockDriver);
// Toggle driver online/offline
router.patch('/drivers/:driverId/online', requireStrictAdmin, supervisorController.toggleDriverOnline);

module.exports = router;
