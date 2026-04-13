import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String url;
  final String displayName;
  final bool isSafe;
  final DateTime scannedAt;

  HistoryEntry({
    required this.url,
    required this.displayName,
    required this.isSafe,
    required this.scannedAt,
  });

  factory HistoryEntry.fromUrl({required String url, required bool isSafe}) {
    return HistoryEntry(
      url: url,
      displayName: _deriveDisplayName(url),
      isSafe: isSafe,
      scannedAt: DateTime.now(),
    );
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      url: json['url'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      isSafe: json['isSafe'] as bool? ?? false,
      scannedAt:
          DateTime.tryParse(json['scannedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'displayName': displayName,
    'isSafe': isSafe,
    'scannedAt': scannedAt.toIso8601String(),
  };

  static String _deriveDisplayName(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    if (host.isEmpty) {
      return url;
    }
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}

class HistoryStore extends ChangeNotifier {
  HistoryStore._();

  static final HistoryStore instance = HistoryStore._();

  static const String _storageKey = 'history_entries_v1';

  final List<HistoryEntry> _entries = [];
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadFromStorage();
  }

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  void addEntry(HistoryEntry entry) {
    _entries.insert(0, entry);
    _persist();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeAt(index);
    _persist();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    _persist();
  }

  Future<void> _loadFromStorage() async {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _entries
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((entry) => HistoryEntry.fromJson(
                      Map<String, dynamic>.from(entry),
                    )),
          );
        notifyListeners();
      }
    } catch (_) {
      // Ignore corrupt cache.
    }
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final data = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
    notifyListeners();
  }
}
