import 'package:flutter/material.dart';
import 'package:safe_scan_flutter/history_store.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final url = Uri.tryParse(urlString);
    if (url == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL')),
        );
      }
      return;
    }

    if (!await launchUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HistoryStore.instance;

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
          'Scan History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final filteredEntries = store.entries.asMap().entries.where((entry) {
              if (_query.isEmpty) return true;
              final item = entry.value;
              return item.displayName.toLowerCase().contains(_query) ||
                  item.url.toLowerCase().contains(_query);
            }).toList(growable: false);

            if (store.entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.history_rounded, size: 36, color: Colors.white24),
                    ),
                    const SizedBox(height: 20),
                    const Text('No scans yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 6),
                    const Text('Your scan history will appear here', style: TextStyle(fontSize: 13, color: Colors.white30)),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFF60A5FA), size: 20),
                        hintText: 'Search history',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredEntries.isEmpty
                      ? Center(
                          child: Text(
                            'No matching scans found',
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final indexedEntry = filteredEntries[index];
                            final storeIndex = indexedEntry.key;
                            final entry = indexedEntry.value;
                            final isSafe = entry.isSafe;
                            final statusColor = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Icon(
                                        isSafe ? Icons.verified_rounded : Icons.dangerous_rounded,
                                        color: statusColor,
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
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            entry.url,
                                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: statusColor.withOpacity(0.25)),
                                            ),
                                            child: Text(
                                              isSafe ? 'Safe' : 'Dangerous',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () => _openUrl(context, entry.url),
                                          icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF60A5FA)),
                                          tooltip: 'Open link',
                                        ),
                                        IconButton(
                                          onPressed: () => store.removeAt(storeIndex),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
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
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3)),
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
