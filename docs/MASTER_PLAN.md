# RidePool AI: Master Plan (Code-Review Fixes + New Features, Merged)

This plan merges two documents:

- **IMPLEMENTATION_PLAN.md** = the code review. It says the app is a UI shell with hardcoded offers, fares and metrics, and lays out how to build a real engine under it.
- **plan.md** = your new feature list: login, typed location search, vehicle types, per-passenger map markers, OTP, payments and a complete backend, plus the seat and fare bugs.

The two plans overlap on the engine, seats, fares and consent, conflict in a few places, and each misses things the other covers. This document resolves all of that into one ordered plan.

---

## 1. What the analysis found

### 1.1 Root causes of your reported bugs (from the code review)

| Your issue | Cause found in the code review | Fixed in |
|---|---|---|
| 4. Fare split incorrect | There is no Shapley engine. Fares are `soloFare × 0.70`, and the receipt uses invented ratios (`× 0.45`, `× 0.60`) | Phase 1, 5 |
| 5. Full 4-seat car still offers "add person" | There is no seat ledger, and the party-size cap is **hardcoded to 3**. Reserved seats are never counted | Phase 2, 3 |
| 6. Map doesn't show each person's pickup/drop | Routes come from a hardcoded sample offer. There is no per-booking stop list | Phase 2, 6 |
| "Features not correctly implemented" | Matching is a hardcoded sample offer after the countdown, detour is a fixed `8.4%`, benchmark numbers are constants, three cubits keep separate copies of state, cancellation and consent do not exist | Phases 1–7 |

### 1.2 What each plan misses

| IMPLEMENTATION_PLAN.md is missing | plan.md is missing |
|---|---|
| Login and roles | Evidence of the actual code gaps (hardcoded values) |
| Typed place search | Seeded simulation and the greedy baseline benchmark |
| Vehicle types (3/4/6 seats) | Ops simulation settings, event log and rejected-candidate inspector |
| Per-passenger map markers | Rolling batcher and shareability filter detail |
| OTP and payments | Honest labelling of simulated data |
| Real road routing (it uses haversine) | A cross-cubit single store |
| A backend (it says offline only, which now contradicts your goal) | |

### 1.3 Conflicts and how they are resolved

| Topic | Plan A (review) | Plan B (new features) | **Decision** |
|---|---|---|---|
| Backend | Offline only | Full FastAPI backend | **Both.** Build the offline engine first (Stage A), then add the backend behind the same repository interface (Stage B). See 2.1 |
| Coalition cost v(S) | Cheapest plan, no detour cap in the accounting game; 15% cap gates dispatch | Cheapest plan including the detour constraint | **Plan A.** v(S) = cheapest plan allowing separate cars, respecting capacity and pickup-before-drop. The 15% cap decides whether a group may be dispatched. This avoids undefined coalition values |
| Party fare policy | Per booking (a 3-person booking is one Shapley player, split equally inside) | Per seat by default | **Per booking.** Capacity still counts seats. Configurable later |
| Fare ceiling | Cap at solo, redistribute excess pro-rata | Redistribute, and reject the pool if impossible | **Combine.** Cap and redistribute; if no allocation satisfies caps and total, reject the pooled plan. Show raw and adjusted fares |
| Batch window | 15 s default, up to 90 s | 30–90 s from the UI spec | Configurable, default 15 s for demos |
| Rounding | Largest remainder | Largest remainder | Same |
| Routing | Haversine behind an interface | OSRM | Haversine × 1.3 in Stage A, OSRM in Stage B, same interface |
| Payments | Not covered | Razorpay | Simulated in Stage A, Razorpay in Stage B |

---

## 2. Architecture

### 2.1 One engine, two implementations, shared test fixtures

The biggest risk of merging is **two engines drifting apart** (Dart for offline mode, Python for the backend). To control it:

- The **Dart engine** (`mobile/lib/core/engine/`) powers offline mode and Stage A.
- The **Python engine** (`backend/app/services/`) is a port that powers live mode.
- Both are tested against the **same golden fixtures** in `contracts/fixtures/*.json` (inputs and expected coalition tables, Shapley shares, rounded fares, detours). A change to either engine that breaks a fixture fails CI.
- Alternative if you prefer a single codebase: write the backend in Dart (shelf / Dart Frog) and share the engine as one package. That drops FastAPI and the Python Razorpay SDK, so choose it only if you want zero duplication.

### 2.2 Layers (additions marked new)

```
mobile/lib/
  core/engine/          cost_model, route_optimizer, detour_validator,
                        shapley_calculator, fare_allocator, seat_ledger (new)
  core/theme, constants
  data/models/          RideRequest, Vehicle, VehicleType (new), Stop (new),
                        RouteAssignment, FareAllocation, ConsentRequest,
                        User (new), Otp (new), Payment (new)
  repositories/         RidePoolRepository (interface, filled in)
                        MockRidePoolRepository   (engine-backed, seeded RNG)
                        HttpRidePoolRepository   (Stage B, REST + WebSocket)
  services/ (new)       PlaceSearchService (Local / Backend)
                        AuthService (Mock / Backend)
                        PaymentService (Simulated / Razorpay / PaymentLink)
  store/                RidePoolStore → Stream<RidePoolSnapshot> (single source of truth)
  blocs/                AuthCubit (new), PassengerCubit, DriverCubit, OpsCubit
  views/                auth/ (new), passenger/, driver/, ops/, common/
  widgets/              PillButton, SeatOccupancyBar (new), VehicleTypeCard (new),
                        PlaceSearchField (new), OtpPad (new), LiveMapWidget (extended)

backend/ (Stage B)     FastAPI + PostgreSQL + Alembic, OSRM, Photon/Nominatim,
                        WebSocket hub, scheduler, simulator, Razorpay
contracts/fixtures/    golden JSON shared by Dart and Python tests (new)
```

Rules:
- Cubits **read the store**, never keep their own copy of ride, seat or fare state.
- The seat ledger and fare engine are the only places those numbers are computed.
- Every simulated number in the UI is labelled "Simulated".

### 2.3 Seat ledger (the fix for issue 5)

```
occupied  = sum(party_size) where status = ONBOARD
reserved  = sum(party_size) where status in (CONFIRMED, WAITING_PICKUP)
held      = sum(party_size) where status in (OFFERED, PENDING_CONSENT)   # expires on timer
available = capacity − occupied − reserved − held
```

- `capacity` comes from the vehicle type: Auto 3, Car 4, Car XL 6.
- A booking needs `party_size <= available` **and** a valid route (capacity at every segment, time windows, 15% detour). A free seat never admits anyone by itself.
- Mutations happen in one place (store in Stage A, DB transaction with a row lock in Stage B). Duplicate taps use idempotency keys.

### 2.4 Fare pipeline (the fix for issue 4)

1. Route optimizer finds the cheapest valid ordering per coalition (brute force, up to 4–5 bookings).
2. `v(S)` for every non-empty subset, including separate-car plans.
3. Exact Shapley by permutation, using `Decimal` in Python and integer paise in Dart.
4. Solo-fare ceiling, pro-rata redistribution, rejection if impossible.
5. Largest-remainder rounding so displayed shares sum exactly to the total.
6. Store the coalition table, raw shares, adjusted shares, cap flag and rounding adjustment so any fare can be reproduced.

### 2.5 Golden test vectors (₹20 start fee + ₹10/km, per-booking policy)

| Case | Expected |
|---|---|
| Case 1: A, B, C on one line to the same drop (4+3+5 km) | A 78.33, B 38.33, C 23.33, total 140 |
| Case 2: A 8 km, B 9 km, shared 12 km | A 65.00, B 75.00, total 140 |
| Case 3: A+C party km 0–8, B km 3–11 (per-booking) | A 32.50, C 32.50, B 65.00, total 130 |
| Case 4: A 0–7, B 4–14, C 9–14, shared 14 km | A 65.00, B 60.00, C 35.00, total 160 (my own calculation from `v(A)=90, v(B)=120, v(C)=70, v(AB)=160, v(AC)=160, v(BC)=120, v(ABC)=160`). `Test_cases.md` gives a different segment-split answer (61.67 / 66.67 / 31.67), so confirm the choice in Phase 0 |
| Case 5: B far from A and C | v(ABC) = 150 (B alone 70, A+C 80); nobody pays above their solo fare |
| 18% detour candidate | Rejected, failing passenger named |
| 4-person booking on a 4-seat car | available = 0, no join offered anywhere |

---

## 3. Phases

The work is split in two stages. **Stage A** produces a correct, fully working offline app (everything runs on the Dart engine and simulated services). **Stage B** swaps the simulated services for the real backend, login, OTP and payments without changing the UI.

### STAGE A: Correct engine and complete UI (offline)

#### Phase 0: Decisions and contracts (1 day)
- Lock the table in 1.3. Confirm the Case 4 policy.
- Write `contracts/` with OpenAPI draft, model JSON shapes, status machine, error codes and the first golden fixtures.
- Booking status machine: `SEARCHING → MATCHED/OFFERED → CONFIRMED → WAITING_PICKUP → ONBOARD → COMPLETED`, branches `CANCELLED`, `NO_VALID_MATCH`, `EXPIRED`, `REJECTED`, `ERROR`. "No valid match" and "error" are different outcomes.
- Audit table: run the 12 scenarios against the current app and record pass/fail.

#### Phase 1: Pure-Dart engine (3–4 days)
Files: `cost_model`, `route_optimizer` (brute force, pickup-before-drop, seat-based capacity, optional time windows), `detour_validator`, `shapley_calculator` (generic over the cost function), `fare_allocator`, `seat_ledger`.
Write the golden tests **first**. Exit: all vectors in 2.5 pass; raw shares sum to v(N); adjusted shares sum to the total.

#### Phase 2: Domain model, store, repository (2.5 days)
- Models listed in 2.2, including `VehicleType` (Auto 3 / Car 4 / Car XL 6 with its own rate multiplier), `Stop` (booking id, type, order, ETA, status, colour index) and the seat ledger on `Vehicle`.
- `RidePoolStore` streams `RidePoolSnapshot`; fill in `RidePoolRepository` (submit, trigger batch, cancel, respond to consent, verify OTP, pay).
- `MockRidePoolRepository` with a seeded RNG, built on the engine.
- All three cubits subscribe to the same store through `main.dart` injection.
- Exit: scenario 1 (3 people = 3 seats) and the full-car case pass; passenger, driver and ops views show identical seat numbers.

#### Phase 3: Booking flow UI (new features 2 and 3) (2.5 days)
- **Typed pickup/drop:** `PlaceSearchField` with 400 ms debounce, minimum 3 characters, cancellation of in-flight searches, "Recent", "Pune landmarks", "Choose on map" (tap and confirm pin), "Use my location", and swap. Uses the `PlaceSearchService` interface; Stage A implementation is fuzzy search over a local Pune places list. Selected places carry coordinates; free text never reaches matching.
- **Vehicle type picker:** Uber-style cards with icons (Auto 3 seats, Car 4 seats, Car XL 6 seats), price and ETA per type. Types smaller than the party size are disabled with a reason.
- **Party selector:** max = min(vehicle capacity, available seats), replacing the hardcoded 3. Shows "N passengers".
- Exit: choosing Auto with 4 people is blocked; seat gauge follows the chosen type.

#### Phase 4: Batching and matching (3 days)
- `Batcher`: rolling window with optional size trigger; requests arriving during optimization queue for the next batch; no request is processed twice.
- `ShareabilityFilter`: capacity, same vehicle type, pickup proximity, route and time overlap, preliminary detour.
- Replace `_generateSampleOffer()` with a real matcher that returns **Match Found**, **No Valid Match** (with reasons) or **Error**.
- UI: countdown, status chip, privacy-safe candidate IDs, seat-availability indicator, no final passenger count until validation completes. On no match: wait longer, another vehicle, or solo.
- Exit: scenarios 2 and 3.

#### Phase 5: Real fares and explanation (2 days)
- Replace every fake fare number with `FareAllocation` output.
- "Why am I paying this fare?" panel: solo fare, total cost, coalition table, marginal contributions, raw vs adjusted fare, cap flag, fixed-fee share, savings, and the plain-language Shapley explanation.
- Three cost views: solo, shared with per-passenger fares, mid-trip revised.
- Show an error rather than a fabricated fare when the engine cannot compute one.
- Exit: scenarios 4, 5, 12.

#### Phase 6: Map, occupancy and simulated vehicle (3 days)
- `LiveMapWidget`: one colour per booking; pickup marked P1/P2 and drop marked D1/D2; stop order numbers; legend; marker tap card.
- Route styles: proposed (dashed), confirmed (solid), rejected (red dashed), completed (faded). Auto-fit bounds; recentre button.
- Passenger view highlights their own stops and shows others with privacy-safe aliases; driver sees the full manifest; ops sees every vehicle.
- Seat occupancy bar with four visible states (onboard, reserved, held, free) on driver and ops screens.
- Driver boarding and drop-off update the store, which updates passenger tracking and ETAs.
- Simulated vehicle ticker along the route, labelled **Simulated**.
- Exit: three bookings show six correct markers; cancelling removes that passenger's markers; scenario 7 (occupancy part).

#### Phase 7: Cancellation, mid-trip insertion and consent (3.5 days)
- **Cancel before departure:** release seats, remove from group, re-run route and Shapley, notify affected riders, require consent for any fare increase.
- **During a trip:** freeze the completed prefix, re-optimize the rest, re-evaluate pending requests; completed fares are not recomputed.
- **Insertion pipeline order:** capacity → time window → 15% detour (existing and new riders) → only then fare and consent.
- `ConsentRequest` state machine: driver and affected passengers respond; commit only when all required approvals arrive; roll back on any decline or timeout; never silently change an accepted fare.
- UI: driver request sheet, passenger accept/decline updated plan sheet, cancellation confirmation, "what changed" banner.
- Exit: scenarios 6–11.

#### Phase 8: Ops console and honest benchmark (2.5 days)
- `GreedyBaseline` (nearest vehicle, proportional split) vs the optimizer on the same seed; delete hardcoded benchmark constants.
- Simulation settings: vehicles, capacity, window, seed, detour cap, speed multiplier.
- Event log and rejected-candidate inspector (capacity, precedence or detour reason).
- Report service rate, mean and p95 detour, total vehicle km. Label everything simulated and state how many vehicles and passengers were tested.

**Stage A checkpoint (about 21–23 days solo):** a complete, correct offline demo. Issues 3 (UI), 4, 5, 6 and the typed-search UI are done. You can demo to judges even if Stage B is not finished.

---

### STAGE B: Backend, login, OTP and payments (live mode)

#### Phase 9: Backend foundation and engine port (4 days)
- FastAPI, PostgreSQL, SQLAlchemy, Alembic, `docker-compose up` (API, Postgres, OSRM; Photon optional), `.env.example`, seed data (users, drivers, all three vehicle types around Pune).
- Port the engine to Python; make it pass the shared fixtures in CI.
- Services: OSRM routing with haversine fallback, geocoding proxy (`/places/search`, `/places/reverse`, Pune bounding box, cache, valid User-Agent), seat ledger with transactional row locks, matching scheduler, insertion, consent, notifications.
- WebSocket hub with events: `match_status, offer, otp_issued, vehicle_position, route_updated, seat_update, consent_request, consent_result, fare_updated, payment_status`.
- Server-side simulator moving vehicles along OSRM polylines; ops endpoints to inject requests, trigger batch, set speed, reset.

#### Phase 10: Login and roles (new feature 1) (2 days)
- Backend: register, login, refresh, logout, `/auth/me`; argon2/bcrypt hashes; JWT with role; `require_role` guards; passengers only see their own bookings; WebSocket authentication.
- Flutter: `AuthCubit`, secure token storage, splash → welcome (Passenger / Driver) → login/register; the driver registration asks for vehicle type, plate and licence number; router guards by role; Dio interceptor refreshes tokens.
- The old role switcher stays, but only behind a Demo flag. Mock auth uses fixed demo accounts, so Stage A screens keep working.

#### Phase 11: Ride-start OTP (new feature 7) (1 day)
- On `CONFIRMED`, create a 4-digit OTP per booking (salted hash, expiry, attempt counter). Passenger sees it on the "driver on the way" screen only after confirmation.
- Driver enters it at the pickup stop; the boarding button stays disabled until it verifies. Correct OTP moves the seat from reserved to occupied. Five wrong attempts lock the stop. OTP is invalidated on cancel or no-show.
- Mock mode generates and verifies OTPs locally; a demo-only "skip OTP" switch exists on the backend when `DEMO_MODE=true`.
- If you also want SMS OTP login, that needs an SMS provider and is a separate add-on.

#### Phase 12: Payments (new feature 8) (2 days)
- Flow: trip ends → final fare per booking (the exact Shapley paise value) → create Razorpay order → checkout → server verifies signature → webhook is the final authority (idempotent on `payment_id`) → receipt.
- Cash option (configurable), refunds for cancellation rules, payment history, driver earnings.
- **Platform caveat:** `razorpay_flutter` works on Android and iOS only. Web and Windows use a Razorpay Payment Link opened with `url_launcher`, or a "simulated payment" button in demo mode.
- The key secret lives only in the backend `.env`.

#### Phase 13: Live wiring and cut-over (2.5 days)
- `HttpRidePoolRepository` implements every contract; `WebSocketService` with reconnect and backoff feeds the same `RidePoolStore`.
- Dual-mode switch (Live Backend / Offline Simulation) kept as in the Flutter spec.
- Replace local `PlaceSearchService`, `AuthService` and `PaymentService` implementations with backend ones; the UI is untouched.
- Android emulator uses `10.0.2.2`; base URL set by flavour.

#### Phase 14: Hardening and demo (3 days)
- Integration tests for all 12 scenarios in both modes, plus auth, OTP and payment tests.
- Concurrency test: two simultaneous requests for the last seat, exactly one succeeds.
- One-click demo script following the acceptance sequence:
  login → type pickup/drop → choose Car → wait through the batch window → matched group → solo vs shared vs Shapley fares → "Why am I paying this fare?" → accept → OTP → driver boards → map shows all stops → mid-trip request with driver and passenger consent → fares update → cancel a passenger and recalculate → trip ends → pay.

---

## 4. Effort and ordering

| Stage | Phases | Effort (one dev) |
|---|---|---|
| A: offline engine and UI | 0–8 | about 21–23 days |
| B: backend, login, OTP, payments | 9–14 | about 14–15 days |
| **Total** | | **about 35–38 days solo, about 20–24 days with two developers** |

Parallel tracks with two people: one owns engine, store and fares (Phases 1, 2, 4, 5, 7); the other owns UI, map, search, vehicle picker and later auth and payments (Phases 3, 6, 8, 10, 12). Phase 1 is the critical path.

**Shortest path to fix what you reported:** Phases 0, 1, 2, 3, 5, 6 fix issues 2 (UI), 3, 4, 5 and 6 in roughly 14–15 days.

---

## 5. Risks

| Risk | Mitigation |
|---|---|
| Dart and Python engines diverge | Shared golden fixtures run in CI for both |
| A Shapley or detour bug breaks the demo | Golden tests are written before UI work |
| Haversine is not road distance | Labelled simulated in Stage A; OSRM in Stage B behind the same interface |
| State drift between cubits | Cubits only read the store |
| Fare cap breaks Shapley axioms | Show raw and adjusted fares separately; log every cap trigger |
| Case 4 policy disagreement between docs | Decided in Phase 0 and recorded in the fixtures |
| Razorpay SDK absent on web/desktop | Payment Link or simulated payment fallback |
| Double booking | Row locks, idempotency keys, disabled buttons in flight |
| Small demo mistaken for scale proof | Label vehicle and passenger counts; make no city-scale claims |
| Scope too large for the deadline | Stage A is a complete demo on its own; Stage B is incremental |

---

## 6. Optional extras (not requested, consider after Stage B)

- Push notifications (FCM) for offers and consent requests
- Rider and driver ratings after trip
- Share-trip link and SOS button
- No-show timer and cancellation fee rules
- Ride history with fare and detour audit (already in the Flutter spec)
- Accessibility pass (contrast, text scaling, screen-reader labels)

---

## 7. Definition of done

- [ ] No hardcoded offers, detours, fares or benchmark values remain in `lib/`.
- [ ] Every offer shown passed capacity, time-window and 15% detour validation.
- [ ] A full vehicle (any of the 3, 4, 6-seat types) offers no further joins; seats are counted per person.
- [ ] Shapley shares are reproducible from the stored coalition table, sum exactly to the total, and never exceed a rider's solo fare.
- [ ] Fares are identical on passenger, driver and ops screens.
- [ ] The map shows each booking's pickup and drop with its own colour and order number.
- [ ] Typed place search, vehicle type selection, login by role, ride-start OTP and payment all work in the flow.
- [ ] Cancellation and mid-trip insertion recalculate route and fares, with consent where required.
- [ ] "No valid match" and "error" are separate, visible outcomes.
- [ ] Benchmark runs both algorithms on the same seed.
- [ ] All 12 scenarios pass in offline and live modes.
- [ ] Simulated data is labelled as simulated everywhere in the UI.

---

## 8. Decisions Settled (Locked for Implementation)

| # | Question | Settled Decision | Rationale |
|---|---|---|---|
| 1 | Case 4 Pricing Policy | **Strict Shapley Value (₹65 / ₹60 / ₹35)** | Adheres to cooperative game theory axioms and marginal contributions over characteristic function $v(S)$, rather than naive segment splitting. |
| 2 | Backend & Engine Phasing | **Stage A in pure Dart first, then Python FastAPI in Stage B** | Guarantees an immediate 100% self-contained, zero-dependency working offline app with shared golden test fixtures before porting to live FastAPI. |
| 3 | Payment Timing | **Charge after trip completion** | Final exact Shapley fare is settled on drop-off receipt, allowing dynamic downward adjustments if pooled riders join mid-trip. |
| 4 | Vehicle Type Matching | **Strict vehicle matching** | Bookings are strictly pooled with rides of the exact vehicle type requested (Auto with Auto, Car with Car, Car XL with Car XL). |
| 5 | Environment & Database | **Local SQLite & in-process routing fallback** | System environment check confirmed Docker and PostgreSQL are not installed; Stage A runs 100% in Flutter/Dart, and Stage B backend supports SQLite/local runs. |
| 6 | Ops Role Access | **Demo / Inspector toggle for Ops** | Passenger and Driver roles have full authentication; Ops Fleet Console is accessible via a Demo toggle so judges/testers can inspect dispatch anytime. |

