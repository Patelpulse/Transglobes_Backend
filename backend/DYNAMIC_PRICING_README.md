# Dynamic Pricing Implementation

## Overview

The booking system now calculates prices dynamically from a database configuration (`PricingConfig`) instead of accepting prices from the client. This ensures:

- **Security**: Prices cannot be manipulated from the frontend
- **Flexibility**: Change pricing rules without code deployment
- **Transparency**: Complete fare breakdown for users
- **Consistency**: Same pricing logic for both rides and logistics

---

## Changes Made

### 1. **New Utility Module** - `utils/pricingCalculator.js`

A centralized pricing engine with helper functions:

- `calculateDynamicFare()` - Main fare calculation with all rules
- `calculateTotalWeight()` - Sum weight from items array
- `calculateTotalVolume()` - Calculate cubic volume from dimensions
- `hasFragileItems()` - Detect fragile cargo
- `hasBulkyItems()` - Detect oversized items

### 2. **Updated Controllers**

#### `logisticsBookingController.js`
- Now calculates prices automatically based on:
  - Distance
  - Weight (from items)
  - Volume (from dimensions)
  - Helpers count
  - Fragile/bulky cargo
  - Transport mode (Road, Train, Flight, Sea Cargo)
  - Time of day (night surcharge)
  - City-specific rules

#### `rideController.js`
- Creates rides with dynamic fare calculation
- Falls back to provided fare if calculation fails (for backward compatibility)
- Supports both regular rides and logistics rides

#### `pricingController.js`
- Refactored to use the centralized pricing utility
- Simplified and consistent with booking logic

### 3. **Updated Models**

#### `LogisticsBooking.js`
- Added `fareBreakdown` field to store pricing details
- Added `weight` and `quantity` fields to `itemSchema`

#### `History.js`
- Added `fareBreakdown` field for ride bookings

### 4. **New Routes**

#### Public Endpoint for Users
```
POST /api/users/calculate-fare
```
Users can now calculate fares before booking.

---

## API Usage

### 1. Calculate Fare (Before Booking)

**Endpoint:** `POST /api/users/calculate-fare`

**Request Body (Logistics):**
```json
{
  "distanceKm": 15,
  "mode": "Road",
  "weightKg": 50,
  "volumeCubicCm": 100000,
  "helperCount": 2,
  "isFragile": true,
  "isBulky": false,
  "city": "Mumbai",
  "bookingType": "logistics"
}
```

**Request Body (Regular Ride):**
```json
{
  "distanceKm": 10,
  "durationMin": 30,
  "mode": "Car",
  "city": "Delhi",
  "bookingType": "ride"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "configId": "507f1f77bcf86cd799439011",
    "configName": "Default",
    "baseFare": 100,
    "distanceCharge": 225,
    "weightCharge": 200,
    "volumeCharge": 100,
    "helperCharge": 300,
    "fragileCharge": 200,
    "bulkyCharge": 0,
    "modeMultiplier": 1.0,
    "nightSurcharge": 0,
    "tollCharges": 0,
    "platformFee": 51,
    "gstAmount": 199,
    "subtotal": 1076,
    "totalFare": 1275
  }
}
```

---

### 2. Create Logistics Booking (With Auto-Pricing)

**Endpoint:** `POST /api/logistics/book`

**Request Body:**
```json
{
  "userId": "user123",
  "userName": "John Doe",
  "userPhone": "+919876543210",
  "pickup": {
    "name": "Mumbai Central",
    "address": "Mumbai Central Station, Mumbai",
    "lat": 18.9685,
    "lng": 72.8205
  },
  "dropoff": {
    "name": "Pune Station",
    "address": "Pune Railway Station, Pune",
    "lat": 18.5204,
    "lng": 73.8567
  },
  "distanceKm": 150,
  "vehicleType": "Road",
  "items": [
    {
      "itemName": "Electronics",
      "type": "Fragile",
      "length": 50,
      "width": 40,
      "height": 30,
      "weight": 25,
      "quantity": 2
    },
    {
      "itemName": "Furniture",
      "type": "General",
      "length": 120,
      "width": 80,
      "height": 60,
      "weight": 50,
      "quantity": 1
    }
  ],
  "helperCount": 2,
  "discountAmount": 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Logistics booking created successfully!",
  "bookingId": "507f191e810c19729de860ea",
  "data": {
    "_id": "507f191e810c19729de860ea",
    "userId": "user123",
    "totalPrice": 2450,
    "vehiclePrice": 2300,
    "helperCost": 300,
    "fareBreakdown": {
      "baseFare": 100,
      "distanceCharge": 2250,
      "weightCharge": 300,
      "helperCharge": 300,
      "gstAmount": 539,
      "totalFare": 2550
    },
    "status": "pending"
  },
  "fareBreakdown": {
    "baseFare": 100,
    "distanceCharge": 2250,
    "weightCharge": 300,
    "helperCharge": 300,
    "gstAmount": 539,
    "subtotal": 2011,
    "totalFare": 2550
  }
}
```

---

### 3. Create Ride Booking (With Auto-Pricing)

**Endpoint:** `POST /api/rides/create`

**Request Body:**
```json
{
  "locations": {
    "pickup": {
      "title": "Home",
      "address": "123 Main Street, Mumbai",
      "latitude": 19.0760,
      "longitude": 72.8777
    },
    "dropoff": {
      "title": "Office",
      "address": "456 Business Park, Mumbai",
      "latitude": 19.1136,
      "longitude": 72.8697
    }
  },
  "rideMode": "Car",
  "paymentMode": "cash",
  "distance": "10 km",
  "vehicleType": "Sedan"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride request created successfully",
  "data": {
    "_id": "507f191e810c19729de860ea",
    "userId": "507f1f77bcf86cd799439011",
    "rideMode": "Car",
    "fare": 185,
    "fareBreakdown": {
      "baseFare": 50,
      "distanceCharge": 100,
      "gstAmount": 27,
      "subtotal": 158,
      "totalFare": 185
    },
    "status": "pending"
  },
  "fareBreakdown": {
    "baseFare": 50,
    "distanceCharge": 100,
    "platformFee": 8,
    "gstAmount": 27,
    "subtotal": 158,
    "totalFare": 185
  }
}
```

---

## Pricing Configuration

### Seeding Default Config

Run this command to create a default pricing configuration:

```bash
node seedPricingConfig.js
```

### Admin Endpoints

**Get All Configs:**
```
GET /api/admin/pricing
```

**Get Active Config:**
```
GET /api/admin/pricing/active?city=Mumbai
```

**Create New Config:**
```
POST /api/admin/pricing
Content-Type: application/json

{
  "name": "Mumbai Premium",
  "city": "Mumbai",
  "isActive": true,
  "baseFare": 75,
  "perKmCharge": 12,
  "minimumFare": 150,
  "logistics": {
    "baseFare": 150,
    "perKmCharge": 18,
    "helperCostPerPerson": 200
  }
}
```

**Update Config:**
```
PUT /api/admin/pricing/:id
```

**Delete Config:**
```
DELETE /api/admin/pricing/:id
```

---

## Pricing Rules

### Regular Rides

1. **Base Fare** - Fixed starting charge
2. **Distance Charge** - Per km rate × distance
3. **Duration Charge** - Per minute rate × duration (if provided)
4. **Night Surcharge** - Applied between 10 PM - 6 AM (configurable)
5. **Peak Hour Surge** - Applied during rush hours
6. **Toll Charges** - Fixed toll amount
7. **Platform Fee** - Percentage of subtotal
8. **GST** - Tax percentage on final amount
9. **Minimum Fare** - Floor price enforcement

### Logistics Bookings

1. **Base Fare** - Fixed starting charge
2. **Distance Charge** - Per km rate × distance
3. **Weight Charge** - Tiered pricing per kg
4. **Volume Charge** - Per cubic cm rate
5. **Mode Multiplier** - Different rates for Road/Train/Flight/Sea
6. **Helper Charge** - Per helper rate × helper count
7. **Fragile Handling** - Extra charge for fragile items
8. **Bulky Surcharge** - Extra charge for oversized items
9. **Night Surcharge** - Multiplier for night bookings
10. **Toll Charges** - Fixed toll amount
11. **Platform Fee** - Percentage of subtotal
12. **GST** - Tax percentage on final amount

---

## Features

### Automatic Detection

- **Fragile Items**: Detects keywords like "fragile", "glass", "electronics"
- **Bulky Items**: Checks volume > 100,000 cubic cm (0.1 cubic meter)
- **Weight Calculation**: Sums weight × quantity for all items
- **Volume Calculation**: Sums (length × width × height × quantity)

### Night Surcharge

Automatically applies night multiplier based on booking time:
- Default: 10 PM to 6 AM
- Configurable per pricing config

### City-Specific Pricing

Support for different pricing in different cities:
- Mumbai: Higher rates
- Delhi: Standard rates
- Default: Fallback for all other cities

---

## Backward Compatibility

- **Rides**: If fare calculation fails, uses provided `fare` from request
- **Logistics**: Requires pricing config to exist (fails if not found)
- **Frontend**: Can still send fare, but it will be recalculated server-side

---

## Testing Checklist

1. ✅ Seed default pricing config
2. ✅ Create logistics booking without sending price
3. ✅ Create ride booking without sending fare
4. ✅ Calculate fare endpoint returns correct breakdown
5. ✅ Night surcharge applies after 10 PM
6. ✅ Weight/volume charges calculated from items
7. ✅ Fragile/bulky detection works
8. ✅ Discount applies correctly
9. ✅ GST calculated properly
10. ✅ fareBreakdown stored in database

---

## Frontend Integration

### Before Booking Flow

1. User selects pickup/dropoff locations
2. Frontend calculates distance using Google Maps
3. **Call `/api/users/calculate-fare`** with trip details
4. Display fare breakdown to user
5. User confirms and creates booking
6. Backend recalculates fare to ensure consistency

### Example Frontend Code

```javascript
// Step 1: Calculate Fare
const response = await fetch('/api/users/calculate-fare', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    distanceKm: 15,
    mode: 'Road',
    weightKg: 50,
    helperCount: 2,
    bookingType: 'logistics'
  })
});

const { data } = await response.json();
console.log('Estimated Fare:', data.totalFare);

// Step 2: Create Booking (price will be recalculated)
const booking = await fetch('/api/logistics/book', {
  method: 'POST',
  headers: { 
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    userId: 'user123',
    pickup: { ... },
    dropoff: { ... },
    distanceKm: 15,
    vehicleType: 'Road',
    items: [ ... ],
    helperCount: 2
  })
});
```

---

## Troubleshooting

### Error: "No active pricing config found"

**Solution:** Run the seed script:
```bash
node seedPricingConfig.js
```

### Prices don't match frontend calculation

**Reason:** Backend always recalculates for security. Ensure frontend uses the same logic as backend.

### Night surcharge not applying

**Check:** 
1. Server time zone matches expected region
2. `nightStartHour` and `nightEndHour` configured correctly

---

## Next Steps

1. **Add City Detection**: Extract city from pickup location coordinates
2. **Add Coupon Support**: Integrate discount codes with pricing
3. **Add Surge Pricing**: Dynamic multipliers based on demand
4. **Add Distance Matrix**: Real-time distance calculation
5. **Add Driver Bidding**: Let drivers quote custom prices

---

## Contact

For questions or issues, contact the backend team.
