import 'dart:async';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class Haptics {
  const Haptics._();

  static Future<void> _safeCall(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Silently ignore platforms without haptic support.
    }
  }

  static Future<void> scanSuccess() async {
    final bool canVibrate = await Vibration.hasVibrator() ?? false;
    final bool hasCustomSupport = await Vibration.hasCustomVibrationsSupport() ?? false;

    if (canVibrate && hasCustomSupport) {
      try {
        await Vibration.vibrate(
          pattern: [0, 40, 40, 80, 30, 120],
          intensities: [64, 180, 120, 200],
        );
        return;
      } catch (_) {
        // Fall through to platform haptics
      }
    }

    await _safeCall(HapticFeedback.heavyImpact);
    await _safeCall(HapticFeedback.vibrate);
    await Future.delayed(const Duration(milliseconds: 55));
    await _safeCall(HapticFeedback.mediumImpact);
    await Future.delayed(const Duration(milliseconds: 45));
    await _safeCall(HapticFeedback.selectionClick);
    await Future.delayed(const Duration(milliseconds: 45));
    await _safeCall(HapticFeedback.vibrate);
    await _safeCall(() => SystemSound.play(SystemSoundType.click));
  }

  static Future<void> navSelection() async {
    final bool canVibrate = await Vibration.hasAmplitudeControl() ?? false;
    if (canVibrate) {
      try {
        await Vibration.vibrate(duration: 28, amplitude: 90);
        return;
      } catch (_) {
        // Continue with standard haptics
      }
    }

    await _safeCall(HapticFeedback.selectionClick);
    await _safeCall(HapticFeedback.mediumImpact);
  }
}
