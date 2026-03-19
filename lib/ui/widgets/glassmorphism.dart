import 'package:flutter/material.dart';
import 'package:tune_bridge/core/constants.dart';

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
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.xl)),
    this.blur = 16,
    this.color = const Color(0x66111722),
    this.borderColor = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    const defaultPanelColor = Color(0x66111722);
    const defaultBorderColor = Color(0x33FFFFFF);
    final resolvedColor = color == defaultPanelColor
        ? (isLight ? const Color(0xCCFFFFFF) : defaultPanelColor)
        : color;
    final resolvedBorder = borderColor == defaultBorderColor
        ? (isLight ? const Color(0x19000000) : defaultBorderColor)
        : borderColor;

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? const [Color(0xFFFDFEFD), Color(0xFFF2F7F4)]
                : const [Color(0xFF101015), Color(0xFF0A0A0D)],
          ),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: resolvedColor,
            borderRadius: borderRadius,
            border: Border.all(color: resolvedBorder),
            boxShadow: [
              BoxShadow(
                color: isLight ? const Color(0x12000000) : const Color(0x66000000),
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isActive
              ? GlassColors.accent.withValues(alpha: 0.18)
              : GlassColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isActive
                ? GlassColors.accent.withValues(alpha: 0.55)
                : const Color(0x26FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? GlassColors.accent : GlassColors.textPrimary,
          size: 23,
        ),
      ),
    );
  }
}
