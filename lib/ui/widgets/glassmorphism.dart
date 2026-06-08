import 'package:tune_bridge/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:tune_bridge/core/constants.dart';



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
        ? (isLight ? Color(0xCCFFFFFF) : defaultPanelColor)
        : color;
    final resolvedBorder = borderColor == defaultBorderColor
        ? (isLight ? Color(0x19000000) : defaultBorderColor)
        : borderColor;

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.surfaceColor,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: resolvedColor,
            borderRadius: borderRadius,
            border: Border.all(color: resolvedBorder),
            boxShadow: [
              BoxShadow(
                color: isLight ? Color(0x12000000) : Color(0x66000000),
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
              ? context.primaryColor.withValues(alpha: 0.18)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isActive
                ? context.primaryColor.withValues(alpha: 0.55)
                : Color(0x26FFFFFF),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? context.primaryColor : context.textPrimaryColor,
          size: 23,
        ),
      ),
    );
  }
}
