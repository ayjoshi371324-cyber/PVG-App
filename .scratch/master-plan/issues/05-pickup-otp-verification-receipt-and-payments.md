# 05: Pickup OTP Verification, Ride Completion, Receipt & Payments

**What to build:**
A secure boarding verification and post-trip settlement pipeline. Generates a secure 4-digit pickup OTP for confirmed passengers that drivers must verify at the curb before boarding riders into the vehicle. Upon reaching the final destination, the trip completes, issuing an audit-ready receipt with finalized Shapley paise amounts and environmental CO2 metrics. Passengers can settle the payment via Razorpay test mode, hosted payment links, or a simulated checkout fallback on desktop/web platforms.

**Blocked by:** 03: Explainable Shapley Fair-Fare Offer & Multi-Passenger Live Map, 04: Mid-Trip Insertion, Dynamic Consent & In-Flight Rebalancing

**Status:** done

- [x] Generates a unique 4-digit OTP upon booking confirmation; displays OTP card on the passenger's tracking screen once driver is en route.
- [x] Driver view provides an OTP entry keypad at pickup stops; boarding the passenger is disabled until the OTP is successfully verified.
- [x] Successful OTP verification transitions the booking from `WAITING_PICKUP` to `ONBOARD`, shifting seats from `reserved` to `occupied` in the seat ledger.
- [x] 5 consecutive invalid OTP attempts lock the stop, requiring manual override; demo mode includes a single-tap "Bypass OTP" shortcut.
- [x] Trip completion triggers generation of the final receipt showing itemized solo vs. pooled fare, exact paise Shapley settlement, driver payout, and CO2 / fuel saved.
- [x] Payment sheet supports Razorpay test mode checkout (UPI, Card, Netbanking) on mobile and a hosted Payment Link / simulated payment fallback on web and desktop, persisting transaction status to the store.
