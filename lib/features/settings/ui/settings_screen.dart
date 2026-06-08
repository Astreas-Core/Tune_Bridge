import 'package:tune_bridge/core/theme.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/routes.dart';
import 'package:tune_bridge/core/services/app_update_service.dart';
import 'package:tune_bridge/core/services/audio_player_service.dart';
import 'package:tune_bridge/features/settings/ui/equalizer_screen.dart';
import 'package:tune_bridge/features/auth/ui/login_screen.dart';
import 'package:tune_bridge/core/services/auth_service.dart';
import 'package:tune_bridge/core/theme_cubit.dart';

import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AudioPlayerService _audioService;
  late final AppUpdateService _appUpdateService;
  late int _crossfadeSeconds;
  bool _highQualityAudio = false;
  bool _isCheckingUpdate = false;
  bool _hasUpdate = false;
  bool _isOffline = false;
  String? _latestVersion;
  String? _downloadUrl;
  String _updateMessage = 'Tap to check for updates';

  final Map<String, Color> _themes = {
    'Classic Green': Color(0xFFD9E8A1),
    'SAREGX Pink': Color(0xFFFF007F),
    'Ocean Blue': Color(0xFF00D2FF),
    'Deep Purple': Color(0xFF9C27B0),
  };

  @override
  void initState() {
    super.initState();
    _audioService = getIt<AudioPlayerService>();
    _appUpdateService = getIt<AppUpdateService>();
    _crossfadeSeconds = _audioService.crossfadeSeconds.clamp(0, 12);
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (!mounted) return;
      setState(() {
        _isOffline = !online;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOffline = true;
      });
    }
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

  void _handleLogout() async {
    await getIt<AuthService>().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
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
                  icon: Icon(Icons.arrow_back_rounded, color: context.primaryColor),
                ),
                Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'ACCOUNT PROFILE',
              child: StreamBuilder(
                stream: getIt<AuthService>().authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  if (user == null) {
                    return _ListTileRow(
                      icon: Icons.account_circle_rounded,
                      title: 'Sign In',
                      subtitle: 'Sync library with SAREGX',
                      trailing: Icon(Icons.login_rounded, color: context.textSecondaryColor),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                    );
                  } else {
                    final initial = (user.displayName ?? user.email ?? '?')[0].toUpperCase();
                    return Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.primaryColor,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? user.email ?? 'User',
                                    style: GoogleFonts.inter(
                                      color: context.textPrimaryColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Authenticated User',
                                    style: GoogleFonts.inter(
                                      color: context.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: _handleLogout,
                            icon: Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                            label: Text(
                              'Log Out',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'GLOBAL PREFERENCES',
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.high_quality_rounded,
                    title: 'High Quality Audio',
                    subtitle: 'Request 256kbps audio streams when available.',
                    value: _highQualityAudio,
                    onChanged: (value) {
                      setState(() {
                        _highQualityAudio = value;
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _ListTileRow(
                    icon: Icons.equalizer_rounded,
                    title: 'Equalizer',
                    subtitle: 'Custom profile',
                    trailing: Icon(Icons.tune_rounded, color: context.textSecondaryColor),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.swap_calls_rounded, color: context.primaryColor),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transition Fade',
                              style: GoogleFonts.inter(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _crossfadeSeconds == 0
                                  ? 'Off'
                                  : '$_crossfadeSeconds sec',
                              style: GoogleFonts.inter(
                                color: context.textSecondaryColor,
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
                      activeTrackColor: context.primaryColor,
                      inactiveTrackColor: Color(0x33FFFFFF),
                      thumbColor: context.primaryColor,
                      overlayColor: context.primaryColor.withOpacity(0.2),
                    ),
                    child: Slider(
                      min: 0,
                      max: 12,
                      divisions: 12,
                      value: _crossfadeSeconds.toDouble(),
                      label: '$_crossfadeSeconds s',
                      onChanged: (value) {
                        setState(() {
                          _crossfadeSeconds = value.round().clamp(0, 12);
                        });
                      },
                      onChangeEnd: (value) {
                        _audioService.setCrossfadeSeconds(value.round().clamp(0, 12));
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'THEME ENGINE',
              child: BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _themes.entries.map((entry) {
                          final isSelected = context.primaryColor == entry.value;
                          return GestureDetector(
                            onTap: () {
                              context.read<ThemeCubit>().setAccentColor(entry.value);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? entry.value : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: entry.value,
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: entry.value.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.inter(
                                      color: isSelected ? Colors.white : context.textSecondaryColor,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),
                      _SwitchRow(
                        icon: Icons.design_services_rounded,
                        title: 'Material 3 UI',
                        subtitle: 'Use native Material 3 design instead of Glassmorphism.',
                        value: themeState.useMaterial3,
                        onChanged: (value) {
                          context.read<ThemeCubit>().toggleMaterial3(value);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.section),
            _HeaderSection(
              title: 'ABOUT & UPDATES',
              child: Column(
                children: [
                  _ListTileRow(
                    icon: _isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    title: _isOffline ? 'Offline' : 'Online',
                    subtitle: _isOffline
                        ? 'Connect to internet for update checks'
                        : 'Network is available',
                    trailing: Icon(
                      _isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                      color: _isOffline
                          ? Color(0xFFFF7A7A)
                          : context.primaryColor,
                    ),
                    onTap: _checkConnectivity,
                  ),
                  _ListTileRow(
                    icon: Icons.system_update_alt_rounded,
                    title: _hasUpdate
                        ? 'Update available${_latestVersion != null ? ' (v$_latestVersion)' : ''}'
                        : 'Check for updates',
                    subtitle: _updateMessage,
                    trailing: _isCheckingUpdate
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _hasUpdate
                                ? Icons.download_rounded
                                : Icons.refresh_rounded,
                            color: context.textSecondaryColor,
                          ),
                    onTap: _isCheckingUpdate
                        ? () {}
                        : _hasUpdate
                            ? _openUpdateLink
                            : _checkForUpdates,
                  ),
                  if (_hasUpdate) ...[
                    SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openUpdateLink,
                        icon: Icon(Icons.open_in_new_rounded),
                        label: Text('Download Update'),
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
        Icon(icon, color: context.primaryColor),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: context.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: context.primaryColor,
          activeTrackColor: context.primaryColor.withOpacity(0.4),
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
            color: context.textSecondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF131313),
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
            Icon(icon, color: context.primaryColor),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: context.textSecondaryColor,
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
