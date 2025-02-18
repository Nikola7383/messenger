import 'package:glasnik/features/auth/domain/entities/user.dart';

abstract class IAuthRepository {
  Future<User?> getCurrentUser();
  Future<User> verifyGuest();
  Future<User> verifyRegular();
  Future<User> verifyMasterAdmin(String qrData, String soundData);
  Future<User> verifySecretMaster(String biometricData);
  Future<User> verifySeed(String verificationData);
  Future<User> verifyGlasnik(String verificationData);
  Future<void> logout();
  Future<void> updateLastActive();
  Future<bool> isValidVerificationChain(String chain);
  Future<String> generateVerificationData();
  Future<void> invalidateUser(String userId);
} 