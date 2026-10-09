# 02: Pune Interactive Map & Solo Route Estimator

**What to build:**
An interactive map view powered by `flutter_map` (OpenStreetMap) centered on the Pune metropolitan bounding box. Enable passengers to search, select, or tap pickup and destination points (with quick Pune landmark presets such as Shivaji Nagar, Hinjawadi Phase 1, Koregaon Park, Swargate). Calculate and display the solo reference route on the map with polyline rendering, solo distance, estimated solo travel duration, and baseline solo reference fare.

**Blocked by:** 01: Flutter Shell Foundation, Uber Theme Tokens & Multi-Role Navigation

**Status:** ready-for-agent

- [ ] `flutter_map` interactive map widget embedded with free OpenStreetMap tile rendering centered on Pune coordinates.
- [ ] Landmark selection chips with quick presets for key Pune transit hubs.
- [ ] Solo route calculation displays estimated distance (km), travel duration (mins), and reference solo fare (₹).
- [ ] Route polyline renders cleanly on the map with custom pickup (black circular dot) and drop-off (square stop pin) markers.
- [ ] Tests verify accurate route distance formatting, solo fare formula calculations, and map state initialization.
