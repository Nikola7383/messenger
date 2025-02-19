import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/security/domain/entities/virus.dart';
import 'package:glasnik/features/security/presentation/blocs/virus_bloc.dart';
import 'package:glasnik/features/security/presentation/widgets/virus_card.dart';
import 'package:glasnik/features/security/presentation/widgets/network_health_card.dart';
import 'package:glasnik/features/security/presentation/widgets/create_virus_dialog.dart';

class VirusManagementPage extends StatelessWidget {
  final UserRole userRole;

  const VirusManagementPage({
    super.key,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // Proveri da li korisnik ima pristup
    if (!_hasAccess()) {
      return const Scaffold(
        body: Center(
          child: Text('Nemate pristup ovoj stranici'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upravljanje Virusima'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<VirusBloc>()
                ..add(NetworkAnalysisRequested())
                ..add(ThreatDetectionRequested())
                ..add(NetworkHealthCheckRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              context.read<VirusBloc>().add(CleanupDeadVirusesRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<VirusBloc, VirusState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<VirusBloc>()
                ..add(NetworkAnalysisRequested())
                ..add(ThreatDetectionRequested())
                ..add(NetworkHealthCheckRequested());
            },
            child: CustomScrollView(
              slivers: [
                // Network Health sekcija
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: NetworkHealthCard(
                      networkHealth: state.networkHealth,
                      networkAnalysis: state.networkAnalysis,
                      detectedThreats: state.detectedThreats,
                      onApplyDefenseMeasures: (threats) {
                        context.read<VirusBloc>().add(
                          DefenseMeasuresRequested(threats),
                        );
                      },
                    ),
                  ),
                ),

                // Aktivni virusi
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Aktivni Virusi',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Novi Virus'),
                                  onPressed: () => _showCreateVirusDialog(context),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (state.activeViruses.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Nema aktivnih virusa'),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.activeViruses.length,
                                itemBuilder: (context, index) {
                                  final virus = state.activeViruses[index];
                                  return VirusCard(
                                    virus: virus,
                                    onActivate: () {
                                      context.read<VirusBloc>().add(
                                        ActivateVirusRequested(virus.id),
                                      );
                                    },
                                    onDeactivate: () {
                                      context.read<VirusBloc>().add(
                                        DeactivateVirusRequested(virus.id),
                                      );
                                    },
                                    onMutate: () => _showMutationDialog(
                                      context,
                                      virus,
                                    ),
                                    onReplicate: () => _showReplicationDialog(
                                      context,
                                      virus,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Detektovane pretnje
                if (state.detectedThreats.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detektovane Pretnje',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Divider(),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.detectedThreats.length,
                                itemBuilder: (context, index) {
                                  final threat = state.detectedThreats[index];
                                  return ListTile(
                                    leading: Icon(
                                      _getThreatIcon(threat['type']),
                                      color: _getThreatColor(threat['severity']),
                                    ),
                                    title: Text(
                                      'Pretnja tipa ${threat['type']}',
                                    ),
                                    subtitle: Text(
                                      'Ozbiljnost: ${threat['severity']}\n'
                                      'Detektovano: ${threat['timestamp']}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.security),
                                      onPressed: () {
                                        context.read<VirusBloc>().add(
                                          DefenseMeasuresRequested([threat]),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasAccess() {
    return userRole == UserRole.secretMaster || 
           userRole == UserRole.masterAdmin;
  }

  void _showCreateVirusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateVirusDialog(),
    );
  }

  void _showMutationDialog(BuildContext context, Virus virus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mutiraj Virus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Izaberite parametre mutacije:'),
            const SizedBox(height: 16),
            // TODO: Implementirati UI za parametre mutacije
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<VirusBloc>().add(
                MutateVirusRequested(
                  virusId: virus.id,
                  mutationParams: {
                    'optimization_target': 'capabilities',
                    'mutation_strength': 0.5,
                  },
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Mutiraj'),
          ),
        ],
      ),
    );
  }

  void _showReplicationDialog(BuildContext context, Virus virus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repliciraj Virus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Izaberite ciljne nodove:'),
            const SizedBox(height: 16),
            // TODO: Implementirati UI za izbor nodova
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<VirusBloc>().add(
                ReplicateVirusRequested(
                  virusId: virus.id,
                  targetNodes: ['node1', 'node2'], // TODO: Dinamički
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Repliciraj'),
          ),
        ],
      ),
    );
  }

  IconData _getThreatIcon(String type) {
    switch (type) {
      case 'anomaly':
        return Icons.warning;
      case 'pattern':
        return Icons.pattern;
      case 'metrics':
        return Icons.speed;
      default:
        return Icons.error;
    }
  }

  Color _getThreatColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }
} 