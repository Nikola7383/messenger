import 'package:flutter/material.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showSenderInfo;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.showSenderInfo = true,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.senderId == 'current_user_id'; // TODO: Get from auth
    final bubbleColor = isCurrentUser
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = isCurrentUser
      ? Theme.of(context).colorScheme.onPrimary
      : Theme.of(context).colorScheme.onSurfaceVariant;

    return Align(
      alignment: isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCurrentUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
        children: [
          if (showSenderInfo && !isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.senderId, // TODO: Get user name
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageContent(textColor),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeago.format(
                                message.timestamp,
                                locale: 'sr',
                              ),
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (message.isEncrypted)
                              Icon(
                                Icons.lock,
                                color: textColor.withOpacity(0.7),
                                size: 12,
                              ),
                            const SizedBox(width: 4),
                            _buildStatusIcon(textColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content['text'] as String,
          style: TextStyle(color: textColor),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.content['url'] as String,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            if (message.content['caption'] != null) ...[
              const SizedBox(height: 8),
              Text(
                message.content['caption'] as String,
                style: TextStyle(color: textColor),
              ),
            ],
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_fill,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio poruka',
              style: TextStyle(color: textColor),
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              message.content['name'] as String,
              style: TextStyle(color: textColor),
            ),
          ],
        );
      case MessageType.system:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.content['text'] as String,
            style: const TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  Widget _buildStatusIcon(Color color) {
    IconData iconData;
    switch (message.status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        break;
      case MessageStatus.sent:
        iconData = Icons.check;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(
      iconData,
      size: 14,
      color: color.withOpacity(0.7),
    );
  }
} 