import 'dart:math';
import 'package:flutter/material.dart';
class HeuristicsCheck{
  //add more later!!!!!
  static final List<String> trustedDomains = [
    'google.com',
    'paypal.com',
    'amazon.com',
    'apple.com',
    'microsoft.com',
    'github.com',
    'linkedin.com',
    'facebook.com',
    'instagram.com',
    'chase.com',
    'bankofamerica.com',
  ];

  static int calculateLevenshtein(String s1, String s2){

    if (s1==s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    //creates dynamic programming matrix
    final dp = List.generate(
      s1.length + 1,
      (_) => List.filled(s2.length + 1, 0),
    );

    for (var i = 0; i <= s1.length; i++){
      dp[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++){
      dp[j][0] = j;
    }
    for(var i = 1; i <= s1.length; i++){
      for(var j = 1; j <= s2.length; j++){
        // compares each char of strings
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = min(
          min(
            dp[i - 1][j] + 1,
            dp[i][j - 1] + 1,
          ),
          dp[i - 1][j - 1] + cost,
        );
      }
    }
    return dp[s1.length][s2.length];



    


  }
  static String extractRootDomain(String domain) {
  final parts = domain
      .split('.')
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return parts[parts.length - 2];
  }

  if (parts.isNotEmpty) {
    return parts.first;
  }

  return domain;
  }
  static Map<String, dynamic> calculateRiskScore(String url, bool safeBrowsingFlagged){
    int score = 0;
    String reason = "";
    // final root = extractRootDomain(url);
    if (safeBrowsingFlagged) {
    return {
      'score': 100,
      'verdict': 'Dangerous',
      'reason': 'Google Safe Browsing flagged this URL'
    };

    
    }
    for (final trusted in trustedDomains) {
      // final trustedRoot = extractRootDomain(trusted);
      final distance = calculateLevenshtein(url, trusted);

      if (distance == 1 && url != trusted) {
        score += 40;
        reason = 'Very close to trusted domain: $trusted';
        break;
      }

      if (distance == 2 && url != trusted) {
        score += 25;
        reason = 'Possibly mimicking trusted domain: $trusted';
        break;
      }
    }
    if (score > 100) score = 100;
    String verdict;

    if (score >= 80) {
      verdict = 'Dangerous';
    } else if (score >= 50) {
      verdict = 'Suspicious';
    } else {
      verdict = 'Safe';
    }
    debugPrint('Score: $score');
    return {
      'score': score,
      'verdict': verdict,
      'reason': reason.isEmpty
          ? 'No major risks detected'
          : reason,
    };
    }
}