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
router.patch('/:id/railway-station', updateRailwayStation);

// POST   /api/logistics-bookings          → create a new booking
router.post('/', createBooking);

// GET    /api/logistics-bookings           → get all bookings (Admin)
router.get('/', getAllBookings);

// GET    /api/logistics-bookings/user/:userId → get all bookings for a user
router.get('/user/:userId', getUserBookings);

// GET    /api/logistics-bookings/:id       → get single booking
router.get('/:id', getBookingById);

// PATCH  /api/logistics-bookings/:id/status → update status
router.patch('/:id/status', updateStatus);

// POST   /api/logistics-bookings/:id/assign → assign a driver manually
router.post('/:id/assign', assignDriver);

// PATCH  /api/logistics-bookings/:id/billing → admin edits billing
router.patch('/:id/billing', updateBilling);

module.exports = router;
