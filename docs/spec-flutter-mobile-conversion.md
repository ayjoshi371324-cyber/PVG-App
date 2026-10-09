# Specification: Flutter & Dart Multi-Role Mobile Application Conversion

> **Label:** `ready-for-agent`  
> **Status:** Draft Spec  
> **Design Foundation:** `DESIGN-uber.md` (Uber-inspired black/white duet, pill geometry, crisp typography)  
> **Target Framework:** Flutter & Dart (Targeting Android, Windows/Web)  

---

## Problem Statement

Commuters travelling in similar directions often take solo rides due to the lack of transparent, predictable shared mobility solutions. Existing ride-pooling platforms suffer from unpredictable detours that frustrate riders and opaque pricing mechanisms that make split fares feel arbitrary. Concurrently, fleet operators lack intuitive mobile dispatch tools to monitor constrained ride pools and verify detour guarantees on the fly. 

The existing proof-of-concept for RidePool AI exists as a desktop/web application. Commuters and drivers operate primarily on mobile devices, making a web-only dashboard inadequate for real-world commuter booking, driver turn-by-turn stop execution, and mobile fleet management.

## Solution

A high-performance, cross-platform Flutter & Dart mobile application (`mobile/`) implementing an Uber-inspired aesthetic (`DESIGN-uber.md`). The application provides a unified multi-role interface with a role switcher catering to three personas:
1. **Passenger**: Search routes, participate in rolling dynamic batch matching, review detour guarantees (<=15%) with transparent Shapley-calculated fare savings, track active rides, and audit explainable fare receipts.
2. **Driver**: Turn-by-turn pickup/dropoff manifest execution, real-time cabin occupancy tracking, and mid-trip join consent approvals.
3. **Operations & Fleet Manager**: Live fleet map with vehicle markers, dynamic intake queue controls, synthetic request injection, and algorithmic vs. baseline comparative benchmark analytics.

The application operates in **Dual Mode**: seamlessly communicating with the Python FastAPI backend via REST/WebSockets when online, while embedding a high-fidelity mock/simulation engine for offline demos and automated testing.

---

## User Stories

### Passenger Experience
1. As a passenger, I want to toggle to Passenger Mode from the role switcher, so that I see an interface dedicated to booking and ride tracking.
2. As a passenger, I want to search and select pickup and drop-off locations using Pune landmark presets or map interaction, so that I can quickly set up my journey.
3. As a passenger, I want to see an upfront reference route preview with solo travel time, solo distance, and solo reference fare, so that I understand my baseline trip cost.
4. As a passenger, I want to specify the number of seats (party size) required, so that the pooling engine reserves adequate vehicle capacity.
5. As a passenger, I want to submit a ride request and enter an interactive matching buffer window with an active countdown timer (15 seconds default), so that I understand my request is being grouped with compatible commuters.
6. As a passenger, I want to cancel my pending request during the batch waiting window, so that I am not locked into a ride if my plans change.
7. As a passenger, I want to receive a pooled ride offer displaying the matched vehicle, co-passengers, guaranteed maximum detour percentage (strictly <= 15%), and estimated arrival time.
8. As a passenger, I want to inspect a transparent fare explanation card showing my solo fare, shared fare, and exact Shapley cost savings, so that I trust the financial benefit of sharing the ride.
9. As a passenger, I want to accept or decline the pooled ride offer within an acceptance timer window, so that the vehicle dispatch can proceed without delay.
10. As a passenger, I want to track the vehicle's live position on an OpenStreetMap view as it approaches my pickup location.
11. As a passenger, I want to see an interactive trip progression bar showing pickup, intermediate passenger stops, and my final drop-off stop.
12. As a passenger, I want to receive a prompt when a mid-trip passenger join request occurs that affects my route, so that I can confirm my detour remains within the guaranteed 15% ceiling.
13. As a passenger, I want to view a finalized explainable fare receipt upon reaching my destination, showing the exact coalition cost breakdown, solo vs. shared comparison, and carbon/kilometre savings.
14. As a passenger, I want to view my past trip history with fare breakdowns and detour audit metrics.

### Driver & Cabin Experience
15. As a driver, I want to switch to Driver Mode, so that I can view my assigned vehicle manifest and active passengers.
16. As a driver, I want to see an ordered sequence of pickup and drop-off stops with passenger names, seat counts, and ETA for the next stop.
17. As a driver, I want to confirm passenger boarding with a single pill-button tap, so that cabin occupancy updates in real-time.
18. As a driver, I want to confirm passenger drop-off, so that the ride completes and passenger fare receipts are generated.
19. As a driver, I want to see a visual cabin seat occupancy gauge (e.g., 3/4 seats occupied), so that I am always aware of available vehicle capacity.
20. As a driver, I want to receive alerts when a new passenger is dynamically inserted into my route during batch optimization.

### Operations & Fleet Console
21. As a fleet operator, I want to switch to Ops Mode, so that I have a macro overview of all fleet vehicles and request queues.
22. As a fleet operator, I want to view all vehicles, routes, and passenger pickup/drop-off pins simultaneously on the interactive map.
23. As a fleet operator, I want to monitor the dynamic request intake queue and see batch countdown timers in real-time.
24. As a fleet operator, I want to manually trigger the optimization batch runner immediately or inject synthetic passenger requests for stress testing.
25. As a fleet operator, I want to inspect per-passenger detour percentages and verify that zero active routes violate the 15% detour ceiling.
26. As a fleet operator, I want to compare algorithmic pooling metrics against a greedy nearest-vehicle baseline across total vehicle kilometres, passenger savings, and fleet utilization.

### General & Offline Simulation
27. As a presenter or evaluator, I want to toggle between Live Backend Mode and Offline Simulation Mode with a single switch, so that the app works reliably without a running Python backend.
28. As a user, I want the app to adhere to the Uber-inspired design tokens in `DESIGN-uber.md` (high-contrast monochrome palette, 999px pill action buttons, clean typography), so that the interface feels fast and modern.

---

## Implementation Decisions

### 1. Project Structure
- The Flutter application will reside in `mobile/` at the root of `PVG-App`.
- Core application layers:
  - `mobile/lib/core/` (Theme tokens from `DESIGN-uber.md`, networking, constants)
  - `mobile/lib/data/` (Models, API contracts, local storage, mock data generator)
  - `mobile/lib/repositories/` (Abstract `RidePoolRepository`, `HttpRidePoolRepository`, `MockRidePoolRepository`)
  - `mobile/lib/blocs/` (Cubit state machines: `RoleCubit`, `PassengerCubit`, `DriverCubit`, `FleetOpsCubit`)
  - `mobile/lib/views/` (`passenger/`, `driver/`, `ops/`, `common/`)
  - `mobile/lib/widgets/` (Reusable Uber-style widgets: `PillButton`, `BottomDrawerSheet`, `MetricChip`, `LiveMapWidget`)

### 2. State Management Architecture
- Utilizes `flutter_bloc` / `Cubit` for unidirectional, testable state management.
- `PassengerCubit` state machine:
  `Idle` -> `RoutePlanning` -> `BatchWaiting(countdown)` -> `OfferReceived(offer)` -> `TripActive(tripState)` -> `TripCompleted(receipt)`.
- `DriverCubit` manages current vehicle manifest, stop progression, and passenger check-ins.
- `FleetOpsCubit` manages fleet simulation ticks, synthetic injections, and benchmark metrics.

### 3. Mapping & Geospatial Engine
- Employs `flutter_map` with OpenStreetMap tile rendering.
- Polylines rendered using decoded route coordinates matching Pune road networks.
- Vehicle and stop markers styled with custom crisp vector pin widgets.

### 4. Design System (`DESIGN-uber.md` Compliance)
- **Palette**: Deep Black (`#000000`), Pure White (`#ffffff`), Neutral Body Text (`#5e5e5e`), Canvas Soft (`#efefef`), Surface Pressed (`#e2e2e2`).
- **Corner Radii**: Signature `999px` pill on buttons, chips, and active tabs; `16px` on elevated bottom sheets and cards.
- **Elevation & Depth**: Flat clean layers, zero unnecessary gradients, high-contrast borders (`#efefef`), and crisp typography.

### 5. API Contracts & Dual Mode
- Standardized REST / WebSocket contracts matching `backend/app/api/`:
  - `POST /api/routing/route`: Point-to-point routing and solo fare estimation.
  - `POST /api/simulation/request`: Submit passenger request.
  - `POST /api/simulation/batch/trigger`: Trigger dynamic batch optimization.
  - `GET /api/simulation/state`: Full fleet, vehicle, and active trips status.
- `MockRidePoolRepository` mirrors these exact endpoints in pure Dart for offline simulation.

---

## Testing Decisions

### Testing Philosophy & Seams
- **Single High-Level Seam:** The boundary between UI Cubits and the `RidePoolRepository` interface serves as the primary testing seam.
- Tests will exercise external behavior (state transitions, UI reactions to domain events) rather than private widget internal states.

### Modules to Test
1. **Repository & Serialization Unit Tests**: Verify JSON encoding/decoding of ride requests, Shapley fair-fare breakdown objects, and stop sequences.
2. **Cubit State Machine Tests**:
   - `PassengerCubitTest`: Request creation -> dynamic batch countdown -> offer receipt -> accept -> trip completion.
   - Detour constraint guarantee: verify state throws or rejects offers when detour exceeds 15.0%.
3. **Widget & Integration Tests**:
   - Role switcher interaction.
   - Bottom sheet display of Shapley fare explanation card.
   - Detour badge styling and indicator behavior.

### Prior Art
- Mirrors the backend test suite structure in `backend/tests/` (`test_route_optimization.py`, `test_dynamic_batching.py`, `test_simulation_optimization_api.py`).

---

## Out of Scope

- Real-money payment processing (Stripe / Razorpay).
- Production SMS / OTP authentication and driver background checks.
- Native background GPS geofencing or battery-optimized background location daemons.
- Multi-city road networks outside the Pune pilot bounding box.

---

## Further Notes

- The project is ready for immediate scaffolding in `mobile/`.
- Development and validation can be previewed on Windows Desktop (`flutter run -d windows`) or Chrome (`flutter run -d chrome`) without needing an Android emulator running initially.
