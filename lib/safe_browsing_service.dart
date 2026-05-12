import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';


class SafeBrowsingMatch {
  final String threatType;
  final String platformType;
  final String threatEntryType;
  final String? threatUrl;

  const SafeBrowsingMatch({
    required this.threatType,
    required this.platformType,
    required this.threatEntryType,
    required this.threatUrl,
  });

  factory SafeBrowsingMatch.fromJson(Map<String, dynamic> json) {
    final threat = json['threat'];
    String? threatUrl;
    if (threat is Map<String, dynamic>) {
      final url = threat['url'];
      if (url is String) {
        threatUrl = url;
      }
    }
    return SafeBrowsingMatch(
      threatType: (json['threatType'] as String?) ?? 'UNKNOWN',
      platformType: (json['platformType'] as String?) ?? 'UNKNOWN',
      threatEntryType: (json['threatEntryType'] as String?) ?? 'UNKNOWN',
      threatUrl: threatUrl,
    );
  }
}

class SafeBrowsingResult {
  final String url;
  final bool isSafe;
  final int riskScore;
  final List<SafeBrowsingMatch> matches;
  final String? error;
  final List<String> threats;
  final List<String> analysisDetails;


  const SafeBrowsingResult({
    required this.url,
    required this.isSafe,
    this.riskScore = 0,
    this.matches = const [],
    this.error,
    this.threats = const [],
    this.analysisDetails = const [],
  });

  String get statusMessage {
    if (error != null && error!.isNotEmpty) {
      return 'Error: $error';
    }
    return isSafe ? 'Safe: no threats found.' : 'Unsafe: threats detected.';
  }

  List<String> get detailsLines {
    if (matches.isEmpty) {
      return const [];
    }
    return matches
        .map((match) {
          final urlPart = match.threatUrl != null ? ' URL: ${match.threatUrl}' : '';
          return '${match.threatType} on ${match.platformType} (${match.threatEntryType}).$urlPart';
        })
        .toList(growable: false);
  }
}

// store threat list
class _ThreatListState {
  final String threatType;
  final String platformType;
  final String threatEntryType;
  String state; // opaque state token from Google
  final Set<String> hashPrefixes; // hex-encoded 4-byte prefixes

  _ThreatListState({
    required this.threatType,
    required this.platformType,
    required this.threatEntryType,
    this.state = '',
    Set<String>? hashPrefixes,
  }) : hashPrefixes = hashPrefixes ?? {};

  Map<String, dynamic> toListSpec() => {
        'threatType': threatType,
        'platformType': platformType,
        'threatEntryType': threatEntryType,
        'state': state,
        'constraints': {
          'maxUpdateEntries': 2048,
          'maxDatabaseEntries': 4096,
          'region': 'US',
          'supportedCompressions': ['RAW'],
        },
      };
}

class SafeBrowsingService {
  SafeBrowsingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://safebrowsing.googleapis.com/v4';

  // Local threat database — keyed by "threatType/platformType/threatEntryType"
  final Map<String, _ThreatListState> _localDatabase = {};
  DateTime? _lastUpdated;

  // The lists we care about
  static const List<(String, String, String)> _threatLists = [
    ('MALWARE', 'ANY_PLATFORM', 'URL'),
    ('SOCIAL_ENGINEERING', 'ANY_PLATFORM', 'URL'),
    ('UNWANTED_SOFTWARE', 'ANY_PLATFORM', 'URL'),
    ('POTENTIALLY_HARMFUL_APPLICATION', 'ANY_PLATFORM', 'URL'),
  ];

  

  String _key(String t, String p, String e) => '$t/$p/$e';

  // ── Step 1: Fetch & apply threat list updates ─────────────────────────────

  Future<String?> updateThreatLists() async {
    final apiKey = _getApiKey();
    if (apiKey == null) return 'Missing API key.';

    // Ensure all lists are initialised in the local DB
    for (final (t, p, e) in _threatLists) {
      _localDatabase.putIfAbsent(
        _key(t, p, e),
        () => _ThreatListState(
          threatType: t,
          platformType: p,
          threatEntryType: e,
        ),
      );
    }

    final uri = Uri.parse('$_baseUrl/threatListUpdates:fetch?key=$apiKey');
    final body = jsonEncode({
      'client': {'clientId': 'safe-scan-flutter', 'clientVersion': '1.0.0'},
      'listUpdateRequests': _localDatabase.values
          .map((s) => s.toListSpec())
          .toList(growable: false),
    });

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        return 'Update API error ${response.statusCode}: ${response.body}';
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final listUpdates = decoded['listUpdateResponses'] as List<dynamic>? ?? [];

      for (final update in listUpdates.cast<Map<String, dynamic>>()) {
        _applyListUpdate(update);
      }

      _lastUpdated = DateTime.now();
      return null; // success
    } catch (e) {
      return 'Failed to update threat lists: $e';
    }
  }

  void _applyListUpdate(Map<String, dynamic> update) {
    final threatType = update['threatType'] as String? ?? '';
    final platformType = update['platformType'] as String? ?? '';
    final threatEntryType = update['threatEntryType'] as String? ?? '';
    final responseType = update['responseType'] as String? ?? '';
    final newState = update['newClientState'] as String? ?? '';

    final dbKey = _key(threatType, platformType, threatEntryType);
    final state = _localDatabase[dbKey];
    if (state == null) return;

    state.state = newState;

    // Full update → wipe existing prefixes first
    if (responseType == 'FULL_UPDATE') {
      state.hashPrefixes.clear();
    }

    final additions = update['additions'] as List<dynamic>? ?? [];
    for (final addition in additions.cast<Map<String, dynamic>>()) {
      final rawHashes = addition['rawHashes'] as Map<String, dynamic>?;
      if (rawHashes == null) continue;

      final prefixSize = rawHashes['prefixSize'] as int? ?? 4;
      final rawHashesB64 = rawHashes['rawHashes'] as String?;
      if (rawHashesB64 == null) continue;

      final bytes = base64.decode(rawHashesB64);
      // Each hash prefix is `prefixSize` bytes; iterate and store as hex
      for (var i = 0; i + prefixSize <= bytes.length; i += prefixSize) {
        final prefix = bytes.sublist(i, i + prefixSize);
        state.hashPrefixes.add(_bytesToHex(prefix));
      }
    }

    final removals = update['removals'] as List<dynamic>? ?? [];
    for (final removal in removals.cast<Map<String, dynamic>>()) {
      final rawIndices = removal['rawIndices'] as Map<String, dynamic>?;
      if (rawIndices == null) continue;
      final indices = (rawIndices['indices'] as List<dynamic>? ?? [])
          .cast<int>();
      final sortedPrefixes = state.hashPrefixes.toList()..sort();
      for (final index in indices.reversed) {
        if (index < sortedPrefixes.length) {
          state.hashPrefixes.remove(sortedPrefixes[index]);
        }
      }
    }
  }

  // ── Step 2 + 3: Check a URL ───────────────────────────────────────────────
  Future<SafeBrowsingResult> _lookupApiCheck(String url, String apiKey) async {
  final uri = Uri.parse('https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey');
  final body = jsonEncode({
    'client': {'clientId': 'safe-scan-flutter', 'clientVersion': '1.0.0'},
    'threatInfo': {
      'threatTypes': ['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE', 'POTENTIALLY_HARMFUL_APPLICATION'],
      'platformTypes': ['ANY_PLATFORM'],
      'threatEntryTypes': ['URL'],
      'threatEntries': [{'url': url}],
    },
  });

  final response = await _client.post(uri, headers: {'Content-Type': 'application/json'}, body: body);
  if (response.body.trim().isEmpty) return SafeBrowsingResult(url: url, isSafe: true);
  
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  final matchesJson = (decoded['matches'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();
  final matches = matchesJson.map((m) => SafeBrowsingMatch(
    threatType: m['threatType'] as String? ?? 'UNKNOWN',
    platformType: m['platformType'] as String? ?? 'UNKNOWN',
    threatEntryType: m['threatEntryType'] as String? ?? 'UNKNOWN',
    threatUrl: url,
  )).toList();

  return SafeBrowsingResult(url: url, isSafe: matches.isEmpty, matches: matches);
}

  Future<SafeBrowsingResult> checkUrl(String url) async {
    print('=== checkUrl called with: $url');
    final apiKey = _getApiKey();
    
    if (apiKey == null) {
      return SafeBrowsingResult(
        url: url,
        isSafe: false,
        error: 'Missing API key. Set API_KEY in assets/config/app.env.',
      );
    }

    // Auto-update if we've never fetched or data is older than 30 minutes
    if (_lastUpdated == null ||
        DateTime.now().difference(_lastUpdated!) > const Duration(minutes: 30)) {
        
      final updateError = await updateThreatLists();
      if (updateError != null) {
        print('UPDATE ERROR: $updateError');
        return _lookupApiCheck(url, apiKey); // fall back

        
        return SafeBrowsingResult(url: url, isSafe: false, error: updateError);
      }
    }
    print('=== DB has ${_localDatabase.length} lists');
    // Compute the full SHA-256 hash of the URL
    final fullHash = _sha256Hash(url);
    final prefix4 = fullHash.substring(0, 8); // first 4 bytes = 8 hex chars

    // Check each local threat list for a matching prefix
    final candidateLists = <_ThreatListState>[];
    for (final state in _localDatabase.values) {
      if (state.hashPrefixes.contains(prefix4)) {
        candidateLists.add(state);
      }
    }
    debugPrint('Full hash: $fullHash');
    debugPrint('Prefix:    $prefix4');
    debugPrint('Candidate lists: ${candidateLists.map((s) => s.threatType).toList()}');

    // No local prefix match → definitely safe (no false negatives here)
    if (candidateLists.isEmpty) {
      return SafeBrowsingResult(url: url, isSafe: true);
    }

    // Prefix match found → verify with fullHashes:find to eliminate false positives
    return _verifyFullHashes(url, fullHash, candidateLists, apiKey);
  }

  Future<SafeBrowsingResult> _verifyFullHashes(
    String url,
    String fullHashHex,
    List<_ThreatListState> candidateLists,
    String apiKey,
  ) async {
    final uri = Uri.parse('$_baseUrl/fullHashes:find?key=$apiKey');

    final body = jsonEncode({
      'client': {'clientId': 'safe-scan-flutter', 'clientVersion': '1.0.0'},
      'clientStates':
          candidateLists.map((s) => s.state).toList(growable: false),
      'threatInfo': {
        'threatTypes': candidateLists.map((s) => s.threatType).toSet().toList(),
        'platformTypes':
            candidateLists.map((s) => s.platformType).toSet().toList(),
        'threatEntryTypes':
            candidateLists.map((s) => s.threatEntryType).toSet().toList(),
        'threatEntries': [
          // Send the raw 4-byte prefix (base64-encoded) as required by the API
          {'hash': base64.encode(_hexToBytes(fullHashHex.substring(0, 8)))},
        ],
      },
    });

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        return SafeBrowsingResult(
          url: url,
          isSafe: false,
          error: 'Full hash verification error ${response.statusCode}.',
        );
      }

      if (response.body.trim().isEmpty) {
        return SafeBrowsingResult(url: url, isSafe: true);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final matchesJson = decoded['matches'] as List<dynamic>? ?? [];

      // Filter matches where the full hash actually matches our URL's hash
      final confirmedMatches = matchesJson
          .cast<Map<String, dynamic>>()
          .where((m) {
            final hashB64 = m['threat']?['hash'] as String?;
            if (hashB64 == null) return false;
            final returnedHashHex = _bytesToHex(base64.decode(hashB64));
            return returnedHashHex == fullHashHex;
          })
          .map((m) => SafeBrowsingMatch(
                threatType: m['threatType'] as String? ?? 'UNKNOWN',
                platformType: m['platformType'] as String? ?? 'UNKNOWN',
                threatEntryType: m['threatEntryType'] as String? ?? 'UNKNOWN',
                threatUrl: url,
              ))
          .toList(growable: false);

      print('Confirmed matches: ${confirmedMatches.length}');
      print('Returning isSafe: ${confirmedMatches.isEmpty}');

      return SafeBrowsingResult(
        url: url,
        isSafe: confirmedMatches.isEmpty,
        matches: confirmedMatches,
      );
    } catch (e) {
      print('CATCH ERROR in _verifyFullHashes: $e');
      return SafeBrowsingResult(
        url: url,
        isSafe: false,
        error: 'Failed to verify full hashes: $e',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _getApiKey() {
    final key = dotenv.env['API_KEY'];
    return (key == null || key.isEmpty) ? null : key;
  }

  /// SHA-256 of the URL bytes, returned as a lowercase hex string.
  String _sha256Hash(String url) {
    final digest = sha256.convert(utf8.encode(url));
    return digest.toString(); // already hex
  }

  String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Expose last update time for UI/debugging.
  DateTime? get lastUpdated => _lastUpdated;

  /// Force a fresh update (call this on app resume, for example).
  Future<String?> forceUpdate() {
    _lastUpdated = null;
    return updateThreatLists();
  }




  // Future<SafeBrowsingResult> checkUrl(String url) async {
  //   final apiKey = dotenv.env['API_KEY'];
  //   if (apiKey == null || apiKey.isEmpty) {
  //     return SafeBrowsingResult(
  //       url: url,
  //       isSafe: false,
  //       error: 'Missing API key. Set API_KEY in assets/config/app.env.',
  //     );
  //   }

  //   final uri = Uri.parse('https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey');
  //   final body = jsonEncode({
  //     'client': {
  //       'clientId': 'safe-scan-flutter',
  //       'clientVersion': '1.0.0',
  //     },
  //     'threatInfo': {
  //       'threatTypes': [
  //         'MALWARE',
  //         'SOCIAL_ENGINEERING',
  //         'UNWANTED_SOFTWARE',
  //         'POTENTIALLY_HARMFUL_APPLICATION',
  //       ],
  //       'platformTypes': ['ANY_PLATFORM'],
  //       'threatEntryTypes': ['URL'],
  //       'threatEntries': [
  //         {'url': url},
  //       ],
  //     },
  //   });

  //   try {
  //     final response = await _client.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: body,
  //     );

  //     if (response.statusCode != 200) {
  //       return SafeBrowsingResult(
  //         url: url,
  //         isSafe: false,
  //         error: 'Safe Browsing API error ${response.statusCode}.',
  //       );
  //     }

  //     if (response.body.trim().isEmpty) {
  //       return SafeBrowsingResult(url: url, isSafe: true);
  //     }

  //     final decoded = jsonDecode(response.body);
  //     if (decoded is! Map<String, dynamic>) {
  //       return SafeBrowsingResult(
  //         url: url,
  //         isSafe: false,
  //         error: 'Unexpected API response.',
  //       );
  //     }

  //     final matchesJson = decoded['matches'];
  //     if (matchesJson is List) {
  //       final matches = matchesJson
  //           .whereType<Map<String, dynamic>>()
  //           .map(SafeBrowsingMatch.fromJson)
  //           .toList(growable: false);
  //       return SafeBrowsingResult(
  //         url: url,
  //         isSafe: matches.isEmpty,
  //         matches: matches,
  //       );
  //     }

  //     return SafeBrowsingResult(url: url, isSafe: true);
  //   } catch (error) {
  //     return SafeBrowsingResult(
  //       url: url,
  //       isSafe: false,
  //       error: 'Failed to check URL: $error',
  //     );
  //   }
  // }
}
