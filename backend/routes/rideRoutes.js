const express = require("express");
const router = express.Router();
const rideController = require("../controllers/rideController");
const { verifyToken } = require("../middlewares/authMiddleware");

router.get("/ride-types", rideController.getRideTypes);

// Route for saving user's input/booking
router.post("/ride-request", verifyToken, rideController.createRideRequest);

module.exports = router;
