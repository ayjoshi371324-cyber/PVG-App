import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';

void main() {
  group('SeatLedger Accounting Tests', () {
    test('Initializes with full availability for vehicle capacity', () {
      final ledger = SeatLedger.empty(capacity: 4);

      expect(ledger.capacity, equals(4));
      expect(ledger.occupied, equals(0));
      expect(ledger.reserved, equals(0));
      expect(ledger.held, equals(0));
      expect(ledger.available, equals(4));
      expect(ledger.isFull, isFalse);
    });

    test('3-person booking reserves 3 seats on a 4-seater car', () {
      var ledger = SeatLedger.empty(capacity: 4);

      expect(ledger.canAccommodate(3), isTrue);
      ledger = ledger.holdSeats(bookingId: 'b1', partySize: 3);

      expect(ledger.held, equals(3));
      expect(ledger.available, equals(1));
      expect(ledger.canAccommodate(2), isFalse);
      expect(ledger.canAccommodate(1), isTrue);

      ledger = ledger.confirmSeats(bookingId: 'b1', partySize: 3);
      expect(ledger.held, equals(0));
      expect(ledger.reserved, equals(3));
      expect(ledger.available, equals(1));
    });

    test('Full 4-seat car strictly blocks further joins (fixes Issue 5)', () {
      var ledger = SeatLedger.empty(capacity: 4);

      // Book 2 seats
      ledger = ledger.holdSeats(bookingId: 'b1', partySize: 2);
      ledger = ledger.confirmSeats(bookingId: 'b1', partySize: 2);

      // Book another 2 seats
      ledger = ledger.holdSeats(bookingId: 'b2', partySize: 2);
      ledger = ledger.confirmSeats(bookingId: 'b2', partySize: 2);

      expect(ledger.reserved, equals(4));
      expect(ledger.available, equals(0));
      expect(ledger.isFull, isTrue);

      // Attempting to hold even 1 seat is strictly blocked
      expect(ledger.canAccommodate(1), isFalse);
      expect(
        () => ledger.holdSeats(bookingId: 'b3', partySize: 1),
        throwsStateError,
      );
    });

    test('Transitions from reserved to occupied when passenger boards', () {
      var ledger = SeatLedger.empty(capacity: 6) // Car XL
          .holdSeats(bookingId: 'b1', partySize: 4)
          .confirmSeats(bookingId: 'b1', partySize: 4);

      expect(ledger.reserved, equals(4));
      expect(ledger.occupied, equals(0));

      ledger = ledger.boardSeats(bookingId: 'b1', partySize: 4);
      expect(ledger.reserved, equals(0));
      expect(ledger.occupied, equals(4));
      expect(ledger.available, equals(2));
    });

    test('Releasing seats on cancellation restores availability immediately', () {
      var ledger = SeatLedger.empty(capacity: 3) // Auto
          .holdSeats(bookingId: 'b1', partySize: 2);

      expect(ledger.available, equals(1));

      ledger = ledger.releaseHeldSeats(bookingId: 'b1', partySize: 2);
      expect(ledger.held, equals(0));
      expect(ledger.available, equals(3));
    });

    test('Expired holds are cleaned up correctly', () {
      final now = DateTime.now();
      var ledger = SeatLedger.empty(capacity: 4).holdSeats(
        bookingId: 'b1',
        partySize: 2,
        expiresAt: now.subtract(const Duration(seconds: 10)),
      );

      expect(ledger.available, equals(2));
      ledger = ledger.purgeExpiredHolds(currentTime: now);
      expect(ledger.held, equals(0));
      expect(ledger.available, equals(4));
    });
  });
}
