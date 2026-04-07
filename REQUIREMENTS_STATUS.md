# TRSNGLOBE Requirements Status

Last updated: 2026-04-07

## Legend

- `Done`: Present in codebase with working implementation paths.
- `Partial`: Some implementation exists, but the requirement is incomplete, placeholder-driven, or not fully wired end-to-end.
- `Missing`: Not found as a real implementation in this repo.

## User Panel

| Requirement | Status | Notes |
| --- | --- | --- |
| Mobile OTP login | Done | Present in `user_app` with Firebase-based OTP flow. |
| Email login optional | Done | Present in auth service, though OTP is the primary path. |
| Profile management | Done | Profile screens and backend profile routes exist. |
| Car booking | Done | Ride booking flow exists in backend and user app. |
| Shuttle booking | Partial | UI exists, but dedicated backend shuttle domain is not clearly separated from the generic ride flow. |
| Logistics booking | Done | User logistics flow posts into backend logistics booking APIs. |
| Goods type and dimensions | Done | User logistics booking collects items and dimensions. |
| Pickup and drop locations | Done | Present in user logistics flow and backend. |
| Transport mode road/train/flight/sea cargo | Partial | Supported by logistics data model, but the user app centers on vehicle selection rather than full multi-modal journey planning. |
| Estimated price and time | Partial | Estimated pricing exists; time estimation is inconsistent across panels. |
| Booking history | Done | User booking and logistics history screens exist. |
| Live tracking | Partial | Socket and tracking screens exist, but map/tracking coverage is not fully unified across all booking types. |
| Notifications | Partial | Push/socket hooks exist, but SMS/email coverage is incomplete and event consistency is still uneven. |
| Payment integration | Partial | Payment screens/models exist, but real gateway integration is not completed. |
| Support/help | Done | Support UI exists. |
| End-to-end booking validation | Done | Automated API-level verifier now exists and passes for Car/Shuttle/Logistics (`backend/scripts/e2e-booking-flows.js`). |

## Driver Panel

| Requirement | Status | Notes |
| --- | --- | --- |
| Driver sign up/sign in | Done | Driver auth and onboarding exist. |
| Document upload | Done | Registration flow and backend upload paths exist. |
| Receive booking requests | Done | Driver fetches rides/logistics and receives socket events. |
| Accept/reject booking | Done | Backend and driver UI support both actions. |
| View booking details | Done | Driver booking detail screens exist. |
| Navigation integration | Partial | Launch-to-map/navigation behavior exists, but not a deeply integrated routing stack. |
| Start ride with OTP | Done | Ride OTP verification is implemented. |
| Complete ride | Done | Status update and completion flows exist. |
| Trip history | Done | Driver bookings are split into pending/active/history. |
| Earnings dashboard | Done | Earnings/wallet UI exists. |

## Corporate Panel

| Requirement | Status | Notes |
| --- | --- | --- |
| Corporate login | Done | Backend corporate login API and app-side authentication flow now exist. |
| Bulk logistics booking | Partial | Corporate logistics request UI exists; CSV/API bulk upload is not implemented. |
| Multi-transport selection | Done | Journey builder supports segmented transport modes. |
| Goods details and dimensions | Partial | Goods type and weight exist; full dimensions/quantity depth is still limited. |
| Estimated price and delivery time | Partial | Price estimation exists; delivery time estimation is not robust. |
| Booking history | Done | Corporate shipments page now loads bookings from the backend. |
| Invoice generation | Partial | Backend invoice API exists (`GET /api/payment/invoice/:bookingId`), but Corporate panel billing/invoice UI is still static and not wired. |
| Dedicated support | Done | Corporate support UI exists. |
| Same logistics functionality as user panel | Partial | Improved in this pass by aligning payloads, but parity is still not full feature-for-feature. |

## Admin Panel

| Requirement | Status | Notes |
| --- | --- | --- |
| Users data | Done | Backend/admin app list users. |
| Drivers data | Done | Backend/admin app list drivers. |
| Corporate accounts | Partial | Corporate model exists, but admin CRUD/management is not complete. |
| Booking data for all booking types | Partial | Ride and logistics visibility exist, but central unification is incomplete. |
| Logistics lifecycle monitoring | Partial | Logistics management screens exist; some routes remain placeholders. |
| Assign/reassign bookings | Done | Logistics assignment flows exist. |
| Pricing control | Partial | Billing edits exist for logistics; full pricing rule engine is incomplete. |
| Commission management | Partial | Transaction/commission concepts exist, but admin control surfaces are limited. |
| Reports and analytics | Partial | Basic report/stats endpoints exist; richer dashboards remain incomplete. |
| Notification system | Partial | Present in parts of the stack. |
| Payment gateway management | Missing | No real admin-managed payment gateway integration found. |
| GPS tracking | Partial | Tracking/socket foundations exist; admin live tracking route is still placeholder UI. |
| Role-based access | Partial | Roles exist in models/tokens, but complete RBAC enforcement is still incomplete. |

## Supervisor Panel

| Requirement | Status | Notes |
| --- | --- | --- |
| Dedicated supervisor panel | Done | Supervisor screen and route are present in admin app with booking management tabs. |
| Edit goods details | Done | Admin logistics detail screen supports edits. |
| Add helpers/transport/pickup/drop | Partial | Helpers and transport edits exist, but not as a separate supervisor workflow. |
| Roadmap creation | Done | Multi-segment roadmap model and UI exist. |
| Dynamic pricing controls | Partial | Logistics billing edits exist, but not a full rule-based supervisor pricing engine. |
| Segment-wise driver assignment | Done | Segment assignment exists in admin logistics management. |
| Sync to admin/user/driver | Done | Socket updates are emitted for roadmap and ride events. |
| Driver segment view and payment | Partial | Segment visibility is present in data, but payment logic per segment is not fully implemented. |

## Security And Platform

| Requirement | Status | Notes |
| --- | --- | --- |
| JWT auth | Done | Implemented in backend. |
| RBAC | Partial | Role fields exist; enforcement is not comprehensive. |
| Session timeout/auto logout | Missing | Not found as a real cross-panel implementation. |
| Sensitive data encryption | Partial | Password hashing exists, but broader sensitive-field encryption is not implemented. |
| HTTPS enforced | Partial | Deployment can use HTTPS, but explicit server-side enforcement was not found. |
| API rate limiting | Partial | Added basic in-memory limiter in this pass; production-grade distributed limiting is still pending. |

## Testing

| Requirement | Status | Notes |
| --- | --- | --- |
| Unit testing | Partial | Minimal test presence only. |
| Integration testing | Partial | API-level end-to-end booking flow verifier exists for Car/Shuttle/Logistics; broader CI integration test coverage is still pending. |
| Load testing | Missing | Not found. |
| UAT coverage | Missing | Not found in repo artifacts. |
| Multi-segment logistics deep testing | Missing | Not automated. |
| Failure scenario testing | Missing | Not automated. |

## Changes Made In This Pass

- Fixed the corporate logistics booking payload to align with backend logistics booking APIs.
- Made backend logistics booking creation more tolerant of mixed payload shapes.
- Removed implicit localhost auth bypass behavior and gated dev bypass behind `ALLOW_DEV_AUTH_BYPASS=true`.
- Added lightweight security headers and a basic in-memory rate limiter to the backend server.
- Added a runnable API-level booking flow verifier for Car, Shuttle, and Logistics:
  - `cd backend && npm run test:e2e-bookings`
  - Script: `backend/scripts/e2e-booking-flows.js`
- Added a project-wide execution checklist aligned to all panel requirements:
  - `TRSNGLOBE_COMPLETION_CHECKLIST.md`

## Next Recommended Build Order

1. Finish real corporate auth, booking history, and invoice generation.
2. Build a dedicated supervisor role and panel instead of relying on admin-only logistics controls.
3. Replace placeholder admin routes with real tracking, bookings, and pricing management pages.
4. Add automated integration tests for car, shuttle, and logistics booking flows.
5. Complete payment gateway, refund, and wallet settlement integrations.

## Advanced Requirements Reference

- Advanced modules (8–35) cross-check is tracked in:
  - `ADVANCED_REQUIREMENTS_STATUS.md`
