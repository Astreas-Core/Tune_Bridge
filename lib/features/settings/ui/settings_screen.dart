import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/local_library_service.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/settings/ui/equalizer_screen.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;
    final library = getIt<LocalLibraryService>();

    return Scaffold(
      backgroundColor: GlassColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GlassColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings',
                  style: GoogleFonts.splineSans(
                    color: GlassColors.textPrimary,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassPanel(
              blur: 10,
              borderRadius: BorderRadius.circular(20),
              color: const Color(0x44121A24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _InfoChip(label: 'Liked', value: '${library.likedCount}'),
                  const SizedBox(width: 10),
                  _InfoChip(label: 'Playlists', value: '${library.playlistCount}'),
                  const SizedBox(width: 10),
                  _InfoChip(label: 'Offline', value: '${library.offlineCount}'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _GlassSettingsTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              title: 'Dark Mode',
              subtitle: isDark ? 'Enabled' : 'Disabled',
              trailing: Switch.adaptive(
                value: isDark,
                activeThumbColor: GlassColors.accent,
                activeTrackColor: GlassColors.accent.withValues(alpha: 0.35),
                onChanged: (value) => context.read<ThemeCubit>().toggleTheme(value),
              ),
              onTap: () => context.read<ThemeCubit>().toggleTheme(!isDark),
            ),
            const SizedBox(height: 10),
            _GlassSettingsTile(
              icon: Icons.graphic_eq_rounded,
              title: 'Audio Quality',
              subtitle: 'High (320 kbps)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Audio quality settings coming soon')),
                );
              },
            ),
            const SizedBox(height: 10),
            _GlassSettingsTile(
              icon: Icons.equalizer_rounded,
              title: 'Equalizer',
              subtitle: 'Customize your sound profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _GlassSettingsTile(
              icon: Icons.color_lens_rounded,
              title: 'Accent Color',
              subtitle: 'Neon blue, cyan, teal and more',
              onTap: () => _showColorPicker(context),
            ),
            const SizedBox(height: 10),
            _GlassSettingsTile(
              icon: Icons.sd_storage_rounded,
              title: 'Storage',
              subtitle: 'Manage downloads and cache',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Storage controls coming soon')),
                );
              },
            ),
            const SizedBox(height: 10),
            _GlassSettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About TuneBridge',
              subtitle: 'Version 1.0.0',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'TuneBridge',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(
                    Icons.graphic_eq_rounded,
                    color: GlassColors.accent,
                    size: 34,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final List<Color> colors = [
      const Color(0xFF00D7FF),
      const Color(0xFF00B7D4),
      const Color(0xFF00C6B8),
      const Color(0xFF18E0FF),
      const Color(0xFF2DD4BF),
      const Color(0xFF38BDF8),
      const Color(0xFF22D3EE),
      const Color(0xFF06B6D4),
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11141A),
          title: Text(
            'Select Accent Color',
            style: GoogleFonts.splineSans(
              color: GlassColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    context.read<ThemeCubit>().setAccentColor(color);
                    Navigator.pop(dialogContext);

                    showDialog(
                      context: context,
                      builder: (restoreContext) => AlertDialog(
                        backgroundColor: const Color(0xFF11141A),
                        title: Text(
                          'Restart Recommended',
                          style: GoogleFonts.splineSans(
                            color: GlassColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Please restart the app to apply the new accent color fully.',
                          style: GoogleFonts.splineSans(color: GlassColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(restoreContext),
                            child: const Text(
                              'OK',
                              style: TextStyle(color: GlassColors.accent),
                            ),
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x33182330),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.splineSans(
                color: GlassColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.splineSans(
                color: GlassColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _GlassSettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassPanel(
        blur: 10,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x33182330),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Icon(icon, color: GlassColors.accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.splineSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: GlassColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.splineSans(
                        fontSize: 12,
                        color: GlassColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: GlassColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
