import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_scan_flutter/scan_result_screen.dart';


// void main() {
//   runApp(const MyApp());
// }
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
      home: MyHomePage(title: "QR Code Scanner"),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ScanSafe Home Page"),
        centerTitle: true,
      ),
      floatingActionButton: SizedBox(
        width: 300,
        height: 300,
        child: FloatingActionButton(
          onPressed: (){},
          child: const Icon(Icons.qr_code_scanner, size: 300,)
        ),
        
          
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      floatingActionButton: SizedBox(
        width: 300,
        height: 300,
        child: FloatingActionButton(
          onPressed: () async {

          
          final scannedValue = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const QrCodeScanner(),
            ),
          );

          
          if (scannedValue == null || !context.mounted) return;

         
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultScreen(
                url: scannedValue,
              ),
            ),
          );
        },
          child: const Icon(Icons.qr_code_scanner, size: 300,)
        ),
        
          
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
 
      );
  }
}