import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_scan_flutter/scanner_overlay_painter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  //this beats url shorteners!
  Future<String> expandUrl(String url) async{
    final client = http.Client();
    try{
      debugPrint("trying to expand using get");
      // final proxyurl = "https://lnky.api.stanleymasinde.com?url=$url";
      final request = http.Request("GET", Uri.parse("http://localhost:3000/expand?url=${Uri.encodeComponent(url)}",));
      request.followRedirects = true;
      request.maxRedirects = 10;
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
      final response = await client.send(request);
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      // return response.request?.url.toString() ?? url;
      return data["expandedUrl"];


    }catch (_) {
    try {
      debugPrint('head failed, using get now.');
      // Fallback to GET if HEAD fails
      // final proxyUrl = "https://corsproxy.io/?$url";
      final getResponse = await client.get(Uri.parse("http://localhost:3000/expand?url=${Uri.encodeComponent(url)}",));
      return getResponse.request?.url.toString() ?? url;
    } catch (e) {
      debugPrint("Expand URL failed: $e");
      return url;
    }
    }
    finally{
      client.close();
    }
  }
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || controller == null || !mounted) return;

    final List<Barcode> barcodes = capture.barcodes;
    final Barcode? barcode = barcodes.isNotEmpty ? barcodes.first : null;
    final String? code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    _isProcessing = true;
    debugPrint('Scanned QR: $code');
    await controller!.stop();
    final String expandedUrl = await expandUrl(code);
    debugPrint(expandedUrl);


    if (mounted) {
      Navigator.of(context).pop(expandedUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SafeScan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: controller!, onDetect: _onDetect),
          CustomPaint(painter: ScannerOverlayPainter(), size: Size.infinite),
          // Instructions text ABOVE frame
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Align QR code within frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Torch button BELOW frame
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(75),
                child: GestureDetector(
                  onTap: () async {
                    if (controller != null) {
                      await controller!.toggleTorch();
                      setState(() {
                        _torchOn = !_torchOn;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
