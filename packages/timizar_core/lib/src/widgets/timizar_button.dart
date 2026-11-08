import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonVariant { primary, secondary, danger, outline }

class TimizarButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final ButtonVariant variant;
  final double? width;
  final double height;

  const TimizarButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.width,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (variant) {
      ButtonVariant.primary => AppColors.primary,
      ButtonVariant.secondary => AppColors.pillBackgroundLight,
      ButtonVariant.danger => AppColors.dangerRed,
      ButtonVariant.outline => Colors.transparent,
    };

    final fgColor = switch (variant) {
      ButtonVariant.primary => Colors.white,
      ButtonVariant.secondary => AppColors.textPrimaryLight,
      ButtonVariant.danger => Colors.white,
      ButtonVariant.outline => AppColors.textPrimaryLight,
    };

    final border = variant == ButtonVariant.outline
        ? Border.all(color: AppColors.cardBorderLight, width: 1.5)
        : null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: onPressed == null ? bgColor.withValues(alpha: 0.5) : bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: border,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
