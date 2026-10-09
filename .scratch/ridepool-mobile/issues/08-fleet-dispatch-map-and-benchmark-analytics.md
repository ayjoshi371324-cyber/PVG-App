# 08: Fleet Dispatch Map, Batch Optimizer & Benchmark Analytics

**What to build:**
The Operations & Fleet Manager interface on mobile. Displays a comprehensive map showing all fleet vehicles, active pooled routes, and passenger markers. Provides controls to inspect the dynamic intake queue, trigger batch optimization immediately, or inject synthetic passenger requests for stress-testing. Features a side-by-side benchmark card comparing Algorithmic Pooling against a Greedy Nearest-Vehicle baseline across vehicle-km, detour bounds compliance, and passenger fare savings.

**Blocked by:** 03: Dynamic Batch Intake Queue & Waiting Countdown, 07: Driver Route Manifest, Stop Progression & Cabin Occupancy

**Status:** completed

- [x] Fleet overview map displays all vehicles with live status badges (idle, picking up, in pool).
- [x] Ops controls allow triggering the batch optimization engine manually.
- [x] Synthetic passenger request generator injects test demand scenarios into the intake queue.
- [x] Comparative analytics dashboard cards display Algorithmic Pooling vs. Greedy Baseline metrics side-by-side.
- [x] Detour guarantees inspector verifies that 100% of active routes comply with the <= 15% detour ceiling.
- [x] Tests verify fleet data parsing, simulation trigger dispatches, and benchmark metric calculations.
