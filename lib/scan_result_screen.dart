import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_scan_flutter/theme.dart';
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
      if (mounted) {
        setState(() {
          _result = SafeBrowsingResult(
            url: widget.url,
            isSafe: false,
            error: 'Invalid URL',
          );
          _loading = false;
        });
      }
      return;
    }

    try {
      final result = await _service.checkUrl(widget.url);

      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL copied to clipboard')));
    }
  }

  IconData getStatusIcon(bool isSafe) {
    return isSafe ? Icons.shield : Icons.warning_amber_rounded;
  }

  Color getStatusColor(bool isSafe) {
    return isSafe ? SafeScanTheme.safeGreen : SafeScanTheme.error;
  }

  String getStatusText(bool isSafe) {
    return isSafe ? 'SAFE' : 'SUSPICIOUS';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result'), elevation: 0),
      body: _loading
          ? const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking safety...'),
                    ],
                  ),
                ),
              ),
            )
          : _result == null
          ? const Center(child: Text('No result'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            getStatusIcon(_result!.isSafe),
                            size: 80,
                            color: getStatusColor(_result!.isSafe),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            getStatusText(_result!.isSafe),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: getStatusColor(_result!.isSafe),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _result!.statusMessage,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.link_rounded),
                              const SizedBox(width: 12),
                              const Text(
                                'Scanned URL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            widget.url,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _copyUrl,
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_result!.detailsLines.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: SafeScanTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._result!.detailsLines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  '• $line',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(widget.url),
                      icon: const Icon(Icons.launch_rounded),
                      label: Text(
                        _result!.isSafe ? 'Visit Site' : 'Visit Anyway',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              _result!.isSafe
                                  ? SafeScanTheme.primary
                                  : SafeScanTheme.primary.withOpacity(0.8),
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
