import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_scan_flutter/theme.dart';
import 'package:safe_scan_flutter/qr_code_scanner.dart';
import 'package:safe_scan_flutter/scan_result_screen.dart';
import 'package:safe_scan_flutter/history_screen.dart';
import 'package:safe_scan_flutter/history_store.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/config/app.env');
  } catch (error) {
    debugPrint('Skipping env load: $error');
  }
  await HistoryStore.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = true;
  void toggleTheme() => setState(() => isDark = !isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeScan',
      theme: SafeScanTheme.theme,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(isDark: isDark),
    );
  }
}

class _Particle {
  double x, y, size, speedX, speedY, opacity;
  _Particle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = rng.nextDouble() * 2 + 1,
        speedX = (rng.nextDouble() - 0.5) * 0.0003,
        speedY = (rng.nextDouble() - 0.5) * 0.0003,
        opacity = rng.nextDouble() * 0.5 + 0.1;

  void update() {
    x += speedX;
    y += speedY;
    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;
  }
}

class MyHomePage extends StatefulWidget {
  final bool isDark;
  const MyHomePage({super.key, required this.isDark});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Offset _mousePosition = const Offset(0.5, 0.5);
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  final TextEditingController _urlController = TextEditingController();
  bool _urlHasText = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) _particles.add(_Particle(_rng));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {
          for (final p in _particles) p.update();
        });
      })
      ..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _urlController.addListener(() {
      setState(() => _urlHasText = _urlController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submitUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    final normalized = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';
    _urlController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanResultScreen(url: normalized)),
    );
  }

  void _showCardInfo(String title, String description, IconData icon) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF0D1B2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3)),
                ),
                child: Icon(icon, color: const Color(0xFF60A5FA), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: widget.isDark
                      ? Colors.white54
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = widget.isDark;

    final bgColor =
        isDark ? const Color(0xFF060E1E) : const Color(0xFFF0F4FF);
    final textColor =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor =
        isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF64748B);
    final cardColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final cardBorder =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.07);

    return Scaffold(
      backgroundColor: bgColor,
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _mousePosition = Offset(
              event.position.dx / size.width,
              event.position.dy / size.height,
            );
          });
        },
        child: Stack(
          children: [
            // Particles — always visible, color changes with theme
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _ParticlePainter(_particles, isDark),
            ),

            // Mouse glow — dark mode only
            if (isDark)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                left: _mousePosition.dx * size.width - 200,
                top: _mousePosition.dy * size.height - 200,
                child: IgnorePointer(
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF1E3A8A).withOpacity(0.25),
                        const Color(0xFF1E3A8A).withOpacity(0.08),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),

            // Corner glow — dark mode only
            if (isDark)
              Positioned(
                top: -120,
                right: -120,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF3B5FD4).withOpacity(0.15),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  // Nav bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'SafeScan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ]),
                        Row(children: [
                          // Theme toggle
                          GestureDetector(
                            onTap: () => MyApp.of(context)?.toggleTheme(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.08)),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // History
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.08)),
                              ),
                              child: Icon(Icons.history_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                  size: 20),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),

                          // Animated icon
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 130 + _pulseController.value * 16,
                                    height: 130 + _pulseController.value * 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1E3A8A)
                                            .withOpacity(0.2 -
                                                _pulseController.value * 0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 105,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? const Color(0xFF0F1F3D)
                                              .withOpacity(0.8)
                                          : const Color(0xFFEFF6FF),
                                      border: Border.all(
                                          color: const Color(0xFF1E3A8A)
                                              .withOpacity(0.3),
                                          width: 1),
                                    ),
                                  ),
                                  Container(
                                    width: 78,
                                    height: 78,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1E3A8A),
                                          Color(0xFF3B5FD4)
                                        ],
                                      ),
                                    ),
                                    child: const Icon(Icons.qr_code_2_rounded,
                                        size: 38, color: Colors.white),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Title
                          Text(
                            'Scan Safely.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              letterSpacing: -1.2,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Stay Protected.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF60A5FA),
                              letterSpacing: -1.2,
                              height: 1.15,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Instantly check any QR code for phishing,\nmalware, and hidden threats.',
                            style: TextStyle(
                                fontSize: 15, color: subTextColor, height: 1.65),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Scan button with shimmer — PRIMARY action
                          AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.5),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final scannedValue =
                                                await Navigator.push<String?>(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const QrCodeScanner()),
                                            );
                                            if (scannedValue != null &&
                                                context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ScanResultScreen(
                                                          url: scannedValue),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1E3A8A),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons.qr_code_scanner_rounded,
                                                  size: 22),
                                              SizedBox(width: 10),
                                              Text('Scan QR Code',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Shimmer
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Transform.translate(
                                            offset: Offset(
                                                (_shimmerController.value * 2 -
                                                        0.5) *
                                                    400,
                                                0),
                                            child: Container(
                                              width: 80,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0),
                                                    Colors.white
                                                        .withOpacity(0.08),
                                                    Colors.white.withOpacity(0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // OR divider
                          Row(children: [
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: TextStyle(
                                      fontSize: 13, color: subTextColor)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12)),
                          ]),

                          const SizedBox(height: 16),

                          // URL paste input — SECONDARY action
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cardBorder),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.link_rounded,
                                    color: isDark
                                        ? Colors.white30
                                        : const Color(0xFF94A3B8),
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _urlController,
                                    onSubmitted: (_) => _submitUrl(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Paste a URL to check...',
                                      hintStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white30
                                            : const Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_urlHasText)
                                  GestureDetector(
                                    onTap: _submitUrl,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A8A),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text('Check',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Clickable info cards
                          Row(children: [
                            Expanded(
                              child: _GlassCard(
                                icon: Icons.phishing_rounded,
                                title: 'Phishing',
                                subtitle: 'Link checks',
                                isDark: isDark,
                                onTap: () => _showCardInfo(
                                  'Phishing Detection',
                                  'Phishing attacks trick you into visiting fake websites that steal your passwords, credit card numbers, or personal data. SafeScan checks every URL against known phishing databases before you visit.',
                                  Icons.phishing_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GlassCard(
                                icon: Icons.bug_report_rounded,
                                title: 'Malware',
                                subtitle: 'URL scanning',
                                isDark: isDark,
                                onTap: () => _showCardInfo(
                                  'Malware Scanning',
                                  'Malicious QR codes can lead to sites that automatically download harmful software onto your device. SafeScan detects and blocks known malware-distributing URLs instantly.',
                                  Icons.bug_report_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GlassCard(
                                icon: Icons.gpp_bad_rounded,
                                title: 'Threats',
                                subtitle: 'Real-time',
                                isDark: isDark,
                                onTap: () => _showCardInfo(
                                  'Real-time Threats',
                                  'New threats emerge every day. SafeScan uses Google\'s Safe Browsing API — updated in real-time — to catch the latest malicious URLs, even ones created in the last few hours.',
                                  Icons.gpp_bad_rounded,
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Powered by Google Safe Browsing',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.25)
                              : Colors.black26),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _GlassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.07)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF1E3A8A).withOpacity(isDark ? 0.5 : 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF93C5FD)),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              )),
          const SizedBox(height: 3),
          Text(subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('tap to learn ›',
              style: TextStyle(
                fontSize: 9,
                color: isDark
                    ? const Color(0xFF60A5FA).withOpacity(0.6)
                    : const Color(0xFF60A5FA),
              )),
        ]),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isDark;
  _ParticlePainter(this.particles, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = isDark
            ? const Color(0xFF60A5FA).withOpacity(p.opacity * 0.6)
            : const Color(0xFF1E3A8A).withOpacity(p.opacity * 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
