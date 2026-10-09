import 'dart:convert';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository interface for persisting and retrieving completed ride receipts.
abstract class TripHistoryRepository {
  Future<void> saveReceipt(TripReceipt receipt);
  Future<List<TripReceipt>> getTripHistory();
  Future<void> clearHistory();
}

/// Local implementation backed by SharedPreferences for offline persistence.
class LocalTripHistoryRepository implements TripHistoryRepository {
  LocalTripHistoryRepository({SharedPreferences? preferences})
      : _prefs = preferences;

  SharedPreferences? _prefs;
  static const String _storageKey = 'ridepool_trip_history_v1';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveReceipt(TripReceipt receipt) async {
    final prefs = await _getPrefs();
    final existingHistory = await getTripHistory();
    // Prepend receipt so newest appears first, deduplicating by receiptId
    final updatedList = [
      receipt,
      ...existingHistory.where((r) => r.receiptId != receipt.receiptId),
    ];

    final encoded = jsonEncode(updatedList.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<List<TripReceipt>> getTripHistory() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) return [];

    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => TripReceipt.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_storageKey);
  }
}
