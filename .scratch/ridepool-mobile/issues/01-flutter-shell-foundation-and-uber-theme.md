# 01: Flutter Shell Foundation, Uber Theme Tokens & Multi-Role Navigation

**What to build:** 
Initialize the Flutter project structure and establish the root application shell. Implement the complete Uber-inspired design tokens from `DESIGN-uber.md` (high-contrast black/white palette, signature 999px pill shapes on interactive elements, crisp geometric typography, and elevated card surfaces). Build the persistent top-level role switcher allowing instantaneous switching between Passenger Mode, Driver Mode, and Ops Console.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] Flutter project structure initialized in `mobile/` with core directories (`core/`, `data/`, `blocs/`, `views/`, `widgets/`).
- [x] Uber design system implemented in `mobile/lib/core/theme.dart` reflecting `DESIGN-uber.md` color palette, 999px pill geometry, and typography styles.
- [x] Persistent role navigation bar / switcher toggles between Passenger, Driver, and Operations modes smoothly.
- [x] Reusable signature widgets (`PillButton`, `MetricBadge`, `UberCard`, `BottomDrawerSheet`) implemented and verified.
- [x] Unit and widget tests pass verifying theme token adherence and role-switching state transitions.
