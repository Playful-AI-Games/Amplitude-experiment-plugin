import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'amplitude_experiment_method_channel.dart';

abstract class AmplitudeExperimentPlatform extends PlatformInterface {
  /// Constructs a AmplitudeExperimentPlatform.
  AmplitudeExperimentPlatform() : super(token: _token);

  static final Object _token = Object();

  static AmplitudeExperimentPlatform _instance = MethodChannelAmplitudeExperiment();

  /// The default instance of [AmplitudeExperimentPlatform] to use.
  ///
  /// Defaults to [MethodChannelAmplitudeExperiment].
  static AmplitudeExperimentPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AmplitudeExperimentPlatform] when
  /// they register themselves.
  static set instance(AmplitudeExperimentPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
