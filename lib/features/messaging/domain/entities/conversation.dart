import 'package:equatable/equatable.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';

enum ConversationType {
  direct,
  group,
  broadcast,
}

class Conversation extends Equatable {
  final String id;
  final String title;
  final ConversationType type;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime lastActivity;
  final Message? lastMessage;
  final int unreadCount;
  final bool isEncrypted;
  final Map<String, dynamic>? metadata;

  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.participants,
    required this.createdAt,
    required this.lastActivity,
    this.lastMessage,
    this.unreadCount = 0,
    this.isEncrypted = true,
    this.metadata,
  });

  bool get isGroup => type == ConversationType.group;
  bool get isBroadcast => type == ConversationType.broadcast;
  bool get isDirect => type == ConversationType.direct;

  Conversation copyWith({
    String? id,
    String? title,
    ConversationType? type,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? lastActivity,
    Message? lastMessage,
    int? unreadCount,
    bool? isEncrypted,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.toString(),
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isEncrypted': isEncrypted,
      'metadata': metadata,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      type: ConversationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      participants: List<String>.from(json['participants']),
      createdAt: DateTime.parse(json['createdAt']),
      lastActivity: DateTime.parse(json['lastActivity']),
      lastMessage: json['lastMessage'] != null 
        ? Message.fromJson(json['lastMessage'])
        : null,
      unreadCount: json['unreadCount'],
      isEncrypted: json['isEncrypted'],
      metadata: json['metadata'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    type,
    participants,
    createdAt,
    lastActivity,
    lastMessage,
    unreadCount,
    isEncrypted,
    metadata,
  ];
} 