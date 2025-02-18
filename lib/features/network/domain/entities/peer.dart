import 'package:equatable/equatable.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

class Peer extends Equatable {
  final String id;
  final String deviceName;
  final UserRole role;
  final bool isConnected;
  final DateTime lastSeen;
  final int signalStrength; // u dBm
  final Map<String, dynamic> capabilities;
  final String verificationChain;

  const Peer({
    required this.id,
    required this.deviceName,
    required this.role,
    required this.isConnected,
    required this.lastSeen,
    required this.signalStrength,
    required this.capabilities,
    required this.verificationChain,
  });

  bool get isRelay => capabilities['canRelay'] == true;
  bool get supportsAudio => capabilities['supportsAudio'] == true;
  bool get supportsQr => capabilities['supportsQr'] == true;

  Peer copyWith({
    String? id,
    String? deviceName,
    UserRole? role,
    bool? isConnected,
    DateTime? lastSeen,
    int? signalStrength,
    Map<String, dynamic>? capabilities,
    String? verificationChain,
  }) {
    return Peer(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      role: role ?? this.role,
      isConnected: isConnected ?? this.isConnected,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
      capabilities: capabilities ?? this.capabilities,
      verificationChain: verificationChain ?? this.verificationChain,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceName,
        role,
        isConnected,
        lastSeen,
        signalStrength,
        capabilities,
        verificationChain,
      ];
} 