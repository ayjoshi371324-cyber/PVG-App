# 04: Fair-Fare Offer Card with Shapley Breakdown & Detour Guarantee

**What to build:**
When batch optimization yields an assignment, present the passenger with an elevated Uber-styled offer card. The card features matched vehicle information, co-passenger count, route ETA, guaranteed detour percentage (prominently labeled with a strict `<= 15%` guarantee badge), and a transparent Shapley fair-fare breakdown comparing the solo fare vs. shared discounted fare with net savings highlighted. Passengers can accept or decline within a 20-second offer expiry window.

**Blocked by:** 03: Dynamic Batch Intake Queue & Waiting Countdown

**Status:** ready-for-agent

- [ ] Elevated bottom sheet renders the matched pooled ride offer.
- [ ] Detour guarantee pill badge highlights the exact detour percentage and certifies that detour is <= 15.0%.
- [ ] Shapley fair-fare comparison breakdown displays solo baseline fare, shared pooled fare, and calculated savings (₹ and %).
- [ ] Accept and Decline pill action buttons with a countdown timer for offer decision expiry.
- [ ] Unit and widget tests verify that detour percentages exceeding 15% are rejected and fare savings calculations are mathematically accurate.
