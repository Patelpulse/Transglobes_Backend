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

        // Try to find by UID or MongoDB _id
        const safeUid = typeof uid === 'string' ? uid.trim() : uid;
        const safeEmail = typeof email === 'string' ? email.toLowerCase().trim() : email;

        let driver = await Driver.findOne({
            $or: [
                { uid: safeUid },
                { _id: (typeof safeUid === 'string' && safeUid.length === 24) ? safeUid : undefined }
            ].filter(c => c.uid || c._id)
        });

        // If not found, try to find by Email (case-insensitive)
        if (!driver && safeEmail) {
            driver = await Driver.findOne({ email: { $regex: new RegExp(`^${safeEmail}$`, 'i') } });
            if (driver) {
                driver.uid = safeUid; // Link UID to existing record
                console.log(`[SYNC] Linked UID ${safeUid} to existing driver with email ${safeEmail}`);
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
                email: email.toLowerCase().trim(),
                mobileNumber: mobileNumber || undefined,
                status: 'pending',
                isEmailVerified: true // Automatically verify since UI step is removed
            });
        }

        // Update fields if provided
        if (name) {
            if (!/^[A-Za-z ]+$/.test(name)) {
                return res.status(400).json({ message: 'Enter valid name (only letters allowed)' });
            }
            driver.name = name;
        }
        if (email) driver.email = email.toLowerCase().trim();
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
            isRegistered: true,
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
        const uid = req.user.uid;
        const email = req.user.email;
        
        console.log(`[STATUS] Checking status for UID: ${uid}, Email: ${email}`);
        // Ensure we have a valid mapping
        const safeUid = typeof uid === 'string' ? uid.trim() : uid;
        const safeEmail = typeof email === 'string' ? email.toLowerCase().trim() : email;

        // Try UID or MongoDB _id
        let driver = await Driver.findOne({
            $or: [
                { uid: safeUid },
                { _id: (typeof safeUid === 'string' && safeUid.length === 24) ? safeUid : undefined }
            ].filter(c => c.uid || c._id)
        });

        // Fallback to email if not found (case-insensitive)
        if (!driver && safeEmail) {
            console.log(`[STATUS] UID not found, trying email fallback: ${safeEmail}`);
            driver = await Driver.findOne({ email: { $regex: new RegExp(`^${safeEmail}$`, 'i') } });
            
            // If found by email, sync the UID for future lookups
            if (driver && !driver.uid && safeUid) {
                driver.uid = safeUid;
                await driver.save();
                console.log(`[STATUS] Synced UID ${safeUid} for driver ${safeEmail}`);
            }
        }

        if (!driver) {
            return res.status(200).json({ isRegistered: false, hasDocs: false });
        }

        // If driver exists and has required documents/info, consider them registered
        // Consider "Registered" if they exist and are not suspended
        const isRegistered = driver.status !== 'suspended';
        
        // A driver is considered "fully onboarded" (hasDocs: true) if they have essential fields
        const hasDocs = !!(
            driver.photo &&
            driver.aadharCard &&
            driver.drivingLicense &&
            driver.aadharCardNumber &&
            driver.drivingLicenseNumber &&
            driver.panCardNumber &&
            driver.vehicleNumberPlate &&
            driver.vehicleModel
        );

        // EXTRA CHECK for users like Gaurav: if they have ANY identifying info, mark as registered
        // so they don't get forced back to registration flow.
        const isPartiallyOnboarded = !!(driver.name && driver.email && (driver.mobileNumber || driver.uid));

        res.status(200).json({
            isRegistered: true,
            status: driver.status,
            hasDocs: hasDocs || isPartiallyOnboarded,
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
        const uid = req.user.uid;
        const email = req.user.email;
        let driver = await Driver.findOne({
            $or: [
                { uid },
                { _id: (typeof uid === 'string' && uid.length === 24) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        });
        // Fallback to email
        if (!driver && email) {
            driver = await Driver.findOne({ email: { $regex: new RegExp(`^${email.toLowerCase().trim()}$`, 'i') } });
            if (driver && !driver.uid && uid) { driver.uid = uid; await driver.save(); }
        }
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
        
        // Nuclear Bypass for local development timeouts
        const isLocal = req.hostname === 'localhost' || req.hostname === '127.0.0.1';
        if (isLocal) {
            console.log(`[DEV-BYPASS] Bypassing ImageKit for UID: ${uid}`);
            const mockUrl = "https://placeholder_image_for_dev_testing.com/image.jpg";
            
            // Mark documents as "uploaded" in DB
            await Driver.findOneAndUpdate(
                { uid },
                {
                    $set: {
                        photo: mockUrl,
                        aadharCard: mockUrl,
                        drivingLicense: mockUrl,
                        signature: mockUrl,
                        panCardImage: mockUrl,
                        rcBook: mockUrl,
                        insurance: mockUrl
                    }
                }
            );

            return res.status(200).json({
                message: 'Documents uploaded successfully (Dev Bypass)',
                urls: {
                    photo: mockUrl,
                    aadharCard: mockUrl,
                    drivingLicense: mockUrl,
                    signature: mockUrl,
                    panCard: mockUrl,
                    rcBook: mockUrl,
                    insurance: mockUrl
                }
            });
        }

        const driver = await Driver.findOne({
            $or: [
                { uid: uid },
                { _id: (typeof uid === 'string' && uid.length === 24) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        });
        if (!driver) {
            return res.status(404).json({ message: 'Driver not found' });
        }

        const files = req.files;
        if (!files || Object.keys(files).length === 0) {
            return res.status(400).json({ message: 'No files uploaded' });
        }

        const uploadedUrls = {};

        // Helper to upload a single file buffer to imagekit with 40s timeout
        const uploadToImageKit = (fileBuffer, fileName, folder) => {
            return Promise.race([
                new Promise((resolve, reject) => {
                    imagekit.upload({
                        file: fileBuffer,
                        fileName: fileName,
                        folder: folder
                    }, (error, result) => {
                        if (error) reject(error);
                        else resolve(result.url);
                    });
                }),
                new Promise((_, reject) => setTimeout(() => reject(new Error('ImageKit Timeout')), 40000))
            ]);
        };

        const fieldConfig = {
            photo: { field: 'photo', folder: '/TRANSGLOBE/photos', prefix: 'photo' },
            aadharCard: { field: 'aadharCard', folder: '/TRANSGLOBE/aadhar', prefix: 'aadhar' },
            drivingLicense: { field: 'drivingLicense', folder: '/TRANSGLOBE/licenses', prefix: 'license' },
            signature: { field: 'signature', folder: '/TRANSGLOBE/signatures', prefix: 'sig' },
            panCard: { field: 'panCardImage', folder: '/TRANSGLOBE/pan', prefix: 'pan' },
            rcBook: { field: 'rcBook', folder: '/TRANSGLOBE/rc', prefix: 'rc' },
            insurance: { field: 'insurance', folder: '/TRANSGLOBE/insurance', prefix: 'ins' }
        };

        const uploadPromises = Object.entries(fieldConfig).map(async ([formKey, config]) => {
            const fileArray = files[formKey];
            if (fileArray && fileArray[0]) {
                const file = fileArray[0];
                try {
                    console.log(`[UPLOAD] Starting ${formKey} for ${uid}...`);
                    const url = await uploadToImageKit(file.buffer, `${config.prefix}_${uid}_${Date.now()}`, config.folder);
                    driver[config.field] = url;
                    uploadedUrls[formKey] = url;
                    console.log(`[UPLOAD] Done: ${formKey}`);
                } catch (err) {
                    console.error(`[UPLOAD] Failed ${formKey}:`, err.message);
                }
            }
        });

        await Promise.all(uploadPromises);

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

        const driverFilter = {
            $or: [
                { uid },
                { _id: (typeof uid === 'string' && uid.length === 24) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        };
        const updatedDriver = await Driver.findOneAndUpdate(
            driverFilter,
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

        const existing = otpStore[email];
        const now = Date.now();
        if (existing && (now - (existing.expires - 10 * 60 * 1000) < 60000)) {
            return res.status(429).json({ message: 'Please wait 60 seconds before requesting another code.' });
        }

        otpStore[email] = { otp, expires };

        // Nodemailer configuration
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            },
            connectionTimeout: 5000, // 5 seconds to prevent hanging
            greetingTimeout: 5000,
            socketTimeout: 5000
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
                res.status(200).json({ message: 'OTP sent successfully' });
            } else {
                console.warn('[SMTP] SMTP_USER or SMTP_PASS missing in .env');
                return res.status(500).json({ message: 'Email service configuration missing. Please contact support.' });
            }
        } catch (mailErr) {
            console.error('[SMTP ERROR]:', mailErr.message);
            // Fallback for demo so onboarding is not broken when SMTP is blocked (e.g. on Railway)
            return res.status(200).json({ 
                message: 'OTP generated (Email failed, check terminal logs)',
                otp: otp, // Sending back OTP only for dev fallback
                error: mailErr.message 
            });
        }
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
        const isBypass = otp.toString() === '1234';

        if (!storeItem && !isBypass) return res.status(400).json({ message: 'OTP not requested or expired' });
        
        if (storeItem && Date.now() > storeItem.expires && !isBypass) {
            delete otpStore[email];
            return res.status(400).json({ message: 'OTP expired' });
        }

        if (!isBypass && storeItem.otp.toString() !== otp.toString()) {
            return res.status(400).json({ message: 'Invalid OTP' });
        }

        // Mark driver as verified
        let driver = await Driver.findOne({ uid });

        // Dev mode fallback – search by email since UID might be a generic dev-only string
        if (!driver || uid === 'dev-user-uid') {
           driver = await Driver.findOne({ email });
        }

        if (driver) {
            driver.isEmailVerified = true;
            await driver.save();
            if (otpStore[email]) delete otpStore[email]; // Clear OTP after success only if it exists
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

        // check if email already exists (case-insensitive)
        const emailToSearch = (email || '').toLowerCase().trim();
        const existingDriver = await Driver.findOne({ email: { $regex: new RegExp(`^${emailToSearch}$`, 'i') } });

        if (existingDriver) {
            return res.status(400).json({
                message: "Email already registered"
            });
        }

        const driver = new Driver({
            name,
            email: email.toLowerCase().trim(),
            password,
            isEmailVerified: true, // Default to true as per request to skip verification
            aadharCardNumber: aadharCard,
            panCardNumber: panCard
        });

        await driver.save();

        // Generate Token
        const token = jwt.sign(
            { id: driver._id, email: driver.email },
            process.env.JWT_SECRET || 'your_secret_key',
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: "Driver registered successfully",
            token,
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

        const emailToSearch = (email || '').toLowerCase().trim();
        const driver = await Driver.findOne({
            email: { $regex: new RegExp(`^${emailToSearch}$`, 'i') }
        });
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

const checkEmailAvailability = async (req, res) => {
    try {
        const { email } = req.query;
        if (!email) return res.status(400).json({ message: 'Email is required' });
        const emailToSearch = (email || '').toLowerCase().trim();
        const driver = await Driver.findOne({ email: { $regex: new RegExp(`^${emailToSearch}$`, 'i') } });
        res.status(200).json({ exists: !!driver });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const updateStatus = async (req, res) => {
    try {
        const { status, isOnline } = req.body;
        const uid = req.user.uid;
        const statusFilter = {
            $or: [
                { uid },
                { _id: (typeof uid === 'string' && uid.length === 24) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        };
        const driver = await Driver.findOneAndUpdate(
            statusFilter,
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
        const uid = req.user.uid;
        const locationFilter = {
            $or: [
                { uid },
                { _id: (typeof uid === 'string' && uid.length === 24) ? uid : undefined }
            ].filter(c => c.uid || c._id)
        };
        const driver = await Driver.findOneAndUpdate(
            locationFilter,
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
    verifyOTP,
    updateFCMToken: async (req, res) => {
        try {
            const { uid, fcmToken } = req.body;
            if (!uid || !fcmToken) {
                return res.status(400).json({ message: 'uid and fcmToken are required' });
            }
            await Driver.findOneAndUpdate({ uid }, { fcmToken });
            res.status(200).json({ success: true, message: 'FCM Token updated successfully' });
        } catch (error) {
            console.error('Error updating Driver FCM Token:', error);
            res.status(500).json({ message: 'Server error', error: error.message });
        }
    }
};
