import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/neumorphic.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/settings/ui/equalizer_screen.dart';

/// Neumorphic settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch relevant providers if needed, or just build
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Neumorphic.background,
      appBar: AppBar(
        backgroundColor: Neumorphic.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Neumorphic.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SETTINGS',
            style: GoogleFonts.splineSans(
                color: Neumorphic.textDark,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Dark Mode Toggle
          _NeuSettingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: 'Dark Mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch(
              value: isDark,
              activeColor: Neumorphic.accent,
              onChanged: (val) {
                context.read<ThemeCubit>().toggleTheme(val);
              },
            ),
            onTap: () => context.read<ThemeCubit>().toggleTheme(!isDark),
          ),
          const SizedBox(height: 16),
          
          _NeuSettingsTile(
             icon: Icons.graphic_eq_rounded,
             title: 'Audio Quality',
             subtitle: 'High (320kbps)',
             onTap: () {
               // TODO: Audio Quality Settings
             },
          ),
          const SizedBox(height: 16),

          _NeuSettingsTile(
             icon: Icons.equalizer_rounded,
             title: 'Equalizer',
             subtitle: 'Customize sound',
             onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EqualizerScreen()));
             },
          ),
          const SizedBox(height: 16),

          _NeuSettingsTile(
             icon: Icons.color_lens_rounded,
             title: 'Accent Color',
             subtitle: 'Change app theme',
             onTap: () => _showColorPicker(context),
          ),
          const SizedBox(height: 16),

          _NeuSettingsTile(
             icon: Icons.sd_storage_rounded,
             title: 'Storage',
             subtitle: 'Manage downloads & cache',
             onTap: () {
               // TODO: Storage Settings
             },
          ),
          const SizedBox(height: 16),

          _NeuSettingsTile(
             icon: Icons.info_outline_rounded,
             title: 'About',
             subtitle: 'Version 1.0.0',
             onTap: () {
               showAboutDialog(
                 context: context, 
                 applicationName: 'TuneBridge',
                 applicationVersion: '1.0.0',
                 applicationIcon: Icon(Icons.graphic_eq, color: Neumorphic.accent, size: 40)
               );
             },
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFFD9E8A1), // Default Lime
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFBA68C8), // Purple
      const Color(0xFFFFB74D), // Orange
      const Color(0xFFE57373), // Red
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFF81C784), // Green 
      const Color(0xFFFFD54F), // Yellow
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Neumorphic.background,
          title: Text('Select Accent Color', style: GoogleFonts.splineSans(color: Neumorphic.textDark, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    context.read<ThemeCubit>().setAccentColor(color);
                    Navigator.pop(dialogContext); // Close picker
                    
                    showDialog(
                      context: context,
                      builder: (restoreContext) => AlertDialog(
                        backgroundColor: Neumorphic.background,
                        title: Text('Restart Required', style: GoogleFonts.splineSans(color: Neumorphic.textDark, fontWeight: FontWeight.bold)),
                        content: Text(
                          'Please restart the app to apply the new accent color fully.',
                          style: GoogleFonts.splineSans(color: Neumorphic.textDark),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(restoreContext),
                            child: Text('OK', style: TextStyle(color: Neumorphic.accent)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Neumorphic.shadowDark.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                      border: Border.all(
                         color: Neumorphic.accent == color ? Neumorphic.textDark : Colors.transparent,
                         width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}


class _NeuSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _NeuSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: Neumorphic.raised(
          radius: 12,
          blurRadius: 8,
          offset: const Offset(3, 3),
        ),
        child: Row(
          children: [
            Icon(icon, color: Neumorphic.textMedium, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.splineSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Neumorphic.textDark,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.splineSans(
                        fontSize: 12,
                        color: Neumorphic.textLight,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
