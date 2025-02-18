import 'package:flutter/material.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingIcon(),
      title: Text(
        conversation.title,
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0
            ? FontWeight.bold
            : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.lastMessage != null)
            Text(
              _getLastMessagePreview(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Text(
            _getLastActivityTime(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: _buildTrailingWidget(),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildLeadingIcon() {
    IconData iconData;
    Color iconColor;

    switch (conversation.type) {
      case ConversationType.direct:
        iconData = Icons.person;
        iconColor = Colors.blue;
        break;
      case ConversationType.group:
        iconData = Icons.group;
        iconColor = Colors.green;
        break;
      case ConversationType.broadcast:
        iconData = Icons.campaign;
        iconColor = Colors.orange;
        break;
    }

    return Stack(
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        if (conversation.isEncrypted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailingWidget() {
    if (conversation.unreadCount > 0) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        child: Text(
          conversation.unreadCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Text(
      _getParticipantsCount(),
      style: const TextStyle(
        color: Colors.grey,
      ),
    );
  }

  String _getLastMessagePreview() {
    if (conversation.lastMessage == null) {
      return 'Nema poruka';
    }

    final content = conversation.lastMessage!.content;
    switch (conversation.lastMessage!.type) {
      case MessageType.text:
        return content['text'] as String;
      case MessageType.image:
        return '📷 Slika';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.file:
        return '📎 Fajl';
      case MessageType.system:
        return '🔔 ${content['text']}';
    }
  }

  String _getLastActivityTime() {
    return timeago.format(
      conversation.lastActivity,
      locale: 'sr',
    );
  }

  String _getParticipantsCount() {
    final count = conversation.participants.length;
    return '$count ${count == 1 ? 'učesnik' : 'učesnika'}';
  }
} 