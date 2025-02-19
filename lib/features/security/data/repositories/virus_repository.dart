import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/network/domain/repositories/mesh_network_repository.dart';
import 'package:glasnik/features/security/domain/entities/virus.dart';
import 'package:glasnik/features/security/domain/repositories/virus_repository.dart';
import 'package:glasnik/features/security/utils/crypto_utils.dart';
import 'package:uuid/uuid.dart';

class VirusRepository implements IVirusRepository {
  final IMeshNetworkRepository _networkRepository;
  final _activeVirusesController = StreamController<List<Virus>>.broadcast();
  final _detectedThreatsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, Virus> _activeViruses = {};
  final _random = Random.secure();
  final _uuid = const Uuid();
  
  final _virusHistory = <String, List<Virus>>{};
  final _detectedThreats = <Map<String, dynamic>>[];
  
  Timer? _networkMonitorTimer;
  Timer? _virusMaintenanceTimer;

  VirusRepository({
    required IMeshNetworkRepository networkRepository,
  }) : _networkRepository = networkRepository {
    _startMonitoring();
  }

  void _startMonitoring() {
    // Monitoring mreže na svakih 30 sekundi
    _networkMonitorTimer?.cancel();
    _networkMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        final threats = await detectThreats();
        threats.fold(
          (failure) => null,
          (detectedThreats) {
            if (detectedThreats.isNotEmpty) {
              _handleThreats(detectedThreats);
            }
          },
        );
      },
    );

    // Održavanje virusa na svakih 5 minuta
    _virusMaintenanceTimer?.cancel();
    _virusMaintenanceTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) async {
        await _maintainViruses();
      },
    );
  }

  @override
  Future<Either<Failure, Virus>> createProbeVirus({
    required Set<VirusCapability> capabilities,
    required Map<String, dynamic> behavior,
    Map<String, dynamic>? mutationRules,
  }) async {
    try {
      final virus = Virus(
        type: VirusType.probe,
        capabilities: capabilities,
        signature: _generateVirusSignature(),
        behavior: behavior,
        mutationRules: mutationRules,
        detectionPatterns: _generateDetectionPatterns(),
        resourceUsage: _initializeResourceUsage(),
      );

      _activeViruses[virus.id] = virus;
      _virusHistory[virus.id] = [virus];
      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(virus);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Virus>> createGuardianVirus({
    required Set<VirusCapability> capabilities,
    required Map<String, dynamic> behavior,
    required Map<String, dynamic> detectionPatterns,
  }) async {
    try {
      final virus = Virus(
        type: VirusType.guardian,
        capabilities: capabilities,
        signature: _generateVirusSignature(),
        behavior: behavior,
        detectionPatterns: detectionPatterns,
        resourceUsage: _initializeResourceUsage(),
      );

      _activeViruses[virus.id] = virus;
      _virusHistory[virus.id] = [virus];
      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(virus);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Virus>> activateVirus(String virusId) async {
    try {
      final virus = _activeViruses[virusId];
      if (virus == null) {
        return Left(SecurityFailure('Virus not found'));
      }

      final activatedVirus = virus.copyWith(
        state: VirusState.active,
        activatedAt: DateTime.now(),
      );

      _activeViruses[virusId] = activatedVirus;
      _virusHistory[virusId]?.add(activatedVirus);
      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(activatedVirus);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Virus>> deactivateVirus(String virusId) async {
    try {
      final virus = _activeViruses[virusId];
      if (virus == null) {
        return Left(SecurityFailure('Virus not found'));
      }

      final deactivatedVirus = virus.copyWith(
        state: VirusState.dormant,
      );

      _activeViruses[virusId] = deactivatedVirus;
      _virusHistory[virusId]?.add(deactivatedVirus);
      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(deactivatedVirus);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Virus>> mutateVirus(
    String virusId,
    Map<String, dynamic> mutationParams,
  ) async {
    try {
      final virus = _activeViruses[virusId];
      if (virus == null) {
        return Left(SecurityFailure('Virus not found'));
      }

      if (!virus.canMutate) {
        return Left(SecurityFailure('Virus cannot mutate'));
      }

      // Započni proces mutacije
      final mutatingVirus = virus.copyWith(
        state: VirusState.mutating,
      );
      _activeViruses[virusId] = mutatingVirus;
      _activeVirusesController.add(_activeViruses.values.toList());

      // Izvrši mutaciju
      final mutatedVirus = await _performMutation(
        mutatingVirus,
        mutationParams,
      );

      _activeViruses[mutatedVirus.id] = mutatedVirus;
      _virusHistory[mutatedVirus.id] = [mutatedVirus];
      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(mutatedVirus);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Virus>>> replicateVirus(
    String virusId,
    List<String> targetNodes,
  ) async {
    try {
      final virus = _activeViruses[virusId];
      if (virus == null) {
        return Left(SecurityFailure('Virus not found'));
      }

      if (!virus.capabilities.contains(VirusCapability.selfReplication)) {
        return Left(SecurityFailure('Virus cannot self-replicate'));
      }

      final replicatedViruses = <Virus>[];

      for (final nodeId in targetNodes) {
        // Kreiraj repliku sa malim varijacijama
        final replicatedVirus = virus.copyWith(
          id: _uuid.v4(),
          parentId: virus.id,
          generation: virus.generation + 1,
          signature: _generateVirusSignature(),
          behavior: _modifyBehavior(virus.behavior),
          resourceUsage: _initializeResourceUsage(),
        );

        // Pokušaj propagaciju kroz mrežu
        final success = await _propagateToNode(replicatedVirus, nodeId);
        if (success) {
          replicatedViruses.add(replicatedVirus);
          _activeViruses[replicatedVirus.id] = replicatedVirus;
        }
      }

      _activeVirusesController.add(_activeViruses.values.toList());

      return Right(replicatedViruses);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> analyzeNetworkTraffic() async {
    try {
      final analysis = await _performNetworkAnalysis();
      return Right(analysis);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> detectThreats() async {
    try {
      final threats = await _detectNetworkThreats();
      _detectedThreats.addAll(threats);
      _detectedThreatsController.add(_detectedThreats);
      return Right(threats);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> applyDefenseMeasures(
    List<Map<String, dynamic>> threats,
  ) async {
    try {
      for (final threat in threats) {
        await _applyDefenseMeasure(threat);
      }
      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Virus>>> getActiveViruses() async {
    try {
      return Right(_activeViruses.values.toList());
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Virus>>> getVirusMutationHistory(
    String virusId,
  ) async {
    try {
      final history = _virusHistory[virusId];
      if (history == null) {
        return Left(SecurityFailure('Virus history not found'));
      }
      return Right(history);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkNetworkHealth() async {
    try {
      final health = await _checkNetworkHealth();
      return Right(health);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cleanupDeadViruses() async {
    try {
      final deadVirusIds = <String>[];
      
      for (final virus in _activeViruses.values) {
        if (virus.isDead || 
            virus.age > const Duration(hours: 24) ||
            (virus.isActive && virus.activeTime! > const Duration(hours: 12))) {
          deadVirusIds.add(virus.id);
        }
      }

      for (final id in deadVirusIds) {
        _activeViruses.remove(id);
      }

      _activeVirusesController.add(_activeViruses.values.toList());

      return const Right(unit);
    } catch (e) {
      return Left(SecurityFailure(e.toString()));
    }
  }

  @override
  Stream<List<Virus>> watchActiveViruses() {
    return _activeVirusesController.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchDetectedThreats() {
    return _detectedThreatsController.stream;
  }

  // Helper metode
  String _generateVirusSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _uuid.v4();
    final data = '$timestamp:$random';
    return CryptoUtils.hashData(data);
  }

  Map<String, dynamic> _generateDetectionPatterns() {
    return {
      'network_patterns': [
        'abnormal_traffic',
        'suspicious_connections',
        'data_exfiltration',
      ],
      'behavior_patterns': [
        'resource_spikes',
        'unauthorized_access',
        'encryption_attempts',
      ],
      'threshold_values': {
        'max_connections': 100,
        'bandwidth_limit': 1024 * 1024, // 1 MB/s
        'cpu_threshold': 80, // 80%
      },
    };
  }

  Map<String, int> _initializeResourceUsage() {
    return {
      'cpu': _random.nextInt(20), // Inicijalno nisko opterećenje
      'memory': _random.nextInt(30),
      'network': _random.nextInt(25),
    };
  }

  Map<String, dynamic> _modifyBehavior(Map<String, dynamic> behavior) {
    final newBehavior = Map<String, dynamic>.from(behavior);
    
    // Modifikuj postojeće parametre
    newBehavior.forEach((key, value) {
      if (value is num) {
        // Dodaj nasumičnu varijaciju ±20%
        final variation = value * (0.8 + _random.nextDouble() * 0.4);
        newBehavior[key] = variation;
      }
    });

    return newBehavior;
  }

  Future<bool> _propagateToNode(Virus virus, String nodeId) async {
    try {
      // Pripremi virus za transport
      final virusData = virus.toJson();
      
      // Pokušaj propagaciju kroz mrežu
      await _networkRepository.sendMessage(
        nodeId,
        {
          'type': 'virus_propagation',
          'payload': virusData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      return true;
    } catch (e) {
      print('Greška pri propagaciji virusa: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _performNetworkAnalysis() async {
    // Implementiraj detaljnu analizu mrežnog saobraćaja
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': {
        'packet_count': _random.nextInt(1000),
        'bandwidth_usage': _random.nextInt(100) * 1024,
        'error_rate': _random.nextDouble() * 5,
        'latency': _random.nextInt(300),
      },
      'patterns': {
        'suspicious_activities': _random.nextInt(5),
        'anomalies_detected': _random.nextInt(3),
      },
    };
  }

  Future<List<Map<String, dynamic>>> _detectNetworkThreats() async {
    final threats = <Map<String, dynamic>>[];
    
    // Simuliraj detekciju pretnji
    if (_random.nextDouble() < 0.3) {
      threats.add({
        'type': 'unauthorized_access',
        'severity': 'high',
        'timestamp': DateTime.now().toIso8601String(),
        'details': {
          'source': 'unknown_node',
          'target': 'network_resource',
          'attempt_count': _random.nextInt(10),
        },
      });
    }

    return threats;
  }

  Future<void> _applyDefenseMeasure(Map<String, dynamic> threat) async {
    // Implementiraj odbrambene mere bazirane na tipu pretnje
    switch (threat['type']) {
      case 'unauthorized_access':
        // Implementiraj blokiranje pristupa
        break;
      case 'data_manipulation':
        // Implementiraj validaciju podataka
        break;
      case 'denial_of_service':
        // Implementiraj rate limiting
        break;
    }
  }

  Future<Map<String, dynamic>> _checkNetworkHealth() async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': {
        'active_nodes': _random.nextInt(10),
        'network_load': _random.nextInt(100),
        'error_rate': _random.nextDouble() * 2,
      },
    };
  }

  Future<void> _maintainViruses() async {
    // Očisti mrtve viruse
    await cleanupDeadViruses();

    // Proveri zdravlje aktivnih virusa
    for (final virus in _activeViruses.values) {
      if (virus.isActive) {
        final resourceUsage = Map<String, int>.from(virus.resourceUsage);
        
        // Ako virus koristi previše resursa, deaktiviraj ga
        if (resourceUsage['cpu']! > 80 || 
            resourceUsage['memory']! > 80 || 
            resourceUsage['network']! > 80) {
          await deactivateVirus(virus.id);
        }
        
        // Ako virus može da mutira i aktivan je duže od 6 sati
        if (virus.canMutate && 
            virus.activeTime! > const Duration(hours: 6)) {
          await mutateVirus(virus.id, {
            'reason': 'maintenance',
            'optimization_target': 'resource_usage',
          });
        }
      }
    }
  }

  void dispose() {
    _networkMonitorTimer?.cancel();
    _virusMaintenanceTimer?.cancel();
    _activeVirusesController.close();
    _detectedThreatsController.close();
  }
} 