import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'lstop_emblem.dart';

class SplashScreen extends StatefulWidget {
  final String nextRoute;

  const SplashScreen({
    super.key,
    this.nextRoute = '/',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _entranceController.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      context.go(widget.nextRoute);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom Emblem with S-curve & position pin
                const LStopEmblem(size: 88),
                const SizedBox(height: 24),
                // App Name in refined modern geometric Grotesk styling
                const Text(
                  'LSTOP',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: 4.0, // Stylized spacing
                  ),
                ),
                const SizedBox(height: 20),
                // 3 Smooth Animated Dots
                _buildAnimatedThreeDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedThreeDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        final val = _dotsController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Wave delay offset
            final offset = (val - (index * 0.22)) % 1.0;
            final scale = 0.7 + (0.5 * (1.0 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0));
            final opacity = 0.3 + (0.7 * (1.0 - (offset - 0.5).abs() * 2).clamp(0.0, 1.0));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
