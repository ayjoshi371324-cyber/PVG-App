import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/services/place_search_service.dart';

/// Place Search Input Field with:
/// - 400ms debounced autocomplete
/// - Minimum 3 characters threshold
/// - Cancellation of in-flight searches
/// - Recent locations & Pune landmarks presets
/// - Tap-to-confirm map pin selector action
/// - Strict coordinate validation: free-form text never escapes to the engine
class PlaceSearchField extends StatefulWidget {
  PlaceSearchField({
    super.key,
    required this.label,
    required this.selectedLocation,
    required this.isPickup,
    PlaceSearchService? searchService,
    required this.onLocationSelected,
    this.onChooseOnMapTap,
    this.focusNode,
  }) : searchService = searchService ?? LocalPlaceSearchService();

  final String label;
  final PuneLocation? selectedLocation;
  final bool isPickup;
  final PlaceSearchService searchService;
  final ValueChanged<PuneLocation> onLocationSelected;
  final VoidCallback? onChooseOnMapTap;
  final FocusNode? focusNode;

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;

  Timer? _debounceTimer;
  int _searchEpoch = 0;
  bool _isLoading = false;
  List<PuneLocation> _searchResults = const [];
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedLocation?.name ?? '',
    );
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(PlaceSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLocation != oldWidget.selectedLocation &&
        !_focusNode.hasFocus) {
      _controller.text = widget.selectedLocation?.name ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isDropdownOpen = _focusNode.hasFocus;
      if (!_focusNode.hasFocus) {
        // Reset text back to selected location if unfocused without selection
        if (widget.selectedLocation != null) {
          _controller.text = widget.selectedLocation!.name;
        }
      }
    });
  }

  void _onTextChanged(String text) {
    _debounceTimer?.cancel();

    final query = text.trim();
    if (query.length < 3) {
      setState(() {
        _isLoading = false;
        _searchResults = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final currentEpoch = ++_searchEpoch;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await widget.searchService.search(query);
      if (mounted && currentEpoch == _searchEpoch) {
        setState(() {
          _isLoading = false;
          _searchResults = results;
        });
      }
    });
  }

  void _selectLocation(PuneLocation location) {
    _debounceTimer?.cancel();
    widget.searchService.recordRecentSearch(location);
    _controller.text = location.name;
    widget.onLocationSelected(location);
    _focusNode.unfocus();
    setState(() {
      _isDropdownOpen = false;
      _searchResults = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyName = widget.isPickup ? 'pickup' : 'dropoff';
    final recents = widget.searchService.getRecentSearches();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main input row
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: UberColors.ink,
                shape: widget.isPickup ? BoxShape.circle : BoxShape.rectangle,
              ),
            ),
            const SizedBox(width: UberSpacing.md),
            Expanded(
              child: TextField(
                key: Key('place_search_input_$keyName'),
                controller: _controller,
                focusNode: _focusNode,
                style: UberTypography.bodyMdStrong,
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: widget.isPickup
                      ? 'Search pickup location'
                      : 'Search destination',
                  hintStyle: UberTypography.bodyMd.copyWith(
                    color: UberColors.mute,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  UberColors.ink,
                                ),
                              ),
                            ),
                          ),
                        )
                      : (_controller.text.isNotEmpty && _focusNode.hasFocus)
                          ? IconButton(
                              key: Key('clear_search_${keyName}_button'),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _controller.clear();
                                _onTextChanged('');
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                ),
              ),
            ),
          ],
        ),

        // Autocomplete suggestions dropdown
        if (_isDropdownOpen) ...[
          const Divider(height: 1, color: UberColors.canvasSoft),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Material(
              color: UberColors.canvas,
              borderRadius: UberRadii.md,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                // 1. Choose on map action tile
                ListTile(
                  key: const Key('choose_on_map_button'),
                  leading: const Icon(
                    Icons.pin_drop_rounded,
                    color: UberColors.primary,
                    size: 20,
                  ),
                  title: Text(
                    'Choose location on map',
                    style: UberTypography.bodyMdStrong.copyWith(fontSize: 13),
                  ),
                  subtitle: Text(
                    'Tap to position and confirm exact map pin',
                    style: UberTypography.caption,
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  onTap: () {
                    _focusNode.unfocus();
                    setState(() {
                      _isDropdownOpen = false;
                    });
                    widget.onChooseOnMapTap?.call();
                  },
                ),

                // 2. Active autocomplete matches if query >= 3 chars
                if (_controller.text.trim().length >= 3) ...[
                  if (_searchResults.isEmpty && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(UberSpacing.sm),
                      child: Text(
                        'No Pune landmarks matching "${_controller.text}"',
                        style: UberTypography.caption,
                      ),
                    ),
                  for (final loc in _searchResults)
                    ListTile(
                      leading: Icon(
                        widget.isPickup
                            ? Icons.radio_button_checked
                            : Icons.stop_rounded,
                        color: UberColors.ink,
                        size: 18,
                      ),
                      title: Text(
                        loc.name,
                        style: UberTypography.bodyMdStrong.copyWith(fontSize: 13),
                      ),
                      subtitle: loc.landmarkNote != null
                          ? Text(loc.landmarkNote!, style: UberTypography.caption)
                          : null,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onTap: () => _selectLocation(loc),
                    ),
                ] else ...[
                  // 3. Recent locations & Presets section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      'Recent & Presets',
                      style: UberTypography.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: UberColors.mute,
                      ),
                    ),
                  ),
                  for (final loc in recents)
                    ListTile(
                      leading: const Icon(
                        Icons.history_rounded,
                        color: UberColors.body,
                        size: 18,
                      ),
                      title: Text(
                        loc.name,
                        style: UberTypography.bodyMdStrong.copyWith(fontSize: 13),
                      ),
                      subtitle: loc.landmarkNote != null
                          ? Text(loc.landmarkNote!, style: UberTypography.caption)
                          : null,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onTap: () => _selectLocation(loc),
                    ),
                  // Fallback Pune Landmarks if recents are empty
                  if (recents.isEmpty)
                    for (final loc in PuneLandmarks.all.take(3))
                      ListTile(
                        leading: const Icon(
                          Icons.near_me_outlined,
                          color: UberColors.body,
                          size: 18,
                        ),
                        title: Text(
                          loc.name,
                          style:
                              UberTypography.bodyMdStrong.copyWith(fontSize: 13),
                        ),
                        subtitle: loc.landmarkNote != null
                            ? Text(loc.landmarkNote!,
                                style: UberTypography.caption)
                            : null,
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        onTap: () => _selectLocation(loc),
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
      ],
    );
  }
}
