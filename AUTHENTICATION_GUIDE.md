# Transglobe Authentication Implementation Guide

## Overview

This document describes the complete authentication architecture for the Transglobe Backend system, supporting three user roles: **User**, **Driver**, and **Corporate**.

Each role supports three authentication methods:
1. **Email + Password** (Traditional)
2. **Mobile Number + Password** (New Implementation)
3. **Google OAuth** (Social Login)

---

## Table of Contents

- [Authentication Methods](#authentication-methods)
- [API Endpoints](#api-endpoints)
- [Request/Response Examples](#requestresponse-examples)
- [Token Management](#token-management)
- [Database Schema](#database-schema)
- [Testing with Postman](#testing-with-postman)
- [Security Features](#security-features)

---

## Authentication Methods

### 1. Email + Password Authentication

Traditional authentication using email and password. Passwords are hashed using bcrypt before storage.

**Supported Roles:** User, Driver, Corporate, Admin

### 2. Mobile Number + Password Authentication (NEW)

Allows users to register and login using their mobile number instead of email.

**Supported Roles:** User, Driver, Corporate

**Features:**
- Mobile number validation
- Unique mobile number constraint
- Password hashing with bcrypt
- JWT token generation
- Role-based authentication

### 3. Google OAuth Authentication

Social login using Firebase Google Authentication.

**Supported Roles:** User, Driver, Corporate

**Features:**
- Firebase ID token verification
- Auto-registration for new users
- Account linking for existing users
- Secure password generation for OAuth accounts

---

## API Endpoints

### Base URL
```
Local: http://localhost:5000/api
Production: https://your-domain.com/api
```

### User Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/user/signup` | Register with email + password |
| POST | `/auth/user/login` | Login with email + password |
| POST | `/auth/user/mobile-signup` | Register with mobile + password |
| POST | `/auth/user/mobile-login` | Login with mobile + password |
| POST | `/auth/user/google-auth` | Google OAuth authentication |
| GET | `/auth/profile` | Get user profile (requires token) |
| PUT | `/auth/profile` | Update user profile (requires token) |

### Driver Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/driver/signup` | Register with email + password |
| POST | `/auth/driver/login` | Login with email + password |
| POST | `/auth/driver/mobile-signup` | Register with mobile + password |
| POST | `/auth/driver/mobile-login` | Login with mobile + password |
| POST | `/auth/driver/google-auth` | Google OAuth authentication |

### Corporate Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/corporate/signup` | Register with email + password |
| POST | `/auth/corporate/login` | Login with email + password |
| POST | `/auth/corporate/mobile-signup` | Register with mobile + password |
| POST | `/auth/corporate/mobile-login` | Login with mobile + password |
| POST | `/auth/corporate/google-auth` | Google OAuth authentication |
| GET | `/auth/corporate/profile` | Get corporate profile (requires token) |

### Admin Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/admin/register` | Register admin account |
| POST | `/auth/admin/login` | Login admin account |
| GET | `/auth/admin/profile` | Get admin profile (requires token) |
| POST | `/auth/admin/logout` | Logout admin |

---

## Request/Response Examples

### 1. User - Email Signup

**Request:**
```bash
POST /api/auth/user/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "password": "SecurePassword123",
  "mobileNumber": "+1234567890"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "uid": "usr_1234567890_abc123",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "mobileNumber": "+1234567890",
    "role": "user"
  }
}
```

### 2. User - Mobile Signup (NEW)

**Request:**
```bash
POST /api/auth/user/mobile-signup
Content-Type: application/json

{
  "name": "Jane Smith",
  "mobileNumber": "+9876543210",
  "password": "MobilePass123"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "User registered successfully with mobile number",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439012",
    "uid": "usr_1234567891_xyz456",
    "name": "Jane Smith",
    "mobileNumber": "+9876543210",
    "role": "user"
  }
}
```

### 3. User - Mobile Login (NEW)

**Request:**
```bash
POST /api/auth/user/mobile-login
Content-Type: application/json

{
  "mobileNumber": "+9876543210",
  "password": "MobilePass123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439012",
    "uid": "usr_1234567891_xyz456",
    "name": "Jane Smith",
    "mobileNumber": "+9876543210",
    "role": "user"
  }
}
```

### 4. User - Google OAuth

**Request:**
```bash
POST /api/auth/user/google-auth
Content-Type: application/json
Authorization: Bearer <FIREBASE_ID_TOKEN>

{
  "mobileNumber": "+1234567890"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Google login successful",
  "isNewUser": false,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "uid": "firebase_uid_abc123",
    "name": "John Doe",
    "email": "john.doe@example.com",
    "mobileNumber": "+1234567890",
    "role": "user"
  }
}
```

### 5. Driver - Mobile Signup (NEW)

**Request:**
```bash
POST /api/auth/driver/mobile-signup
Content-Type: application/json

{
  "name": "Driver Sarah",
  "mobileNumber": "+9123456789",
  "password": "DriverMobile123"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Driver registered successfully with mobile number",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "driver": {
    "id": "507f1f77bcf86cd799439013",
    "uid": "drv_1234567892_def789",
    "name": "Driver Sarah",
    "mobileNumber": "+9123456789",
    "status": "pending"
  }
}
```

### 6. Corporate - Mobile Signup (NEW)

**Request:**
```bash
POST /api/auth/corporate/mobile-signup
Content-Type: application/json

{
  "companyName": "TechCorp Ltd",
  "gstin": "27BBBBB1111B2Z6",
  "mobileNumber": "+9988776655",
  "contactPhone": "+9988776655",
  "address": "456 Tech Park, City, Country",
  "password": "TechCorp123"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Corporate account created successfully with mobile number",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "corporate": {
    "id": "507f1f77bcf86cd799439014",
    "companyName": "TechCorp Ltd",
    "mobileNumber": "+9988776655",
    "contactPhone": "+9988776655",
    "address": "456 Tech Park, City, Country",
    "gstin": "27BBBBB1111B2Z6",
    "role": "corporate",
    "status": "active"
  }
}
```

---

## Token Management

### JWT Token Structure

Tokens are generated using JSON Web Tokens (JWT) and include:

```javascript
{
  id: "<user_mongodb_id>",
  uid: "<user_unique_id>",
  email: "<user_email>",
  role: "<user_role>",  // 'user', 'driver', 'corporate', 'admin'
  iat: <issued_at_timestamp>,
  exp: <expiration_timestamp>
}
```

### Token Expiration
- **User/Driver/Corporate tokens:** 7 days
- **Admin tokens:** 1 day

### Using Tokens

Include the token in the Authorization header for protected routes:

```bash
Authorization: Bearer <your_jwt_token>
```

### Token Verification

The `verifyToken` middleware automatically:
1. Validates Firebase ID tokens (for Google OAuth)
2. Validates local JWT tokens (for email/mobile auth)
3. Attaches user information to `req.user`
4. Tracks device information and last active time

---

## Database Schema

### User Model

```javascript
{
  uid: String (unique, indexed),
  name: String,
  email: String (unique, sparse),
  mobileNumber: String (unique, sparse, indexed),
  password: String (hashed),
  googleId: String (unique, sparse, indexed),
  imageUrl: String,
  role: String (enum: ['user', 'corporate']),
  lastActive: Date,
  lastLoginAt: Date,
  isFraudulent: Boolean,
  fcmToken: String,
  deviceInfo: {
    model: String,
    platform: String,
    version: String
  },
  createdAt: Date,
  updatedAt: Date
}
```

### Driver Model

```javascript
{
  uid: String (unique, sparse, indexed),
  name: String (required),
  email: String (unique, required),
  mobileNumber: String (unique, sparse),
  password: String (hashed),
  googleId: String (unique, sparse, indexed),
  status: String (enum: ['pending', 'active', 'suspended']),
  role: String (default: 'driver'),
  walletBalance: Number,
  photo: String,
  aadharCard: String,
  drivingLicense: String,
  aadharCardNumber: String,
  drivingLicenseNumber: String,
  panCardNumber: String,
  vehicleNumberPlate: String,
  vehicleModel: String,
  vehicleYear: String,
  // ... more fields
  lastLoginAt: Date,
  deviceInfo: Object,
  createdAt: Date,
  updatedAt: Date
}
```

### Corporate Model

```javascript
{
  companyName: String (required, unique),
  gstin: String (required, unique),
  email: String (required, unique),
  mobileNumber: String (unique, sparse, indexed),
  contactPhone: String (required),
  address: String (required),
  password: String (hashed, required),
  googleId: String (unique, sparse, indexed),
  role: String (default: 'corporate'),
  creditLimit: Number,
  currentBalance: Number,
  status: String (enum: ['active', 'inactive', 'on_hold']),
  accountManagerId: ObjectId (ref: 'Admin'),
  createdAt: Date,
  updatedAt: Date
}
```

---

## Testing with Postman

### Import the Collection

1. Open Postman
2. Click **Import**
3. Select the file: `backend/postman/Transglobe_Authentication_Collection.json`
4. The collection will be imported with all endpoints

### Setup Environment Variables

Create a new environment in Postman with these variables:

```
base_url: http://localhost:5000/api
production_url: https://your-domain.com/api
user_token: (auto-populated after login)
driver_token: (auto-populated after login)
corporate_token: (auto-populated after login)
admin_token: (auto-populated after login)
google_id_token: <your_firebase_id_token>
```

### Running Tests

1. Start with signup requests to create test accounts
2. Use login requests to obtain tokens (automatically saved to environment)
3. Use protected endpoints with the saved tokens
4. Test all three authentication methods for each role

---

## Security Features

### Password Security
- Passwords hashed using bcrypt with salt rounds: 10
- Passwords never returned in API responses
- Strong password validation recommended (implement client-side)

### Token Security
- JWT tokens signed with secret key (JWT_SECRET env variable)
- Tokens include expiration time
- Bearer token authentication scheme
- Token verification on every protected route

### Google OAuth Security
- Firebase Admin SDK for token verification
- ID tokens verified server-side
- Email verification through Google
- Secure random password generation for OAuth accounts

### Mobile Number Security
- Mobile numbers normalized and validated
- Unique constraint prevents duplicate registrations
- Stored as indexed fields for fast lookup

### Database Security
- Passwords hashed before saving (pre-save hooks)
- Unique indexes prevent duplicate accounts
- Sparse indexes allow optional fields (email, mobile)
- Role-based access control

### Middleware Protection
- `verifyToken`: Validates JWT/Firebase tokens
- `verifyAdminToken`: Admin-specific token validation
- Device tracking and session management
- Last active timestamp updates

---

## Error Responses

### Common Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request (missing fields, validation errors) |
| 401 | Unauthorized (invalid credentials, expired token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found (user/resource doesn't exist) |
| 409 | Conflict (duplicate email/mobile number) |
| 500 | Internal Server Error |

### Error Response Format

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (in development)"
}
```

---

## Environment Variables

Required environment variables in `.env`:

```env
# JWT Secret
JWT_SECRET=your_jwt_secret_key_here

# MongoDB Connection
MONGODB_URI=mongodb://localhost:27017/transglobe

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Development Flags (optional)
NODE_ENV=development
ALLOW_DEV_AUTH_BYPASS=false
ALLOW_UNVERIFIED_FIREBASE_TOKEN=false

# SMTP Configuration (for OTP emails)
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

---

## Integration Guide

### Frontend Integration

#### 1. Email/Password Authentication

```javascript
// Signup
const response = await fetch('http://localhost:5000/api/auth/user/signup', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'John Doe',
    email: 'john@example.com',
    password: 'SecurePass123'
  })
});

const data = await response.json();
localStorage.setItem('token', data.token);
```

#### 2. Mobile/Password Authentication

```javascript
// Signup
const response = await fetch('http://localhost:5000/api/auth/user/mobile-signup', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'Jane Smith',
    mobileNumber: '+9876543210',
    password: 'MobilePass123'
  })
});

const data = await response.json();
localStorage.setItem('token', data.token);
```

#### 3. Google OAuth Authentication

```javascript
// After getting Firebase ID token from Google Sign-In
const firebaseIdToken = await firebaseAuth.currentUser.getIdToken();

const response = await fetch('http://localhost:5000/api/auth/user/google-auth', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${firebaseIdToken}`
  },
  body: JSON.stringify({
    mobileNumber: '+1234567890' // optional
  })
});

const data = await response.json();
localStorage.setItem('token', data.token);
```

#### 4. Using Protected Routes

```javascript
const token = localStorage.getItem('token');

const response = await fetch('http://localhost:5000/api/auth/profile', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const userData = await response.json();
```

---

## Mobile App Integration (Flutter/React Native)

### Flutter Example

```dart
// User Mobile Login
Future<Map<String, dynamic>> loginWithMobile(String mobile, String password) async {
  final response = await http.post(
    Uri.parse('http://localhost:5000/api/auth/user/mobile-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'mobileNumber': mobile,
      'password': password,
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await storage.write(key: 'token', value: data['token']);
    return data;
  } else {
    throw Exception('Login failed');
  }
}

// Google Sign-In
Future<Map<String, dynamic>> loginWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  
  final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
  final idToken = await userCredential.user!.getIdToken();
  
  final response = await http.post(
    Uri.parse('http://localhost:5000/api/auth/user/google-auth'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
  );
  
  final data = jsonDecode(response.body);
  await storage.write(key: 'token', value: data['token']);
  return data;
}
```

---

## Next Steps

1. **Test all endpoints** using the provided Postman collection
2. **Integrate with your frontend** using the examples above
3. **Configure Firebase** for Google OAuth (if not already done)
4. **Set up environment variables** properly
5. **Implement proper error handling** in your frontend
6. **Add password strength validation** on the client side
7. **Implement refresh token logic** if needed for longer sessions
8. **Set up proper logging** and monitoring

---

## Support

For issues or questions:
- Check the Postman collection for working examples
- Review error responses for debugging hints
- Ensure all environment variables are set correctly
- Verify Firebase configuration for Google OAuth

---

## Changelog

### Version 1.0.0 (April 2026)
- ✅ Email + Password authentication for User, Driver, Corporate
- ✅ Mobile + Password authentication for User, Driver, Corporate (NEW)
- ✅ Google OAuth authentication for User, Driver, Corporate
- ✅ JWT token management with 7-day expiration
- ✅ Role-based authentication and authorization
- ✅ Comprehensive Postman collection
- ✅ Password hashing with bcrypt
- ✅ Device tracking and session management
