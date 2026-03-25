const express = require('express');
const router = express.Router();
const {
    createBooking,
    getUserBookings,
    getAllBookings,
    getBookingById,
    updateStatus,
    assignDriver,
    updateRailwayStation,
    updateBilling,
} = require('../controllers/logisticsBookingController');

// ... (other routes)

// PATCH  /api/logistics-bookings/:id/railway-station → update railway station
router.patch('/logistics-bookings/:id/railway-station', updateRailwayStation);

// POST   /api/logistics-bookings          → create a new booking
router.post('/logistics-bookings', createBooking);

// GET    /api/logistics-bookings           → get all bookings (Admin)
router.get('/logistics-bookings', getAllBookings);

// GET    /api/logistics-bookings/user/:userId → get all bookings for a user
router.get('/logistics-bookings/user/:userId', getUserBookings);

// GET    /api/logistics-bookings/:id       → get single booking
router.get('/logistics-bookings/:id', getBookingById);

// PATCH  /api/logistics-bookings/:id/status → update status
router.patch('/logistics-bookings/:id/status', updateStatus);

// POST   /api/logistics-bookings/:id/assign → assign a driver manually
router.post('/logistics-bookings/:id/assign', assignDriver);

// PATCH  /api/logistics-bookings/:id/billing → admin edits billing
router.patch('/logistics-bookings/:id/billing', updateBilling);
router.patch('/logistics-booking/:id/billing', updateBilling);

module.exports = router;
