# 06: Final Trip Receipt, Shapley Audit & Trip History

**What to build:**
Upon reaching the destination, transition the passenger to a comprehensive fare receipt screen styled after Uber's receipt aesthetics. Show the final payable fare, solo reference comparison, net savings, environmental impact (estimated CO2 and vehicle-km reduction), and an expandable Shapley coalition cost breakdown. Persist completed rides to local history so riders can review past journeys anytime.

**Blocked by:** 05: Live Trip Tracking & Mid-Trip Join Consent

**Status:** ready-for-agent

- [ ] Destination arrival triggers the final trip completion screen.
- [ ] Explainable fare receipt displays solo fare, shared discount, final charge, and carbon savings metrics.
- [ ] Expandable coalition table shows the marginal contribution and Shapley cost allocation for each passenger in the pool.
- [ ] Completed trips are saved in local storage (shared_preferences / sqlite) for offline review.
- [ ] Trip history screen displays past rides with expandable receipts.
- [ ] Tests verify receipt calculation displays, local persistence, and trip history list rendering.
