import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:local_auth/local_auth.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
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

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Glasnik',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (state.selectedRole == null) ...[
                    _buildRoleButton(
                      context,
                      'Gost',
                      UserRole.guest,
                    ),
                    _buildRoleButton(
                      context,
                      'Regularni Korisnik',
                      UserRole.regular,
                    ),
                    _buildRoleButton(
                      context,
                      'Master Admin',
                      UserRole.masterAdmin,
                    ),
                    _buildRoleButton(
                      context,
                      'Secret Master',
                      UserRole.secretMaster,
                    ),
                  ] else ...[
                    Text(
                      'Verifikacija za ${state.selectedRole.toString().split('.').last}',
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _buildVerificationWidget(context, state.selectedRole!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String label, UserRole role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          context.read<AuthBloc>().add(AuthRoleSelected(role));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildVerificationWidget(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.guest:
        return ElevatedButton(
          onPressed: () {
            context.read<AuthBloc>().add(
              AuthVerificationSubmitted('guest'),
            );
          },
          child: const Text('Nastavi kao Gost'),
        );
      case UserRole.regular:
        return Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Broj Telefona',
              ),
              keyboardType: TextInputType.phone,
              onSubmitted: (value) {
                context.read<AuthBloc>().add(
                  AuthVerificationSubmitted(value),
                );
              },
            ),
          ],
        );
      case UserRole.masterAdmin:
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Implementirati QR skeniranje
              },
              child: const Text('Skeniraj QR Kod'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implementirati zvučnu verifikaciju
              },
              child: const Text('Zvučna Verifikacija'),
            ),
          ],
        );
      case UserRole.secretMaster:
        return ElevatedButton(
          onPressed: () async {
            final localAuth = LocalAuthentication();
            final canCheckBiometrics = await localAuth.canCheckBiometrics;
            
            if (!canCheckBiometrics) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Biometrijska autentifikacija nije dostupna')),
                );
              }
              return;
            }

            final didAuthenticate = await localAuth.authenticate(
              localizedReason: 'Molimo vas da se autentifikujete kao Secret Master',
              options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: true,
              ),
            );

            if (didAuthenticate && context.mounted) {
              context.read<AuthBloc>().add(
                AuthVerificationSubmitted('biometric_success'),
              );
            }
          },
          child: const Text('Biometrijska Verifikacija'),
        );
    }
  }
} 