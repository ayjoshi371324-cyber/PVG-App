import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/boarding_verification_engine.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';

void main() {
  group('BoardingVerificationEngine Tests', () {
    late BoardingVerificationEngine engine;

    setUp(() {
      engine = const BoardingVerificationEngine();
    });

    test('generateOtp returns a 4-digit numeric string', () {
      final otp = engine.generateOtp();
      expect(otp.length, equals(4));
      expect(int.tryParse(otp), isNotNull);
      expect(int.parse(otp), inInclusiveRange(1000, 9999));
    });

    test('cleanCode normalizes hashes, spaces, and formatting', () {
      expect(engine.cleanCode('#4821'), equals('4821'));
      expect(engine.cleanCode('  4821  '), equals('4821'));
      expect(engine.cleanCode('# 9104 '), equals('9104'));
      expect(engine.cleanCode('1234'), equals('1234'));
    });

    test('verifyOtp returns success when entered matches expected', () {
      final result = engine.verifyOtp(
        enteredOtp: '4821',
        expectedOtp: '#4821',
        currentFailedAttempts: 2,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isLocked, isFalse);
      expect(result.newFailedAttempts, equals(0));
      expect(result.errorMessage, isNull);
    });

    test('verifyOtp increments failed attempts on mismatch', () {
      final result = engine.verifyOtp(
        enteredOtp: '0000',
        expectedOtp: '#4821',
        currentFailedAttempts: 2,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isLocked, isFalse);
      expect(result.newFailedAttempts, equals(3));
      expect(result.remainingAttempts, equals(2));
      expect(result.errorMessage, contains('2 attempts remaining'));
    });

    test('5 consecutive failed attempts lock the stop', () {
      final result = engine.verifyOtp(
        enteredOtp: '1111',
        expectedOtp: '#4821',
        currentFailedAttempts: 4,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isLocked, isTrue);
      expect(result.newFailedAttempts, equals(5));
      expect(result.remainingAttempts, equals(0));
      expect(result.errorMessage, contains('Stop locked'));
    });

    test('further attempts on locked stop remain locked', () {
      final result = engine.verifyOtp(
        enteredOtp: '4821',
        expectedOtp: '#4821',
        currentFailedAttempts: 5,
      );

      expect(result.isSuccess, isFalse);
      expect(result.isLocked, isTrue);
      expect(result.errorMessage, contains('locked'));
    });

    test('manualOverride resets lockout and failed attempts count', () {
      final result = engine.manualOverride();
      expect(result.isSuccess, isFalse);
      expect(result.isLocked, isFalse);
      expect(result.newFailedAttempts, equals(0));
      expect(result.remainingAttempts, equals(5));
    });

    test('bypassOtp returns demo success and resets lock', () {
      final result = engine.bypassOtp();
      expect(result.isSuccess, isTrue);
      expect(result.isBypassed, isTrue);
      expect(result.isLocked, isFalse);
      expect(result.newFailedAttempts, equals(0));
    });

    test('boardPassenger transitions seat ledger status from reserved to occupied', () {
      // Vehicle capacity 4 with 2 reserved seats for booking 'book-1'
      final ledger = SeatLedger.empty(capacity: 4).confirmSeats(
        bookingId: 'book-1',
        partySize: 2,
      );

      expect(ledger.reserved, equals(2));
      expect(ledger.occupied, equals(0));

      final updatedLedger = engine.boardPassenger(
        ledger: ledger,
        bookingId: 'book-1',
        partySize: 2,
      );

      expect(updatedLedger.reserved, equals(0));
      expect(updatedLedger.occupied, equals(2));
      expect(updatedLedger.available, equals(2));
    });
  });
}
