const mongoose = require('mongoose');
require('dotenv').config();

const checkUsers = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb+srv://transgolbe:723pw4h.mongodb.net/test');
        const User = mongoose.model('User', new mongoose.Schema({ mobileNumber: String }));
        const users = await User.find({});
        console.log('Total users:', users.length);
        users.forEach(u => console.log('User Mobile:', u.mobileNumber));
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

checkUsers();
