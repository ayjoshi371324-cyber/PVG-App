import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';

/// Result of evaluating a passenger boarding verification code.
class BoardingVerificationResult extends Equatable {
  const BoardingVerificationResult({
    required this.isSuccess,
    this.isLocked = false,
    this.isBypassed = false,
    required this.newFailedAttempts,
    this.errorMessage,
  });

  final bool isSuccess;
  final bool isLocked;
  final bool isBypassed;
  final int newFailedAttempts;
  final String? errorMessage;

  int get remainingAttempts =>
      (BoardingVerificationEngine.maxFailedAttempts - newFailedAttempts).clamp(0, BoardingVerificationEngine.maxFailedAttempts);

  @override
  List<Object?> get props => [
        isSuccess,
        isLocked,
        isBypassed,
        newFailedAttempts,
        errorMessage,
      ];
}

/// Core Boarding Verification Engine enforcing:
/// - 4-digit numeric OTP generation
/// - Curb-side driver verification against passenger code
/// - 5-attempt lockout security policy with manual override
/// - Seat ledger transition from reserved to occupied upon boarding
class BoardingVerificationEngine {
  const BoardingVerificationEngine();

  static const int maxFailedAttempts = 5;

  /// Generates a cryptographically strong or pseudo-random 4-digit OTP.
  String generateOtp([Random? random]) {
    final rng = random ?? Random();
    final code = 1000 + rng.nextInt(9000);
    return code.toString();
  }

  /// Normalizes verification code removing hashes and whitespace.
  String cleanCode(String raw) {
    return raw.replaceAll('#', '').replaceAll(' ', '').trim();
  }

  /// Verifies entered OTP against expected code.
  /// If failed attempts reach [maxFailedAttempts], the stop is locked.
  BoardingVerificationResult verifyOtp({
    required String enteredOtp,
    required String expectedOtp,
    required int currentFailedAttempts,
  }) {
    if (currentFailedAttempts >= maxFailedAttempts) {
      return BoardingVerificationResult(
        isSuccess: false,
        isLocked: true,
        newFailedAttempts: currentFailedAttempts,
        errorMessage: 'Stop locked due to $maxFailedAttempts consecutive failed attempts. Manual override required.',
      );
    }

    final cleanedEntered = cleanCode(enteredOtp);
    final cleanedExpected = cleanCode(expectedOtp);

    if (cleanedEntered == cleanedExpected && cleanedEntered.isNotEmpty) {
      return const BoardingVerificationResult(
        isSuccess: true,
        isLocked: false,
        newFailedAttempts: 0,
        errorMessage: null,
      );
    }

    final updatedFailed = currentFailedAttempts + 1;
    final isLocked = updatedFailed >= maxFailedAttempts;
    final remaining = (maxFailedAttempts - updatedFailed).clamp(0, maxFailedAttempts);

    final errorMsg = isLocked
        ? 'Stop locked due to $maxFailedAttempts consecutive failed attempts. Manual override required.'
        : 'Invalid OTP ($remaining attempts remaining).';

    return BoardingVerificationResult(
      isSuccess: false,
      isLocked: isLocked,
      newFailedAttempts: updatedFailed,
      errorMessage: errorMsg,
    );
  }

  /// Single-tap demo mode shortcut to bypass OTP verification.
  BoardingVerificationResult bypassOtp() {
    return const BoardingVerificationResult(
      isSuccess: true,
      isBypassed: true,
      isLocked: false,
      newFailedAttempts: 0,
      errorMessage: null,
    );
  }

  /// Administrative manual override to unlock a locked stop.
  BoardingVerificationResult manualOverride() {
    return const BoardingVerificationResult(
      isSuccess: false,
      isLocked: false,
      newFailedAttempts: 0,
      errorMessage: null,
    );
  }

  /// Transitions passenger allocation from [SeatStatus.reserved] to [SeatStatus.occupied].
  SeatLedger boardPassenger({
    required SeatLedger ledger,
    required String bookingId,
    required int partySize,
  }) {
    return ledger.boardSeats(
      bookingId: bookingId,
      partySize: partySize,
    );
  }
}
