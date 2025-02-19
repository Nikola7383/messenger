import 'package:flutter/material.dart';

class NetworkHealthCard extends StatelessWidget {
  final Map<String, dynamic>? networkHealth;
  final Map<String, dynamic>? networkAnalysis;
  final List<Map<String, dynamic>> detectedThreats;
  final Function(List<Map<String, dynamic>>) onApplyDefenseMeasures;

  const NetworkHealthCard({
    super.key,
    this.networkHealth,
    this.networkAnalysis,
    required this.detectedThreats,
    required this.onApplyDefenseMeasures,
  });

  @override
  Widget build(BuildContext context) {
    if (networkHealth == null || networkAnalysis == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Nema dostupnih podataka o mreži'),
          ),
        ),
      );
    }

    final status = networkHealth!['status'] as String;
    final metrics = networkAnalysis!['metrics'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zdravlje Mreže',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildStatusChip(status),
              ],
            ),
            const Divider(),
            // Metrike
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  'Packet Count',
                  metrics['packet_count']?.toString() ?? '0',
                  Icons.compare_arrows,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Bandwidth',
                  '${(metrics['bandwidth_usage'] ?? 0) / 1024} KB/s',
                  Icons.speed,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Error Rate',
                  '${(metrics['error_rate'] ?? 0.0).toStringAsFixed(2)}%',
                  Icons.error_outline,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Latency',
                  '${metrics['latency'] ?? 0} ms',
                  Icons.timer,
                  Colors.purple,
                ),
              ],
            ),
            if (detectedThreats.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detektovane Pretnje: ${detectedThreats.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.security),
                    label: const Text('Primeni Odbranu'),
                    onPressed: () => onApplyDefenseMeasures(detectedThreats),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'healthy':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'warning':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'critical':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 