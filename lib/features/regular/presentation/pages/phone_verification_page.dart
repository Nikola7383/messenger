import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/regular/presentation/blocs/phone_verification_bloc.dart';
import 'package:glasnik/core/utils/phone_utils.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikacija Broja'),
      ),
      body: BlocConsumer<PhoneVerificationBloc, PhoneVerificationState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }

          if (state.isVerified) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Unesite vaš broj telefona za verifikaciju',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Broj Telefona',
                    hintText: '+381 6X XXX XXX',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isCodeSent) ...[
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Verifikacioni Kod',
                      hintText: 'Unesite kod koji ste dobili',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _isLoading = true);
                            context.read<PhoneVerificationBloc>().add(
                                  VerifyCodeSubmitted(
                                    _codeController.text.trim(),
                                  ),
                                );
                            setState(() => _isLoading = false);
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Verifikuj Kod'),
                  ),
                ] else
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final phone = _phoneController.text.trim();
                            if (!PhoneUtils.isValidPhoneNumber(phone)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unesite validan broj telefona'),
                                ),
                              );
                              return;
                            }

                            // Proveri da li se broj podudara sa SIM karticom
                            final simMatch = await PhoneUtils.matchesSimCard(phone);
                            if (!simMatch) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Broj se ne podudara sa SIM karticom',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            setState(() => _isLoading = true);
                            if (mounted) {
                              context.read<PhoneVerificationBloc>().add(
                                    SendVerificationRequested(phone),
                                  );
                            }
                            setState(() => _isLoading = false);
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Pošalji Kod'),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'Napomena: Broj telefona mora da se podudara sa brojem '
                  'SIM kartice u vašem uređaju.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 