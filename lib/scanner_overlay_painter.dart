import 'package:flutter/material.dart';

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke;

    const cornerLength = 40.0;
    const radius = 30.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, radius)
        ..lineTo(0, cornerLength),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radius),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, radius)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..quadraticBezierTo(0, size.height, radius, size.height),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(radius, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - radius)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}