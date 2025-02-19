import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/core/utils/phone_utils.dart';

// Events
abstract class PhoneVerificationEvent extends Equatable {
  const PhoneVerificationEvent();

  @override
  List<Object?> get props => [];
}

class SendVerificationRequested extends PhoneVerificationEvent {
  final String phoneNumber;

  const SendVerificationRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyCodeSubmitted extends PhoneVerificationEvent {
  final String code;

  const VerifyCodeSubmitted(this.code);

  @override
  List<Object?> get props => [code];
}

// State
class PhoneVerificationState extends Equatable {
  final bool isLoading;
  final bool isCodeSent;
  final bool isVerified;
  final String? phoneNumber;
  final String? error;

  const PhoneVerificationState({
    this.isLoading = false,
    this.isCodeSent = false,
    this.isVerified = false,
    this.phoneNumber,
    this.error,
  });

  PhoneVerificationState copyWith({
    bool? isLoading,
    bool? isCodeSent,
    bool? isVerified,
    String? phoneNumber,
    String? error,
  }) {
    return PhoneVerificationState(
      isLoading: isLoading ?? this.isLoading,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isVerified: isVerified ?? this.isVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isCodeSent,
    isVerified,
    phoneNumber,
    error,
  ];
}

// Bloc
class PhoneVerificationBloc extends Bloc<PhoneVerificationEvent, PhoneVerificationState> {
  PhoneVerificationBloc() : super(const PhoneVerificationState()) {
    on<SendVerificationRequested>(_onSendVerificationRequested);
    on<VerifyCodeSubmitted>(_onVerifyCodeSubmitted);
  }

  Future<void> _onSendVerificationRequested(
    SendVerificationRequested event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      // Validiraj broj telefona
      if (!PhoneUtils.isValidPhoneNumber(event.phoneNumber)) {
        throw Exception('Nevažeći broj telefona');
      }

      // Proveri da li se podudara sa SIM karticom
      final matches = await PhoneUtils.matchesSimCard(event.phoneNumber);
      if (!matches) {
        throw Exception('Broj se ne podudara sa SIM karticom');
      }

      // TODO: Implementirati slanje verifikacionog koda
      // Za sada samo simuliramo slanje
      await Future.delayed(const Duration(seconds: 2));

      emit(state.copyWith(
        isLoading: false,
        isCodeSent: true,
        phoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onVerifyCodeSubmitted(
    VerifyCodeSubmitted event,
    Emitter<PhoneVerificationState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      if (event.code.length != 6) {
        throw Exception('Kod mora imati 6 cifara');
      }

      // TODO: Implementirati verifikaciju koda
      // Za sada samo simuliramo verifikaciju
      await Future.delayed(const Duration(seconds: 2));

      // Simuliramo uspešnu verifikaciju ako je kod "123456"
      if (event.code != "123456") {
        throw Exception('Nevažeći verifikacioni kod');
      }

      emit(state.copyWith(
        isLoading: false,
        isVerified: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
} 