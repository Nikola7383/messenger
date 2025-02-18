import 'package:equatable/equatable.dart';

enum UserRole {
  guest,
  regular,
  glasnik,
  seed,
  masterAdmin,
  secretMaster,
}

class User extends Equatable {
  final String id;
  final UserRole role;
  final DateTime? validUntil;
  final String? verificationChain;
  final bool isVerified;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastActive;

  const User({
    required this.id,
    required this.role,
    this.validUntil,
    this.verificationChain,
    this.isVerified = false,
    this.phoneNumber,
    required this.createdAt,
    required this.lastActive,
  });

  bool get isValid {
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }

  bool get isGlasnik => role == UserRole.glasnik;
  bool get isSeed => role == UserRole.seed;
  bool get isMasterAdmin => role == UserRole.masterAdmin;
  bool get isSecretMaster => role == UserRole.secretMaster;
  bool get isGuest => role == UserRole.guest;
  bool get isRegular => role == UserRole.regular;

  User copyWith({
    String? id,
    UserRole? role,
    DateTime? validUntil,
    String? verificationChain,
    bool? isVerified,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      validUntil: validUntil ?? this.validUntil,
      verificationChain: verificationChain ?? this.verificationChain,
      isVerified: isVerified ?? this.isVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    validUntil,
    verificationChain,
    isVerified,
    phoneNumber,
    createdAt,
    lastActive,
  ];
} 