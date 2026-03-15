import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';


void main() {
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
  String? qrCodeValue;

  Future<void> _launchUrl(String urlString) async{
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      // If it fails (e.g., malformed link), show a snackbar or error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Text(qrCodeValue ?? 'You have not scanned a QR Code'),
            // const Text("testing...is this thing on?"),
            if (qrCodeValue != null)
              ElevatedButton(onPressed: ()=> _launchUrl(qrCodeValue!), 
              child: Text("open link! $qrCodeValue"))

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          qrCodeValue = await Navigator.push(context, MaterialPageRoute(builder: (context) => QrCodeScanner()));
          setState(() {});
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}