import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/core/config/build_config.dart';
import 'package:glasnik/features/messaging/presentation/blocs/messaging_bloc.dart';
import 'package:glasnik/features/messaging/presentation/widgets/message_bubble.dart';
import 'package:glasnik/features/messaging/presentation/widgets/message_input.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

class RegularHomePage extends StatelessWidget {
  const RegularHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glasnik'),
        actions: [
          // Prikaži status konekcije
          BlocBuilder<MessagingBloc, MessagingState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  state.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: state.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista poruka
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
                    child: Text(
                      'Greška: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text('Nema poruka'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    return MessageBubble(
                      message: message,
                      onLongPress: () {}, // Nema opcija za regular build
                    );
                  },
                );
              },
            ),
          ),

          // Input za poruke (samo ako je verifikovan broj telefona)
          if (BuildConfig.requirePhoneVerification)
            BlocBuilder<MessagingBloc, MessagingState>(
              builder: (context, state) {
                if (!state.isPhoneVerified) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Da biste slali poruke, potrebno je da verifikujete broj telefona',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Implementirati verifikaciju broja
                          },
                          child: const Text('Verifikuj Broj'),
                        ),
                      ],
                    ),
                  );
                }

                return MessageInput(
                  onSendMessage: (content, type) {
                    context.read<MessagingBloc>().add(
                      SendMessage(
                        message: {
                          'content': content,
                          'type': type,
                        },
                      ),
                    );
                  },
                  allowedTypes: const ['text'], // Samo tekstualne poruke
                );
              },
            ),
        ],
      ),
    );
  }
} 