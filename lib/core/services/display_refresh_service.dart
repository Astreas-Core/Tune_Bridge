import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tune_bridge/core/constants.dart';

class DisplayRefreshService {
  static const String _forceMaxRefreshRateKey = 'force_max_refresh_rate';
  static const MethodChannel _channel = MethodChannel('com.tunebridge/display_refresh');

  late final Box _settingsBox;

  DisplayRefreshService() {
    _settingsBox = Hive.box(AppConstants.settingsBox);
  }

  bool get isForceMaxRefreshRateEnabled {
    return _settingsBox.get(_forceMaxRefreshRateKey, defaultValue: false) == true;
  }

  Future<void> applySavedPreference() async {
    await setForceMaxRefreshRate(
      isForceMaxRefreshRateEnabled,
      persist: false,
    );
  }

  Future<void> setForceMaxRefreshRate(bool enabled, {bool persist = true}) async {
    if (persist) {
      await _settingsBox.put(_forceMaxRefreshRateKey, enabled);
    }

    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('setForceMaxRefreshRate', {
        'enabled': enabled,
      });
    } catch (_) {
      // Ignore unsupported devices/ROMs and keep preference persisted.
    }
  }
}
