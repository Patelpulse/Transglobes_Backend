const express = require("express");
const router = express.Router();
const rideController = require("../controllers/rideController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/driver-bookings", verifyToken, rideController.getDriverBookings);
router.get("/ride-types", rideController.getRideTypes);

// Route for saving user's input/booking
router.post("/ride-request", verifyToken, rideController.createRideRequest);

// DRIVER APIs
// fetch full list (optionally filter)
router.get('/rides', verifyToken, rideController.getRideDetails);
// only pending rides (for quick polling)
router.get('/rides/pending', verifyToken, rideController.getPendingRides);
// driver accepts/assigns a ride
router.put('/rides/:rideId/assign', verifyToken, rideController.assignRide);
// driver rejects a ride
router.put('/rides/:rideId/reject', verifyToken, rideController.rejectRide);
// update status or complete
router.put('/rides/:rideId/status', verifyToken, rideController.updateRideStatus);
router.put('/rides/:rideId/complete', verifyToken, rideController.updateRideStatus);
router.put('/rides/:rideId/verify-otp', verifyToken, rideController.verifyRideOtp);

module.exports = router;
