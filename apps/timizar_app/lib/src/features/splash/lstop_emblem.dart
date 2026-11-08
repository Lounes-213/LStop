import 'package:flutter/material.dart';

class LStopEmblem extends StatelessWidget {
  final double size;
  final bool isDark;

  const LStopEmblem({
    super.key,
    this.size = 52,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.60, size * 0.60),
          painter: _LStopLetterSPainter(isDark: isDark),
        ),
      ),
    );
  }
}

/// Custom vector drawing: A road curve forming the letter 'S' with an embedded position pin icon
class _LStopLetterSPainter extends CustomPainter {
  final bool isDark;

  const _LStopLetterSPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Stylized Road forming the letter 'S'
    final sPaint = Paint()
      ..color = const Color(0xFF2563EB) // Brand Blue
      ..strokeWidth = w * 0.13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final sPath = Path();
    // Top right hook of the S
    sPath.moveTo(w * 0.74, h * 0.22);
    // Upper arc to the left
    sPath.cubicTo(
      w * 0.74,
      h * 0.08,
      w * 0.22,
      h * 0.08,
      w * 0.22,
      h * 0.35,
    );
    // Center diagonal stroke of the S
    sPath.cubicTo(
      w * 0.22,
      h * 0.55,
      w * 0.78,
      h * 0.48,
      w * 0.78,
      h * 0.68,
    );
    // Lower arc to the bottom left and finish
    sPath.cubicTo(
      w * 0.78,
      h * 0.92,
      w * 0.22,
      h * 0.92,
      w * 0.22,
      h * 0.78,
    );

    canvas.drawPath(sPath, sPaint);

    // 2. Position Pin Icon on the top right (replacing the green dot)
    final pinCenter = Offset(w * 0.74, h * 0.22);
    final pinRadius = w * 0.14;

    final pinPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Pin teardrop body
    final pinPath = Path();
    pinPath.addArc(
      Rect.fromCircle(center: pinCenter.translate(0, -pinRadius * 0.3), radius: pinRadius * 0.8),
      3.14 * 0.75,
      3.14 * 1.5,
    );
    pinPath.lineTo(pinCenter.dx, pinCenter.dy + pinRadius * 0.7);
    pinPath.close();

    canvas.drawPath(pinPath, pinPaint);

    // Pin Inner White Center Hole
    final pinHolePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pinCenter.translate(0, -pinRadius * 0.3), pinRadius * 0.32, pinHolePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
