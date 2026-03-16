import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_scan_flutter/scanner_overlay_painter.dart';
import 'package:safe_scan_flutter/safe_browsing_service.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final MobileScannerController scannerController = MobileScannerController(autoZoom: true);
  final SafeBrowsingService _safeBrowsingService = SafeBrowsingService();

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      _isProcessing = true;
      final rawValue = barcode.rawValue!.trim();
      debugPrint('Barcode found! Value: $rawValue');
      scannerController.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final uri = Uri.tryParse(rawValue);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.host.isEmpty) {
        Navigator.pop(
          context,
          SafeBrowsingResult(
            url: rawValue,
            isSafe: false,
            error: 'Scanned data is not a valid http/https URL.',
          ),
        );
        return;
      }

      final result = await _safeBrowsingService.checkUrl(rawValue);
      if (!mounted) return;
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Scanner")),
      body: Stack(
        children: [
          MobileScanner(
            controller: scannerController,
            onDetect: _onDetect,
            overlayBuilder: (context, constraints) {
              final size = constraints.biggest;
              final scanSize = Size(size.width * 0.5, size.width * 0.5);
              return Center(child: CustomPaint(size: scanSize, painter: ScannerOverlayPainter()));
            },
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: () async {
                  await scannerController.toggleTorch();
                  setState(() {
                    _torchOn = !_torchOn;
                  });
                },
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(color: Colors.black.withAlpha(50), shape: BoxShape.circle),
                  child: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
