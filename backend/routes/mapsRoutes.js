const express = require('express');
const router = express.Router();
const https = require('https');

const proxyRequest = (url, res) => {
    https.get(url, (apiRes) => {
        let data = '';
        apiRes.on('data', (chunk) => {
            data += chunk;
        });
        apiRes.on('end', () => {
            try {
                res.status(apiRes.statusCode).json(JSON.parse(data));
            } catch (e) {
                res.status(500).json({ error: 'Failed to parse Google Maps response' });
            }
        });
    }).on('error', (err) => {
        res.status(500).json({ error: err.message });
    });
};

router.get('/autocomplete', (req, res) => {
    const { input, key, components } = req.query;
    if (!input || !key) return res.status(400).json({ error: 'Missing input or key' });

    // Construct Google Maps URL
    let url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${key}`;
    if (components) url += `&components=${components}`;

    proxyRequest(url, res);
});

router.get('/details', (req, res) => {
    const { place_id, key, fields } = req.query;
    if (!place_id || !key) return res.status(400).json({ error: 'Missing place_id or key' });

    let url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${place_id}&key=${key}`;
    if (fields) url += `&fields=${fields}`;

    proxyRequest(url, res);
});

router.get('/geocode', (req, res) => {
    const { latlng, address, key } = req.query;
    if (!key) return res.status(400).json({ error: 'Missing key' });
    if (!latlng && !address) return res.status(400).json({ error: 'Missing latlng or address' });

    let url;
    if (address) {
        // Forward geocoding (address -> coordinates)
        url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${key}`;
    } else {
        // Reverse geocoding (coordinates -> address)
        url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latlng}&key=${key}`;
    }
    proxyRequest(url, res);
});

router.get('/directions', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) return res.status(400).json({ error: 'Missing origin, destination, or key' });

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&key=${key}`;
    proxyRequest(url, res);
});

// ─── GET /api/maps/eta ────────────────────────────────────
// Returns distance, duration, and ETA for origin→destination
router.get('/eta', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) {
        return res.status(400).json({ error: 'Missing origin, destination, or key' });
    }

    const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${encodeURIComponent(origin)}&destinations=${encodeURIComponent(destination)}&mode=driving&language=en&key=${key}`;

    https.get(url, (apiRes) => {
        let data = '';
        apiRes.on('data', (chunk) => { data += chunk; });
        apiRes.on('end', () => {
            try {
                const parsed = JSON.parse(data);
                const element = parsed?.rows?.[0]?.elements?.[0];
                if (!element || element.status !== 'OK') {
                    return res.status(404).json({ error: 'Could not calculate ETA', raw: parsed });
                }
                res.status(200).json({
                    success: true,
                    data: {
                        distanceText: element.distance.text,
                        distanceMeters: element.distance.value,
                        durationText: element.duration.text,
                        durationSeconds: element.duration.value,
                        eta: new Date(Date.now() + element.duration.value * 1000).toISOString(),
                    },
                });
            } catch (e) {
                res.status(500).json({ error: 'Failed to parse ETA response' });
            }
        });
    }).on('error', (err) => res.status(500).json({ error: err.message }));
});

// ─── GET /api/maps/route-optimize ─────────────────────────
// Optimized waypoint route for multi-segment logistics
router.get('/route-optimize', (req, res) => {
    const { origin, destination, waypoints, key } = req.query;
    if (!origin || !destination || !key) {
        return res.status(400).json({ error: 'Missing origin, destination, or key' });
    }

    let url = `https://maps.googleapis.com/maps/api/directions/json?origin=${encodeURIComponent(origin)}&destination=${encodeURIComponent(destination)}&optimize:true&key=${key}`;
    if (waypoints) url += `&waypoints=optimize:true|${encodeURIComponent(waypoints)}`;

    proxyRequest(url, res);
});

// ─── POST /api/maps/ratings ───────────────────────────────
const ratingController = require('../controllers/ratingController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.post('/ratings', verifyToken, ratingController.submitRating);
router.get('/ratings/booking/:bookingId', ratingController.getBookingRatings);
router.get('/ratings/driver/:driverId', ratingController.getDriverRatings);
router.get('/ratings/user/:userId', ratingController.getUserRatings);

module.exports = router;
