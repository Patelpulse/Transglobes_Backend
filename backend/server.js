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

// Middleware
app.use(cors());
app.use(express.json());

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
app.use('/api/user', userRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/ride', rideRoutes);
app.use('/api/maps', mapsRoutes);

// Error Handling Middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send({ message: 'Internal Server Error' });
});

const PORT = 8000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`)); // Server is active and listening..

