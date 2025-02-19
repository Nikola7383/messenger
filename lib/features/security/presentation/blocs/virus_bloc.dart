import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/security/domain/entities/virus.dart';
import 'package:glasnik/features/security/domain/repositories/virus_repository.dart';

// Events
abstract class VirusEvent extends Equatable {
  const VirusEvent();

  @override
  List<Object?> get props => [];
}

class CreateProbeVirusRequested extends VirusEvent {
  final Set<VirusCapability> capabilities;
  final Map<String, dynamic> behavior;
  final Map<String, dynamic>? mutationRules;

  const CreateProbeVirusRequested({
    required this.capabilities,
    required this.behavior,
    this.mutationRules,
  });

  @override
  List<Object?> get props => [capabilities, behavior, mutationRules];
}

class CreateGuardianVirusRequested extends VirusEvent {
  final Set<VirusCapability> capabilities;
  final Map<String, dynamic> behavior;
  final Map<String, dynamic> detectionPatterns;

  const CreateGuardianVirusRequested({
    required this.capabilities,
    required this.behavior,
    required this.detectionPatterns,
  });

  @override
  List<Object?> get props => [capabilities, behavior, detectionPatterns];
}

class ActivateVirusRequested extends VirusEvent {
  final String virusId;

  const ActivateVirusRequested(this.virusId);

  @override
  List<Object?> get props => [virusId];
}

class DeactivateVirusRequested extends VirusEvent {
  final String virusId;

  const DeactivateVirusRequested(this.virusId);

  @override
  List<Object?> get props => [virusId];
}

class MutateVirusRequested extends VirusEvent {
  final String virusId;
  final Map<String, dynamic> mutationParams;

  const MutateVirusRequested({
    required this.virusId,
    required this.mutationParams,
  });

  @override
  List<Object?> get props => [virusId, mutationParams];
}

class ReplicateVirusRequested extends VirusEvent {
  final String virusId;
  final List<String> targetNodes;

  const ReplicateVirusRequested({
    required this.virusId,
    required this.targetNodes,
  });

  @override
  List<Object?> get props => [virusId, targetNodes];
}

class NetworkAnalysisRequested extends VirusEvent {}

class ThreatDetectionRequested extends VirusEvent {}

class DefenseMeasuresRequested extends VirusEvent {
  final List<Map<String, dynamic>> threats;

  const DefenseMeasuresRequested(this.threats);

  @override
  List<Object?> get props => [threats];
}

class NetworkHealthCheckRequested extends VirusEvent {}

class CleanupDeadVirusesRequested extends VirusEvent {}

// State
class VirusState extends Equatable {
  final List<Virus> activeViruses;
  final List<Map<String, dynamic>> detectedThreats;
  final Map<String, dynamic>? networkAnalysis;
  final Map<String, dynamic>? networkHealth;
  final bool isLoading;
  final String? error;

  const VirusState({
    this.activeViruses = const [],
    this.detectedThreats = const [],
    this.networkAnalysis,
    this.networkHealth,
    this.isLoading = false,
    this.error,
  });

  VirusState copyWith({
    List<Virus>? activeViruses,
    List<Map<String, dynamic>>? detectedThreats,
    Map<String, dynamic>? networkAnalysis,
    Map<String, dynamic>? networkHealth,
    bool? isLoading,
    String? error,
  }) {
    return VirusState(
      activeViruses: activeViruses ?? this.activeViruses,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      networkAnalysis: networkAnalysis ?? this.networkAnalysis,
      networkHealth: networkHealth ?? this.networkHealth,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    activeViruses,
    detectedThreats,
    networkAnalysis,
    networkHealth,
    isLoading,
    error,
  ];
}

// Bloc
class VirusBloc extends Bloc<VirusEvent, VirusState> {
  final IVirusRepository _virusRepository;
  StreamSubscription? _activeVirusesSubscription;
  StreamSubscription? _detectedThreatsSubscription;

  VirusBloc({
    required IVirusRepository virusRepository,
  }) : _virusRepository = virusRepository,
       super(const VirusState()) {
    on<CreateProbeVirusRequested>(_onCreateProbeVirusRequested);
    on<CreateGuardianVirusRequested>(_onCreateGuardianVirusRequested);
    on<ActivateVirusRequested>(_onActivateVirusRequested);
    on<DeactivateVirusRequested>(_onDeactivateVirusRequested);
    on<MutateVirusRequested>(_onMutateVirusRequested);
    on<ReplicateVirusRequested>(_onReplicateVirusRequested);
    on<NetworkAnalysisRequested>(_onNetworkAnalysisRequested);
    on<ThreatDetectionRequested>(_onThreatDetectionRequested);
    on<DefenseMeasuresRequested>(_onDefenseMeasuresRequested);
    on<NetworkHealthCheckRequested>(_onNetworkHealthCheckRequested);
    on<CleanupDeadVirusesRequested>(_onCleanupDeadVirusesRequested);

    // Pretplati se na promene
    _activeVirusesSubscription = _virusRepository.watchActiveViruses()
      .listen((viruses) {
        emit(state.copyWith(activeViruses: viruses));
      });

    _detectedThreatsSubscription = _virusRepository.watchDetectedThreats()
      .listen((threats) {
        emit(state.copyWith(detectedThreats: threats));
      });
  }

  Future<void> _onCreateProbeVirusRequested(
    CreateProbeVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.createProbeVirus(
      capabilities: event.capabilities,
      behavior: event.behavior,
      mutationRules: event.mutationRules,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (virus) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onCreateGuardianVirusRequested(
    CreateGuardianVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.createGuardianVirus(
      capabilities: event.capabilities,
      behavior: event.behavior,
      detectionPatterns: event.detectionPatterns,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (virus) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onActivateVirusRequested(
    ActivateVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.activateVirus(event.virusId);

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (virus) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onDeactivateVirusRequested(
    DeactivateVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.deactivateVirus(event.virusId);

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (virus) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onMutateVirusRequested(
    MutateVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.mutateVirus(
      event.virusId,
      event.mutationParams,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (virus) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onReplicateVirusRequested(
    ReplicateVirusRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.replicateVirus(
      event.virusId,
      event.targetNodes,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (viruses) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onNetworkAnalysisRequested(
    NetworkAnalysisRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.analyzeNetworkTraffic();

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (analysis) => emit(state.copyWith(
        networkAnalysis: analysis,
        isLoading: false,
      )),
    );
  }

  Future<void> _onThreatDetectionRequested(
    ThreatDetectionRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.detectThreats();

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (threats) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onDefenseMeasuresRequested(
    DefenseMeasuresRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.applyDefenseMeasures(event.threats);

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  Future<void> _onNetworkHealthCheckRequested(
    NetworkHealthCheckRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.checkNetworkHealth();

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (health) => emit(state.copyWith(
        networkHealth: health,
        isLoading: false,
      )),
    );
  }

  Future<void> _onCleanupDeadVirusesRequested(
    CleanupDeadVirusesRequested event,
    Emitter<VirusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _virusRepository.cleanupDeadViruses();

    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(isLoading: false)),
    );
  }

  @override
  Future<void> close() {
    _activeVirusesSubscription?.cancel();
    _detectedThreatsSubscription?.cancel();
    return super.close();
  }
} 