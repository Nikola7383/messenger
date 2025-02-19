import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/admin/domain/entities/user_management.dart';
import 'package:glasnik/features/admin/presentation/blocs/user_management_bloc.dart';
import 'package:glasnik/features/admin/presentation/widgets/user_list_tile.dart';
import 'package:glasnik/features/admin/presentation/widgets/user_details_dialog.dart';
import 'package:glasnik/features/admin/presentation/widgets/security_metrics_card.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upravljanje Korisnicima'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Svi Korisnici'),
              Tab(text: 'Na Čekanju'),
              Tab(text: 'Zahtevaju Pažnju'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<UserManagementBloc>()
                  ..add(LoadUsersRequested())
                  ..add(LoadPendingUsersRequested())
                  ..add(LoadUsersRequiringAttentionRequested());
              },
            ),
          ],
        ),
        body: BlocConsumer<UserManagementBloc, UserManagementState>(
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

            return TabBarView(
              children: [
                _buildUserList(
                  context,
                  state.users,
                  showStatus: true,
                ),
                _buildUserList(
                  context,
                  state.pendingUsers,
                  showVerifyButton: true,
                ),
                _buildUsersRequiringAttention(
                  context,
                  state.usersRequiringAttention,
                  state.securityMetrics,
                  state.anomalies,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<UserManagementEntry> users, {
    bool showStatus = false,
    bool showVerifyButton = false,
  }) {
    if (users.isEmpty) {
      return const Center(
        child: Text('Nema korisnika'),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserListTile(
          entry: user,
          showStatus: showStatus,
          showVerifyButton: showVerifyButton,
          onTap: () => _showUserDetails(context, user),
          onVerify: showVerifyButton ? () => _verifyUser(context, user) : null,
          onSuspend: user.status == UserStatus.active
            ? () => _suspendUser(context, user)
            : null,
          onRevoke: user.canBeRevoked
            ? () => _revokeUser(context, user)
            : null,
          onActivate: user.status == UserStatus.suspended
            ? () => _activateUser(context, user)
            : null,
        );
      },
    );
  }

  Widget _buildUsersRequiringAttention(
    BuildContext context,
    List<UserManagementEntry> users,
    Map<String, List<UserManagementEntry>> securityMetrics,
    List<Map<String, dynamic>> anomalies,
  ) {
    return Column(
      children: [
        // Security Metrics Card
        if (securityMetrics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SecurityMetricsCard(
              metrics: securityMetrics,
              anomalies: anomalies,
            ),
          ),
        
        // Users List
        Expanded(
          child: _buildUserList(
            context,
            users,
            showStatus: true,
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context, UserManagementEntry entry) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsDialog(entry: entry),
    );
  }

  void _verifyUser(BuildContext context, UserManagementEntry entry) {
    // TODO: Implementirati verifikaciju
    context.read<UserManagementBloc>().add(
      VerifyUserRequested(
        userId: entry.user.id,
        verifierUserId: 'current_user_id', // TODO: Get from auth
        verificationChain: [], // TODO: Get verification chain
      ),
    );
  }

  void _suspendUser(BuildContext context, UserManagementEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspenduj Korisnika'),
        content: Text(
          'Da li ste sigurni da želite da suspendujete korisnika ${entry.user.id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserManagementBloc>().add(
                SuspendUserRequested(entry.user.id),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suspenduj'),
          ),
        ],
      ),
    );
  }

  void _revokeUser(BuildContext context, UserManagementEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revokuj Korisnika'),
        content: Text(
          'Da li ste sigurni da želite da revokujete korisnika ${entry.user.id}?\n'
          'Ova akcija je trajna i ne može se poništiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserManagementBloc>().add(
                RevokeUserRequested(entry.user.id),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revokuj'),
          ),
        ],
      ),
    );
  }

  void _activateUser(BuildContext context, UserManagementEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktiviraj Korisnika'),
        content: Text(
          'Da li ste sigurni da želite da aktivirate korisnika ${entry.user.id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserManagementBloc>().add(
                ActivateUserRequested(entry.user.id),
              );
              Navigator.pop(context);
            },
            child: const Text('Aktiviraj'),
          ),
        ],
      ),
    );
  }
} 