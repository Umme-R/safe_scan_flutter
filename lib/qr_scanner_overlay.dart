import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/theme.dart';

class QrScannerOverlay extends StatelessWidget {
  const QrScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Align QR code',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                shadows: [
                  const Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Position the QR code inside the frame',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
