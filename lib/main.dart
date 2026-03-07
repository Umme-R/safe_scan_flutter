import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text(qrCodeValue ?? 'You have not scanned a QR Code')],
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