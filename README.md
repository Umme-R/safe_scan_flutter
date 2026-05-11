# 🛡️ SafeScan

A Flutter-based QR code security scanner that protects users from malicious links using real-time threat analysis and multi-layer heuristic detection.

Built by a team of 4 as a security-focused mobile/web application.

---

## 📱 Features

### Core Scanning
- **QR Code Scanner** — scan any QR code using your device camera
- **URL Paste Input** — manually paste or type any URL to check it instantly
- **URL Expander** — automatically expands shortened URLs (bit.ly, tinyurl, etc.) before checking, so you always see the real destination

### Threat Detection
- **Google Safe Browsing API** — real-time check against Google's database of millions of known malicious URLs
- **Multi-layer Heuristic Analysis** — 11 independent detection rules that catch threats Google hasn't flagged yet:
  - Typosquatting detection (Levenshtein distance — catches `paypa1.com` vs `paypal.com`)
  - HTTP vs HTTPS check
  - Raw IP address detection
  - Suspicious TLD detection (`.xyz`, `.tk`, `.top`, etc.)
  - Excessive hyphens in domain
  - Too many subdomains
  - Unusually long URLs
  - Leet-speak number substitution in domain
  - Phishing keyword detection (`login`, `verify`, `secure`, etc.)
  - Special character injection detection
  - Brand impersonation in subdomain detection

### Results & Risk Scoring
- **Animated Risk Score** — circular gauge and bar that fills from 0–100 with color coding (green / yellow / red)
- **URL Breakdown Panel** — splits the URL into protocol, domain, path, and query parameters
- **Analysis Details** — lists every heuristic flag that was triggered
- **Warning Dialog** — dangerous URLs show a confirmation popup with a 3-second countdown before "Open Anyway" becomes tappable

### History & Stats
- **Scan History** — every scan is saved locally with safe/dangerous status
- **Search History** — filter past scans by domain or URL
- **Stats Screen** — total scans, safe vs dangerous count, percentage safe, animated bar chart, and current safe scan streak

### UI & Experience
- **Dark / Light Mode Toggle** — switches instantly across all screens
- **Animated Home Screen** — floating particles, mouse-reactive glow orb, pulsing QR icon
- **Glassmorphism Cards** — frosted glass effect on feature cards
- **Shimmer Button** — subtle moving shine on the scan button
- **Onboarding Screen** — 3-slide intro shown on first launch, skipped on return visits
- **Clickable Info Cards** — tap Phishing, Malware, or Threats to learn what each means

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Threat API | Google Safe Browsing v4 |
| QR Scanning | mobile_scanner |
| URL Expansion | Node.js + Express server |
| Local Storage | shared_preferences |
| URL Launching | url_launcher |
| HTTP Client | http |
| Config | flutter_dotenv |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- Node.js (for the URL expansion server)
- A Google Safe Browsing API key

### 1. Clone the repo
```bash
git clone https://github.com/Umme-R/safe_scan_flutter.git
cd safe_scan_flutter
```

### 2. Set up your API key
Create a file at `assets/config/app.env`:
```
API_KEY=your_google_safe_browsing_api_key_here
```

To get an API key:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable the **Safe Browsing API**
3. Create an API key under **APIs & Services → Credentials**

### 3. Install Flutter dependencies
```bash
flutter pub get
```

### 4. Start the URL expansion server
```bash
node server.js
```

### 5. Run the app
```bash
# Chrome (web)
flutter run -d chrome

# iOS simulator
flutter run -d ios

# Android emulator
flutter run -d android
```

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, home screen, theme toggle
├── theme.dart                  # Color palette and theme constants
├── onboarding_screen.dart      # First-launch onboarding slides
├── scan_result_screen.dart     # Result screen with risk score and breakdown
├── history_screen.dart         # Scan history with search
├── history_store.dart          # Local persistence for scan history
├── stats_screen.dart           # Statistics and charts
├── qr_code_scanner.dart        # Camera-based QR scanner
├── qr_scanner_overlay.dart     # Scanner frame overlay
├── scanner_overlay_painter.dart # Custom painter for scanner UI
├── safe_browsing_service.dart  # Google Safe Browsing API integration
└── url_heuristics.dart         # 11-rule heuristic risk scoring engine
```

---

## 🔬 How the Risk Score Works

Every scanned URL goes through two layers:

**Layer 1 — Google Safe Browsing**
If Google flags the URL, the score is immediately set to 100 (Dangerous) and no further checks are needed.

**Layer 2 — Heuristic Engine**
If Google doesn't flag it, the URL is run through 11 independent rules. Each rule adds points to the risk score:

| Rule | Points |
|---|---|
| 1-character typosquat of trusted domain | +45 |
| 2-character typosquat of trusted domain | +25 |
| Brand name in subdomain (not root) | +35 |
| Raw IP address as host | +30 |
| 3+ phishing keywords | +30 |
| Suspicious TLD (.xyz, .tk, etc.) | +20 |
| 3+ hyphens in domain | +20 |
| URL over 150 characters | +20 |
| 2+ number substitutions in domain | +25 |
| Multiple subdomains | +10–25 |
| HTTP (not HTTPS) | +15 |

**Final verdict:**
- 0–34 → ✅ Safe
- 35–69 → ⚠️ Suspicious
- 70–100 → 🚨 Dangerous

---

## 👥 Team

| Contributor | GitHub |
|---|---|
| Umme R | [@Umme-R](https://github.com/Umme-R) |
| jid2118 | [@jid2118](https://github.com/jid2118) |
| Helen Zheng | [@oat1e](https://github.com/oat1e) |
| Maria Showalter | [@Mariaareadne1](https://github.com/Mariaareadne1) |

---

## 📄 License

This project is for educational purposes.