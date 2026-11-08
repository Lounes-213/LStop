import 'dart:math' as math;
import 'package:flutter/material.dart';

class UserPositionPin extends StatelessWidget {
  final double? heading;

  const UserPositionPin({
    super.key,
    this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: (heading ?? 0) * (math.pi / 180),
        child: CustomPaint(
          size: const Size(54, 54),
          painter: _UserPositionPainter(),
        ),
      ),
    );
  }
}

class _UserPositionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Outer Translucent Radar Halo (Transparent chwiya)
    final outerPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.44, outerPaint);

    // 2. Middle Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, size.width * 0.36, ringPaint);

    // 3. Inner Solid Core (Semi-transparent with white border)
    final corePaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, 12, shadowPaint);
    canvas.drawCircle(center, 12, corePaint);
    canvas.drawCircle(center, 12, borderPaint);

    // 4. Direction Arrow Point
    final path = Path();
    path.moveTo(center.dx, center.dy - 7);
    path.lineTo(center.dx - 4.5, center.dy + 5);
    path.lineTo(center.dx, center.dy + 2.5);
    path.lineTo(center.dx + 4.5, center.dy + 5);
    path.close();

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
