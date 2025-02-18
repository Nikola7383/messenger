import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/domain/entities/user.dart';
import 'package:glasnik/features/security/presentation/blocs/verification_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeGenerator extends StatelessWidget {
  final UserRole issuerRole;
  final UserRole targetRole;
  final Map<String, dynamic>? metadata;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const QrCodeGenerator({
    super.key,
    required this.issuerRole,
    required this.targetRole,
    this.metadata,
    this.size = 200.0,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listenWhen: (previous, current) => 
        previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.qrCode == null) {
          // Generiši QR kod ako još nije generisan
          context.read<VerificationBloc>().add(
            QrCodeGenerated(
              issuerRole: issuerRole,
              targetRole: targetRole,
              metadata: metadata,
            ),
          );

          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: Text('Generisanje QR koda...'),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: state.qrCode!,
                version: QrVersions.auto,
                size: size,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                embeddedImage: const AssetImage('assets/images/logo.png'),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(size * 0.2, size * 0.2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Skenirajte QR kod za verifikaciju',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Važi ${state.currentChain?.expiresAt.difference(DateTime.now()).inMinutes} minuta',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            if (state.currentChain?.isValid == true) ...[
              const SizedBox(height: 16),
              const Icon(
                Icons.verified,
                color: Colors.green,
                size: 32,
              ),
              const Text(
                'Verifikacioni lanac je validan',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generiši Novi'),
                  onPressed: () {
                    context.read<VerificationBloc>().add(
                      QrCodeGenerated(
                        issuerRole: issuerRole,
                        targetRole: targetRole,
                        metadata: metadata,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Podeli'),
                  onPressed: () {
                    // TODO: Implementirati deljenje QR koda
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
} 