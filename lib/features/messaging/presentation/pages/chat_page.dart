import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:glasnik/features/messaging/presentation/blocs/messaging_bloc.dart';
import 'package:glasnik/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:glasnik/features/messaging/presentation/widgets/message_input.dart';

class ChatPage extends StatelessWidget {
  final Conversation conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation.title),
            Text(
              _getSubtitle(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (conversation.isEncrypted)
            const Icon(
              Icons.lock,
              color: Colors.green,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Greška: ${state.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MessagingBloc>().add(
                              LoadMessages(conversation.id),
                            );
                          },
                          child: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = state.messages[conversation.id] ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Nema poruka'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final previousMessage = index < messages.length - 1
                      ? messages[index + 1]
                      : null;
                    final showSenderInfo = previousMessage == null ||
                      previousMessage.senderId != message.senderId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MessageBubble(
                        message: message,
                        showSenderInfo: showSenderInfo,
                        onLongPress: () => _showMessageOptions(
                          context,
                          message,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            conversation: conversation,
            onSendMessage: (content, type) {
              final message = Message(
                senderId: 'current_user_id', // TODO: Get from auth
                receiverId: conversation.id,
                type: type,
                content: content,
              );
              context.read<MessagingBloc>().add(SendMessage(message));
            },
          ),
        ],
      ),
    );
  }

  String _getSubtitle() {
    final count = conversation.participants.length;
    switch (conversation.type) {
      case ConversationType.direct:
        return 'Direktna konverzacija';
      case ConversationType.group:
        return '$count učesnika';
      case ConversationType.broadcast:
        return 'Broadcast • $count primalaca';
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Učesnici'),
              onTap: () {
                Navigator.pop(context);
                _showParticipants(context);
              },
            ),
            if (conversation.type != ConversationType.direct)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Dodaj učesnike'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementiraj dodavanje učesnika
                },
              ),
            if (!conversation.isEncrypted)
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Uključi enkripciju'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implementiraj uključivanje enkripcije
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Obriši konverzaciju'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipants(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Učesnici'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: conversation.participants.length,
            itemBuilder: (context, index) {
              final participant = conversation.participants[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(participant),
                trailing: conversation.type != ConversationType.direct
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () {
                        // TODO: Implementiraj uklanjanje učesnika
                      },
                    )
                  : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši konverzaciju'),
        content: const Text(
          'Da li ste sigurni da želite da obrišete ovu konverzaciju? '
          'Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () {
              context.read<MessagingBloc>().add(
                DeleteConversation(conversation.id),
              );
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Kopiraj'),
              onTap: () {
                // TODO: Implementiraj kopiranje poruke
                Navigator.pop(context);
              },
            ),
            if (message.senderId == 'current_user_id') // TODO: Get from auth
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Obriši'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(context, message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Detalji'),
              onTap: () {
                Navigator.pop(context);
                _showMessageDetails(context, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši poruku'),
        content: const Text(
          'Da li ste sigurni da želite da obrišete ovu poruku? '
          'Ova akcija se ne može poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementiraj brisanje poruke
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  void _showMessageDetails(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalji poruke'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${message.id}'),
            const SizedBox(height: 8),
            Text('Tip: ${message.type.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Status: ${message.status.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Vreme: ${message.timestamp.toString().split('.').first}'),
            if (message.isEncrypted) ...[
              const SizedBox(height: 8),
              const Text('🔒 End-to-end enkriptovana'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }
} 