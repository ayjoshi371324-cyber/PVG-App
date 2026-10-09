/// Seat status in the vehicle lifecycle.
enum SeatStatus {
  held,
  reserved,
  occupied,
}

/// Represents an allocated seat slice for a booking.
class SeatAllocation {
  final String bookingId;
  final int partySize;
  final SeatStatus status;
  final DateTime? expiresAt;

  const SeatAllocation({
    required this.bookingId,
    required this.partySize,
    required this.status,
    this.expiresAt,
  });

  SeatAllocation copyWith({
    String? bookingId,
    int? partySize,
    SeatStatus? status,
    DateTime? expiresAt,
  }) {
    return SeatAllocation(
      bookingId: bookingId ?? this.bookingId,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

/// Dynamic Seat Ledger for vehicle occupancy.
///
/// Implements the exact rule:
/// `occupied  = sum(party_size) where status = ONBOARD`
/// `reserved  = sum(party_size) where status in (CONFIRMED, WAITING_PICKUP)`
/// `held      = sum(party_size) where status in (OFFERED, PENDING_CONSENT)`
/// `available = capacity - occupied - reserved - held`
///
/// Prevents overbooking and guarantees full vehicles (e.g. 4/4) offer no join options.
class SeatLedger {
  final int capacity;
  final List<SeatAllocation> allocations;

  const SeatLedger({
    required this.capacity,
    required this.allocations,
  });

  factory SeatLedger.empty({required int capacity}) {
    return SeatLedger(
      capacity: capacity,
      allocations: const [],
    );
  }

  int get occupied => allocations
      .where((a) => a.status == SeatStatus.occupied)
      .fold(0, (sum, a) => sum + a.partySize);

  int get reserved => allocations
      .where((a) => a.status == SeatStatus.reserved)
      .fold(0, (sum, a) => sum + a.partySize);

  int get held => allocations
      .where((a) => a.status == SeatStatus.held)
      .fold(0, (sum, a) => sum + a.partySize);

  int get available {
    final free = capacity - (occupied + reserved + held);
    return free < 0 ? 0 : free;
  }

  bool get isFull => available <= 0;

  bool canAccommodate(int partySize) => partySize > 0 && partySize <= available;

  SeatLedger holdSeats({
    required String bookingId,
    required int partySize,
    DateTime? expiresAt,
  }) {
    if (!canAccommodate(partySize)) {
      throw StateError(
        'Vehicle capacity exceeded. Needed: $partySize, Available: $available (Capacity: $capacity)',
      );
    }

    final newAllocations = List<SeatAllocation>.from(allocations)
      ..add(
        SeatAllocation(
          bookingId: bookingId,
          partySize: partySize,
          status: SeatStatus.held,
          expiresAt: expiresAt,
        ),
      );

    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger confirmSeats({
    required String bookingId,
    required int partySize,
  }) {
    final existingIndex = allocations.indexWhere(
      (a) => a.bookingId == bookingId && a.status == SeatStatus.held,
    );

    final newAllocations = List<SeatAllocation>.from(allocations);
    if (existingIndex >= 0) {
      newAllocations[existingIndex] = newAllocations[existingIndex].copyWith(
        status: SeatStatus.reserved,
        expiresAt: null,
      );
    } else {
      if (!canAccommodate(partySize)) {
        throw StateError(
          'Cannot confirm booking $bookingId. Needed $partySize, available $available',
        );
      }
      newAllocations.add(
        SeatAllocation(
          bookingId: bookingId,
          partySize: partySize,
          status: SeatStatus.reserved,
        ),
      );
    }

    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger boardSeats({
    required String bookingId,
    required int partySize,
  }) {
    final existingIndex = allocations.indexWhere(
      (a) => a.bookingId == bookingId && a.status == SeatStatus.reserved,
    );

    final newAllocations = List<SeatAllocation>.from(allocations);
    if (existingIndex >= 0) {
      newAllocations[existingIndex] = newAllocations[existingIndex].copyWith(
        status: SeatStatus.occupied,
      );
    } else {
      newAllocations.add(
        SeatAllocation(
          bookingId: bookingId,
          partySize: partySize,
          status: SeatStatus.occupied,
        ),
      );
    }

    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger releaseHeldSeats({
    required String bookingId,
    required int partySize,
  }) {
    final newAllocations = allocations
        .where(
          (a) => !(a.bookingId == bookingId && a.status == SeatStatus.held),
        )
        .toList();
    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger releaseReservedSeats({
    required String bookingId,
    required int partySize,
  }) {
    final newAllocations = allocations
        .where(
          (a) => !(a.bookingId == bookingId && a.status == SeatStatus.reserved),
        )
        .toList();
    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger releaseOccupiedSeats({
    required String bookingId,
    required int partySize,
  }) {
    final newAllocations = allocations
        .where(
          (a) => !(a.bookingId == bookingId && a.status == SeatStatus.occupied),
        )
        .toList();
    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }

  SeatLedger purgeExpiredHolds({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final newAllocations = allocations.where((a) {
      if (a.status == SeatStatus.held && a.expiresAt != null) {
        return a.expiresAt!.isAfter(now);
      }
      return true;
    }).toList();

    return SeatLedger(capacity: capacity, allocations: newAllocations);
  }
}
