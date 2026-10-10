import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ridepool_app/core/engine/benchmark_simulator.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/auth_models.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/services/auth_service.dart';
import 'package:ridepool_app/services/place_search_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RepositoryMode {
  offlineSimulation,
  liveBackend;

  String get label => this == RepositoryMode.offlineSimulation
      ? 'Offline Simulation'
      : 'Live Backend';
}

/// Base contract for RidePool repositories supporting Dual Mode (Live backend vs Offline Simulation)
abstract class RidePoolRepository {
  /// Whether the repository is running in simulated offline mode
  bool get isSimulated;

  RepositoryMode get mode;

  // Auth operations
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request);
  Future<AuthResponse> registerDriver(RegisterDriverRequest request);

  // Places
  Future<List<PuneLocation>> searchPlaces(String query);

  // Vehicles
  Future<List<FleetVehicle>> getFleetVehicles();

  // Benchmark
  Future<BenchmarkMetrics> fetchBenchmark({int seed = 42});

  // Batch trigger
  Future<void> triggerBatchOptimization();

  // Real-time Event Stream (WebSocket or simulated)
  Stream<Map<String, dynamic>> get eventStream;
}

class OfflineSimulationRepository implements RidePoolRepository {
  OfflineSimulationRepository({
    AuthService? authService,
    PlaceSearchService? placeSearchService,
    BenchmarkSimulator? benchmarkSimulator,
  })  : _authService = authService ?? MockAuthService(),
        _placeSearchService = placeSearchService ?? LocalPlaceSearchService(),
        _benchmarkSimulator = benchmarkSimulator ?? const BenchmarkSimulator();

  final AuthService _authService;
  final PlaceSearchService _placeSearchService;
  final BenchmarkSimulator _benchmarkSimulator;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  bool get isSimulated => true;

  @override
  RepositoryMode get mode => RepositoryMode.offlineSimulation;

  @override
  Future<AuthResponse> login(String email, String password) =>
      _authService.login(email: email, password: password);

  @override
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request) =>
      _authService.registerPassenger(request);

  @override
  Future<AuthResponse> registerDriver(RegisterDriverRequest request) =>
      _authService.registerDriver(request);

  @override
  Future<List<PuneLocation>> searchPlaces(String query) async {
    return _placeSearchService.search(query);
  }

  @override
  Future<List<FleetVehicle>> getFleetVehicles() async {
    return [
      const FleetVehicle(
        id: 'EV-01',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 4001',
        status: FleetVehicleStatus.idle,
        currentLocation: PuneLandmarks.swargate,
        currentOccupancy: 0,
        maxCapacity: 4,
        batteryPercentage: 88,
        onboardSeats: 0,
        reservedSeats: 0,
        heldSeats: 0,
      ),
      const FleetVehicle(
        id: 'EV-02',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 4002',
        status: FleetVehicleStatus.pickingUp,
        currentLocation: PuneLandmarks.kothrud,
        currentOccupancy: 1,
        maxCapacity: 4,
        batteryPercentage: 79,
        assignedRouteName: 'Kothrud-Hinjawadi Corridor',
        onboardSeats: 1,
        reservedSeats: 1,
        heldSeats: 0,
      ),
      const FleetVehicle(
        id: 'EV-03',
        name: 'Tata Nexon EV',
        licensePlate: 'MH 12 RN 5100',
        status: FleetVehicleStatus.inPool,
        currentLocation: PuneLandmarks.hinjawadiPhase1,
        currentOccupancy: 3,
        maxCapacity: 4,
        batteryPercentage: 65,
        assignedRouteName: 'ShivajiNagar-Hinjawadi Express',
        onboardSeats: 2,
        reservedSeats: 1,
        heldSeats: 0,
      ),
      const FleetVehicle(
        id: 'EV-04',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 8842',
        status: FleetVehicleStatus.inPool,
        currentLocation: PuneLandmarks.shivajiNagar,
        currentOccupancy: 2,
        maxCapacity: 4,
        batteryPercentage: 84,
        assignedRouteName: 'Central-West IT Pool',
        onboardSeats: 2,
        reservedSeats: 0,
        heldSeats: 1,
      ),
      const FleetVehicle(
        id: 'EV-05',
        name: 'Tata Tigor EV',
        licensePlate: 'MH 12 RN 6012',
        status: FleetVehicleStatus.pickingUp,
        currentLocation: PuneLandmarks.vimanNagar,
        currentOccupancy: 1,
        maxCapacity: 4,
        batteryPercentage: 92,
        assignedRouteName: 'East Corridor Shuttle',
        onboardSeats: 1,
        reservedSeats: 0,
        heldSeats: 1,
      ),
      const FleetVehicle(
        id: 'EV-06',
        name: 'Tata Nexon EV',
        licensePlate: 'MH 12 RN 7200',
        status: FleetVehicleStatus.idle,
        currentLocation: PuneLandmarks.hadapsar,
        currentOccupancy: 0,
        maxCapacity: 4,
        batteryPercentage: 81,
        onboardSeats: 0,
        reservedSeats: 0,
        heldSeats: 0,
      ),
    ];
  }

  @override
  Future<BenchmarkMetrics> fetchBenchmark({int seed = 42}) async {
    final vehicles = await getFleetVehicles();
    final requests = [
      SyntheticDemandRequest(
        id: 'req-sim-1',
        passengerName: 'Passenger 1',
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        requestedAt: DateTime.now(),
      ),
      SyntheticDemandRequest(
        id: 'req-sim-2',
        passengerName: 'Passenger 2',
        pickup: PuneLandmarks.shivajiNagar,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        requestedAt: DateTime.now(),
      ),
      SyntheticDemandRequest(
        id: 'req-sim-3',
        passengerName: 'Passenger 3',
        pickup: PuneLandmarks.swargate,
        dropoff: PuneLandmarks.vimanNagar,
        partySize: 2,
        requestedAt: DateTime.now(),
      ),
    ];

    return _benchmarkSimulator.runBenchmark(
      requests: requests,
      vehicles: vehicles,
      seed: seed,
    );
  }

  @override
  Future<void> triggerBatchOptimization() async {
    _eventController.add({
      'event': 'batch_optimized',
      'message': 'Simulated batch optimization completed',
    });
  }

  @override
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
}

class LiveBackendRepository implements RidePoolRepository {
  LiveBackendRepository({
    this.baseUrl = 'http://localhost:8000',
    this.wsUrl = 'ws://localhost:8000/ws',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String wsUrl;
  final http.Client _client;
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;

  void _initWebSocket() {
    if (_channel != null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (data) {
          try {
            final map = jsonDecode(data.toString()) as Map<String, dynamic>;
            _eventController.add(map);
          } catch (_) {}
        },
        onError: (_) {
          _channel = null;
        },
        onDone: () {
          _channel = null;
        },
      );
    } catch (_) {
      _channel = null;
    }
  }

  @override
  bool get isSimulated => false;

  @override
  RepositoryMode get mode => RepositoryMode.liveBackend;

  @override
  Future<AuthResponse> login(String email, String password) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return AuthResponse(
        user: AuthUser.fromJson(data['user']),
        tokens: AuthTokenPair.fromJson(data['tokens']),
      );
    }
    throw Exception('Login failed: ${res.body}');
  }

  @override
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/register/passenger'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return AuthResponse(
        user: AuthUser.fromJson(data['user']),
        tokens: AuthTokenPair.fromJson(data['tokens']),
      );
    }
    throw Exception('Passenger registration failed: ${res.body}');
  }

  @override
  Future<AuthResponse> registerDriver(RegisterDriverRequest request) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/auth/register/driver'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return AuthResponse(
        user: AuthUser.fromJson(data['user']),
        tokens: AuthTokenPair.fromJson(data['tokens']),
      );
    }
    throw Exception('Driver registration failed: ${res.body}');
  }

  @override
  Future<List<PuneLocation>> searchPlaces(String query) async {
    final res = await _client.get(Uri.parse('$baseUrl/places/search?q=$query'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map<PuneLocation>((item) {
        return PuneLocation(
          name: item['name'] as String,
          latitude: (item['latitude'] as num).toDouble(),
          longitude: (item['longitude'] as num).toDouble(),
          landmarkNote: item['address'] as String?,
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<List<FleetVehicle>> getFleetVehicles() async {
    final res = await _client.get(Uri.parse('$baseUrl/vehicles'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map<FleetVehicle>((item) {
        FleetVehicleStatus status;
        switch (item['status']) {
          case 'inPool':
            status = FleetVehicleStatus.inPool;
            break;
          case 'pickingUp':
            status = FleetVehicleStatus.pickingUp;
            break;
          default:
            status = FleetVehicleStatus.idle;
        }

        return FleetVehicle(
          id: item['id'],
          name: item['name'],
          licensePlate: item['license_plate'],
          status: status,
          currentLocation: PuneLocation(
            name: item['name'],
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            landmarkNote: 'Pune Corridor',
          ),
          currentOccupancy: item['current_occupancy'] ?? 0,
          maxCapacity: item['max_capacity'] ?? 4,
          batteryPercentage: item['battery_percentage'] ?? 80,
          assignedRouteName: item['assigned_route_name'],
          onboardSeats: item['onboard_seats'] ?? 0,
          reservedSeats: item['reserved_seats'] ?? 0,
          heldSeats: item['held_seats'] ?? 0,
        );
      }).toList();
    }
    return [];
  }

  @override
  Future<BenchmarkMetrics> fetchBenchmark({int seed = 42}) async {
    final res = await _client.get(Uri.parse('$baseUrl/ops/benchmark?seed=$seed'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return BenchmarkMetrics(
        vktAlgorithmic: (data['vkt_algorithmic'] as num).toDouble(),
        vktGreedy: (data['vkt_greedy'] as num).toDouble(),
        detourAlgorithmic: (data['detour_algorithmic'] as num).toDouble(),
        detourGreedy: (data['detour_greedy'] as num).toDouble(),
        fareSavingsPercentAlgorithmic:
            (data['fare_savings_percent_algorithmic'] as num).toDouble(),
        fareSavingsPercentGreedy:
            (data['fare_savings_percent_greedy'] as num).toDouble(),
        serviceRateAlgorithmic:
            (data['service_rate_algorithmic'] as num).toDouble(),
        serviceRateGreedy: (data['service_rate_greedy'] as num).toDouble(),
        p95DetourAlgorithmic:
            (data['p95_detour_algorithmic'] as num).toDouble(),
        p95DetourGreedy: (data['p95_detour_greedy'] as num).toDouble(),
        testedVehiclesCount: data['tested_vehicles_count'] ?? 6,
        testedPassengersCount: data['tested_passengers_count'] ?? 12,
        seed: data['seed'],
      );
    }
    throw Exception('Failed to fetch benchmark: ${res.body}');
  }

  @override
  Future<void> triggerBatchOptimization() async {
    final res = await _client.post(Uri.parse('$baseUrl/ops/batch'));
    if (res.statusCode != 200) {
      throw Exception('Failed to trigger batch: ${res.body}');
    }
  }

  @override
  Stream<Map<String, dynamic>> get eventStream {
    _initWebSocket();
    return _eventController.stream;
  }
}

/// Dual-Mode Repository managing seamless switching between
/// Live Backend and Offline Simulation at runtime.
class DualModeRidePoolRepository implements RidePoolRepository {
  static final DualModeRidePoolRepository instance = DualModeRidePoolRepository();

  DualModeRidePoolRepository({
    RidePoolRepository? simulatedRepository,
    RidePoolRepository? liveRepository,
    RepositoryMode initialMode = RepositoryMode.offlineSimulation,
  })  : _simulated = simulatedRepository ?? OfflineSimulationRepository(),
        _live = liveRepository ?? LiveBackendRepository(),
        _currentMode = initialMode;

  final RidePoolRepository _simulated;
  final RidePoolRepository _live;
  RepositoryMode _currentMode;

  RidePoolRepository get _activeRepo =>
      _currentMode == RepositoryMode.offlineSimulation ? _simulated : _live;

  void setMode(RepositoryMode newMode) {
    _currentMode = newMode;
  }

  @override
  bool get isSimulated => _currentMode == RepositoryMode.offlineSimulation;

  @override
  RepositoryMode get mode => _currentMode;

  @override
  Future<AuthResponse> login(String email, String password) =>
      _activeRepo.login(email, password);

  @override
  Future<AuthResponse> registerPassenger(RegisterPassengerRequest request) =>
      _activeRepo.registerPassenger(request);

  @override
  Future<AuthResponse> registerDriver(RegisterDriverRequest request) =>
      _activeRepo.registerDriver(request);

  @override
  Future<List<PuneLocation>> searchPlaces(String query) =>
      _activeRepo.searchPlaces(query);

  @override
  Future<List<FleetVehicle>> getFleetVehicles() =>
      _activeRepo.getFleetVehicles();

  @override
  Future<BenchmarkMetrics> fetchBenchmark({int seed = 42}) =>
      _activeRepo.fetchBenchmark(seed: seed);

  @override
  Future<void> triggerBatchOptimization() =>
      _activeRepo.triggerBatchOptimization();

  @override
  Stream<Map<String, dynamic>> get eventStream => _activeRepo.eventStream;
}
