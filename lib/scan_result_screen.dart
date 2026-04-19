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
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      if (mounted) {
        setState(() {
          _result = SafeBrowsingResult(url: widget.url, isSafe: false, error: 'Invalid URL');
          _loading = false;
        });
      }
      _addToHistory(_result);
      return;
    }
    try {
      final result = await _service.checkUrl(widget.url);
      if (mounted) setState(() { _result = result; _loading = false; });
      _addToHistory(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = SafeBrowsingResult(url: widget.url, isSafe: false, error: e.toString());
          _loading = false;
        });
      }
      _addToHistory(_result);
    }
  }

  void _addToHistory(SafeBrowsingResult? result) {
    if (result == null || _historyAdded) return;
    _historyAdded = true;
    HistoryStore.instance.addEntry(HistoryEntry.fromUrl(url: result.url, isSafe: result.isSafe));
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
    }
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
          ),
        ),
        title: const Text(
          'Security Check',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF60A5FA),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analyzing link safety...',
                    style: TextStyle(fontSize: 15, color: Colors.white54),
                  ),
                ],
              ),
            )
          : _result == null
              ? const Center(child: Text('No results available', style: TextStyle(color: Colors.white54)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Status hero card
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: (_result!.isSafe
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)).withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_result!.isSafe
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444)).withOpacity(0.1),
                                blurRadius: 32,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (_result!.isSafe
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444)).withOpacity(0.15),
                                  border: Border.all(
                                    color: (_result!.isSafe
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444)).withOpacity(0.4),
                                  ),
                                ),
                                child: Icon(
                                  _result!.isSafe ? Icons.verified_rounded : Icons.dangerous_rounded,
                                  size: 36,
                                  color: _result!.isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _result!.isSafe ? 'Safe to Open' : 'Dangerous',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _result!.isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _result!.statusMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.55),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // URL card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3A8A).withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.link_rounded, color: Color(0xFF93C5FD), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Destination URL',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  widget.url,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: Color(0xFF93C5FD),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _copyUrl,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 15, color: Color(0xFF60A5FA)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Copy URL',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF60A5FA), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_result!.detailsLines.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.info_rounded, color: Color(0xFF93C5FD), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Analysis Details',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                ..._result!.detailsLines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 6, height: 6,
                                          margin: const EdgeInsets.only(top: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF60A5FA).withOpacity(0.6),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            line,
                                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), height: 1.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Open button
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (_result!.isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => _launchUrl(widget.url),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _result!.isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.launch_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _result!.isSafe ? 'Open Link' : 'Open Anyway',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Scan another button
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Scan Another', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}