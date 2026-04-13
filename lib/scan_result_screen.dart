import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_scan_flutter/theme.dart';
import 'package:safe_scan_flutter/safe_browsing_service.dart';
import 'package:safe_scan_flutter/history_store.dart';
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
  bool _historyAdded = false;

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
      _addToHistory(_result);
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
      _addToHistory(result);
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
      _addToHistory(_result);
    }
  }

  void _addToHistory(SafeBrowsingResult? result) {
    if (result == null || _historyAdded) return;
    _historyAdded = true;
    HistoryStore.instance.addEntry(
      HistoryEntry.fromUrl(url: result.url, isSafe: result.isSafe),
    );
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
      ).showSnackBar(const SnackBar(content: Text('URL copied')));
    }
  }

  Color getStatusColor(bool isSafe) {
    return isSafe ? SafeScanTheme.safe : SafeScanTheme.danger;
  }

  IconData getStatusIcon(bool isSafe) {
    return isSafe ? Icons.security : Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Check'), elevation: 0),
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 24),
                    Text(
                      'Analyzing link safety...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : _result == null
          ? const Center(child: Text('No results available'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            Icon(
                              getStatusIcon(_result!.isSafe),
                              size: 72,
                              color: getStatusColor(_result!.isSafe),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _result!.isSafe ? 'Safe' : 'Dangerous',
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
                    // URL Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link_outlined,
                                  color: SafeScanTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Destination URL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              widget.url,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                              maxLines: 3,
                              minLines: 1,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _copyUrl,
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Copy URL'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Details Card
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
                                    Icons.info_outlined,
                                    color: SafeScanTheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Analysis Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
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
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: SafeScanTheme.onSurface
                                              .withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(line)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // Primary Action - FIXED GREEN BUTTON TEXT VISIBILITY
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(widget.url),
                        icon: const Icon(
                          Icons.launch_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          _result!.isSafe ? 'Open Link' : 'Open Anyway',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _result!.isSafe
                              ? SafeScanTheme.safe
                              : SafeScanTheme.danger.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          elevation: _result!.isSafe ? 2 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Secondary Action
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.qr_code_scanner_outlined),
                        label: const Text('Scan Another'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
