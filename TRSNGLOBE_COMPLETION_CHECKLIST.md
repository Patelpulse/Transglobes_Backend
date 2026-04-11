# TRSNGLOBE Completion Checklist

Last updated: 2026-04-11

This checklist converts the project points into execution-ready deliverables.

## 1) User Panel (Customer App/Web)

- [ ] OTP login (mobile) is stable for Android, iOS, and web
- [ ] Optional email login works and links to the same user profile safely
- [ ] Profile management supports edit profile, image, and contact updates
- [x] Car booking flow works end-to-end (request -> assign -> OTP -> complete)
- [x] Shuttle booking flow works end-to-end (request -> assign -> OTP -> complete)
- [ ] Logistics booking flow captures goods type, dimensions, pickup/drop, transport mode
- [ ] Logistics estimated price and ETA are shown before confirmation
- [ ] Booking history includes Car, Shuttle, and Logistics entries
- [ ] Live tracking works for all active booking types
- [ ] Notifications (SMS/Push/In-app) fire at each major status change
- [ ] Payment integration is live (Razorpay/Stripe) including success/failure handling
- [ ] Support/help module is reachable and stores support tickets

## 2) Driver Panel (Driver App)

- [ ] Driver sign-up/sign-in is stable
- [ ] Document upload supports DL/RC and validation states
- [ ] Driver receives booking requests in real time
- [ ] Accept/reject actions update backend and requester instantly
- [ ] Booking details page includes customer, goods, segment, and fare details
- [ ] Navigation handoff to Google Maps works from each task/segment
- [ ] Start ride requires OTP verification
- [ ] Complete ride updates status and timestamps correctly
- [ ] Trip history persists and can be filtered
- [ ] Earnings dashboard calculates per-km/per-trip payout correctly

## 3) Corporate Panel (B2B Dashboard)

- [ ] Corporate login/auth works with role isolation
- [ ] Bulk logistics booking supports multi-item entries in one operation
- [ ] Transport type selection supports train/flight/sea/road
- [ ] Goods details include type, quantity, dimensions, weight
- [ ] Estimated price and ETA are shown before final submit
- [ ] Corporate booking history supports filtering/export
- [ ] Invoice generation is available per booking and in bulk
- [ ] Dedicated support flow is available for corporate users
- [ ] Logistics parity with user panel is maintained for core features

## 4) Admin Panel (Central Control)

- [ ] Admin can view/manage users, drivers, corporates
- [ ] Admin can view/manage all bookings (Car/Shuttle/Logistics)
- [ ] Admin can monitor full logistics lifecycle
- [ ] Admin can assign/reassign bookings and segment owners
- [ ] Pricing control supports base fare, per-km, and dynamic charges
- [ ] Commission management supports configurable splits
- [ ] Reports/analytics dashboard includes business and operations KPIs
- [ ] Role-based access enforcement is active across all admin actions
- [ ] Notification and payment modules are configurable from admin
- [ ] GPS tracking is available in admin live operations views

## 5) Supervisor Panel (Advanced Logistics Controller)

- [ ] Booking intake from user/corporate is visible in supervisor queue
- [ ] Supervisor can edit goods details, helper count, pickup/drop
- [ ] Supervisor can build multi-step roadmap segments (A->B->C->D)
- [ ] Segment-level transport details (train/flight/sea/road) are editable
- [ ] Supervisor can edit dynamic billing (toll/night/handling/transport)
- [ ] Supervisor can assign segment drivers based on locality/availability
- [ ] Data sync reflects in Admin, User, and Driver panels in real time
- [ ] Driver app shows only assigned segment details and payment details

## 6) Common Platform Requirements

- [ ] Real-time data sync via API + WebSocket
- [ ] Notification system covers SMS/Push/Email by role and event
- [ ] Role-based authentication and authorization is enforced
- [ ] Payment integration includes callbacks/webhooks and reconciliation
- [ ] GPS live location tracking works for active rides/shipments
- [ ] OTP verification is used in ride/shipment start flow
- [ ] Standard status progression is consistent across panels:
  - `Pending -> Approved -> In Progress -> Completed -> Delivered`

## 7) Mandatory Testing Gate

- [x] Car booking flow passes end-to-end validation
- [x] Shuttle booking flow passes end-to-end validation
- [x] Logistics booking flow passes end-to-end validation
- [ ] Failure scenarios are validated (invalid OTP, driver reject, payment fail)
- [ ] Regression suite is run before release

Backend verifier added in this pass:

- Command: `cd backend && npm run test:e2e-bookings`
- Script: `backend/scripts/e2e-booking-flows.js`
- Live run: passed against `http://localhost:8080/api` on 2026-04-11.
