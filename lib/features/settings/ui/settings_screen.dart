import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/app_update_service.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/core/services/display_refresh_service.dart';
import 'package:tune_bridge/features/settings/ui/equalizer_screen.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AudioPlayerService _audioService;
  late final DisplayRefreshService _displayRefreshService;
  late final AppUpdateService _appUpdateService;
  late int _crossfadeSeconds;
  late bool _forceMaxRefreshRate;
  bool _isCheckingUpdate = false;
  bool _hasUpdate = false;
  String? _latestVersion;
  String? _downloadUrl;
  String _updateMessage = 'Tap to check for updates';

  @override
  void initState() {
    super.initState();
    _audioService = getIt<AudioPlayerService>();
    _displayRefreshService = getIt<DisplayRefreshService>();
    _appUpdateService = getIt<AppUpdateService>();
    _crossfadeSeconds = _audioService.crossfadeSeconds.clamp(1, 12);
    _forceMaxRefreshRate = _displayRefreshService.isForceMaxRefreshRateEnabled;
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateMessage = 'Checking for updates...';
    });

    final packageInfo = await PackageInfo.fromPlatform();
    final result = await _appUpdateService.checkForUpdate(
      currentVersion: packageInfo.version,
    );

    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
      _hasUpdate = result.hasUpdate;
      _latestVersion = result.latestVersion;
      _downloadUrl = result.apkUrl ?? result.releasePageUrl;
      _updateMessage = result.message;
    });
  }

  Future<void> _openUpdateLink() async {
    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No update link available yet.')),
      );
      return;
    }

    final uri = Uri.tryParse(_downloadUrl!);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 140),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00FF41)),
                ),
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    color: GlassColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'AUDIO',
              child: Column(
                children: [
                  _ListTileRow(
                    icon: Icons.equalizer_rounded,
                    title: 'Equalizer',
                    subtitle: 'Custom profile',
                    trailing: const Icon(Icons.tune_rounded, color: GlassColors.textSecondary),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                    ),
                  ),
                  _ListTileRow(
                    icon: Icons.high_quality_rounded,
                    title: 'Streaming Quality',
                    subtitle: 'Ultra High (320kbps)',
                    trailing: const Icon(Icons.chevron_right_rounded, color: GlassColors.textSecondary),
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(Icons.swap_calls_rounded, color: Color(0xFF00E639)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crossfade',
                              style: GoogleFonts.inter(
                                color: GlassColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$_crossfadeSeconds sec',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFB9CCB2),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00FF41),
                      inactiveTrackColor: const Color(0x33FFFFFF),
                      thumbColor: const Color(0xFF00FF41),
                      overlayColor: const Color(0x4400FF41),
                    ),
                    child: Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: _crossfadeSeconds.toDouble(),
                      label: '$_crossfadeSeconds s',
                      onChanged: (value) {
                        setState(() {
                          _crossfadeSeconds = value.round().clamp(1, 12);
                        });
                      },
                      onChangeEnd: (value) {
                        _audioService.setCrossfadeSeconds(value.round().clamp(1, 12));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'DISPLAY',
              child: _SwitchRow(
                icon: Icons.speed_rounded,
                title: 'Force Max Refresh Rate',
                subtitle: 'Run at highest supported refresh rate (up to 120Hz)',
                value: _forceMaxRefreshRate,
                onChanged: (value) async {
                  setState(() {
                    _forceMaxRefreshRate = value;
                  });
                  await _displayRefreshService.setForceMaxRefreshRate(value);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'UPDATES',
              child: Column(
                children: [
                  _ListTileRow(
                    icon: Icons.system_update_alt_rounded,
                    title: _hasUpdate
                        ? 'Update available${_latestVersion != null ? ' (v$_latestVersion)' : ''}'
                        : 'Check for updates',
                    subtitle: _updateMessage,
                    trailing: _isCheckingUpdate
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _hasUpdate
                                ? Icons.download_rounded
                                : Icons.refresh_rounded,
                            color: GlassColors.textSecondary,
                          ),
                    onTap: _isCheckingUpdate
                        ? () {}
                        : _hasUpdate
                            ? _openUpdateLink
                            : _checkForUpdates,
                  ),
                  if (_hasUpdate) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openUpdateLink,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Download Update'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E639)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: GlassColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFFB9CCB2),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: const Color(0xFF00FF41),
          activeTrackColor: const Color(0x6600FF41),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _HeaderSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFFB9CCB2),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ],
    );
  }
}

class _ListTileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ListTileRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00E639)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: GlassColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFB9CCB2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
