require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const checkDB = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to DB:', mongoose.connection.name);

        const users = await User.find({});
        console.log(`Found ${users.length} users:`);
        users.forEach(u => {
            console.log(` - ID: ${u._id}, Mobile: ${u.mobileNumber}, Name: ${u.name}, Email: ${u.email}`);
        });

        process.exit(0);
    } catch (err) {
        console.error('Connection error:', err);
        process.exit(1);
    }
};

checkDB();
