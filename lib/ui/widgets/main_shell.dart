import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tune_bridge/core/constants.dart';
import 'package:tune_bridge/core/di.dart';
import 'package:tune_bridge/core/services/app_update_service.dart';
import 'package:tune_bridge/core/theme_cubit.dart';
import 'package:tune_bridge/features/home/ui/home_screen.dart';
import 'package:tune_bridge/features/library/ui/library_screen.dart';
import 'package:tune_bridge/features/search/ui/search_screen.dart';
import 'package:tune_bridge/ui/widgets/glassmorphism.dart';
import 'package:tune_bridge/ui/widgets/mini_player.dart';
import 'package:url_launcher/url_launcher.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _lastUpdateCheckAtMsKey = 'last_update_check_at_ms';
  static const _dismissedUpdateVersionKey = 'dismissed_update_version';

  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late final AppUpdateService _updateService;
  bool _showUpdateBanner = false;
  String? _latestVersion;
  String? _downloadUrl;

  @override
  void initState() {
    super.initState();
    _updateService = getIt<AppUpdateService>();
    _runStartupUpdateCheck();
  }

  // Removed _screens list to define in build for reactivity

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
    HapticFeedback.selectionClick();
  }

  Future<void> _runStartupUpdateCheck() async {
    try {
      final settingsBox = Hive.box(AppConstants.settingsBox);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lastMs = settingsBox.get(_lastUpdateCheckAtMsKey, defaultValue: 0) as int;
      const cooldown = Duration(hours: 24);

      if (nowMs - lastMs < cooldown.inMilliseconds) {
        return;
      }

      await settingsBox.put(_lastUpdateCheckAtMsKey, nowMs);

      final packageInfo = await PackageInfo.fromPlatform();
      final result = await _updateService.checkForUpdate(
        currentVersion: packageInfo.version,
      );

      if (!mounted || !result.hasUpdate) {
        return;
      }

      final dismissedVersion =
          (settingsBox.get(_dismissedUpdateVersionKey) ?? '').toString();
      final latestVersion = result.latestVersion ?? '';
      if (latestVersion.isNotEmpty && latestVersion == dismissedVersion) {
        return;
      }

      setState(() {
        _showUpdateBanner = true;
        _latestVersion = result.latestVersion;
        _downloadUrl = result.apkUrl ?? result.releasePageUrl;
      });
    } catch (_) {
      // Silent fail: startup should never be blocked by update checks.
    }
  }

  Future<void> _dismissUpdateBanner() async {
    if (_latestVersion != null && _latestVersion!.isNotEmpty) {
      await Hive.box(AppConstants.settingsBox)
          .put(_dismissedUpdateVersionKey, _latestVersion);
    }
    if (!mounted) return;
    setState(() {
      _showUpdateBanner = false;
    });
  }

  Future<void> _openUpdateLink() async {
    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(_downloadUrl!);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeCubit>();
    final mediaQuery = MediaQuery.of(context);

    const screens = [
      HomeScreen(),
      SearchScreen(showBackButton: false),
      LibraryScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _onItemTapped(0);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: GlassColors.background,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF040404), Color(0xFF0A0A0D), Color(0xFF040404)],
                ),
              ),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: screens,
              ),
            ),

            if (_showUpdateBanner)
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                top: mediaQuery.padding.top + AppSpacing.sm,
                child: GlassPanel(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  blur: 0,
                  color: const Color(0xDD171717),
                  borderColor: const Color(0x3300FF41),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.system_update_alt_rounded,
                        color: Color(0xFF00FF41),
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _latestVersion == null
                              ? 'Update available'
                              : 'Update available (v$_latestVersion)',
                          style: GoogleFonts.inter(
                            color: GlassColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _dismissUpdateBanner,
                        child: const Text('Later'),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: _openUpdateLink,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 32),
                          backgroundColor: const Color(0xFF00FF41),
                          foregroundColor: const Color(0xFF041105),
                        ),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: 6,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: GlassPanel(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  blur: 0,
                  color: const Color(0xCC171717),
                  borderColor: const Color(0x2200FF41),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    6 + mediaQuery.padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MiniPlayer(
                        embedded: true,
                        margin: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: const Color(0x22FFFFFF),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildNavItem(Icons.home_rounded, 'Home', 0),
                          _buildNavItem(Icons.search_rounded, 'Search', 1),
                          _buildNavItem(Icons.library_music_rounded, 'Library', 2),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF353535)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFEBFFE2) : const Color(0xFFB9CCB2),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  color: isSelected ? const Color(0xFFEBFFE2) : const Color(0xFFB9CCB2),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
