import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';
import 'package:glasnik/features/admin/presentation/blocs/user_management_bloc.dart';

class UserDetailsDialog extends StatelessWidget {
  final UserManagementEntry entry;

  const UserDetailsDialog({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Detalji Korisnika',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              context,
              'Osnovne Informacije',
              [
                _buildInfoRow('ID', entry.user.id),
                _buildInfoRow(
                  'Uloga',
                  entry.user.role.toString().split('.').last,
                ),
                _buildInfoRow(
                  'Status',
                  entry.status.toString().split('.').last,
                ),
                _buildInfoRow(
                  'Kreiran',
                  _formatDateTime(entry.user.createdAt),
                ),
                _buildInfoRow(
                  'Poslednja Aktivnost',
                  _formatDateTime(entry.lastActivity),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoSection(
              context,
              'Verifikacija',
              [
                _buildInfoRow(
                  'Verifikovan',
                  entry.user.isVerified ? 'Da' : 'Ne',
                ),
                if (entry.verifiedBy != null)
                  _buildInfoRow('Verifikovao', entry.verifiedBy!),
                if (entry.verificationDate != null)
                  _buildInfoRow(
                    'Datum Verifikacije',
                    _formatDateTime(entry.verificationDate!),
                  ),
                if (entry.verificationChainPath.isNotEmpty)
                  _buildInfoRow(
                    'Verifikacioni Lanac',
                    entry.verificationChainPath.join(' → '),
                  ),
              ],
            ),
            if (entry.securityMetrics.isNotEmpty) ...[
              const Divider(height: 32),
              _buildInfoSection(
                context,
                'Security Metrike',
                [
                  _buildInfoRow(
                    'Trust Score',
                    '${(entry.securityMetrics['trust_score'] as num).toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'Anomaly Score',
                    '${(entry.securityMetrics['anomaly_score'] as num).toStringAsFixed(2)}',
                  ),
                  _buildInfoRow(
                    'Risk Level',
                    entry.securityMetrics['risk_level'] as String,
                  ),
                ],
              ),
            ],
            if (entry.activityLog.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Aktivnosti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: entry.activityLog.length,
                  itemBuilder: (context, index) {
                    final activity = entry.activityLog[index];
                    return _buildActivityItem(context, activity);
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    context.read<UserManagementBloc>().add(
                      GenerateUserReportRequested(entry.user.id),
                    );
                  },
                  child: const Text('Generiši Izveštaj'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zatvori'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    Map<String, dynamic> activity,
  ) {
    final type = activity['type'] as String;
    final description = activity['description'] as String;
    final timestamp = DateTime.parse(activity['timestamp'] as String);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getActivityColor(type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(type),
              size: 16,
              color: _getActivityColor(type),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  _formatDateTime(timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'verification':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'verification':
        return Icons.verified_user;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 