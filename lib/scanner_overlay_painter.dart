import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/theme.dart';

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);

    // MUCH larger centered scan frame (60-70% screen width)
    final double frameSize = size.width * 0.35;
    final frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: frameSize,
      height: frameSize,
    );

    // Transparent cutout
    final cutoutPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      cutoutPaint,
    );

    // Clean large rounded border (no corners)
    final borderPaint = Paint()
      ..color = SafeScanTheme.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      borderPaint,
    );

    // Subtle inner glow
    final glowPaint = Paint()
      ..color = SafeScanTheme.primary.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect.deflate(2), const Radius.circular(22)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
