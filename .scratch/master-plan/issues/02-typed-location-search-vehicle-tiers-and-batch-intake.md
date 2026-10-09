# 02: Typed Location Search, Vehicle Tiers & Combinatorial Batch Intake

**What to build:**
A streamlined ride booking intake flow that enables passengers to search and select pickup/dropoff locations with debounced text input, choose between distinct vehicle tiers with real-time capacity and fare previews, and enter a rolling batch intake queue. The matching engine evaluates pooled groups combinatorially rather than generating hardcoded mocks, enforcing vehicle tier boundaries (strict matching: Auto with Auto, Car with Car, Car XL with Car XL) and party-size limits.

**Blocked by:** 01: Core Game-Theory Engine, Dynamic Seat Ledger & Golden Fixtures

**Status:** done

- [x] `PlaceSearchField` provides debounced (400ms) autocomplete search across Pune landmarks, recent locations, and a tap-to-confirm map pin selector.
- [x] Selected pickup and dropoff points resolve to validated coordinates before reaching the matching engine (no free-form raw text sent).
- [x] Vehicle tier selector displays Auto (3 seats, 0.8× base multiplier), Car (4 seats, 1.0× multiplier), and Car XL (6 seats, 1.4× multiplier) with real-time estimated fares and ETAs.
- [x] Vehicle tiers with capacity smaller than the requested party size are visibly disabled with explanatory helper text.
- [x] Rolling batch intake queue holds incoming requests for a configurable window (15–90s) and runs combinatorial group evaluation against active vehicles.
- [x] Matching outcomes produce discrete, truthful states: **Match Found**, **No Valid Match** (with explicit reasons: >15% detour, capacity, or time window), or **Solo Direct Ride**.
