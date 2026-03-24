import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_scan_flutter/theme.dart';
import 'package:safe_scan_flutter/scanner_overlay_painter.dart';
import 'package:safe_scan_flutter/qr_scanner_overlay.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final MobileScannerController scannerController = MobileScannerController(
    autoZoom: true,
  );

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;

    if (barcode?.rawValue == null) {
      _isProcessing = false;
      return;
    }
    final rawValue = barcode!.rawValue!.trim();
    debugPrint('Scanned: $rawValue');

    await scannerController.stop();

    if (!mounted) return;
    Navigator.pop(context, rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner'), elevation: 0),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: _onDetect,
            overlayBuilder: (context, constraints) {
              final size = constraints.biggest;
              final scanSize = Size(size.width * 0.6, size.width * 0.6);
              return Center(
                child: CustomPaint(
                  size: scanSize,
                  painter: ScannerOverlayPainter(),
                ),
              );
            },
          ),
          const QrScannerOverlay(),
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: SafeScanTheme.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SafeScanTheme.primary.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    await scannerController.toggleTorch();
                    if (mounted) {
                      setState(() {
                        _torchOn = !_torchOn;
                      });
                    }
                  },
                  icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                  color: Colors.white,
                  iconSize: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
