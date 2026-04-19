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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Icon(Icons.arrow_back_rounded, color: SafeScanTheme.primary, size: 20),
          ),
        ),
        title: const Text('Security Check', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: SafeScanTheme.primary.withOpacity(0.15), blurRadius: 24)],
                    ),
                    child: Center(child: CircularProgressIndicator(color: SafeScanTheme.primary, strokeWidth: 2.5)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Analyzing link safety...', style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
                ],
              ),
            )
          : _result == null
              ? const Center(child: Text('No results available'))
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
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _result!.isSafe
                                  ? [const Color(0xFF059669), const Color(0xFF10B981)]
                                  : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (_result!.isSafe ? SafeScanTheme.safe : SafeScanTheme.danger).withOpacity(0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
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
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: Icon(
                                  _result!.isSafe ? Icons.verified_rounded : Icons.dangerous_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _result!.isSafe ? 'Safe to Open' : 'Dangerous',
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _result!.statusMessage,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // URL card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: SafeScanTheme.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.link_rounded, color: SafeScanTheme.primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Destination URL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText(
                                  widget.url,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFF475569)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _copyUrl,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 15, color: SafeScanTheme.primary),
                                    const SizedBox(width: 6),
                                    Text('Copy URL', style: TextStyle(fontSize: 13, color: SafeScanTheme.primary, fontWeight: FontWeight.w500)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: SafeScanTheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.info_rounded, color: SafeScanTheme.primary, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Analysis Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B))),
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
                                          decoration: BoxDecoration(color: SafeScanTheme.primary.withOpacity(0.5), shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(line, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        // Action buttons
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _launchUrl(widget.url),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _result!.isSafe ? SafeScanTheme.safe : SafeScanTheme.danger,
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
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: SafeScanTheme.primary,
                              side: BorderSide(color: SafeScanTheme.primary.withOpacity(0.3)),
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