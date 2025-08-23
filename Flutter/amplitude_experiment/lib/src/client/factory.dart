import 'package:logger/logger.dart';
import '../config/experiment_config.dart';
import 'experiment_client.dart';

/// Global instances for managing singleton clients
final Map<String, ExperimentClient> _instances = {};

/// Initialize a singleton ExperimentClient identified by the configured
/// instance name.
/// 
/// @param apiKey The deployment API Key
/// @param config See ExperimentConfig for config options
ExperimentClient _initialize(
  String apiKey, {
  ExperimentConfig? config,
}) {
  final instanceKey = _getInstanceKey(apiKey, config);
  
  // Return existing instance if already initialized
  if (_instances.containsKey(instanceKey)) {
    return _instances[instanceKey]!;
  }
  
  // Create new instance
  final client = ExperimentClient(
    apiKey,
    config: config,
    logger: Logger(
      level: config?.debug == true ? Level.debug : Level.warning,
    ),
  );
  
  _instances[instanceKey] = client;
  return client;
}

/// Initialize a singleton ExperimentClient which automatically
/// integrates with the installed and initialized instance of the amplitude
/// analytics SDK.
/// 
/// @param apiKey The deployment API Key
/// @param config See ExperimentConfig for config options
ExperimentClient _initializeWithAmplitudeAnalytics(
  String apiKey, {
  ExperimentConfig? config,
}) {
  // TODO: Add Amplitude Analytics integration
  // This will be implemented when we add the integration plugin
  return _initialize(apiKey, config: config);
}

/// Get an existing ExperimentClient instance by API key and config
ExperimentClient? _getInstance(
  String apiKey, {
  ExperimentConfig? config,
}) {
  final instanceKey = _getInstanceKey(apiKey, config);
  return _instances[instanceKey];
}

/// Clear all instances (useful for testing)
void clearAllInstances() {
  for (final client in _instances.values) {
    client.dispose();
  }
  _instances.clear();
}

String _getInstanceKey(String apiKey, ExperimentConfig? config) {
  final instanceName = config?.instanceName ?? DefaultConfig.instanceName;
  return '$instanceName.$apiKey';
}

/// Main entry point for the Amplitude Experiment Flutter SDK
class Experiment {
  /// Initialize a singleton ExperimentClient
  static ExperimentClient initialize(
    String apiKey, {
    ExperimentConfig? config,
  }) =>
      _initialize(apiKey, config: config);
  
  /// Initialize with Amplitude Analytics integration
  static ExperimentClient initializeWithAmplitudeAnalytics(
    String apiKey, {
    ExperimentConfig? config,
  }) =>
      _initializeWithAmplitudeAnalytics(apiKey, config: config);
  
  /// Get an existing instance
  static ExperimentClient? getInstance(
    String apiKey, {
    ExperimentConfig? config,
  }) =>
      _getInstance(apiKey, config: config);
}