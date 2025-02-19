import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/security/domain/entities/virus.dart';

abstract class IVirusRepository {
  /// Kreira novi virus za testiranje mreže
  Future<Either<Failure, Virus>> createProbeVirus({
    required Set<VirusCapability> capabilities,
    required Map<String, dynamic> behavior,
    Map<String, dynamic>? mutationRules,
  });

  /// Kreira guardian virus za odbranu
  Future<Either<Failure, Virus>> createGuardianVirus({
    required Set<VirusCapability> capabilities,
    required Map<String, dynamic> behavior,
    required Map<String, dynamic> detectionPatterns,
  });

  /// Aktivira virus
  Future<Either<Failure, Virus>> activateVirus(String virusId);

  /// Deaktivira virus
  Future<Either<Failure, Virus>> deactivateVirus(String virusId);

  /// Mutira virus bazirano na novim uslovima
  Future<Either<Failure, Virus>> mutateVirus(
    String virusId,
    Map<String, dynamic> mutationParams,
  );

  /// Replicira virus na druge nodove
  Future<Either<Failure, List<Virus>>> replicateVirus(
    String virusId,
    List<String> targetNodes,
  );

  /// Analizira mrežni saobraćaj i traži anomalije
  Future<Either<Failure, Map<String, dynamic>>> analyzeNetworkTraffic();

  /// Detektuje potencijalne pretnje u mreži
  Future<Either<Failure, List<Map<String, dynamic>>>> detectThreats();

  /// Primenjuje odbrambene mere protiv detektovanih pretnji
  Future<Either<Failure, Unit>> applyDefenseMeasures(
    List<Map<String, dynamic>> threats,
  );

  /// Vraća sve aktivne viruse
  Future<Either<Failure, List<Virus>>> getActiveViruses();

  /// Vraća istoriju mutacija za virus
  Future<Either<Failure, List<Virus>>> getVirusMutationHistory(String virusId);

  /// Proverava zdravlje mreže
  Future<Either<Failure, Map<String, dynamic>>> checkNetworkHealth();

  /// Čisti mrtve ili neaktivne viruse
  Future<Either<Failure, Unit>> cleanupDeadViruses();

  /// Stream za praćenje stanja virusa
  Stream<List<Virus>> watchActiveViruses();

  /// Stream za praćenje detektovanih pretnji
  Stream<List<Map<String, dynamic>>> watchDetectedThreats();
} 