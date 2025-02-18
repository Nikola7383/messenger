import 'package:equatable/equatable.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

enum VerificationType {
  qr,
  audio,
}

class VerificationChain extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final UserRole issuerRole;
  final UserRole targetRole;
  final VerificationType verificationType;
  final bool isRevoked;

  const VerificationChain({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.issuerRole,
    required this.targetRole,
    required this.verificationType,
    this.isRevoked = false,
  });

  bool get isValid => !isRevoked && DateTime.now().isBefore(expiresAt);
  
  bool isValidForRole(UserRole role) {
    if (!isValid) return false;
    if (role == targetRole) return true;
    
    switch (issuerRole) {
      case UserRole.secretMaster:
        return true;
      case UserRole.masterAdmin:
        return role == UserRole.regular || role == UserRole.glasnik;
      case UserRole.seed:
        return role == UserRole.glasnik;
      default:
        return false;
    }
  }

  VerificationChain copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? expiresAt,
    UserRole? issuerRole,
    UserRole? targetRole,
    VerificationType? verificationType,
    bool? isRevoked,
  }) {
    return VerificationChain(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      issuerRole: issuerRole ?? this.issuerRole,
      targetRole: targetRole ?? this.targetRole,
      verificationType: verificationType ?? this.verificationType,
      isRevoked: isRevoked ?? this.isRevoked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'issuerRole': issuerRole.toString(),
      'targetRole': targetRole.toString(),
      'verificationType': verificationType.toString(),
      'isRevoked': isRevoked,
    };
  }

  factory VerificationChain.fromJson(Map<String, dynamic> json) {
    return VerificationChain(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      issuerRole: UserRole.values.firstWhere(
        (e) => e.toString() == json['issuerRole'],
      ),
      targetRole: UserRole.values.firstWhere(
        (e) => e.toString() == json['targetRole'],
      ),
      verificationType: VerificationType.values.firstWhere(
        (e) => e.toString() == json['verificationType'],
      ),
      isRevoked: json['isRevoked'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    expiresAt,
    issuerRole,
    targetRole,
    verificationType,
    isRevoked,
  ];
} 