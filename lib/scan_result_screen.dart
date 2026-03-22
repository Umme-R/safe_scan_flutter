import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/safe_browsing_service.dart';
import 'package:url_launcher/url_launcher.dart';


class ScanResultScreen extends StatefulWidget {
  final String url;

  const ScanResultScreen({super.key, required this.url});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final SafeBrowsingService _service = SafeBrowsingService();

  SafeBrowsingResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkUrl();
  }

  Future<void> _checkUrl() async {
    final uri = Uri.tryParse(widget.url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      setState(() {
        _result = SafeBrowsingResult(
          url: widget.url,
          isSafe: false,
          error: 'Invalid URL',
        );
        _loading = false;
      });
      return;
    }


    try {
      final result = await _service.checkUrl(widget.url);

      if (!mounted) return;

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = SafeBrowsingResult(
          url: widget.url,
          isSafe: false,
          error: e.toString(),
        );
        _loading = false;
      });
    }
  }
  Future<void> _launchUrl(String urlString) async{
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
    
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
      appBar: AppBar(title: const Text('Scan Result')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _result == null
                ? const Text('No result')
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: ()=> _launchUrl(widget.url),
                          child:
                          Text(
                          widget.url,
                         
                          textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _result!.statusMessage,
                          style: TextStyle(
                            color:
                                _result!.isSafe ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._result!.detailsLines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(line),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}