import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/auth/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

class AuthRepository implements IAuthRepository {
  final FlutterSecureStorage _storage;
  final _uuid = const Uuid();

  AuthRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: 'current_user');
    if (userData == null) return null;

    final Map<String, dynamic> data = json.decode(userData);
    return _createUserFromData(data);
  }

  @override
  Future<User> verifyGuest() async {
    final user = User(
      id: _uuid.v4(),
      role: UserRole.guest,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<User> verifyRegular() async {
    // TODO: Implementirati verifikaciju telefona
    final user = User(
      id: _uuid.v4(),
      role: UserRole.regular,
      isVerified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<User> verifyMasterAdmin(String qrData, String soundData) async {
    if (!_isValidMasterAdminData(qrData, soundData)) {
      throw Exception('Nevažeći verifikacioni podaci');
    }

    final user = User(
      id: _uuid.v4(),
      role: UserRole.masterAdmin,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      verificationChain: _generateVerificationChain(),
      isVerified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<User> verifySecretMaster(String biometricData) async {
    if (biometricData != 'biometric_success') {
      throw Exception('Biometrijska verifikacija nije uspela');
    }

    final user = User(
      id: _uuid.v4(),
      role: UserRole.secretMaster,
      verificationChain: _generateRootChain(),
      isVerified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<User> verifySeed(String verificationData) async {
    if (!await isValidVerificationChain(verificationData)) {
      throw Exception('Nevažeći verifikacioni lanac');
    }

    final user = User(
      id: _uuid.v4(),
      role: UserRole.seed,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      verificationChain: verificationData,
      isVerified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<User> verifyGlasnik(String verificationData) async {
    if (!await isValidVerificationChain(verificationData)) {
      throw Exception('Nevažeći verifikacioni lanac');
    }

    final user = User(
      id: _uuid.v4(),
      role: UserRole.glasnik,
      validUntil: DateTime.now().add(const Duration(hours: 48)),
      verificationChain: verificationData,
      isVerified: true,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'current_user');
  }

  @override
  Future<void> updateLastActive() async {
    final user = await getCurrentUser();
    if (user == null) return;

    final updatedUser = user.copyWith(
      lastActive: DateTime.now(),
    );

    await _saveUser(updatedUser);
  }

  @override
  Future<bool> isValidVerificationChain(String chain) async {
    // TODO: Implementirati proveru lanca verifikacije
    return true;
  }

  @override
  Future<String> generateVerificationData() async {
    return _generateVerificationChain();
  }

  @override
  Future<void> invalidateUser(String userId) async {
    final user = await getCurrentUser();
    if (user?.id == userId) {
      await logout();
    }
  }

  Future<void> _saveUser(User user) async {
    final userData = {
      'id': user.id,
      'role': user.role.toString(),
      'validUntil': user.validUntil?.toIso8601String(),
      'verificationChain': user.verificationChain,
      'isVerified': user.isVerified,
      'phoneNumber': user.phoneNumber,
      'createdAt': user.createdAt.toIso8601String(),
      'lastActive': user.lastActive.toIso8601String(),
    };

    await _storage.write(
      key: 'current_user',
      value: json.encode(userData),
    );
  }

  User _createUserFromData(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == data['role'],
      ),
      validUntil: data['validUntil'] != null
          ? DateTime.parse(data['validUntil'])
          : null,
      verificationChain: data['verificationChain'],
      isVerified: data['isVerified'],
      phoneNumber: data['phoneNumber'],
      createdAt: DateTime.parse(data['createdAt']),
      lastActive: DateTime.parse(data['lastActive']),
    );
  }

  bool _isValidMasterAdminData(String qrData, String soundData) {
    // TODO: Implementirati validaciju QR i zvučnih podataka
    return true;
  }

  String _generateVerificationChain() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _uuid.v4();
    final data = '$timestamp:$random';
    return sha256.convert(utf8.encode(data)).toString();
  }

  String _generateRootChain() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _uuid.v4();
    final data = 'root:$timestamp:$random';
    return sha256.convert(utf8.encode(data)).toString();
  }
} 