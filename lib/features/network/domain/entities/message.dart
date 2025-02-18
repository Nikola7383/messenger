import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

enum MessageType {
  text,
  verification,
  command,
  heartbeat,
  routingTable,
  systemAlert,
}

enum MessagePriority {
  low,
  normal,
  high,
  critical,
}

class NetworkMessage extends Equatable {
  final String id;
  final String senderId;
  final String? targetId; // null za broadcast
  final MessageType type;
  final MessagePriority priority;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int ttl; // Time To Live
  final List<String> routingPath;
  final String? encryptionKey;
  final bool isEncrypted;
  final Map<String, dynamic>? metadata;

  NetworkMessage({
    String? id,
    required this.senderId,
    this.targetId,
    required this.type,
    this.priority = MessagePriority.normal,
    required this.payload,
    DateTime? timestamp,
    this.ttl = 10,
    List<String>? routingPath,
    this.encryptionKey,
    this.isEncrypted = true,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        routingPath = routingPath ?? [senderId];

  bool get isBroadcast => targetId == null;
  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > ttl;
  bool get requiresAck => priority != MessagePriority.low;

  NetworkMessage copyWith({
    String? id,
    String? senderId,
    String? targetId,
    MessageType? type,
    MessagePriority? priority,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? ttl,
    List<String>? routingPath,
    String? encryptionKey,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      routingPath: routingPath ?? this.routingPath,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'targetId': targetId,
      'type': type.toString(),
      'priority': priority.toString(),
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl,
      'routingPath': routingPath,
      'isEncrypted': isEncrypted,
      'metadata': metadata,
    };
  }

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      id: json['id'],
      senderId: json['senderId'],
      targetId: json['targetId'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
      ),
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'],
      routingPath: List<String>.from(json['routingPath']),
      isEncrypted: json['isEncrypted'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        targetId,
        type,
        priority,
        payload,
        timestamp,
        ttl,
        routingPath,
        encryptionKey,
        isEncrypted,
        metadata,
      ];
} 