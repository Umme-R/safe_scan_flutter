import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _particleController;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  static const _slides = [
    _SlideData(
      icon: Icons.qr_code_2_rounded,
      title: 'Welcome to SafeScan',
      subtitle:
          'Your personal QR code security guard. Never get tricked by a malicious link again.',
    ),
    _SlideData(
      icon: Icons.shield_rounded,
      title: 'Instant Threat Detection',
      subtitle:
          'Every QR code is checked against Google Safe Browsing in real time — phishing, malware, and hidden threats.',
    ),
    _SlideData(
      icon: Icons.history_rounded,
      title: 'Track Your Scans',
      subtitle:
          'Every scan is saved to your history so you can review or share results anytime.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 40; i++) _particles.add(_Particle(_rng));
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {
          for (final p in _particles) p.update();
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    widget.onComplete();
  }

  Widget _buildSlide(_SlideData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0F1F3D).withOpacity(0.8),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B5FD4)],
                  ),
                ),
                child: Icon(data.icon, size: 40, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.55),
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: Stack(
        children: [
          CustomPaint(
            size: Size(size.width, size.height),
            painter: _ParticlePainter(_particles),
          ),
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
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isLast)
                          TextButton(
                            onPressed: _complete,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: _slides.map(_buildSlide).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: i == _currentPage ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? const Color(0xFF60A5FA)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isLast) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _complete();
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isLast ? 'Get Started' : 'Next',
                            key: ValueKey(isLast),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
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

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        Paint()
          ..color = const Color(0xFF60A5FA).withOpacity(p.opacity * 0.6)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
