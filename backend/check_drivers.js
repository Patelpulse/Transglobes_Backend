require('dotenv').config();
const mongoose = require('mongoose');

async function run() {
    await mongoose.connect(process.env.MONGODB_URI);
    const db = mongoose.connection.db;
    const drivers = await db.collection('drivers').find({}).toArray();
    console.log(`Found ${drivers.length} drivers:`);
    drivers.forEach(d => {
        console.log(` - ID: ${d._id}, Name: ${d.name}, Status: ${d.status}, Vehicle: ${d.vehicleNumberPlate}`);
    });
    
    const bookings = await db.collection('logisticsbookings').find({}).toArray();
    console.log(`\nFound ${bookings.length} total bookings:`);
    bookings.forEach(b => {
        console.log(` - ID: ${b._id}, DriverID: ${b.driverId}, Status: ${b.status}, Mode: ${b.vehicleType}, User: ${b.userName}, Created: ${b.createdAt}`);
    });

    await mongoose.disconnect();
}
run();
