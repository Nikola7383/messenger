import 'package:flutter/material.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';

class SecurityMetricsCard extends StatelessWidget {
  final Map<String, List<UserManagementEntry>> metrics;
  final List<Map<String, dynamic>> anomalies;

  const SecurityMetricsCard({
    super.key,
    required this.metrics,
    required this.anomalies,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Security Metrike',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (anomalies.isNotEmpty)
                  _buildAnomalyIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(context),
            if (anomalies.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Detektovane Anomalije',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildAnomaliesList(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${anomalies.length} ${anomalies.length == 1 ? 'Anomalija' : 'Anomalije'}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          'Kompromitovani Korisnici',
          metrics['compromised']?.length ?? 0,
          Icons.security,
          Colors.red,
        ),
        _buildMetricCard(
          context,
          'Nizak Trust Score',
          metrics['low_trust']?.length ?? 0,
          Icons.sentiment_very_dissatisfied,
          Colors.orange,
        ),
        _buildMetricCard(
          context,
          'Anomalije u Ponašanju',
          metrics['anomalous']?.length ?? 0,
          Icons.warning,
          Colors.yellow.shade800,
        ),
        _buildMetricCard(
          context,
          'Suspendovani Korisnici',
          metrics['suspended']?.length ?? 0,
          Icons.pause_circle,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = anomalies[index];
        return _buildAnomalyItem(context, anomaly);
      },
    );
  }

  Widget _buildAnomalyItem(
    BuildContext context,
    Map<String, dynamic> anomaly,
  ) {
    final type = anomaly['type'] as String;
    final severity = anomaly['severity'] as String;
    final description = anomaly['description'] as String;
    final timestamp = DateTime.parse(anomaly['timestamp'] as String);

    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.yellow.shade800;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getAnomalyIcon(type),
              color: severityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAnomalyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'authentication':
        return Icons.lock;
      case 'network':
        return Icons.wifi_tethering;
      case 'behavior':
        return Icons.psychology;
      case 'access':
        return Icons.security;
      default:
        return Icons.warning;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Upravo sada';
    } else if (difference.inHours < 1) {
      return 'Pre ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Pre ${difference.inHours} h';
    } else {
      return 'Pre ${difference.inDays} d';
    }
  }
} 