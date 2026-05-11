import 'dart:math';
import 'package:flutter/material.dart';

class HeuristicsCheck {
  // ── Trusted domains ──────────────────────────────────────────────────────
  static const List<String> trustedDomains = [
    'google.com', 'paypal.com', 'amazon.com', 'apple.com',
    'microsoft.com', 'github.com', 'linkedin.com', 'facebook.com',
    'instagram.com', 'chase.com', 'bankofamerica.com', 'twitter.com',
    'netflix.com', 'spotify.com', 'dropbox.com', 'adobe.com',
    'yahoo.com', 'wellsfargo.com', 'citibank.com', 'ebay.com',
  ];

  // ── Suspicious TLDs ──────────────────────────────────────────────────────
  static const List<String> suspiciousTlds = [
    '.xyz', '.tk', '.top', '.click', '.gq', '.ml', '.cf',
    '.ga', '.pw', '.cc', '.su', '.buzz', '.rest', '.loan',
    '.work', '.party', '.download', '.racing', '.stream',
  ];

  // ── Phishing keywords ────────────────────────────────────────────────────
  static const List<String> phishingKeywords = [
    'login', 'verify', 'secure', 'update', 'confirm',
    'account', 'banking', 'password', 'credential', 'signin',
    'validate', 'authenticate', 'suspend', 'unlock', 'recover',
  ];

  // ── Levenshtein distance ─────────────────────────────────────────────────
  static int calculateLevenshtein(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final dp = List.generate(
      s1.length + 1,
      (_) => List.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++) dp[i][0] = i;
    for (var j = 0; j <= s2.length; j++) dp[0][j] = j;

    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = min(
          min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[s1.length][s2.length];
  }

  // ── Extract root domain (e.g. "paypal" from "login.paypal.com") ──────────
  static String extractRootDomain(String domain) {
    final parts = domain
        .split('.')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    if (parts.isNotEmpty) return parts.first;
    return domain;
  }

  // ── Main scoring function ────────────────────────────────────────────────
  static Map<String, dynamic> calculateRiskScore(
      String url, bool safeBrowsingFlagged) {

    // Google already flagged it — instant 100
    if (safeBrowsingFlagged) {
      return {
        'score': 100,
        'verdict': 'Dangerous',
        'reason': 'Google Safe Browsing flagged this URL',
        'flags': ['Google Safe Browsing match'],
      };
    }

    int score = 0;
    final List<String> flags = [];

    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return {
        'score': 80,
        'verdict': 'Suspicious',
        'reason': 'Could not parse URL structure',
        'flags': ['Unparseable URL'],
      };
    }

    final host = uri.host.toLowerCase();
    final fullUrl = url.toLowerCase();
    final rootDomain = extractRootDomain(host);

    // ── 1. Typosquatting check (Levenshtein) ─────────────────────────────
    for (final trusted in trustedDomains) {
      final trustedRoot = extractRootDomain(trusted);
      final distance = calculateLevenshtein(rootDomain, trustedRoot);

      if (rootDomain == trustedRoot) break; // exact match — trusted, skip

      if (distance == 1) {
        score += 45;
        flags.add('Very close to trusted domain: $trusted (1 character off)');
        break;
      } else if (distance == 2) {
        score += 25;
        flags.add('Possibly mimicking trusted domain: $trusted');
        break;
      }
    }

    // ── 2. HTTP (not HTTPS) ──────────────────────────────────────────────
    if (uri.scheme == 'http') {
      score += 15;
      flags.add('Uses unencrypted HTTP instead of HTTPS');
    }

    // ── 3. IP address as host ────────────────────────────────────────────
    final ipRegex = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');
    if (ipRegex.hasMatch(host)) {
      score += 30;
      flags.add('Uses raw IP address instead of a domain name');
    }

    // ── 4. Suspicious TLD ────────────────────────────────────────────────
    for (final tld in suspiciousTlds) {
      if (host.endsWith(tld)) {
        score += 20;
        flags.add('Uses suspicious top-level domain: $tld');
        break;
      }
    }

    // ── 5. Too many hyphens in domain ────────────────────────────────────
    final hyphenCount = host.split('').where((c) => c == '-').length;
    if (hyphenCount >= 3) {
      score += 20;
      flags.add('Excessive hyphens in domain ($hyphenCount found)');
    } else if (hyphenCount == 2) {
      score += 10;
      flags.add('Multiple hyphens in domain');
    }

    // ── 6. Too many subdomains ───────────────────────────────────────────
    final subdomainCount = host.split('.').length - 2;
    if (subdomainCount >= 3) {
      score += 25;
      flags.add('Excessive subdomains ($subdomainCount) — classic phishing trick');
    } else if (subdomainCount == 2) {
      score += 10;
      flags.add('Multiple subdomains detected');
    }

    // ── 7. Very long URL ─────────────────────────────────────────────────
    if (url.length > 150) {
      score += 20;
      flags.add('Unusually long URL (${url.length} characters)');
    } else if (url.length > 100) {
      score += 10;
      flags.add('Long URL (${url.length} characters)');
    }

    // ── 8. Numbers replacing letters in domain (e.g. paypa1, g00gle) ────
    final leetRegex = RegExp(r'[0-9]');
    final numberMatches = leetRegex.allMatches(rootDomain).length;
    if (numberMatches >= 2) {
      score += 25;
      flags.add('Domain contains numbers that may replace letters (leet-speak)');
    } else if (numberMatches == 1) {
      score += 10;
      flags.add('Domain contains a number (possible letter substitution)');
    }

    // ── 9. Phishing keywords in URL ──────────────────────────────────────
    int keywordCount = 0;
    final List<String> foundKeywords = [];
    for (final keyword in phishingKeywords) {
      if (fullUrl.contains(keyword)) {
        keywordCount++;
        foundKeywords.add(keyword);
      }
    }
    if (keywordCount >= 3) {
      score += 30;
      flags.add('Multiple phishing keywords found: ${foundKeywords.take(3).join(', ')}');
    } else if (keywordCount >= 1) {
      score += 15;
      flags.add('Phishing keyword found: ${foundKeywords.first}');
    }

    // ── 10. Special characters in host ──────────────────────────────────
    if (host.contains('@') || fullUrl.contains('%00') || fullUrl.contains('%2f%2f')) {
      score += 35;
      flags.add('Suspicious special characters in URL');
    }

    // ── 11. Trusted brand name in path/subdomain (not in root domain) ───
    // e.g. "paypal.verify-account.com" — paypal is in the subdomain, not root
    for (final trusted in trustedDomains) {
      final brand = extractRootDomain(trusted);
      if (host.contains(brand) && rootDomain != brand) {
        score += 35;
        flags.add('Trusted brand "$brand" appears outside root domain — possible impersonation');
        break;
      }
    }

    // ── Cap score ────────────────────────────────────────────────────────
    if (score > 100) score = 100;

    // ── Verdict ──────────────────────────────────────────────────────────
    String verdict;
    String reason;

    if (score >= 70) {
      verdict = 'Dangerous';
      reason = flags.isNotEmpty
          ? flags.first
          : 'Multiple risk factors detected';
    } else if (score >= 35) {
      verdict = 'Suspicious';
      reason = flags.isNotEmpty
          ? flags.first
          : 'Some risk factors detected';
    } else {
      verdict = 'Safe';
      reason = flags.isEmpty
          ? 'No major risks detected'
          : 'Minor risk factors noted';
    }

    debugPrint('Heuristics score: $score | Flags: $flags');

    return {
      'score': score,
      'verdict': verdict,
      'reason': reason,
      'flags': flags,
    };
  }
}