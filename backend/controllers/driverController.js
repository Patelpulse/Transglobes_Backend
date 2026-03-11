const Driver = require('../models/Driver');
const imagekit = require('../config/imagekit');
const nodemailer = require('nodemailer');
const jwt = require('jsonwebtoken');
const History = require('../models/History');

const otpStore = {}; // Memory store: { email: { otp, expires } }

// Controller for syncing driver data upon login or initial load
const syncDriverData = async (req, res) => {
    try {
        const { uid, name, email, mobileNumber, aadharCardNumber, drivingLicenseNumber, panCardNumber, dob, vehicleNumberPlate, vehicleModel, vehicleYear } = req.body;

        if (!uid) {
            return res.status(400).json({ message: 'UID is required' });
        }

        // Try to find by UID first
        let driver = await Driver.findOne({ uid });

        // If not found by UID, try to find by Email or Mobile (to link social logins to existing records)
        if (!driver && email) {
            driver = await Driver.findOne({ email });
            if (driver) {
                driver.uid = uid; // Link UID to existing record
            }
        }

        if (!driver) {
            // Validate required fields for new registration
            if (!name || !email) {
                return res.status(400).json({
                    message: 'Missing required fields for registration',
                    required: ['name', 'email']
                });
            }

            // Register or Create
            driver = new Driver({
                uid,
                name,
                email,
                mobileNumber: mobileNumber || undefined,
                status: 'pending'
            });
        }

        // Update fields if provided
        if (name) {
            if (!/^[A-Za-z ]+$/.test(name)) {
                return res.status(400).json({ message: 'Enter valid name (only letters allowed)' });
            }
            driver.name = name;
        }
        if (email) driver.email = email;
        if (mobileNumber) {
            if (!/^[6-9][0-9]{9}$/.test(mobileNumber)) {
                return res.status(400).json({ message: 'Enter valid 10-digit mobile number starting with 6-9' });
            }
            driver.mobileNumber = mobileNumber;
        }
        if (aadharCardNumber) {
            if (!/^[0-9]{12}$/.test(aadharCardNumber)) {
                return res.status(400).json({ message: 'Enter valid 12-digit Aadhar number' });
            }
            driver.aadharCardNumber = aadharCardNumber;
        }
        if (drivingLicenseNumber) {
            // Normalizing DL (removing spaces/hyphens if any, though frontend should handle this)
            const cleanDL = drivingLicenseNumber.replace(/[\s-]/g, '').toUpperCase();
            if (!/^[A-Z]{2}[0-9]{2}[0-9]{4}[0-9]{7}$/.test(cleanDL)) {
                return res.status(400).json({ message: 'Enter valid Driving License number (e.g., MH-12-20110012345)' });
            }
            driver.drivingLicenseNumber = cleanDL;
        }
        if (panCardNumber) {
            const cleanPAN = panCardNumber.toUpperCase();
            if (!/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(cleanPAN)) {
                return res.status(400).json({ message: 'Enter valid PAN number (ABCDE1234F)' });
            }
            driver.panCardNumber = cleanPAN;
        }
        if (dob) driver.dob = new Date(dob);
        if (vehicleNumberPlate) driver.vehicleNumberPlate = vehicleNumberPlate;
        if (vehicleModel) driver.vehicleModel = vehicleModel;
        if (vehicleYear) driver.vehicleYear = vehicleYear;

        // Mock KYC Verification Logic (Replace with real API calls like Signzy/Karza)
        if (driver.panCardNumber && !driver.panVerified) {
            // Here you would call verifyPAN(driver.panCardNumber, driver.name, driver.dob)
            driver.panVerified = true;
        }
        if (driver.aadharCardNumber && !driver.aadharVerified) {
            // Aadhaar usually requires OTP, but for this flow we mark as verified once submitted
            driver.aadharVerified = true;
        }
        if (driver.drivingLicenseNumber && !driver.drivingLicenseVerified) {
            // Here you would call verifyDL(driver.drivingLicenseNumber, driver.dob)
            driver.drivingLicenseVerified = true;
        }

        await driver.save();

        // A driver is considered "fully registered" if they have all required fields and documents
        const isComplete = !!(
            driver.photo &&
            driver.aadharCard &&
            driver.drivingLicense &&
            driver.signature &&
            driver.aadharCardNumber &&
            driver.drivingLicenseNumber &&
            driver.panCardNumber &&
            driver.vehicleNumberPlate &&
            driver.vehicleModel &&
            driver.isEmailVerified
        );

        res.status(200).json({
            message: 'Driver synced successfully',
            driver,
            hasDocs: isComplete
        });
    } catch (error) {
        console.error('Error syncing driver:', error);
        if (error.code === 11000) {
            const field = Object.keys(error.keyPattern)[0];
            return res.status(400).json({ message: `A driver with this ${field} already exists` });
        }
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getDriverStatus = async (req, res) => {
    try {
        const driver = await Driver.findOne({ uid: req.user.uid });
        if (!driver) {
            return res.status(200).json({ isRegistered: false });
        }

        // If driver exists and has required documents/info, consider them registered
        const isRegistered = driver.status === 'active' || driver.status === 'pending';
        // You might want more complex logic here, e.g., checking if all docs are uploaded
        // A driver is considered "fully registered" if they have all required fields and documents
        const hasDocs = !!(
            driver.photo &&
            driver.aadharCard &&
            driver.drivingLicense &&
            driver.signature &&
            driver.aadharCardNumber &&
            driver.drivingLicenseNumber &&
            driver.panCardNumber &&
            driver.vehicleNumberPlate &&
            driver.vehicleModel &&
            driver.isEmailVerified
        );

        res.status(200).json({
            isRegistered: true,
            status: driver.status,
            hasDocs: !!hasDocs,
            driver
        });
    } catch (error) {
        console.error('Error checking status:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const getDriverProfile = async (req, res) => {
    try {
        // req.user added by authMiddleware
        const driver = await Driver.findOne({ uid: req.user.uid });
        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }
        res.status(200).json({ driver });
    } catch (error) {
        console.error('Error fetching driver:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const uploadDocuments = async (req, res) => {
    try {
        const uid = req.user.uid;
        const driver = await Driver.findOne({ uid });

        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        const files = req.files; // Expected to be an object with fieldnames as keys

        if (!files || Object.keys(files).length === 0) {
            return res.status(400).json({ message: 'No files uploaded' });
        }

        const uploadedUrls = {};

        // Helper to upload a single file buffer to imagekit
        const uploadToImageKit = (fileBuffer, fileName, folder) => {
            return new Promise((resolve, reject) => {
                imagekit.upload({
                    file: fileBuffer,
                    fileName: fileName,
                    folder: folder
                }, (error, result) => {
                    if (error) reject(error);
                    else resolve(result.url);
                });
            });
        };

        if (files.photo && files.photo[0]) {
            uploadedUrls.photo = await uploadToImageKit(
                files.photo[0].buffer,
                `photo_${uid}_${Date.now()}`,
                '/TRANSGLOBE/photos'
            );
            driver.photo = uploadedUrls.photo;
        }

        if (files.aadharCard && files.aadharCard[0]) {
            uploadedUrls.aadharCard = await uploadToImageKit(
                files.aadharCard[0].buffer,
                `aadhar_${uid}_${Date.now()}`,
                '/TRANSGLOBE/aadhar'
            );
            driver.aadharCard = uploadedUrls.aadharCard;
        }

        if (files.drivingLicense && files.drivingLicense[0]) {
            uploadedUrls.drivingLicense = await uploadToImageKit(
                files.drivingLicense[0].buffer,
                `license_${uid}_${Date.now()}`,
                '/TRANSGLOBE/licenses'
            );
            driver.drivingLicense = uploadedUrls.drivingLicense;
        }

        if (files.signature && files.signature[0]) {
            uploadedUrls.signature = await uploadToImageKit(
                files.signature[0].buffer,
                `signature_${uid}_${Date.now()}`,
                '/TRANSGLOBE/signatures'
            );
            driver.signature = uploadedUrls.signature;
        }

        // Change status to pending approval or active depending on your logic
        await driver.save();

        res.status(200).json({
            message: 'Documents uploaded successfully',
            urls: uploadedUrls,
            driver
        });
    } catch (error) {
        console.error('Error uploading documents:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateDriverProfile = async (req, res) => {
    try {
        const uid = req.user.uid;
        const { name, mobileNumber, signature, vehicleNumberPlate, vehicleModel, vehicleYear } = req.body;

        const updatedDriver = await Driver.findOneAndUpdate(
            { uid },
            {
                $set: {
                    ...(name && { name }),
                    ...(mobileNumber && { mobileNumber }),
                    ...(signature && { signature }),
                    ...(vehicleNumberPlate && { vehicleNumberPlate }),
                    ...(vehicleModel && { vehicleModel }),
                    ...(vehicleYear && { vehicleYear })
                }
            },
            { new: true, runValidators: true }
        );

        if (!updatedDriver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        // Re-process KYC whenever numbers are updated (mock)
        if (updatedDriver.panCardNumber && !updatedDriver.panVerified) updatedDriver.panVerified = true;
        if (updatedDriver.aadharCardNumber && !updatedDriver.aadharVerified) updatedDriver.aadharVerified = true;
        if (updatedDriver.drivingLicenseNumber && !updatedDriver.drivingLicenseVerified) updatedDriver.drivingLicenseVerified = true;

        await updatedDriver.save();

        res.status(200).json({
            success: true,
            data: updatedDriver
        });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const sendOTP = async (req, res) => {
    try {
        let { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        email = email.toLowerCase().trim();
        console.log(`[AUTH] Generating OTP for email: ${email}`);

        const otp = Math.floor(100000 + Math.random() * 900000);
        const expires = Date.now() + 10 * 60 * 1000; // 10 minutes

        otpStore[email] = { otp, expires };

        // Nodemailer configuration (User requested 587/TLS config)
        const transporter = nodemailer.createTransport({
            host: "smtp.gmail.com",
            port: 587,
            secure: false, // TLS
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            },
            tls: {
                rejectUnauthorized: false
            }
        });

        const mailOptions = {
            from: `"Ride App" <${process.env.SMTP_USER}>`,
            to: email,
            subject: "Your OTP Code",
            html: `<h2>Your OTP is: ${otp}</h2>`
        };

        // For demo/dev: always log the OTP to console so developer can test without real SMTP
        console.log(`[OTP DEBUG] OTP for ${email} is: ${otp}`);

        // Try to send email
        try {
            console.log(`[SMTP] Attempting to send email via ${process.env.SMTP_USER}...`);
            if (process.env.SMTP_USER && process.env.SMTP_PASS) {
                const info = await transporter.sendMail(mailOptions);
                console.log(`[SMTP] Email sent successfully: ${info.messageId}`);
            } else {
                console.warn('[SMTP] SMTP_USER or SMTP_PASS missing in .env. Skipping real mail send.');
            }
        } catch (mailErr) {
            console.error('[SMTP ERROR]:', mailErr.message);
            // We don't return error 500 here because the OTP is still logged in console for dev use
        }

        res.status(200).json({ message: 'OTP sent successfully' });
    } catch (error) {
        console.error('Error sending OTP:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

const verifyOTP = async (req, res) => {
    try {
        let { email, otp } = req.body;
        const uid = req.user.uid;

        if (!email || !otp) return res.status(400).json({ message: 'Email and OTP are required' });

        email = email.toLowerCase().trim();
        console.log(`[AUTH] Verifying OTP for ${email}: ${otp}`);

        const storeItem = otpStore[email];

        if (!storeItem) return res.status(400).json({ message: 'OTP not requested or expired' });
        if (Date.now() > storeItem.expires) {
            delete otpStore[email];
            return res.status(400).json({ message: 'OTP expired' });
        }

        if (storeItem.otp.toString() !== otp.toString()) {
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        // Mark driver as verified
        const driver = await Driver.findOne({ uid });
        if (driver) {
            driver.isEmailVerified = true;
            await driver.save();
            delete otpStore[email]; // Clear OTP after success
            return res.status(200).json({ success: true, message: 'Email verified successfully' });
        }

        res.status(404).json({ message: 'Driver not found' });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

const register = async (req, res) => {
    try {
        const { name, email, password, aadharCard, panCard } = req.body;

        if (!password) {
            return res.status(400).json({ message: "Password is required" });
        }

        // check if email already exists
        const existingDriver = await Driver.findOne({ email });

        if (existingDriver) {
            return res.status(400).json({
                message: "Email already registered"
            });
        }

        const driver = new Driver({
            name,
            email,
            password,
            aadharCardNumber: aadharCard,
            panCardNumber: panCard
        });

        await driver.save();

        res.status(201).json({
            message: "Driver registered successfully",
            driver: {
                id: driver._id,
                name: driver.name,
                email: driver.email
            }
        });

    } catch (error) {
        console.error('Driver Registration error:', error);
        res.status(500).json({ error: error.message });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const driver = await Driver.findOne({ email });
        if (!driver) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const isMatch = await driver.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        // Generate Token
        const token = jwt.sign(
            { id: driver._id, email: driver.email },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        res.status(200).json({
            message: 'Login successful.',
            token,
            driver: {
                id: driver._id,
                name: driver.name,
                email: driver.email
            }
        });
    } catch (error) {
        console.error('Driver Login error:', error);
        res.status(500).json({ message: 'Server error', error: error.message });
    }
};

const updateStatus = async (req, res) => {
    try {
        const { status, isOnline } = req.body;
        const driver = await Driver.findOneAndUpdate(
            { uid: req.user.uid },
            { $set: { status: status || 'offline', isOnline: isOnline ?? false } },
            { new: true }
        );
        if (!driver) return res.status(404).json({ message: 'Driver not found' });
        res.json({ success: true, status: driver.status, isOnline: driver.isOnline });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateLocation = async (req, res) => {
    try {
        const { latitude, longitude } = req.body;
        const driver = await Driver.findOneAndUpdate(
            { uid: req.user.uid },
            {
                $set: {
                    location: {
                        type: 'Point',
                        coordinates: [longitude, latitude]
                    }
                }
            },
            { new: true }
        );
        if (!driver) return res.status(404).json({ message: 'Driver not found' });

        // If driver is on an active ride, notify the user
        const activeRide = await History.findOne({
            'driverId': driver._id,
            status: { $in: ['accepted', 'on_the_way', 'arrived', 'started'] }
        });

        if (activeRide && req.io) {
            req.io.to(activeRide.userId.toString()).emit("driver_location_update", {
                rideId: activeRide._id,
                latitude,
                longitude
            });
        }

        res.json({ success: true, location: driver.location });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    syncDriverData,
    register,
    login,
    getDriverProfile,
    uploadDocuments,
    getDriverStatus,
    updateDriverProfile,
    updateStatus,
    updateLocation,
    sendOTP,
    verifyOTP
};
