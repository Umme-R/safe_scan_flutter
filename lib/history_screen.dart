import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_scan_flutter/history_store.dart';
import 'package:safe_scan_flutter/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _copyUrl(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HistoryStore.instance;

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
        title: const Text('Scan History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final entries = store.entries;

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: SafeScanTheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_rounded, size: 36, color: SafeScanTheme.primary.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 20),
                    const Text('No scans yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Text('Your scan history will appear here', style: TextStyle(fontSize: 13, color: const Color(0xFF334155).withOpacity(0.5))),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isSafe = entry.isSafe;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: (isSafe ? SafeScanTheme.safe : SafeScanTheme.danger).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isSafe ? Icons.verified_rounded : Icons.dangerous_rounded,
                                  color: isSafe ? SafeScanTheme.safe : SafeScanTheme.danger,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.displayName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.url,
                                      style: TextStyle(fontSize: 12, color: const Color(0xFF334155).withOpacity(0.5)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (isSafe ? SafeScanTheme.safe : SafeScanTheme.danger).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isSafe ? 'Safe' : 'Dangerous',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSafe ? SafeScanTheme.safe : SafeScanTheme.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () => _copyUrl(context, entry.url),
                                    icon: Icon(Icons.copy_rounded, size: 18, color: SafeScanTheme.primary),
                                    tooltip: 'Copy link',
                                  ),
                                  IconButton(
                                    onPressed: () => store.removeAt(index),
                                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: SafeScanTheme.danger),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: store.clear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SafeScanTheme.danger,
                        side: BorderSide(color: SafeScanTheme.danger.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Clear All History', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}