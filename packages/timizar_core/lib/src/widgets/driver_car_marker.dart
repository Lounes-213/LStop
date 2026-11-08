import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DriverCarMarker extends StatelessWidget {
  final double heading; // 0 to 360 degrees
  final bool isAvailable;
  final double size;

  const DriverCarMarker({
    super.key,
    this.heading = 0.0,
    this.isAvailable = true,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * (math.pi / 180),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isAvailable ? AppColors.surfaceLight : const Color(0xFF94A3B8),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isAvailable ? AppColors.primary : const Color(0xFF64748B),
            width: 2.0,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.navigation_rounded,
            color: isAvailable ? AppColors.primary : Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}

