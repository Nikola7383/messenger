import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/security/domain/repositories/i_network_repository.dart';

// Events
abstract class NetworkAnalysisEvent extends Equatable {
  const NetworkAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class StartNetworkAnalysisRequested extends NetworkAnalysisEvent {}

class StopNetworkAnalysisRequested extends NetworkAnalysisEvent {}

class NetworkMetricsUpdated extends NetworkAnalysisEvent {
  final Map<String, dynamic> metrics;

  const NetworkMetricsUpdated(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

class ThreatDetected extends NetworkAnalysisEvent {
  final Map<String, dynamic> threat;

  const ThreatDetected(this.threat);

  @override
  List<Object?> get props => [threat];
}

class ApplyDefenseMeasuresRequested extends NetworkAnalysisEvent {
  final List<Map<String, dynamic>> threats;

  const ApplyDefenseMeasuresRequested(this.threats);

  @override
  List<Object?> get props => [threats];
}

// State
class NetworkAnalysisState extends Equatable {
  final bool isAnalyzing;
  final Map<String, dynamic>? networkHealth;
  final Map<String, dynamic>? networkAnalysis;
  final List<Map<String, dynamic>> detectedThreats;
  final String? error;

  const NetworkAnalysisState({
    this.isAnalyzing = false,
    this.networkHealth,
    this.networkAnalysis,
    this.detectedThreats = const [],
    this.error,
  });

  NetworkAnalysisState copyWith({
    bool? isAnalyzing,
    Map<String, dynamic>? networkHealth,
    Map<String, dynamic>? networkAnalysis,
    List<Map<String, dynamic>>? detectedThreats,
    String? error,
  }) {
    return NetworkAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      networkHealth: networkHealth ?? this.networkHealth,
      networkAnalysis: networkAnalysis ?? this.networkAnalysis,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isAnalyzing,
        networkHealth,
        networkAnalysis,
        detectedThreats,
        error,
      ];
}

// Bloc
class NetworkAnalysisBloc
    extends Bloc<NetworkAnalysisEvent, NetworkAnalysisState> {
  final INetworkRepository _networkRepository;
  StreamSubscription? _networkMetricsSubscription;
  StreamSubscription? _threatDetectionSubscription;

  NetworkAnalysisBloc(this._networkRepository)
      : super(const NetworkAnalysisState()) {
    on<StartNetworkAnalysisRequested>(_onStartNetworkAnalysis);
    on<StopNetworkAnalysisRequested>(_onStopNetworkAnalysis);
    on<NetworkMetricsUpdated>(_onNetworkMetricsUpdated);
    on<ThreatDetected>(_onThreatDetected);
    on<ApplyDefenseMeasuresRequested>(_onApplyDefenseMeasures);
  }

  Future<void> _onStartNetworkAnalysis(
    StartNetworkAnalysisRequested event,
    Emitter<NetworkAnalysisState> emit,
  ) async {
    try {
      emit(state.copyWith(isAnalyzing: true, error: null));

      // Pokreni analizu mreže
      await _networkRepository.startNetworkAnalysis();

      // Pretplati se na metrike
      _networkMetricsSubscription?.cancel();
      _networkMetricsSubscription = _networkRepository.networkMetrics.listen(
        (metrics) => add(NetworkMetricsUpdated(metrics)),
      );

      // Pretplati se na detekciju pretnji
      _threatDetectionSubscription?.cancel();
      _threatDetectionSubscription = _networkRepository.threatDetection.listen(
        (threat) => add(ThreatDetected(threat)),
      );
    } catch (e) {
      emit(state.copyWith(
        isAnalyzing: false,
        error: 'Greška pri pokretanju analize: $e',
      ));
    }
  }

  Future<void> _onStopNetworkAnalysis(
    StopNetworkAnalysisRequested event,
    Emitter<NetworkAnalysisState> emit,
  ) async {
    await _networkMetricsSubscription?.cancel();
    await _threatDetectionSubscription?.cancel();
    await _networkRepository.stopNetworkAnalysis();
    emit(state.copyWith(isAnalyzing: false));
  }

  void _onNetworkMetricsUpdated(
    NetworkMetricsUpdated event,
    Emitter<NetworkAnalysisState> emit,
  ) {
    final metrics = event.metrics;
    final health = _calculateNetworkHealth(metrics);
    
    emit(state.copyWith(
      networkHealth: health,
      networkAnalysis: {'metrics': metrics},
    ));
  }

  void _onThreatDetected(
    ThreatDetected event,
    Emitter<NetworkAnalysisState> emit,
  ) {
    final updatedThreats = List<Map<String, dynamic>>.from(state.detectedThreats)
      ..add(event.threat);
    
    emit(state.copyWith(detectedThreats: updatedThreats));
  }

  Future<void> _onApplyDefenseMeasures(
    ApplyDefenseMeasuresRequested event,
    Emitter<NetworkAnalysisState> emit,
  ) async {
    try {
      await _networkRepository.applyDefenseMeasures(event.threats);
      emit(state.copyWith(detectedThreats: []));
    } catch (e) {
      emit(state.copyWith(
        error: 'Greška pri primeni odbrambenih mera: $e',
      ));
    }
  }

  Map<String, dynamic> _calculateNetworkHealth(Map<String, dynamic> metrics) {
    final errorRate = metrics['error_rate'] as double? ?? 0.0;
    final latency = metrics['latency'] as int? ?? 0;
    final bandwidthUsage = metrics['bandwidth_usage'] as int? ?? 0;

    String status;
    if (errorRate > 5.0 || latency > 500 || bandwidthUsage > 1024 * 1024) {
      status = 'critical';
    } else if (errorRate > 2.0 || latency > 200 || bandwidthUsage > 512 * 1024) {
      status = 'warning';
    } else {
      status = 'healthy';
    }

    return {
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': metrics,
    };
  }

  @override
  Future<void> close() async {
    await _networkMetricsSubscription?.cancel();
    await _threatDetectionSubscription?.cancel();
    await _networkRepository.stopNetworkAnalysis();
    return super.close();
  }
} 