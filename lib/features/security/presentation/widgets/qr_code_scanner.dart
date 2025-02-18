import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/security/presentation/blocs/verification_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeScanner extends StatefulWidget {
  final double width;
  final double height;
  final bool showOverlay;
  final Color overlayColor;
  final VoidCallback? onSuccess;

  const QrCodeScanner({
    super.key,
    this.width = 300,
    this.height = 300,
    this.showOverlay = true,
    this.overlayColor = Colors.black54,
    this.onSuccess,
  });

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.height,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listenWhen: (previous, current) =>
          previous.isVerifying != current.isVerifying ||
          previous.error != current.error ||
          previous.isValid != current.isValid,
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (!state.isVerifying && state.isValid) {
          widget.onSuccess?.call();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        _isProcessing = true;

                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            context.read<VerificationBloc>().add(
                              QrCodeScanned(barcode.rawValue!),
                            );
                            break;
                          }
                        }

                        _isProcessing = false;
                      },
                    ),
                  ),
                ),
                if (widget.showOverlay)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: QrScannerOverlayPainter(
                        borderColor: Theme.of(context).primaryColor,
                        overlayColor: widget.overlayColor,
                        scanLineY: _animation.value,
                      ),
                    ),
                  ),
                if (state.isVerifying)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller.torchState,
                    builder: (context, state, child) {
                      switch (state as TorchState) {
                        case TorchState.off:
                          return const Icon(Icons.flash_off);
                        case TorchState.on:
                          return const Icon(Icons.flash_on);
                      }
                    },
                  ),
                  onPressed: () => _controller.toggleTorch(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller.cameraFacingState,
                    builder: (context, state, child) {
                      switch (state as CameraFacing) {
                        case CameraFacing.front:
                          return const Icon(Icons.camera_front);
                        case CameraFacing.back:
                          return const Icon(Icons.camera_rear);
                      }
                    },
                  ),
                  onPressed: () => _controller.switchCamera(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Pozicionirajte QR kod unutar okvira',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class QrScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final Color overlayColor;
  final double scanLineY;

  QrScannerOverlayPainter({
    required this.borderColor,
    required this.overlayColor,
    required this.scanLineY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final scanAreaSize = width * 0.7;
    final left = (width - scanAreaSize) / 2;
    final top = (height - scanAreaSize) / 2;
    final right = left + scanAreaSize;
    final bottom = top + scanAreaSize;

    // Overlay
    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final scanAreaPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRect(Rect.fromLTRB(left, top, right, bottom));

    canvas.drawPath(
      scanAreaPath,
      backgroundPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Corners
    final cornerLength = scanAreaSize * 0.1;
    final cornerPath = Path();

    // Top left corner
    cornerPath.moveTo(left, top + cornerLength);
    cornerPath.lineTo(left, top);
    cornerPath.lineTo(left + cornerLength, top);

    // Top right corner
    cornerPath.moveTo(right - cornerLength, top);
    cornerPath.lineTo(right, top);
    cornerPath.lineTo(right, top + cornerLength);

    // Bottom right corner
    cornerPath.moveTo(right, bottom - cornerLength);
    cornerPath.lineTo(right, bottom);
    cornerPath.lineTo(right - cornerLength, bottom);

    // Bottom left corner
    cornerPath.moveTo(left + cornerLength, bottom);
    cornerPath.lineTo(left, bottom);
    cornerPath.lineTo(left, bottom - cornerLength);

    canvas.drawPath(cornerPath, borderPaint);

    // Scan line
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          borderColor.withOpacity(0),
          borderColor.withOpacity(0.5),
          borderColor.withOpacity(0),
        ],
      ).createShader(
        Rect.fromLTRB(left, scanLineY - 15, right, scanLineY + 15),
      );

    canvas.drawRect(
      Rect.fromLTRB(left, scanLineY - 15, right, scanLineY + 15),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(QrScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanLineY != scanLineY;
  }
} 