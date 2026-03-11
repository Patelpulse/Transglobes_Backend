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
    const { latlng, key } = req.query;
    if (!latlng || !key) return res.status(400).json({ error: 'Missing latlng or key' });

    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${latlng}&key=${key}`;
    proxyRequest(url, res);
});

router.get('/directions', (req, res) => {
    const { origin, destination, key } = req.query;
    if (!origin || !destination || !key) return res.status(400).json({ error: 'Missing origin, destination, or key' });

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&key=${key}`;
    proxyRequest(url, res);
});

module.exports = router;
