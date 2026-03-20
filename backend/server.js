require('dotenv').config({ path: require('path').resolve(__dirname, '.env') });
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

const http = require('http');
const initSocket = require('./socket/socketHandler');

// Initialize Express
const app = express();
const server = http.createServer(app);

// Initialize Socket.io
const io = initSocket(server);

// Trust proxy (needed for Railway/Heroku to correctly handle headers behind their proxy)
app.set('trust proxy', 1);

// Middleware
app.use((req, res, next) => {
    const origin = req.headers.origin;
    if (origin) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Vary', 'Origin');
    } else {
        res.setHeader('Access-Control-Allow-Origin', '*');
    }
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept, Origin');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    
    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }
    next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Attach io to req object
app.use((req, res, next) => {
    req.io = io;
    next();
});

// Connect to MongoDB
connectDB();

// Basic Route
app.get('/', (req, res) => {
    res.send('API is running with Socket.io...');
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
app.use('/api/user', userRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/ride', rideRoutes);
app.use('/api/maps', mapsRoutes);
app.use('/api/typegood', typeGoodRoutes);
app.use('/api/logistics-vehicles', logisticsVehicleRoutes);
app.use('/api/logistic-goods', logisticGoodRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send({ message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`)); // Server is active and listening..

