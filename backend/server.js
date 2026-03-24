require('dotenv').config();
const express = require('express');
const connectDB = require('./config/db');
const http = require('http');
const initSocket = require('./socket/socketHandler');

const app = express();

// Trust proxy for Railway/Heroku
app.set('trust proxy', 1);
app.disable('x-powered-by');

// DIAGNOSTIC LOGGING - EVERY REQUEST MUST SHOW UP
app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    console.warn(`\n[${timestamp}] >>> INCOMING REQUEST: ${req.method} ${req.originalUrl || req.url}`);
    console.warn(`[${timestamp}] Origin: ${req.headers.origin} | Host: ${req.headers.host}`);
    console.warn(`[${timestamp}] Headers: ${JSON.stringify(req.headers)}\n`);
    next();
});

// Robust Manual CORS Middleware
app.use((req, res, next) => {
    const origin = req.headers.origin;
    // Mirror the origin if it exists, otherwise fallback to wildcard
    // Using mirrored origin is required when credentials: true
    if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Vary', 'Origin');
    } else {
        res.setHeader('Access-Control-Allow-Origin', '*');
    }

    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin, X-Dev-Uid, X-Dev-Id, x-dev-uid, x-dev-id');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Max-Age', '86400'); // Cache preflight for 24 hours

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const server = http.createServer(app);
const io = initSocket(server);

// Attach socket.io to request object
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Import Routes
const userRoutes = require('./routes/userRoutes');
const driverRoutes = require('./routes/driverRoutes');
const adminRoutes = require('./routes/routeAdmin');
const rideRoutes = require('./routes/rideRoutes');
const mapsRoutes = require('./routes/mapsRoutes');
const typeGoodRoutes = require('./routes/typeGoodRoutes');
const logisticsVehicleRoutes = require('./routes/logisticsVehicleRoutes');
const logisticGoodRoutes = require('./routes/logisticGoodRoutes');
const logisticsBookingRoutes = require('./routes/logisticsBookingRoutes');

// Root & Health Check Routes
app.get('/', (req, res) => res.send('API is running with Socket.io...'));
app.get('/health', (req, res) => res.status(200).json({ status: 'ok', timestamp: new Date() }));

// Register Routes
app.use('/api/user', userRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/ride', rideRoutes);
app.use('/api/maps', mapsRoutes);
app.use('/api/typegood', typeGoodRoutes);
app.use('/api/logistics-vehicles', logisticsVehicleRoutes);
app.use('/api/logistic-goods', logisticGoodRoutes);
app.use('/api/logistics-bookings', logisticsBookingRoutes);

// Database Connection
connectDB();

// Error Handling Middleware
app.use((err, req, res, next) => {
    console.error('SERVER ERROR:', err.stack);
    res.status(500).json({
        message: 'Internal Server Error',
        error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

const PORT = 8080;
server.listen(PORT, () => {
    console.log(`>>> Server is active and listening on port ${PORT}  `);
});
