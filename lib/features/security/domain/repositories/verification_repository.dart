import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/security/domain/entities/verification_chain.dart';

abstract class IVerificationRepository {
  /// Generiše QR kod za verifikaciju
  Future<String> generateQrCode({
    required UserRole issuerRole,
    required UserRole targetRole,
    Duration? validity,
  });

  /// Verifikuje QR kod
  Future<VerificationChain> verifyQrCode(String qrData);

  /// Generiše zvučni signal za verifikaciju
  Future<List<int>> generateAudioSignal({
    required UserRole issuerRole,
    required UserRole targetRole,
    Duration? validity,
  });

  /// Verifikuje zvučni signal
  Future<VerificationChain> verifyAudioSignal(List<int> audioData);

  /// Verifikuje verifikacioni lanac
  Future<bool> verifyChain(VerificationChain chain);

  /// Revokuje verifikacioni lanac
  Future<void> revokeChain(String chainId);

  /// Vraća sve aktivne verifikacione lance
  Future<List<VerificationChain>> getActiveChains();

  /// Vraća istoriju verifikacija za korisnika
  Future<List<VerificationChain>> getUserVerificationHistory(String userId);

  /// Proverava da li je verifikacioni lanac validan za određenu ulogu
  Future<bool> isChainValidForRole(String chainId, UserRole role);
} 