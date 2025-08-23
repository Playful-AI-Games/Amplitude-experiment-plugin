import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'amplitude_experiment_platform_interface.dart';

/// An implementation of [AmplitudeExperimentPlatform] that uses method channels.
class MethodChannelAmplitudeExperiment extends AmplitudeExperimentPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('amplitude_experiment');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
