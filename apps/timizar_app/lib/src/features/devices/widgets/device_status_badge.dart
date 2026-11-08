import 'package:flutter/material.dart';
import '../connected_device_model.dart';

class DeviceStatusBadge extends StatefulWidget {
  final DeviceStatus status;
  final bool compact;

  const DeviceStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  State<DeviceStatusBadge> createState() => _DeviceStatusBadgeState();
}

class _DeviceStatusBadgeState extends State<DeviceStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.status) {
        DeviceStatus.online => const Color(0xFF0D9488), // Refined Emerald-Teal
        DeviceStatus.onTrip => const Color(0xFF2563EB), // Dynamic Blue
        DeviceStatus.standby => const Color(0xFFD97706), // Warm Amber
        DeviceStatus.offline => const Color(0xFF94A3B8), // Slate
      };

  Color get _bgTint => switch (widget.status) {
        DeviceStatus.online => const Color(0xFFF0FDFA),
        DeviceStatus.onTrip => const Color(0xFFEFF6FF),
        DeviceStatus.standby => const Color(0xFFFFFBEB),
        DeviceStatus.offline => const Color(0xFFF8FAFC),
      };

  @override
  Widget build(BuildContext context) {
    final isLive = widget.status == DeviceStatus.online ||
        widget.status == DeviceStatus.onTrip;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 10,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing Dot
          SizedBox(
            width: 10,
            height: 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLive)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _color.withValues(alpha: _opacityAnimation.value),
                          ),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.status.label,
            style: TextStyle(
              fontSize: widget.compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
