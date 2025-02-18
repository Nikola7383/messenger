import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/security/domain/entities/verification_chain.dart';
import 'package:glasnik/features/security/presentation/blocs/verification_bloc.dart';
import 'package:glasnik/features/security/presentation/widgets/qr_code_generator.dart';
import 'package:glasnik/features/security/presentation/widgets/qr_code_scanner.dart';

class VerificationPage extends StatefulWidget {
  final UserRole currentRole;

  const VerificationPage({
    super.key,
    required this.currentRole,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikacija'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generiši'),
            Tab(text: 'Skeniraj'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneratorTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    if (!_canGenerateVerification()) {
      return const Center(
        child: Text(
          'Nemate dozvolu za generisanje verifikacionih kodova',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Generisanje Verifikacionog Koda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Izaberite tip korisnika za verifikaciju:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildRoleSelector(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<VerificationBloc, VerificationState>(
            builder: (context, state) {
              if (state.currentChain != null) {
                return QrCodeGenerator(
                  issuerRole: widget.currentRole,
                  targetRole: state.currentChain!.targetRole,
                  metadata: {
                    'issuer': state.currentChain!.id,
                    'timestamp': DateTime.now().toIso8601String(),
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Skeniranje Verifikacionog Koda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Skenirajte QR kod za verifikaciju:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_showScanner)
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Pokreni Skener'),
              onPressed: () => setState(() => _showScanner = true),
            )
          else
            Column(
              children: [
                QrCodeScanner(
                  onSuccess: () {
                    setState(() => _showScanner = false);
                    _showSuccessDialog();
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Zatvori Skener'),
                  onPressed: () => setState(() => _showScanner = false),
                ),
              ],
            ),
          const SizedBox(height: 16),
          BlocBuilder<VerificationBloc, VerificationState>(
            builder: (context, state) {
              if (state.currentChain != null && state.isValid) {
                return _buildVerificationDetails(state.currentChain!);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return BlocBuilder<VerificationBloc, VerificationState>(
      builder: (context, state) {
        final availableRoles = _getAvailableRolesForVerification();

        return Column(
          children: availableRoles.map((role) {
            final isSelected = state.currentChain?.targetRole == role;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: Text(_getRoleName(role)),
                subtitle: Text(_getRoleDescription(role)),
                leading: Icon(
                  _getRoleIcon(role),
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                selected: isSelected,
                onTap: () {
                  context.read<VerificationBloc>().add(
                    VerificationStarted(
                      issuerRole: widget.currentRole,
                      targetRole: role,
                      type: VerificationType.qr,
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVerificationDetails(VerificationChain chain) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Verifikacija Uspešna',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Izdavač:', _getRoleName(chain.issuerRole)),
            _buildDetailRow('Za ulogu:', _getRoleName(chain.targetRole)),
            _buildDetailRow(
              'Važi do:',
              chain.expiresAt.toLocal().toString(),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementirati primenu verifikacije
                },
                child: const Text('Primeni Verifikaciju'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikacija Uspešna'),
        content: const Text(
          'QR kod je uspešno skeniran i verifikovan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _canGenerateVerification() {
    switch (widget.currentRole) {
      case UserRole.secretMaster:
      case UserRole.masterAdmin:
      case UserRole.seed:
        return true;
      default:
        return false;
    }
  }

  List<UserRole> _getAvailableRolesForVerification() {
    switch (widget.currentRole) {
      case UserRole.secretMaster:
        return [
          UserRole.masterAdmin,
          UserRole.seed,
          UserRole.glasnik,
          UserRole.regular,
        ];
      case UserRole.masterAdmin:
        return [
          UserRole.glasnik,
          UserRole.regular,
        ];
      case UserRole.seed:
        return [UserRole.glasnik];
      default:
        return [];
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.secretMaster:
        return 'Secret Master';
      case UserRole.masterAdmin:
        return 'Master Admin';
      case UserRole.seed:
        return 'Seed';
      case UserRole.glasnik:
        return 'Glasnik';
      case UserRole.regular:
        return 'Regularni Korisnik';
      case UserRole.guest:
        return 'Gost';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.secretMaster:
        return 'Najviši nivo pristupa sa punim ovlašćenjima';
      case UserRole.masterAdmin:
        return 'Administrator sistema sa naprednim ovlašćenjima';
      case UserRole.seed:
        return 'Verifikator Glasnika';
      case UserRole.glasnik:
        return 'Aktivni član mreže za prenos poruka';
      case UserRole.regular:
        return 'Standardni korisnik sistema';
      case UserRole.guest:
        return 'Privremeni pristup sa ograničenim funkcijama';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.secretMaster:
        return Icons.security;
      case UserRole.masterAdmin:
        return Icons.admin_panel_settings;
      case UserRole.seed:
        return Icons.verified_user;
      case UserRole.glasnik:
        return Icons.message;
      case UserRole.regular:
        return Icons.person;
      case UserRole.guest:
        return Icons.person_outline;
    }
  }
} 