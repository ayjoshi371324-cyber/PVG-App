# 03: Explainable Shapley Fair-Fare Offer & Multi-Passenger Live Map

**What to build:**
A transparent offer presentation and live multi-passenger map visualization. Replaces artificial discount multipliers with genuine Shapley Fair-Fare offers backed by mathematical coalition data. An interactive breakdown sheet explains why each passenger pays their specific share, highlighting solo vs. shared savings and detour guarantees. Upon acceptance, the live map renders all passengers' stops with distinct high-contrast colors, ordered stop numbers, and visual polyline states.

**Blocked by:** 01: Core Game-Theory Engine, Dynamic Seat Ledger & Golden Fixtures, 02: Typed Location Search, Vehicle Tiers & Combinatorial Batch Intake

**Status:** ready-for-agent

- [ ] Pooled ride offer displays exact Shapley calculated fare, per-person cost for parties, and honest detour percentage (strictly <=15%).
- [ ] Expandable *"Why am I paying this fare?"* sheet displays solo baseline fare, total pooled route cost, marginal contribution per passenger, fixed fee share, and the characteristic function coalition table.
- [ ] Sum of all passenger shares shown on the offer card matches the total vehicle route cost exactly to the nearest rupee/paise.
- [ ] Live map assigns a unique high-contrast color per booking and renders numbered markers (P1/D1, P2/D2) indicating exact pickup and dropoff sequences.
- [ ] Map renders confirmed route polylines in solid styling, proposed modifications in dashed styling, and completed segments in faded tones.
- [ ] Stop list legend displays passenger aliases (privacy-safe, e.g. "Rider A"), party sizes, ETAs, and auto-fits map bounds to all active route waypoints.
