import 'package:equatable/equatable.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

enum UserStatus {
  active,
  suspended,
  revoked,
  pending,
}

class UserManagementEntry extends Equatable {
  final User user;
  final UserStatus status;
  final DateTime lastActivity;
  final String? verifiedBy;
  final DateTime? verificationDate;
  final List<String> verificationChainPath;
  final Map<String, dynamic> securityMetrics;
  final List<Map<String, dynamic>> activityLog;
  final Map<String, dynamic> permissions;
  final bool isCompromised;

  const UserManagementEntry({
    required this.user,
    required this.status,
    required this.lastActivity,
    this.verifiedBy,
    this.verificationDate,
    this.verificationChainPath = const [],
    this.securityMetrics = const {},
    this.activityLog = const [],
    this.permissions = const {},
    this.isCompromised = false,
  });

  bool get canBeVerified => 
    status == UserStatus.pending && 
    verificationChainPath.isEmpty;

  bool get canBeRevoked =>
    status == UserStatus.active || 
    status == UserStatus.suspended;

  bool get requiresAttention =>
    isCompromised || 
    hasAnomalousActivity ||
    hasLowTrustScore;

  bool get hasAnomalousActivity =>
    securityMetrics['anomaly_score'] != null &&
    (securityMetrics['anomaly_score'] as num) > 0.7;

  bool get hasLowTrustScore =>
    securityMetrics['trust_score'] != null &&
    (securityMetrics['trust_score'] as num) < 0.3;

  UserManagementEntry copyWith({
    User? user,
    UserStatus? status,
    DateTime? lastActivity,
    String? verifiedBy,
    DateTime? verificationDate,
    List<String>? verificationChainPath,
    Map<String, dynamic>? securityMetrics,
    List<Map<String, dynamic>>? activityLog,
    Map<String, dynamic>? permissions,
    bool? isCompromised,
  }) {
    return UserManagementEntry(
      user: user ?? this.user,
      status: status ?? this.status,
      lastActivity: lastActivity ?? this.lastActivity,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationDate: verificationDate ?? this.verificationDate,
      verificationChainPath: verificationChainPath ?? this.verificationChainPath,
      securityMetrics: securityMetrics ?? this.securityMetrics,
      activityLog: activityLog ?? this.activityLog,
      permissions: permissions ?? this.permissions,
      isCompromised: isCompromised ?? this.isCompromised,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'status': status.toString(),
      'lastActivity': lastActivity.toIso8601String(),
      'verifiedBy': verifiedBy,
      'verificationDate': verificationDate?.toIso8601String(),
      'verificationChainPath': verificationChainPath,
      'securityMetrics': securityMetrics,
      'activityLog': activityLog,
      'permissions': permissions,
      'isCompromised': isCompromised,
    };
  }

  factory UserManagementEntry.fromJson(Map<String, dynamic> json) {
    return UserManagementEntry(
      user: User.fromJson(json['user']),
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      lastActivity: DateTime.parse(json['lastActivity']),
      verifiedBy: json['verifiedBy'],
      verificationDate: json['verificationDate'] != null
          ? DateTime.parse(json['verificationDate'])
          : null,
      verificationChainPath: List<String>.from(json['verificationChainPath']),
      securityMetrics: Map<String, dynamic>.from(json['securityMetrics']),
      activityLog: List<Map<String, dynamic>>.from(json['activityLog']),
      permissions: Map<String, dynamic>.from(json['permissions']),
      isCompromised: json['isCompromised'],
    );
  }

  @override
  List<Object?> get props => [
    user,
    status,
    lastActivity,
    verifiedBy,
    verificationDate,
    verificationChainPath,
    securityMetrics,
    activityLog,
    permissions,
    isCompromised,
  ];
} 