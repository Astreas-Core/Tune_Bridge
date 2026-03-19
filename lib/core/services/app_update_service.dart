import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tune_bridge/core/constants.dart';

class UpdateCheckResult {
  final bool configured;
  final bool hasUpdate;
  final String? latestVersion;
  final String? releasePageUrl;
  final String? apkUrl;
  final String message;

  const UpdateCheckResult({
    required this.configured,
    required this.hasUpdate,
    required this.message,
    this.latestVersion,
    this.releasePageUrl,
    this.apkUrl,
  });
}

class AppUpdateService {
  final http.Client _client;

  AppUpdateService({http.Client? client}) : _client = client ?? http.Client();

  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    if (!_isConfigured()) {
      return const UpdateCheckResult(
        configured: false,
        hasUpdate: false,
        message:
            'Update checker is not configured. Set githubOwner/githubRepo in AppConstants.',
      );
    }

    try {
      final response = await _client.get(
        Uri.parse(AppConstants.githubLatestReleaseApi),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode == 404) {
        return const UpdateCheckResult(
          configured: true,
          hasUpdate: false,
          message:
              'No published GitHub release found yet. Create a public release with an APK asset.',
        );
      }

      if (response.statusCode != 200) {
        return UpdateCheckResult(
          configured: true,
          hasUpdate: false,
          message: 'Could not check updates (GitHub HTTP ${response.statusCode}).',
        );
      }

      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (map['tag_name'] ?? '').toString().trim();
      final latestVersion = _normalizeVersion(tag);
      if (latestVersion.isEmpty) {
        return const UpdateCheckResult(
          configured: true,
          hasUpdate: false,
          message: 'Latest release tag is missing or invalid.',
        );
      }

      final current = _normalizeVersion(currentVersion);
      final hasUpdate = _compareVersions(latestVersion, current) > 0;

      final releasePageUrl = (map['html_url'] ?? '').toString();
      final assets = (map['assets'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      final apkAsset = assets.firstWhere(
        (asset) =>
            (asset['name'] ?? '').toString().toLowerCase().endsWith('.apk'),
        orElse: () => <String, dynamic>{},
      );
      final apkUrl = (apkAsset['browser_download_url'] ?? '').toString();

      return UpdateCheckResult(
        configured: true,
        hasUpdate: hasUpdate,
        latestVersion: latestVersion,
        releasePageUrl: releasePageUrl.isEmpty ? null : releasePageUrl,
        apkUrl: apkUrl.isEmpty ? null : apkUrl,
        message: hasUpdate
            ? 'Update available: v$latestVersion'
            : 'You are on the latest version.',
      );
    } catch (_) {
      return const UpdateCheckResult(
        configured: true,
        hasUpdate: false,
        message: 'Could not check updates right now. Try again later.',
      );
    }
  }

  bool _isConfigured() {
    return AppConstants.githubOwner != 'YOUR_GITHUB_USERNAME' &&
        AppConstants.githubOwner.isNotEmpty &&
        AppConstants.githubRepo.isNotEmpty;
  }

  String _normalizeVersion(String input) {
    var value = input.trim().toLowerCase();
    if (value.startsWith('v')) {
      value = value.substring(1);
    }
    final buildSeparator = value.indexOf('+');
    if (buildSeparator != -1) {
      value = value.substring(0, buildSeparator);
    }
    return value;
  }

  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final bParts = b.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final maxLen = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < maxLen; i++) {
      final left = i < aParts.length ? aParts[i] : 0;
      final right = i < bParts.length ? bParts[i] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }

    return 0;
  }
}
