# 04: Mid-Trip Insertion, Dynamic Consent & In-Flight Rebalancing

**What to build:**
Dynamic lifecycle management for mid-trip joins and ride cancellations. When a new passenger requests to join an in-flight vehicle, the engine checks segment-by-segment cabin capacity and verifies that no existing passenger exceeds the 15% detour limit. If feasible, a multi-party consent protocol prompts both the driver and affected passengers with clear route and fare delta previews. Cancellations release seats dynamically and trigger automatic re-optimization of remaining stops and fair-fare reallocations.

**Blocked by:** 01: Core Game-Theory Engine, Dynamic Seat Ledger & Golden Fixtures, 03: Explainable Shapley Fair-Fare Offer & Multi-Passenger Live Map

**Status:** done

- [x] Mid-trip insertion engine evaluates candidate pickup/dropoff insertions along the vehicle's remaining route, strictly rejecting requests exceeding 15% detour or seat capacity.
- [x] Valid insertion triggers a multi-party consent request with a 30s countdown, notifying the driver and all existing riders whose route or ETA is impacted.
- [x] Consent sheet displays the explicit delta: updated ETA, detour change, and updated (discounted) fare.
- [x] Inserting a rider requires approval from all required parties; any rejection or timeout cleanly rolls back the proposed route without altering active trips.
- [x] Pre-departure cancellation removes the passenger from the active pool, releases their held/reserved seats in the ledger, and rebalances the remaining route and Shapley fares.
- [x] Mid-trip cancellation freezes completed prefixes, re-optimizes the pending leg, and adjusts fares with re-consent if remaining riders' costs change.
