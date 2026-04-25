import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  final List<SafeBrowsingMatch> matches;
  final String? error;
  final List<String> threats;
  final List<String> analysisDetails;


  const SafeBrowsingResult({
    required this.url,
    required this.isSafe,
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

class SafeBrowsingService {
  SafeBrowsingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SafeBrowsingResult> checkUrl(String url) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return SafeBrowsingResult(
        url: url,
        isSafe: false,
        error: 'Missing API key. Set API_KEY in .env.',
      );
    }

    final uri = Uri.parse('https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey');
    final body = jsonEncode({
      'client': {
        'clientId': 'safe-scan-flutter',
        'clientVersion': '1.0.0',
      },
      'threatInfo': {
        'threatTypes': [
          'MALWARE',
          'SOCIAL_ENGINEERING',
          'UNWANTED_SOFTWARE',
          'POTENTIALLY_HARMFUL_APPLICATION',
        ],
        'platformTypes': ['ANY_PLATFORM'],
        'threatEntryTypes': ['URL'],
        'threatEntries': [
          {'url': url},
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
          error: 'Safe Browsing API error ${response.statusCode}.',
        );
      }

      if (response.body.trim().isEmpty) {
        return SafeBrowsingResult(url: url, isSafe: true);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return SafeBrowsingResult(
          url: url,
          isSafe: false,
          error: 'Unexpected API response.',
        );
      }

      final matchesJson = decoded['matches'];
      if (matchesJson is List) {
        final matches = matchesJson
            .whereType<Map<String, dynamic>>()
            .map(SafeBrowsingMatch.fromJson)
            .toList(growable: false);
        return SafeBrowsingResult(
          url: url,
          isSafe: matches.isEmpty,
          matches: matches,
        );
      }

      return SafeBrowsingResult(url: url, isSafe: true);
    } catch (error) {
      return SafeBrowsingResult(
        url: url,
        isSafe: false,
        error: 'Failed to check URL: $error',
      );
    }
  }
}
