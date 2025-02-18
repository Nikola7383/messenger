import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/presentation/blocs/messaging_bloc.dart';
import 'package:uuid/uuid.dart';

class NewConversationDialog extends StatefulWidget {
  const NewConversationDialog({super.key});

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  ConversationType _type = ConversationType.direct;
  bool _isEncrypted = true;
  final List<String> _participants = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova konverzacija'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Naziv',
                  hintText: 'Unesite naziv konverzacije',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Naziv je obavezan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ConversationType>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Tip konverzacije',
                ),
                items: ConversationType.values.map((type) {
                  String label;
                  switch (type) {
                    case ConversationType.direct:
                      label = 'Direktna';
                      break;
                    case ConversationType.group:
                      label = 'Grupna';
                      break;
                    case ConversationType.broadcast:
                      label = 'Broadcast';
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('End-to-end enkripcija'),
                subtitle: const Text(
                  'Poruke će biti enkriptovane i vidljive samo učesnicima',
                ),
                value: _isEncrypted,
                onChanged: (value) {
                  setState(() {
                    _isEncrypted = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Dodaj učesnike'),
                onPressed: _showParticipantsDialog,
              ),
              if (_participants.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _participants.map((participant) {
                    return Chip(
                      label: Text(participant),
                      onDeleted: () {
                        setState(() {
                          _participants.remove(participant);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _createConversation,
          child: const Text('Kreiraj'),
        ),
      ],
    );
  }

  void _showParticipantsDialog() {
    // TODO: Implementiraj dijalog za izbor učesnika
    // Za sada samo dodajemo test učesnike
    setState(() {
      _participants.add('user_${_participants.length + 1}');
    });
  }

  void _createConversation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dodajte bar jednog učesnika'),
        ),
      );
      return;
    }

    final conversation = Conversation(
      id: const Uuid().v4(),
      title: _titleController.text,
      type: _type,
      participants: _participants,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      isEncrypted: _isEncrypted,
    );

    context.read<MessagingBloc>().add(CreateConversation(conversation));
    Navigator.pop(context);
  }
} 