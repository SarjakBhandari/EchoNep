import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final String? message;

  const SplashScreen({super.key, this.message});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _charFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
  );

  late final Animation<double> _charScale = Tween<double>(
    begin: 0.55,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
  ));

  late final Animation<double> _charSlide = Tween<double>(
    begin: 40.0,
    end: 0.0,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _subtitleFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
  );

  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF062A3A),
              Color(0xFF0A4D6B),
              Color(0xFF0B6E99),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _MountainDecor(),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  _BrandMark(fade: _titleFade),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(0, _charSlide.value),
                          child: Transform.scale(
                            scale: _charScale.value,
                            child: Opacity(
                              opacity: _charFade.value,
                              child: Image.asset(
                                'assets/branding/image.png',
                                height: size.height * 0.52,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) => Opacity(
                      opacity: _titleFade.value,
                      child: Column(
                        children: [
                          Text(
                            'ECHONEP',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 48,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2B705),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) => Opacity(
                      opacity: _subtitleFade.value,
                      child: Text(
                        'Nepali Voice Translator',
                        style: GoogleFonts.manrope(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) => Opacity(
                      opacity: _loaderFade.value,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              color: const Color(0xFFF2B705),
                              minHeight: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.message ?? 'Loading models...',
                            style: GoogleFonts.manrope(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final Animation<double> fade;
  const _BrandMark({required this.fade});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (context, _) => Opacity(
        opacity: fade.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/branding/logo_foreground.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'EchoNep',
              style: GoogleFonts.manrope(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MountainDecor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _MountainPainter()),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF09405A).withValues(alpha: 0.6);
    final path1 = Path()
      ..moveTo(0, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.42)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = const Color(0xFF073347).withValues(alpha: 0.7);
    final path2 = Path()
      ..moveTo(size.width * 0.3, size.height * 0.78)
      ..lineTo(size.width * 0.58, size.height * 0.45)
      ..lineTo(size.width * 0.75, size.height * 0.65)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(path2, paint);

    paint.color = const Color(0xFF062A3A).withValues(alpha: 0.9);
    final path3 = Path()
      ..moveTo(0, size.height * 0.88)
      ..lineTo(size.width * 0.35, size.height * 0.62)
      ..lineTo(size.width * 0.55, size.height * 0.82)
      ..lineTo(size.width * 0.72, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
