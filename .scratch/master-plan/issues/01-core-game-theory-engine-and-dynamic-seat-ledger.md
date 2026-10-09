# 01: Core Game-Theory Engine, Dynamic Seat Ledger & Golden Fixtures

**What to build:**
A deterministic, pure-Dart ride-pooling and fair-fare allocation engine with an exact seat ledger. This engine acts as the computational brain for all pooling, routing, seat availability, and pricing decisions. It enforces strict cooperative game theory via exact Shapley values, calculates characteristic functions v(S) across feasible vehicle coalitions, guarantees detour limits <=15%, applies solo-fare ceilings, and resolves rounding via the largest-remainder method. It also introduces a dynamic seat ledger that models occupied, reserved, and temporary held seats to completely prevent overbooking and eliminate the legacy 3-person seat bug.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Shared golden fixtures (`golden_fares.json`) defining exact cost, detour, and Shapley test vectors for Golden Cases 1–5 pass all test assertions.
- [x] Brute-force route permutation optimizer correctly orders stops respecting precedence (pickup before dropoff) and vehicle seat capacity.
- [x] Exact Shapley value allocator divides the coalition cost efficiently (`Σ shares == v(N)`) with largest-remainder paise rounding (`sum(paise) == totalCost`).
- [x] Solo-fare ceiling cap ensures no passenger ever pays more than their solo direct trip cost; plans violating this or exceeding 15% detour are rejected.
- [x] Seat ledger accurately computes `available = capacity - occupied - reserved - held` per vehicle; joining or booking when `party_size > available` is strictly rejected.
- [x] All golden fixture test cases (Case 1: 78.33/38.34/23.33, Case 2: 65/75, Case 3: 32.50/32.50/65.00, Case 4: 65/60/35, Case 5: 150) pass with 100% precision.
