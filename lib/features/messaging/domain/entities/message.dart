import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:glasnik/features/auth/domain/entities/user.dart';

enum MessageType {
  text,
  image,
  audio,
  file,
  system,
  verification,
  command,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class Message extends Equatable {
  final String id;
  final String senderId;
  final String? receiverId; // null za broadcast
  final MessageType type;
  final Map<String, dynamic> content;
  final DateTime timestamp;
  final MessageStatus status;
  final int ttl; // Time To Live u minutima
  final List<String> routingPath;
  final String? encryptionKey;
  final bool isEncrypted;
  final String? signature; // Digitalni potpis za verifikaciju autentičnosti
  final int priority; // 0-100, veći broj = veći prioritet

  const Message({
    String? id,
    required this.senderId,
    this.receiverId,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    this.ttl = 60, // 1 sat default
    List<String>? routingPath,
    this.encryptionKey,
    this.isEncrypted = true,
    this.signature,
    this.priority = 50,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       routingPath = routingPath ?? [senderId];

  bool get isBroadcast => receiverId == null;
  bool get isExpired => DateTime.now().difference(timestamp).inMinutes > ttl;
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;
  bool get needsRelay => routingPath.length < 3; // Max 3 hopa

  // Veličina poruke u bajtovima (za optimizaciju)
  int get sizeInBytes {
    return id.length +
           senderId.length +
           (receiverId?.length ?? 0) +
           4 + // type enum
           content.toString().length +
           8 + // timestamp
           4 + // status enum
           4 + // ttl
           routingPath.fold<int>(0, (sum, path) => sum + path.length) +
           (encryptionKey?.length ?? 0) +
           1 + // isEncrypted bool
           (signature?.length ?? 0) +
           4; // priority
  }

  // Proveri da li korisnik ima dozvolu za slanje ovog tipa poruke
  bool canUserSend(UserRole userRole) {
    switch (type) {
      case MessageType.text:
        return true; // Svi korisnici mogu slati tekstualne poruke
      case MessageType.image:
      case MessageType.audio:
      case MessageType.file:
        return userRole == UserRole.masterAdmin || 
               userRole == UserRole.secretMaster ||
               userRole == UserRole.seed; // Samo privilegovani korisnici
      case MessageType.system:
        return userRole == UserRole.masterAdmin || 
               userRole == UserRole.secretMaster; // Samo admin poruke
      case MessageType.verification:
        return userRole == UserRole.masterAdmin || 
               userRole == UserRole.secretMaster ||
               userRole == UserRole.seed; // Samo verifikatori
      case MessageType.command:
        return userRole == UserRole.masterAdmin || 
               userRole == UserRole.secretMaster; // Samo najviše privilegije
    }
  }

  // Proveri da li je poruka validna za mrežni prenos
  bool isValidForTransmission() {
    // Proveri veličinu poruke bazirano na tipu
    switch (type) {
      case MessageType.text:
        return content['text'].length <= 1024; // Max 1KB za tekst
      case MessageType.image:
        return content['size'] <= 1024 * 1024; // Max 1MB za slike
      case MessageType.audio:
        return content['duration'] <= 60; // Max 60 sekundi
      case MessageType.file:
        return content['size'] <= 5 * 1024 * 1024; // Max 5MB za fajlove
      case MessageType.system:
      case MessageType.verification:
      case MessageType.command:
        return true; // Sistemske poruke nemaju ograničenja
    }
  }

  // Generiši digitalni potpis
  String generateSignature(String privateKey) {
    final data = '$id$senderId$receiverId$type${content.toString()}${timestamp.toIso8601String()}';
    final key = utf8.encode(privateKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  // Verifikuj digitalni potpis
  bool verifySignature(String publicKey) {
    if (signature == null) return false;
    final data = '$id$senderId$receiverId$type${content.toString()}${timestamp.toIso8601String()}';
    final key = utf8.encode(publicKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final expectedSignature = hmac.convert(bytes).toString();
    return signature == expectedSignature;
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    MessageType? type,
    Map<String, dynamic>? content,
    DateTime? timestamp,
    MessageStatus? status,
    int? ttl,
    List<String>? routingPath,
    String? encryptionKey,
    bool? isEncrypted,
    String? signature,
    int? priority,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      ttl: ttl ?? this.ttl,
      routingPath: routingPath ?? this.routingPath,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      signature: signature ?? this.signature,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'ttl': ttl,
      'routingPath': routingPath,
      'isEncrypted': isEncrypted,
      'signature': signature,
      'priority': priority,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      ttl: json['ttl'],
      routingPath: List<String>.from(json['routingPath']),
      isEncrypted: json['isEncrypted'],
      signature: json['signature'],
      priority: json['priority'] ?? 50,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    type,
    content,
    timestamp,
    status,
    ttl,
    routingPath,
    encryptionKey,
    isEncrypted,
    signature,
    priority,
  ];
} 