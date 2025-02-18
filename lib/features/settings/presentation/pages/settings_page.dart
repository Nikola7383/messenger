import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podešavanja'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              _buildUserSection(user),
              const Divider(),
              _buildSecuritySection(context),
              const Divider(),
              _buildNetworkSection(context),
              if (user.isSecretMaster) ...[
                const Divider(),
                _buildAdvancedSection(context),
              ],
              const Divider(),
              _buildAboutSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserSection(User user) {
    return ListTile(
      title: const Text(
        'Korisnički Profil',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uloga: ${user.role.toString().split('.').last}'),
          if (user.validUntil != null)
            Text('Važi do: ${user.validUntil!.toLocal()}'),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Bezbednost',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.security),
          title: const Text('Biometrijska Verifikacija'),
          trailing: Switch(
            value: true, // TODO: Implementirati stvarnu vrednost
            onChanged: (value) {
              // TODO: Implementirati promenu
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Promeni Tajni Ključ'),
          onTap: () {
            // TODO: Implementirati
          },
        ),
      ],
    );
  }

  Widget _buildNetworkSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Mreža',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.wifi),
          title: const Text('Mesh Mreža'),
          trailing: Switch(
            value: true, // TODO: Implementirati stvarnu vrednost
            onChanged: (value) {
              // TODO: Implementirati promenu
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bluetooth),
          title: const Text('Bluetooth'),
          trailing: Switch(
            value: true, // TODO: Implementirati stvarnu vrednost
            onChanged: (value) {
              // TODO: Implementirati promenu
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Napredne Opcije',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.warning),
          title: const Text('Aktiviraj Mutated Virus'),
          subtitle: const Text('Samo za hitne slučajeve'),
          onTap: () {
            // TODO: Implementirati
          },
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Regeneriši Root Seed'),
          onTap: () {
            // TODO: Implementirati
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'O Aplikaciji',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Verzija'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Pomoć'),
          onTap: () {
            // TODO: Implementirati
          },
        ),
      ],
    );
  }
} 