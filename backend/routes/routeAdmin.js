const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminSignupController = require('../controllers/adminsigup');
const pricingController = require('../controllers/pricingController');
const supervisorController = require('../controllers/supervisorController');
const analyticsController = require('../controllers/analyticsController');
const { verifyAdminToken } = require('../middlewares/authMiddlewareAdmin');
const upload = require('../middlewares/uploadMiddleware');

// Unprotected routes
router.post('/login', adminSignupController.login);
router.post('/register', adminSignupController.signup);
router.post('/auth', adminSignupController.auth);

// All admin routes below should be protected
router.use(verifyAdminToken);

// Admin sync/auth
router.post('/sync', adminController.syncAdminData);
router.post('/logout', adminSignupController.logout);

// Profile
router.get('/profile', adminSignupController.getProfile);
router.post('/profile/photo', upload.single('photo'), adminSignupController.updateProfilePhoto);
router.post('/profile/change-password', adminSignupController.changePassword);


// Driver management
router.get('/drivers', adminController.getAllDrivers);
router.put('/drivers/:driverId/status', adminController.updateDriverStatus);
router.put('/drivers/:driverId/warn', adminController.warnDriver);
router.delete('/drivers/:driverId', adminController.deleteDriver);

// User management
router.get('/users', adminController.getAllUsers);
router.put('/users/:userId/status', adminController.updateUserStatus);
router.put('/users/:userId/profile', adminController.updateUserProfile);
router.put('/users/:userId/fraud', adminController.blacklistUser);
router.delete('/users/:userId', adminController.deleteUser);
router.get('/users/:userId/bookings', adminController.getUserBookings);

// Booking management
router.get('/bookings', adminController.getAllBookings);
router.put('/bookings/:bookingId/status', adminController.updateBookingStatus);

// Complaint management
router.get('/complaints', adminController.getAllComplaints);
router.put('/complaints/:complaintId/status', adminController.updateComplaintStatus);

// Review management
router.get('/reviews', adminController.getAllReviews);

// Vehicle management
router.get('/vehicles', adminController.getAllVehicles);
router.put('/vehicles/:vehicleId/status', adminController.updateVehicleStatus);

// Service Categories
router.post('/categories', adminController.createServiceCategory);
router.get('/categories', adminController.getServiceCategories);

// Route Management
router.post('/routes', adminController.createRoute);
router.get('/routes', adminController.getAllRoutes);

// Shift Management
router.post('/shifts', adminController.createShift);
router.get('/shifts', adminController.getAllShifts);

// Settlements & Reports
router.get('/reports/transactions', adminController.getTransactionReports);
router.get('/stats', adminController.getPlatformStats);

// CMS & Notifications
router.post('/cms', adminController.updateCMSContent);
router.get('/cms', adminController.getCMSContent);

// Delay Logs
router.post('/delays', adminController.logDelay);

// ─── Analytics & Reports ─────────────────────────────────
router.get('/analytics/dashboard', analyticsController.getDashboard);
router.get('/analytics/revenue', analyticsController.getRevenueReport);
router.get('/analytics/driver/:driverId/performance', analyticsController.getDriverPerformance);
router.post('/analytics/delay-log', analyticsController.logDelay);
router.get('/analytics/delay-logs/:bookingId', analyticsController.getDelayLogs);

// ─── Pricing Configuration (Admin + Supervisor) ──────────
router.get('/pricing', pricingController.getAllConfigs);
router.get('/pricing/active', pricingController.getActiveConfig);
router.post('/pricing', pricingController.createConfig);
router.put('/pricing/:id', pricingController.updateConfig);
router.delete('/pricing/:id', pricingController.deleteConfig);
router.post('/pricing/calculate', pricingController.calculateFare);

// ─── Supervisor Panel Routes ─────────────────────────────
// Edit logistics booking goods details
router.patch('/supervisor/bookings/:bookingId/goods', supervisorController.editGoodsDetails);
// Override pricing charges for a booking
router.patch('/supervisor/bookings/:bookingId/pricing-override', supervisorController.overridePricing);
// Approve and finalize a booking (sets status to processing)
router.patch('/supervisor/bookings/:bookingId/approve', supervisorController.approveBooking);
// Get supervisor dashboard stats
router.get('/supervisor/stats', supervisorController.getSupervisorStats);
// Block/Unblock user
router.patch('/users/:userId/block', supervisorController.blockUser);
// Block/Unblock driver
router.patch('/drivers/:driverId/block', supervisorController.blockDriver);
// Toggle driver online/offline
router.patch('/drivers/:driverId/online', supervisorController.toggleDriverOnline);

module.exports = router;
