# 06: Role-Based Authentication, Fleet Ops Console & FastAPI Backend Bridge

**What to build:**
Complete user authentication by role, fleet operational oversight, and a production-grade FastAPI backend bridge. Delivers Passenger and Driver registration and login screens with secure token storage and role-based route guards, while preserving a header Demo/Inspector toggle for judges to access the Ops Fleet Console. The Ops Console renders fleet-wide vehicle locations, live cabin occupancy bars, synthetic request injection, and an honest side-by-side benchmark comparing the RidePool optimizer against a greedy nearest-vehicle baseline on identical seeds. Finally, builds the Python FastAPI backend (Stage B) with SQLite/PostgreSQL persistence, geocoding proxy, matching scheduler, and a WebSocket event hub connecting to Flutter via a dual-mode repository switch.

**Blocked by:** 01: Core Game-Theory Engine, Dynamic Seat Ledger & Golden Fixtures, 05: Pickup OTP Verification, Ride Completion, Receipt & Payments

**Status:** completed

- [x] `AuthCubit` provides Passenger and Driver registration and login flows; driver onboarding captures vehicle tier, license plate, and driver license number.
- [x] JWT tokens are securely stored, refreshed automatically, and guard navigation to appropriate role home views upon launch.
- [x] Header includes a Demo/Inspector switch granting instant access to the Ops Fleet Console without logging out of user sessions.
- [x] Ops Fleet Console renders all active vehicles, cabin occupancy bars (onboard, reserved, held, free), and supports manual synthetic request injection and batch triggering.
- [x] Benchmark analytics run the RidePool optimizer alongside a greedy nearest-vehicle baseline on the exact same seed, reporting truthful service rates, mean and p95 detour percentages, and vehicle km saved.
- [x] Python FastAPI backend provides REST endpoints for auth, places, vehicles, bookings, trips, consent, and payments, backed by SQLite/PostgreSQL.
- [x] WebSocket hub broadcasts real-time events (`vehicle_position`, `route_updated`, `seat_update`, `consent_request`, `payment_status`), and Flutter's repository seamlessly toggles between `Live Backend` and `Offline Simulation`.
