import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/security/presentation/bloc/network_analysis_bloc.dart';
import 'package:glasnik/features/security/presentation/widgets/network_health_card.dart';

class NetworkAnalysisPage extends StatelessWidget {
  const NetworkAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiza Mreže'),
        actions: [
          BlocBuilder<NetworkAnalysisBloc, NetworkAnalysisState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.isAnalyzing ? Icons.stop : Icons.play_arrow,
                  color: state.isAnalyzing ? Colors.red : Colors.green,
                ),
                onPressed: () {
                  if (state.isAnalyzing) {
                    context.read<NetworkAnalysisBloc>().add(
                          StopNetworkAnalysisRequested(),
                        );
                  } else {
                    context.read<NetworkAnalysisBloc>().add(
                          StartNetworkAnalysisRequested(),
                        );
                  }
                },
                tooltip: state.isAnalyzing
                    ? 'Zaustavi Analizu'
                    : 'Pokreni Analizu',
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NetworkAnalysisBloc, NetworkAnalysisState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (!state.isAnalyzing &&
              state.networkHealth == null &&
              state.networkAnalysis == null) {
            return const Center(
              child: Text('Kliknite na dugme za pokretanje analize mreže'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (state.isAnalyzing) {
                // Ako je analiza već pokrenuta, samo sačekaj nove podatke
                await Future.delayed(const Duration(seconds: 1));
              } else {
                // Ako analiza nije pokrenuta, pokreni je
                context.read<NetworkAnalysisBloc>().add(
                      StartNetworkAnalysisRequested(),
                    );
                // Sačekaj da se podaci učitaju
                await Future.delayed(const Duration(seconds: 2));
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (state.isAnalyzing && state.networkHealth == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  NetworkHealthCard(
                    networkHealth: state.networkHealth,
                    networkAnalysis: state.networkAnalysis,
                    detectedThreats: state.detectedThreats,
                    onApplyDefenseMeasures: (threats) {
                      context.read<NetworkAnalysisBloc>().add(
                            ApplyDefenseMeasuresRequested(threats),
                          );
                    },
                  ),
                if (state.isAnalyzing) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Analiza u toku...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
} 