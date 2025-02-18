import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/security/domain/entities/verification_chain.dart';
import 'package:glasnik/features/security/domain/repositories/verification_repository.dart';

// Events
abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object?> get props => [];
}

class VerificationStarted extends VerificationEvent {
  final UserRole issuerRole;
  final UserRole targetRole;
  final VerificationType type;
  final Duration? validity;

  const VerificationStarted({
    required this.issuerRole,
    required this.targetRole,
    required this.type,
    this.validity,
  });

  @override
  List<Object?> get props => [issuerRole, targetRole, type, validity];
}

class QrCodeScanned extends VerificationEvent {
  final String qrData;

  const QrCodeScanned(this.qrData);

  @override
  List<Object?> get props => [qrData];
}

class AudioSignalDetected extends VerificationEvent {
  final List<int> audioData;

  const AudioSignalDetected(this.audioData);

  @override
  List<Object?> get props => [audioData];
}

class ChainVerificationRequested extends VerificationEvent {
  final VerificationChain chain;

  const ChainVerificationRequested(this.chain);

  @override
  List<Object?> get props => [chain];
}

// State
class VerificationState extends Equatable {
  final bool isLoading;
  final String? error;
  final String? qrCode;
  final List<int>? audioSignal;
  final VerificationChain? currentChain;
  final bool isValid;

  const VerificationState({
    this.isLoading = false,
    this.error,
    this.qrCode,
    this.audioSignal,
    this.currentChain,
    this.isValid = false,
  });

  VerificationState copyWith({
    bool? isLoading,
    String? error,
    String? qrCode,
    List<int>? audioSignal,
    VerificationChain? currentChain,
    bool? isValid,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      qrCode: qrCode ?? this.qrCode,
      audioSignal: audioSignal ?? this.audioSignal,
      currentChain: currentChain ?? this.currentChain,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    error,
    qrCode,
    audioSignal,
    currentChain,
    isValid,
  ];
}

// Bloc
class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final IVerificationRepository _verificationRepository;

  VerificationBloc({
    required IVerificationRepository verificationRepository,
  })  : _verificationRepository = verificationRepository,
        super(const VerificationState()) {
    on<VerificationStarted>(_onVerificationStarted);
    on<QrCodeScanned>(_onQrCodeScanned);
    on<AudioSignalDetected>(_onAudioSignalDetected);
    on<ChainVerificationRequested>(_onChainVerificationRequested);
  }

  Future<void> _onVerificationStarted(
    VerificationStarted event,
    Emitter<VerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      if (event.type == VerificationType.qr) {
        final qrCode = await _verificationRepository.generateQrCode(
          issuerRole: event.issuerRole,
          targetRole: event.targetRole,
          validity: event.validity,
        );
        emit(state.copyWith(qrCode: qrCode, isLoading: false));
      } else {
        final audioSignal = await _verificationRepository.generateAudioSignal(
          issuerRole: event.issuerRole,
          targetRole: event.targetRole,
          validity: event.validity,
        );
        emit(state.copyWith(audioSignal: audioSignal, isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onQrCodeScanned(
    QrCodeScanned event,
    Emitter<VerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final chain = await _verificationRepository.verifyQrCode(event.qrData);
      final isValid = await _verificationRepository.verifyChain(chain);

      emit(state.copyWith(
        currentChain: chain,
        isValid: isValid,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
        isValid: false,
      ));
    }
  }

  Future<void> _onAudioSignalDetected(
    AudioSignalDetected event,
    Emitter<VerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final chain = await _verificationRepository.verifyAudioSignal(event.audioData);
      final isValid = await _verificationRepository.verifyChain(chain);

      emit(state.copyWith(
        currentChain: chain,
        isValid: isValid,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
        isValid: false,
      ));
    }
  }

  Future<void> _onChainVerificationRequested(
    ChainVerificationRequested event,
    Emitter<VerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final isValid = await _verificationRepository.verifyChain(event.chain);

      emit(state.copyWith(
        currentChain: event.chain,
        isValid: isValid,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
        isValid: false,
      ));
    }
  }
} 