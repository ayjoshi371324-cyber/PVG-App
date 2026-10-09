# 03: Dynamic Batch Intake Queue & Waiting Countdown

**What to build:**
The passenger ride booking flow with seat selection (party size 1–3). Upon tapping "Find Shared Pool", the request enters a dynamic request buffer window with an animated 15-second countdown timer. The passenger sees the batch aggregation state in real-time, accompanied by an option to cancel the pending request prior to optimization batch closure.

**Blocked by:** 02: Pune Interactive Map & Solo Route Estimator

**Status:** completed

- [x] Party size counter (1 to 3 passengers) integrated into the booking sheet with capacity validation.
- [x] Transition into `BatchWaiting` state displaying a circular / linear countdown progress bar for the rolling buffer window.
- [x] Informational status text explaining the dynamic batch grouping logic in simple terms.
- [x] Cancel button allows the passenger to withdraw the request before the batch window closes.
- [x] Tests verify countdown tick events, timeout triggers, and cancellation state transitions.
