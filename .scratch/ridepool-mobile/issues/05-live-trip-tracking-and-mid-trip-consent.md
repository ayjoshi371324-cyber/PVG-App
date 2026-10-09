# 05: Live Trip Tracking & Mid-Trip Join Consent

**What to build:**
Following offer acceptance, transition the passenger into live trip tracking. Display the vehicle's position advancing along the planned polyline, upcoming pickup/dropoff stops, and an interactive trip progression bar. If a new passenger joins the route mid-trip, trigger an in-app alert informing the existing rider, verifying that the new pickup maintains their <= 15% detour guarantee, and providing a two-way consent modal.

**Blocked by:** 04: Fair-Fare Offer Card with Shapley Breakdown & Detour Guarantee

**Status:** ready-for-agent

- [ ] Live map displays the dispatched vehicle moving along the assigned multi-stop route.
- [ ] Visual progress indicator shows upcoming passenger pickup and dropoff milestones.
- [ ] Mid-trip join event displays a notification sheet detailing the newly added rider and re-verifying the <= 15% detour guarantee.
- [ ] Two-way consent dialog allows riders to approve the route adjustment.
- [ ] Tests verify event handling for vehicle movement, waypoint completion, and mid-trip join consent dialogs.
