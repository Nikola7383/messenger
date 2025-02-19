import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/security/domain/entities/chameleon.dart';
import 'package:glasnik/features/security/domain/repositories/chameleon_repository.dart';

// Events
abstract class ChameleonEvent extends Equatable {
  const ChameleonEvent();

  @override
  List<Object?> get props => [];
}

class ActivateDecoyModeRequested extends ChameleonEvent {}
class ActivateRealModeRequested extends ChameleonEvent {}
class SecurityCheckRequested extends ChameleonEvent {}
class AntiDebuggingRequested extends ChameleonEvent {}
class AntiTamperingRequested extends ChameleonEvent {}
class HoneypotsSetupRequested extends ChameleonEvent {}
class NetworkCamouflageRequested extends ChameleonEvent {}
class DataHidingRequested extends ChameleonEvent {}
class SteganographyRequested extends ChameleonEvent {
  final List<int> data;
  const SteganographyRequested(this.data);

  @override
  List<Object?> get props => [data];
}

class AttackAttemptDetected extends ChameleonEvent {
  final Map<String, dynamic> attempt;
  const AttackAttemptDetected(this.attempt);

  @override
  List<Object?> get props => [attempt];
}

class SecurityReportRequested extends ChameleonEvent {}

// State
class ChameleonState extends Equatable {
  final Chameleon? chameleon;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? securityReport;
  final List<Map<String, dynamic>> detectedThreats;
  final bool isCompromised;

  const ChameleonState({
    this.chameleon,
    this.isLoading = false,
    this.error,
    this.securityReport,
    this.detectedThreats = const [],
    this.isCompromised = false,
  });

  ChameleonState copyWith({
    Chameleon? chameleon,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? securityReport,
    List<Map<String, dynamic>>? detectedThreats,
    bool? isCompromised,
  }) {
    return ChameleonState(
      chameleon: chameleon ?? this.chameleon,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      securityReport: securityReport ?? this.securityReport,
      detectedThreats: detectedThreats ?? this.detectedThreats,
      isCompromised: isCompromised ?? this.isCompromised,
    );
  }

  @override
  List<Object?> get props => [
    chameleon,
    isLoading,
    error,
    securityReport,
    detectedThreats,
    isCompromised,
  ];
}

// Bloc
class ChameleonBloc extends Bloc<ChameleonEvent, ChameleonState> {
  final IChameleonRepository _chameleonRepository;
  StreamSubscription? _reverseEngineeringSubscription;
  StreamSubscription? _manipulationAttemptsSubscription;
  StreamSubscription? _suspiciousActivitiesSubscription;

  ChameleonBloc({
    required IChameleonRepository chameleonRepository,
  }) : _chameleonRepository = chameleonRepository,
       super(const ChameleonState()) {
    on<ActivateDecoyModeRequested>(_onActivateDecoyMode);
    on<ActivateRealModeRequested>(_onActivateRealMode);
    on<SecurityCheckRequested>(_onSecurityCheck);
    on<AntiDebuggingRequested>(_onAntiDebugging);
    on<AntiTamperingRequested>(_onAntiTampering);
    on<HoneypotsSetupRequested>(_onHoneypotsSetup);
    on<NetworkCamouflageRequested>(_onNetworkCamouflage);
    on<DataHidingRequested>(_onDataHiding);
    on<SteganographyRequested>(_onSteganography);
    on<AttackAttemptDetected>(_onAttackAttempt);
    on<SecurityReportRequested>(_onSecurityReport);

    // Inicijalizuj monitoring
    _setupMonitoring();
  }

  void _setupMonitoring() {
    // Prati pokušaje reverse engineering-a
    _reverseEngineeringSubscription = _chameleonRepository
      .watchReverseEngineeringAttempts()
      .listen((attempt) {
        add(AttackAttemptDetected(attempt));
      });

    // Prati pokušaje manipulacije
    _manipulationAttemptsSubscription = _chameleonRepository
      .watchManipulationAttempts()
      .listen((attempt) {
        add(AttackAttemptDetected(attempt));
      });

    // Prati sumnjive aktivnosti
    _suspiciousActivitiesSubscription = _chameleonRepository
      .watchSuspiciousActivities()
      .listen((activities) {
        for (final activity in activities) {
          add(AttackAttemptDetected({
            'type': 'suspicious_activity',
            'details': activity,
          }));
        }
      });
  }

  Future<void> _onActivateDecoyMode(
    ActivateDecoyModeRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.activateDecoyMode();
    
    await result.fold(
      (failure) async => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) async {
        // Aktiviraj sve zaštitne mere
        await _chameleonRepository.obfuscateCriticalComponents();
        await _chameleonRepository.generateDecoyTraffic();
        await _chameleonRepository.setupHoneypots();
        await _chameleonRepository.implementEvasionTechniques();
        
        final isInDecoy = await _chameleonRepository.isInDecoyMode();
        
        emit(state.copyWith(
          isLoading: false,
          error: null,
          isCompromised: false,
        ));
      },
    );
  }

  Future<void> _onActivateRealMode(
    ActivateRealModeRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.activateRealMode();
    
    await result.fold(
      (failure) async => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) async {
        // Aktiviraj prave funkcionalnosti
        await _chameleonRepository.transformCode();
        await _chameleonRepository.activateHiddenChannels();
        
        emit(state.copyWith(
          isLoading: false,
          error: null,
        ));
      },
    );
  }

  Future<void> _onSecurityCheck(
    SecurityCheckRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final integrityResult = await _chameleonRepository.verifyAppIntegrity();
    
    await integrityResult.fold(
      (failure) async => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (isIntegrityValid) async {
        if (!isIntegrityValid) {
          emit(state.copyWith(
            isLoading: false,
            isCompromised: true,
            error: 'Integritet aplikacije je narušen',
          ));
          return;
        }

        final report = await _chameleonRepository.generateSecurityReport();
        
        await report.fold(
          (failure) async => emit(state.copyWith(
            error: failure.message,
            isLoading: false,
          )),
          (securityReport) async => emit(state.copyWith(
            securityReport: securityReport,
            isLoading: false,
            error: null,
          )),
        );
      },
    );
  }

  Future<void> _onAntiDebugging(
    AntiDebuggingRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.applyAntiDebuggingMeasures();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onAntiTampering(
    AntiTamperingRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.implementAntiTampering();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onHoneypotsSetup(
    HoneypotsSetupRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.setupHoneypots();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onNetworkCamouflage(
    NetworkCamouflageRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.maskNetworkTraffic();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onDataHiding(
    DataHidingRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.hideRealData();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onSteganography(
    SteganographyRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.applySteganography(event.data);
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        error: null,
      )),
    );
  }

  Future<void> _onAttackAttempt(
    AttackAttemptDetected event,
    Emitter<ChameleonState> emit,
  ) async {
    // Dodaj pretnju u listu
    final updatedThreats = List<Map<String, dynamic>>.from(state.detectedThreats)
      ..add(event.attempt);

    emit(state.copyWith(
      detectedThreats: updatedThreats,
    ));

    // Logiraj pokušaj napada
    await _chameleonRepository.logAttackAttempts(event.attempt);
  }

  Future<void> _onSecurityReport(
    SecurityReportRequested event,
    Emitter<ChameleonState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await _chameleonRepository.generateSecurityReport();
    
    result.fold(
      (failure) => emit(state.copyWith(
        error: failure.message,
        isLoading: false,
      )),
      (report) => emit(state.copyWith(
        securityReport: report,
        isLoading: false,
        error: null,
      )),
    );
  }

  @override
  Future<void> close() {
    _reverseEngineeringSubscription?.cancel();
    _manipulationAttemptsSubscription?.cancel();
    _suspiciousActivitiesSubscription?.cancel();
    return super.close();
  }
} 