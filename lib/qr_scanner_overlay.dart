import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/theme.dart';

class QrScannerOverlay extends StatelessWidget {
  const QrScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 120),
            const Text(
              'Align QR code within frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'ll check the destination for safety risks',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Spacer(flex: 2),
            CustomPaint(
              size: Size.infinite,
              painter: const ScannerFramePainter(),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  const ScannerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double framePadding = 48.0;
    const double cornerLength = 32.0;
    const double strokeWidth = 3.0;

    final frameRect = Rect.fromLTWH(
      framePadding,
      (size.height - 280) / 2, // Centered vertically
      size.width - 2 * framePadding,
      280,
    );

    final paint = Paint()
      ..color = SafeScanTheme.primary
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Top line
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top + strokeWidth / 2),
      Offset(frameRect.right, frameRect.top + strokeWidth / 2),
      paint,
    );
    // Bottom line
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom - strokeWidth / 2),
      Offset(frameRect.right, frameRect.bottom - strokeWidth / 2),
      paint,
    );
    // Left line
    canvas.drawLine(
      Offset(frameRect.left + strokeWidth / 2, frameRect.top),
      Offset(frameRect.left + strokeWidth / 2, frameRect.bottom),
      paint,
    );
    // Right line
    canvas.drawLine(
      Offset(frameRect.right - strokeWidth / 2, frameRect.top),
      Offset(frameRect.right - strokeWidth / 2, frameRect.bottom),
      paint,
    );

    // Top-left L
    canvas.drawLine(
      Offset(frameRect.left, frameRect.top + cornerLength),
      Offset(frameRect.left + cornerLength, frameRect.top + cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.left + cornerLength, frameRect.top),
      Offset(frameRect.left + cornerLength, frameRect.top + cornerLength),
      paint,
    );

    // Top-right L
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.top + cornerLength),
      Offset(frameRect.right, frameRect.top + cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.top),
      Offset(frameRect.right - cornerLength, frameRect.top + cornerLength),
      paint,
    );

    // Bottom-left L
    canvas.drawLine(
      Offset(frameRect.left, frameRect.bottom - cornerLength),
      Offset(frameRect.left + cornerLength, frameRect.bottom - cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.left + cornerLength, frameRect.bottom - cornerLength),
      Offset(frameRect.left + cornerLength, frameRect.bottom),
      paint,
    );

    // Bottom-right L
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.bottom - cornerLength),
      Offset(frameRect.right, frameRect.bottom - cornerLength),
      paint,
    );
    canvas.drawLine(
      Offset(frameRect.right - cornerLength, frameRect.bottom),
      Offset(frameRect.right - cornerLength, frameRect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
