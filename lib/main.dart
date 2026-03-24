import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_scan_flutter/theme.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';
import 'package:safe_scan_flutter/scan_result_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeScan',
      theme: SafeScanTheme.theme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F8FF), Color(0xFFE6E6FA)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 1),
                Icon(
                  Icons.shield_rounded,
                  size: 80,
                  color: SafeScanTheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'SafeScan',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Protect yourself with instant QR code safety checks',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final scannedValue = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrCodeScanner(),
                        ),
                      );
                      if (scannedValue != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanResultScreen(url: scannedValue),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 32),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(elevation: 8),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
