const admin = require('../config/firebase');
const Driver = require('../models/Driver');
const User = require('../models/User');

const sendPushNotification = async (tokens, payload) => {
    if (!tokens || tokens.length === 0) return;
    
    // Filter out empty strings
    const validTokens = tokens.filter(token => token && token.trim() !== '');
    if (validTokens.length === 0) return;

    const message = {
        notification: {
            title: payload.title,
            body: payload.body,
        },
        data: payload.data || {},
        tokens: validTokens,
    };

    try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} notifications; ${response.failureCount} failed.`);
        
        // Handle failures (e.g., remove invalid tokens)
        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(validTokens[idx]);
                }
            });
            console.warn('Failed tokens:', failedTokens);
        }
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
};

const notifyAllDrivers = async (payload) => {
    try {
        const onlineDrivers = await Driver.find({ isOnline: true }).select('fcmToken');
        const tokens = onlineDrivers.map(d => d.fcmToken).filter(t => t);
        await sendPushNotification(tokens, payload);
    } catch (error) {
        console.error('Error in notifyAllDrivers:', error);
    }
};

const notifyUser = async (userId, payload) => {
    try {
        const user = await User.findById(userId).select('fcmToken');
        if (user && user.fcmToken) {
            await sendPushNotification([user.fcmToken], payload);
        }
    } catch (error) {
        console.error('Error in notifyUser:', error);
    }
};

module.exports = {
    sendPushNotification,
    notifyAllDrivers,
    notifyUser
};
