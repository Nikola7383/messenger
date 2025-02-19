import 'package:equatable/equatable.dart';

class SecureData extends Equatable {
  final String data;
  final String iv;
  final String salt;
  final String version;
  final DateTime createdAt;
  final DateTime lastModified;
  final String checksum;
  final Map<String, dynamic>? metadata;

  const SecureData({
    required this.data,
    required this.iv,
    required this.salt,
    required this.version,
    required this.createdAt,
    required this.lastModified,
    required this.checksum,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'iv': iv,
      'salt': salt,
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'checksum': checksum,
      'metadata': metadata,
    };
  }

  factory SecureData.fromJson(Map<String, dynamic> json) {
    return SecureData(
      data: json['data'],
      iv: json['iv'],
      salt: json['salt'],
      version: json['version'],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      checksum: json['checksum'],
      metadata: json['metadata'],
    );
  }

  SecureData copyWith({
    String? data,
    String? iv,
    String? salt,
    String? version,
    DateTime? createdAt,
    DateTime? lastModified,
    String? checksum,
    Map<String, dynamic>? metadata,
  }) {
    return SecureData(
      data: data ?? this.data,
      iv: iv ?? this.iv,
      salt: salt ?? this.salt,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      checksum: checksum ?? this.checksum,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    data,
    iv,
    salt,
    version,
    createdAt,
    lastModified,
    checksum,
    metadata,
  ];
} 