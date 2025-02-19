import 'package:flutter/material.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';

class UserListTile extends StatelessWidget {
  final UserManagementEntry entry;
  final bool showStatus;
  final bool showVerifyButton;
  final VoidCallback onTap;
  final VoidCallback? onVerify;
  final VoidCallback? onSuspend;
  final VoidCallback? onRevoke;
  final VoidCallback? onActivate;

  const UserListTile({
    super.key,
    required this.entry,
    this.showStatus = false,
    this.showVerifyButton = false,
    required this.onTap,
    this.onVerify,
    this.onSuspend,
    this.onRevoke,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.user.id,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Uloga: ${entry.user.role.toString().split('.').last}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (entry.isCompromised)
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                ],
              ),
              if (showStatus) ...[
                const SizedBox(height: 8),
                _buildStatusChip(),
              ],
              if (entry.requiresAttention) ...[
                const SizedBox(height: 8),
                _buildAttentionIndicators(context),
              ],
              if (_shouldShowActions) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    Color backgroundColor;
    IconData icon;

    switch (entry.user.role) {
      case UserRole.secretMaster:
        backgroundColor = Colors.red;
        icon = Icons.security;
        break;
      case UserRole.masterAdmin:
        backgroundColor = Colors.orange;
        icon = Icons.admin_panel_settings;
        break;
      case UserRole.seed:
        backgroundColor = Colors.green;
        icon = Icons.hub;
        break;
      case UserRole.glasnik:
        backgroundColor = Colors.blue;
        icon = Icons.message;
        break;
      case UserRole.regular:
        backgroundColor = Colors.grey;
        icon = Icons.person;
        break;
      case UserRole.guest:
        backgroundColor = Colors.grey.shade300;
        icon = Icons.person_outline;
        break;
    }

    return CircleAvatar(
      backgroundColor: backgroundColor.withOpacity(0.2),
      child: Icon(icon, color: backgroundColor),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    IconData icon;

    switch (entry.status) {
      case UserStatus.active:
        color = Colors.green;
        label = 'Aktivan';
        icon = Icons.check_circle;
        break;
      case UserStatus.suspended:
        color = Colors.orange;
        label = 'Suspendovan';
        icon = Icons.pause_circle;
        break;
      case UserStatus.revoked:
        color = Colors.red;
        label = 'Revokovan';
        icon = Icons.cancel;
        break;
      case UserStatus.pending:
        color = Colors.blue;
        label = 'Na Čekanju';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionIndicators(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (entry.hasAnomalousActivity)
          _buildIndicatorChip(
            context,
            'Anomalije',
            Icons.warning,
            Colors.orange,
          ),
        if (entry.hasLowTrustScore)
          _buildIndicatorChip(
            context,
            'Nizak Trust Score',
            Icons.sentiment_very_dissatisfied,
            Colors.red,
          ),
        if (entry.isCompromised)
          _buildIndicatorChip(
            context,
            'Kompromitovan',
            Icons.gpp_bad,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildIndicatorChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowActions =>
    showVerifyButton ||
    onSuspend != null ||
    onRevoke != null ||
    onActivate != null;

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showVerifyButton && onVerify != null)
          TextButton.icon(
            icon: const Icon(Icons.verified_user),
            label: const Text('Verifikuj'),
            onPressed: onVerify,
          ),
        if (onSuspend != null)
          TextButton.icon(
            icon: const Icon(Icons.pause),
            label: const Text('Suspenduj'),
            onPressed: onSuspend,
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
          ),
        if (onRevoke != null)
          TextButton.icon(
            icon: const Icon(Icons.block),
            label: const Text('Revokuj'),
            onPressed: onRevoke,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        if (onActivate != null)
          TextButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Aktiviraj'),
            onPressed: onActivate,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
      ],
    );
  }
} 