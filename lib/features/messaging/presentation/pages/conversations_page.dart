import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/presentation/blocs/messaging_bloc.dart';
import 'package:glasnik/features/messaging/presentation/widgets/conversation_tile.dart';
import 'package:glasnik/features/messaging/presentation/widgets/new_conversation_dialog.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konverzacije'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewConversationDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<MessagingBloc, MessagingState>(
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
                      context.read<MessagingBloc>().add(LoadConversations());
                    },
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            );
          }

          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Nema aktivnih konverzacija'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showNewConversationDialog(context),
                    child: const Text('Započni novu konverzaciju'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<MessagingBloc>().add(LoadConversations());
            },
            child: ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () => _navigateToChat(context, conversation),
                  onLongPress: () => _showConversationOptions(
                    context,
                    conversation,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewConversationDialog(),
    );
  }

  void _navigateToChat(BuildContext context, Conversation conversation) {
    // Učitaj poruke pre navigacije
    context.read<MessagingBloc>().add(LoadMessages(conversation.id));
    
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: conversation,
    );
  }

  void _showConversationOptions(
    BuildContext context,
    Conversation conversation,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Obriši konverzaciju'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation(context, conversation);
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
              leading: const Icon(Icons.info),
              title: const Text('Detalji'),
              onTap: () {
                Navigator.pop(context);
                _showConversationDetails(context, conversation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(
    BuildContext context,
    Conversation conversation,
  ) {
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

  void _showConversationDetails(
    BuildContext context,
    Conversation conversation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalji konverzacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Naziv: ${conversation.title}'),
            const SizedBox(height: 8),
            Text('Tip: ${conversation.type.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Učesnici: ${conversation.participants.length}'),
            const SizedBox(height: 8),
            Text(
              'Enkripcija: ${conversation.isEncrypted ? 'Uključena' : 'Isključena'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Kreirana: ${conversation.createdAt.toString().split('.').first}',
            ),
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