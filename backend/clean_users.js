require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const User = require('./models/User');

const cleanUserEmails = async () => {
    try {
        await connectDB();

        console.log('Cleaning up User email fields...');

        // Remove the email field from docs where it is null
        const result = await User.updateMany(
            { email: null },
            { $unset: { email: "" } }
        );

        console.log(`Updated ${result.modifiedCount} users by unsetting null emails.`);

        process.exit(0);
    } catch (error) {
        console.error('Error cleaning users:', error);
        process.exit(1);
    }
};

cleanUserEmails();
