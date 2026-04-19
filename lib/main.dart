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
  await dotenv.load(fileName: '.env');
  await HistoryStore.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeScan',
      theme: SafeScanTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

// Floating particle data
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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Offset _mousePosition = const Offset(0.5, 0.5);
  late AnimationController _particleController;
  late AnimationController _pulseController;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(_rng));
    }
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
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
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
            // Particle layer
            CustomPaint(
              size: Size(size.width, size.height),
              painter: _ParticlePainter(_particles),
            ),

            // Mouse-reactive glow orb
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
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF1E3A8A).withOpacity(0.25),
                        const Color(0xFF1E3A8A).withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Static corner glow (top right)
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B5FD4).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Nav bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SafeScan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.history_rounded, color: Colors.white70, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated shield / QR icon
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse ring
                                  Container(
                                    width: 130 + _pulseController.value * 16,
                                    height: 130 + _pulseController.value * 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.2 - _pulseController.value * 0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Middle ring
                                  Container(
                                    width: 105,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF0F1F3D).withOpacity(0.8),
                                      border: Border.all(
                                        color: const Color(0xFF1E3A8A).withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  // Inner icon circle
                                  Container(
                                    width: 78,
                                    height: 78,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF1E3A8A), Color(0xFF3B5FD4)],
                                      ),
                                    ),
                                    // QR-style icon like option 3
                                    child: const Icon(Icons.qr_code_2_rounded, size: 38, color: Colors.white),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Title
                          const Text(
                            'Scan Safely.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
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

                          const SizedBox(height: 16),

                          Text(
                            'Instantly check any QR code for phishing,\nmalware, and hidden threats.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.45),
                              height: 1.65,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 44),

                          // Scan button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E3A8A).withOpacity(0.6),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final scannedValue = await Navigator.push<String?>(
                                    context,
                                    MaterialPageRoute(builder: (_) => const QrCodeScanner()),
                                  );
                                  if (scannedValue != null && context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScanResultScreen(url: scannedValue),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Scan QR Code',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Glassmorphism feature cards
                          Row(
                            children: [
                              Expanded(child: _GlassCard(Icons.phishing_rounded, 'Phishing', 'Link checks')),
                              const SizedBox(width: 12),
                              Expanded(child: _GlassCard(Icons.bug_report_rounded, 'Malware', 'URL scanning')),
                              const SizedBox(width: 12),
                              Expanded(child: _GlassCard(Icons.gpp_bad_rounded, 'Threats', 'Real-time')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      'Powered by Google Safe Browsing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.25),
                      ),
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

// Glassmorphism card
class _GlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _GlassCard(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF93C5FD)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(p.opacity * 0.6)
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