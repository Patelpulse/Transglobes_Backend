const { Server } = require("socket.io");
const Message = require("../models/Message");
const Booking = require("../models/Booking");

const initSocket = (server) => {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        },
    });

    console.log("Socket.io initialized");

    io.on("connection", (socket) => {
        console.log("A user connected:", socket.id);

        // Join personal room based on userId for targeted messaging
        socket.on("register", (data) => {
            const userId = typeof data === 'string' ? data : data.userId;
            const name = typeof data === 'object' ? data.name : "User";
            if (userId) {
                socket.join(userId);
                console.log(`User ${userId} (${name}) registered and joined room`);
                socket.emit("connection_success", { 
                    message: `Welcome ${name}, Socket connected successfully!`,
                    userId,
                    name
                });
            }
        });

        // Join specific ride room
        socket.on("join_ride", (rideId) => {
            if (rideId) {
                socket.join(rideId);
                console.log(`Socket ${socket.id} joined ride room: ${rideId}`);
            }
        });

        // Update Fare and Notify User
        socket.on("update_fare", async (data) => {
            const { rideId, amount, newFare } = data;
            try {
                // Update in database
                await Booking.findByIdAndUpdate(rideId, { fare: newFare });
                
                // Notify user in the ride room
                io.to(rideId).emit("fare_increased", {
                    rideId,
                    amount,
                    newFare,
                    message: `Driver has increased the fare by ₹${amount}. New fare is ₹${newFare}.`
                });
                
                console.log(`Fare updated for ride ${rideId}: +${amount} (Total: ${newFare})`);
            } catch (error) {
                console.error("Error updating fare:", error);
                socket.emit("fare_error", { error: "Failed to update fare" });
            }
        });

        // Send and Persist Message
        socket.on("send_message", async (data) => {
            const { senderId, receiverId, message, senderRole, senderName } = data;

            try {
                // Save to MongoDB
                const newMessage = await Message.create({
                    senderId,
                    receiverId,
                    message,
                    senderRole: senderRole || 'unknown'
                });

                // Emit to both parties rooms to sync all devices/tabs
                io.to(receiverId).to(senderId).emit("receive_message", {
                    _id: newMessage._id,
                    senderId,
                    receiverId,
                    message,
                    senderName,
                    timestamp: newMessage.createdAt
                });

                // Also emit back to sender (for multi-device sync if needed, or confirmation)
                socket.emit("message_sent", {
                    status: "success",
                    messageId: newMessage._id,
                    timestamp: newMessage.createdAt
                });

            } catch (error) {
                console.error("Error saving message:", error);
                socket.emit("message_error", { error: "Failed to send message" });
            }
        });

        // Edit Message
        socket.on("edit_message", async ({ messageId, newMessage, receiverId }) => {
            try {
                const msg = await Message.findByIdAndUpdate(messageId, { message: newMessage, isEdited: true }, { new: true });
                if (msg) {
                    // Emit to both to keep all sessions in sync
                    io.to(receiverId).to(msg.senderId).emit("message_edited", {
                        messageId,
                        newMessage,
                        receiverId,
                        senderId: msg.senderId
                    });
                }
            } catch (error) { console.error("Edit error:", error); }
        });

        // Delete Message
        socket.on("delete_message", async ({ messageId, receiverId }) => {
            try {
                const msg = await Message.findByIdAndUpdate(messageId, { isDeleted: true, message: "This message was deleted" }, { new: true });
                if (msg) {
                    // Emit to both to keep all sessions in sync
                    io.to(receiverId).to(msg.senderId).emit("message_deleted", {
                        messageId,
                        receiverId,
                        senderId: msg.senderId
                    });
                }
            } catch (error) { console.error("Delete error:", error); }
        });

        // Fetch Chat History (Optional but useful for UI)
        socket.on("fetch_history", async ({ userId1, userId2 }) => {
            try {
                const history = await Message.find({
                    $or: [
                        { senderId: userId1, receiverId: userId2 },
                        { senderId: userId2, receiverId: userId1 }
                    ]
                }).sort({ createdAt: 1 });

                socket.emit("chat_history", history);
            } catch (error) {
                console.error("Error fetching history:", error);
            }
        });

        // Driver Location Updates
        socket.on("update_location", (data) => {
            const { rideId, userId, latitude, longitude, heading } = data;
            // Emit to the ride-specific room so all participants (user/driver) get it
            io.to(rideId).emit("driver_location_update", {
                rideId,
                latitude,
                longitude,
                heading,
                timestamp: new Date()
            });
        });

        socket.on("disconnect", () => {
            console.log("User disconnected:", socket.id);
        });
    });

    return io;
};

module.exports = initSocket;
