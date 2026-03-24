import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/theme.dart';

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SafeScanTheme.primary.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    const radius = 20.0;

    // Top-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cornerLength, cornerLength),
        const Radius.circular(radius),
      ),
      paint,
    );

    // Top-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - cornerLength, 0, cornerLength, cornerLength),
        const Radius.circular(radius),
      ),
      paint,
    );

    // Bottom-left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          size.height - cornerLength,
          cornerLength,
          cornerLength,
        ),
        const Radius.circular(radius),
      ),
      paint,
    );

    // Bottom-right
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width - cornerLength,
          size.height - cornerLength,
          cornerLength,
          cornerLength,
        ),
        const Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
