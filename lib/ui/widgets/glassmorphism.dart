import 'package:flutter/material.dart';

class GlassColors {
  GlassColors._();

  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF0C0C0E);
  static const Color surfaceRaised = Color(0xFF141419);
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFF9A9AA3);
  static const Color accent = Color(0xFF2AE6C9);
  static const Color accentMuted = Color(0xFF1AB49E);
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
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF101015), Color(0xFF0A0A0D)],
          ),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
          color: isActive
              ? GlassColors.accent.withValues(alpha: 0.18)
              : GlassColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? GlassColors.accent.withValues(alpha: 0.55)
                : const Color(0x26FFFFFF),
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
