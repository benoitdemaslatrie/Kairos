import 'dart:math' show pi;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class AppFrame extends StatelessWidget {
  final Widget? child;
  const AppFrame({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    if (!kIsWeb) return child!;

    return Container(
      color: const Color(0xFF0D0D1A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: child!,
              ),
              const Positioned.fill(
                child: IgnorePointer(child: _SiriBorder()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SiriBorder extends StatefulWidget {
  const _SiriBorder();

  @override
  State<_SiriBorder> createState() => _SiriBorderState();
}

class _SiriBorderState extends State<_SiriBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(painter: _SiriBorderPainter(_ctrl.value)),
    );
  }
}

class _SiriBorderPainter extends CustomPainter {
  final double t;
  _SiriBorderPainter(this.t);

  static const _colors = [
    Color(0xFF0A84FF), // blue
    Color(0xFF5E5CE6), // indigo
    Color(0xFFBF5AF2), // purple
    Color(0xFFFF375F), // pink
    Color(0xFFFF9F0A), // orange — flash
    Color(0xFF0A84FF), // back to blue
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final angle = 2 * pi * t;

    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * pi,
      colors: _colors,
    );
    final shader = gradient.createShader(rect);

    // Outer glow (wide, soft)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = shader
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Inner glow (tighter)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = shader
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Crisp line
    canvas.drawRect(
      rect,
      Paint()
        ..shader = shader
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_SiriBorderPainter old) => old.t != t;
}
