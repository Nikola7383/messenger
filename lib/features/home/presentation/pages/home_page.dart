import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/network/presentation/blocs/network_bloc.dart';
import 'package:glasnik/features/network/domain/entities/peer.dart';
import 'package:glasnik/features/network/domain/entities/message.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<NetworkBloc, NetworkState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
          },
          builder: (context, networkState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Glasnik'),
                actions: [
                  IconButton(
                    icon: Icon(
                      networkState.isRunning ? Icons.wifi : Icons.wifi_off,
                      color: networkState.isRunning ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      if (networkState.isRunning) {
                        context.read<NetworkBloc>().add(NetworkStopRequested());
                      } else {
                        context.read<NetworkBloc>().add(NetworkStartRequested());
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  _buildUserInfo(user),
                  const Divider(),
                  _buildNetworkStatus(networkState),
                  const Divider(),
                  Expanded(
                    child: _buildMainContent(user, networkState),
                  ),
                ],
              ),
              floatingActionButton: _buildActionButton(context, user, networkState),
            );
          },
        );
      },
    );
  }

  Widget _buildUserInfo(User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Uloga: ${user.role.toString().split('.').last}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (user.validUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              'Važi do: ${user.validUntil!.toLocal()}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          if (user.verificationChain != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verifikacioni lanac: ${user.verificationChain!.substring(0, 8)}...',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNetworkStatus(NetworkState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: state.isRunning ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                state.isRunning ? Icons.wifi : Icons.wifi_off,
                color: state.isRunning ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesh Mreža: ${state.isRunning ? 'Aktivna' : 'Neaktivna'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${state.connectedPeers.length} aktivnih čvorova'),
                ],
              ),
            ],
          ),
          if (state.isRunning) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(
                    state.isDiscovering ? Icons.search_off : Icons.search,
                  ),
                  label: Text(
                    state.isDiscovering ? 'Zaustavi Pretragu' : 'Pretraži Uređaje',
                  ),
                  onPressed: () {
                    if (state.isDiscovering) {
                      BlocProvider.of<NetworkBloc>(context)
                          .add(NetworkDiscoveryStopRequested());
                    } else {
                      BlocProvider.of<NetworkBloc>(context)
                          .add(NetworkDiscoveryStartRequested());
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMainContent(User user, NetworkState networkState) {
    if (user.isSecretMaster || user.isMasterAdmin) {
      return _buildAdminContent(networkState);
    }
    if (user.isSeed) {
      return _buildSeedContent(networkState);
    }
    if (user.isGlasnik) {
      return _buildGlasnikContent(networkState);
    }
    return _buildRegularContent(networkState);
  }

  Widget _buildAdminContent(NetworkState state) {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildGridItem(
                icon: Icons.security,
                label: 'Verifikacija',
                onTap: () {
                  // TODO: Implementirati
                },
              ),
              _buildGridItem(
                icon: Icons.people,
                label: 'Korisnici (${state.connectedPeers.length})',
                onTap: () {
                  // TODO: Implementirati
                },
              ),
              _buildGridItem(
                icon: Icons.message,
                label: 'Poruke (${state.messages.length})',
                onTap: () {
                  // TODO: Implementirati
                },
              ),
              _buildGridItem(
                icon: Icons.analytics,
                label: 'Statistika',
                onTap: () {
                  // TODO: Implementirati
                },
              ),
            ],
          ),
        ),
        if (state.connectedPeers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Povezani Uređaji:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.connectedPeers.length,
                    itemBuilder: (context, index) {
                      final peer = state.connectedPeers[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                peer.isRelay ? Icons.router : Icons.devices,
                                size: 32,
                              ),
                              Text(peer.deviceName),
                              Text(
                                peer.role.toString().split('.').last,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeedContent(NetworkState state) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildListItem(
          icon: Icons.qr_code,
          label: 'Generiši QR Kod',
          onTap: () {
            // TODO: Implementirati
          },
        ),
        _buildListItem(
          icon: Icons.volume_up,
          label: 'Zvučna Verifikacija',
          onTap: () {
            // TODO: Implementirati
          },
        ),
        const Divider(),
        if (state.connectedPeers.isNotEmpty) ...[
          const Text(
            'Povezani Uređaji:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.connectedPeers.map((peer) => ListTile(
            leading: Icon(peer.isRelay ? Icons.router : Icons.devices),
            title: Text(peer.deviceName),
            subtitle: Text(peer.role.toString().split('.').last),
            trailing: Text('${peer.signalStrength} dBm'),
          )),
        ],
      ],
    );
  }

  Widget _buildGlasnikContent(NetworkState state) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildListItem(
          icon: Icons.message,
          label: 'Nove Poruke (${state.messages.where((m) => !m.isExpired).length})',
          onTap: () {
            // TODO: Implementirati
          },
        ),
        _buildListItem(
          icon: Icons.history,
          label: 'Istorija Poruka',
          onTap: () {
            // TODO: Implementirati
          },
        ),
        const Divider(),
        if (state.messages.isNotEmpty) ...[
          const Text(
            'Poslednje Poruke:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.messages.take(5).map((message) => ListTile(
            leading: Icon(_getMessageIcon(message.type)),
            title: Text(_getMessageTitle(message)),
            subtitle: Text(
              'Od: ${message.senderId.substring(0, 8)}...',
            ),
            trailing: Text(
              '${DateTime.now().difference(message.timestamp).inMinutes}m',
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildRegularContent(NetworkState state) {
    if (!state.isRunning) {
      return const Center(
        child: Text('Mesh mreža nije aktivna'),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Dobrodošli u Glasnik!',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),
          if (state.connectedPeers.isEmpty)
            const Text('Traženje drugih uređaja...')
          else
            Text('${state.connectedPeers.length} povezanih uređaja'),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  Widget? _buildActionButton(BuildContext context, User user, NetworkState state) {
    if (!state.isRunning) return null;

    if (user.isSecretMaster || user.isMasterAdmin) {
      return FloatingActionButton(
        onPressed: () {
          // Broadcast sistemsku poruku
          final message = NetworkMessage(
            senderId: user.id,
            type: MessageType.systemAlert,
            priority: MessagePriority.high,
            payload: {
              'title': 'Sistemsko Obaveštenje',
              'content': 'Test broadcast poruke',
            },
          );
          
          context.read<NetworkBloc>().add(NetworkMessageSent(message: message));
        },
        child: const Icon(Icons.broadcast_on_personal),
      );
    }
    return null;
  }

  IconData _getMessageIcon(MessageType type) {
    switch (type) {
      case MessageType.text:
        return Icons.message;
      case MessageType.verification:
        return Icons.verified;
      case MessageType.command:
        return Icons.terminal;
      case MessageType.heartbeat:
        return Icons.favorite;
      case MessageType.routingTable:
        return Icons.router;
      case MessageType.systemAlert:
        return Icons.warning;
    }
  }

  String _getMessageTitle(NetworkMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.payload['content'] ?? 'Nova poruka';
      case MessageType.verification:
        return 'Verifikacioni zahtev';
      case MessageType.command:
        return 'Komanda: ${message.payload['command']}';
      case MessageType.heartbeat:
        return 'Heartbeat';
      case MessageType.routingTable:
        return 'Ažuriranje ruting tabele';
      case MessageType.systemAlert:
        return message.payload['title'] ?? 'Sistemsko obaveštenje';
    }
  }
} 