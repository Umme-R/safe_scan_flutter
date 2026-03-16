import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';
import 'package:safe_scan_flutter/safe_browsing_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter QR Code Scanner Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'QR Code Scanner'),
    );
  }
}


class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  SafeBrowsingResult? scanResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(scanResult?.url ?? 'You have not scanned a QR Code'),
            const SizedBox(height: 12),
            if (scanResult != null) Text(scanResult!.statusMessage),
            if (scanResult != null && scanResult!.detailsLines.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...scanResult!.detailsLines.map(Text.new),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<SafeBrowsingResult>(
            context,
            MaterialPageRoute(builder: (context) => const QrCodeScanner()),
          );
          if (!mounted || result == null) return;
          setState(() {
            scanResult = result;
          });
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
