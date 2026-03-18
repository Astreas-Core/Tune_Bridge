import 'dart:ui';

import 'package:flutter/material.dart';

class GlassColors {
  GlassColors._();

  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF11141A);
  static const Color textPrimary = Color(0xFFEAEAEA);
  static const Color textSecondary = Color(0xFFADB3C2);
  static const Color accent = Color(0xFF00D7FF);
  static const Color accentMuted = Color(0xFF00B7D4);
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color color;
  final Color borderColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 16,
    this.color = const Color(0x66111722),
    this.borderColor = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: panel,
            )
          : panel,
    );
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? GlassColors.accent.withValues(alpha: 0.18) : const Color(0x2219202A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? GlassColors.accent.withValues(alpha: 0.55) : const Color(0x22FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? GlassColors.accent : GlassColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
