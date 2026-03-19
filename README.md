 
 

Key Enhancements
🗺️ Interactive Route Mapping
Live Route Plotting: The map now dynamically fetches and draws a polyline between your pickup and drop-off locations using OSRM (Open Source Routing Machine).
Dual Markers: Added specific markers for both Pickup (Green) and Drop-off (Red) locations.
Auto-Fitting View: The map automatically adjusts its zoom and center position to perfectly fit the entire route, ensuring both locations are always visible once selected.
💰 Dynamic Distance Pricing
Variable Fare Calculation: Pricing is no longer just a flat base rate. It now follows the formula:
Total Price = Base Price + (Price Per Km × Distance).
Real-time Estimates: The "Estimated Total" in the footer updates instantly as you search for locations or switch between transport modes (Train, Flight, Sea).
Distance Breakdown: A new distance indicator (e.g., "Distance: 15.4 km") appears in the booking summary once a valid route is found.
⚙️ Admin Control & Backend
Per-Mode Rates: Admins can now manage the Price Per Km for each mode (e.g., Sea might be ₹10/km while Flight is ₹50/km) via the updated Admin Dashboard.
Database Sync: Migrated all existing vehicle modes to support distance-based pricing with default rates.
🚀 How to Test
Select Locations: Search for a Pickup and a Drop-off location in the User App.
Verify Map: Watch as the blue route line appears and the map zooms to show the start and end points.
Check Price: Observe the total price change as the distance is calculated. Try switching modes to see how different Price Per Km rates affect the final cost.
The system is now fully integrated and ready for operations! Would you like to implement live driver tracking on this map once the booking is confirmed?

=============>web notification
npm install firebase
Then, initialize Firebase and begin using the SDKs for the products you'd like to use.

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBnml6vJJQz05so1pNmsyLpLCqdcFM6RAQ",
  authDomain: "transgolbe-a1eeb.firebaseapp.com",
  projectId: "transgolbe-a1eeb",
  storageBucket: "transgolbe-a1eeb.firebasestorage.app",
  messagingSenderId: "531372125872",
  appId: "1:531372125872:web:348b0f06ba434b74021575",
  measurementId: "G-RW1D2MLE7Z"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);