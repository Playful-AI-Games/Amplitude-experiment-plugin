// Web-specific implementation for Amplitude Experiment
// This file is kept for plugin registration but the actual SDK
// works cross-platform without platform-specific code

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation placeholder for the AmplitudeExperiment plugin.
class AmplitudeExperimentWeb {
  /// Constructs a AmplitudeExperimentWeb
  AmplitudeExperimentWeb();

  /// Registers the web plugin
  static void registerWith(Registrar registrar) {
    // No-op - the SDK works cross-platform without platform channels
    // This is just for Flutter plugin system registration
  }
}