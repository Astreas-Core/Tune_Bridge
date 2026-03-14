import 'package:flutter/material.dart';

/// Neumorphic design system — supports light and dark modes with glow effects.
class Neumorphic {
  Neumorphic._();

  static bool _isDark = false;
  static void setIsDark(bool isDark) {
    _isDark = isDark;
  }

  // ── Light Palette (Stitch Theme) ───────────────────────────
  static Color _lightBg = const Color(0xFFF7F8F6); // Stitch Light Background
  static const Color _lightShadowDark = Color(0xFFD1D2D0); // Stitch Dark Shadow
  static const Color _lightShadowLight = Color(0xFFFFFFFF); // Stitch Light Highlight
  
  // ── Dark Palette (Stitch Theme) ─────────────────────────────
  static Color _darkBg = const Color(0xFF1D1F13); // Stitch Dark Background
  static const Color _darkShadowDark = Color(0xFF15160D); // Darker shade for shadows
  static const Color _darkShadowLight = Color(0xFF2A2D1B); // Lighter shade for highlights

  // ── Accent Palette ──────────────────────────────────────────
  static Color _accent = const Color(0xFFD9E8A1); // Stitch Primary Lime/Green
  static Color _accentLight = const Color(0xFFEAF5C2);

  static Color get accent => _accent;
  static Color get accentLight => _accentLight;

  static void setAccent(Color color) {
    _accent = color;
    // Derive a lighter shade for accentLight
    _accentLight = Color.alphaBlend(Colors.white.withValues(alpha: 0.3), color);

    // Update backgrounds with slight tint
    _lightBg = Color.alphaBlend(color.withValues(alpha: 0.03), const Color(0xFFF7F8F6));
    _darkBg = Color.alphaBlend(color.withValues(alpha: 0.05), const Color(0xFF1D1F13));
  }
  
  // ── Theme Accessors ─────────────────────────────────────────
  static Color get background => _isDark ? _darkBg : _lightBg;
  
  static Color get shadowDark => _isDark ? _darkShadowDark : _lightShadowDark;
  
  static Color get shadowLight => _isDark ? _darkShadowLight : _lightShadowLight;

  // Text colors adapted for Stitch Theme
  static Color get textDark => _isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A); // Slate-900 / Slate-100
  
  static Color get textMedium => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B); // Slate-400 / Slate-500
  
  static Color get textLight => _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  
  static Color get cardBg => _isDark ? _darkBg : _lightBg;
  
  static Color get insetBg => _isDark ? const Color(0xFF181910) : const Color(0xFFF0F1EF); // Slightly darker for inset
  
  static Color get iconColor => _isDark ? const Color(0xFFF1F5F9) : const Color(0xFF475569); // Slate-600
  
  static Color get error => const Color(0xFFFF5252);

  // ── Raised (convex) decoration ──────────────────────────────
  static BoxDecoration raised({
    double radius = 16,
    double blurRadius = 12,
    Offset offset = const Offset(6, 6),
    Color? color,
    bool glow = false,
  }) {
    final baseColor = color ?? (_isDark ? const Color(0xFF262822) : const Color(0xFFFFFFFF));
    
    // If glow is true, replace shadows with accent colored spread
    if (glow && _isDark) {
       // Dark mode glow - White/Bioluminescent effect
       return BoxDecoration(
         color: baseColor,
         borderRadius: BorderRadius.circular(radius),
         boxShadow: [
           BoxShadow(
             color: Colors.white.withValues(alpha: 0.15),
             blurRadius: 15,
             spreadRadius: 1,
           ),
           BoxShadow(
             color: Colors.white.withValues(alpha: 0.05),
             blurRadius: 30,
             spreadRadius: 5,
           ),
         ],
       );       
    } else if (glow && !_isDark) {
       // Light mode glow
       return BoxDecoration(
         color: baseColor,
         borderRadius: BorderRadius.circular(radius),
         boxShadow: [
           BoxShadow(
             color: accent.withValues(alpha: 0.4),
             blurRadius: 12,
             offset: offset,
           ),
           BoxShadow(
             color: Colors.white,
             offset: Offset(-offset.dx, -offset.dy),
             blurRadius: blurRadius,
           ),
         ],
       );
    }

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: _isDark ? 0.9 : 0.6), // Darker processing
          offset: offset,
          blurRadius: blurRadius,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: _isDark ? 0.1 : 0.9), // Lighter highlight
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blurRadius,
        ),
      ],
    );
  }

  // ── Inset (concave/pressed) decoration ──────────────────────
  static BoxDecoration inset({
    double radius = 16,
    double blurRadius = 10,
    Offset offset = const Offset(4, 4),
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? insetBg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        // Inner shadow effect via gradient + shadows
        BoxShadow(
          color: shadowDark.withValues(alpha: _isDark ? 0.8 : 0.6), // Increased shadow
          offset: offset,
          blurRadius: blurRadius,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: _isDark ? 0.05 : 0.9), // Brighter highlight
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blurRadius,
          spreadRadius: -1,
        ),
      ],
    );
  }

  // ── Flat (subtle) decoration ────────────────────────────────
  static BoxDecoration flat({
    double radius = 12,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? background,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // ── Circular raised button decoration ───────────────────────
  static BoxDecoration circleRaised({
    double blurRadius = 10,
    Offset offset = const Offset(4, 4),
    Color? color,
    bool glow = false,
  }) {
    final baseColor = color ?? background;
    
    // Glow logic - Adjusted for user request
    if (glow && _isDark) {
       // Dark Mode: White/Bright Glow
       return BoxDecoration(
         color: baseColor,
         shape: BoxShape.circle,
         boxShadow: [
           BoxShadow(
             color: Colors.white.withValues(alpha: 0.15),
             blurRadius: 20,
             spreadRadius: 2,
           ),
           BoxShadow(
             color: Colors.white.withValues(alpha: 0.05),
             blurRadius: 40,
             spreadRadius: 8,
           ),
           // Keep original shadows for depth
           BoxShadow(
             color: shadowDark.withValues(alpha: 0.8),
             offset: offset,
             blurRadius: blurRadius,
           ),
         ],
       );
    } else if (glow) {
       // Light Mode: Dark/Accent Glow
       return BoxDecoration(
         color: baseColor,
         shape: BoxShape.circle,
         boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3), // Darker accent glow
              offset: offset,
              blurRadius: blurRadius * 1.5,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-offset.dx, -offset.dy),
              blurRadius: blurRadius,
            ),
         ],
       );
    }

    return BoxDecoration(
      color: baseColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: _isDark ? 0.8 : 0.5),
          offset: offset,
          blurRadius: blurRadius,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: _isDark ? 0.2 : 1.0),
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blurRadius,
        ),
      ],
    );
  }

  // ── Circular inset button decoration ────────────────────────
  static BoxDecoration circleInset({
    double blurRadius = 8,
    Offset offset = const Offset(3, 3),
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? insetBg,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: shadowDark.withValues(alpha: _isDark ? 0.6 : 0.4),
          offset: offset,
          blurRadius: blurRadius,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: shadowLight.withValues(alpha: _isDark ? 0.1 : 0.7),
          offset: Offset(-offset.dx, -offset.dy),
          blurRadius: blurRadius,
          spreadRadius: -2,
        ),
      ],
    );
  }
}

/// A neumorphic icon button (raised circle).
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final bool glow;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.size = 56,
    this.iconSize = 24,
    this.iconColor,
    this.onPressed,
    this.glow = false,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: _pressed
            ? Neumorphic.circleInset()
            : Neumorphic.circleRaised(glow: widget.glow),
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor ?? Neumorphic.accent,
          ),
        ),
      ),
    );
  }
}

/// A neumorphic container card.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isInset;
  final Color? color;

  const NeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.isInset = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration: isInset
          ? Neumorphic.inset(radius: borderRadius, color: color)
          : Neumorphic.raised(radius: borderRadius, color: color),
      child: child,
    );
  }
}
