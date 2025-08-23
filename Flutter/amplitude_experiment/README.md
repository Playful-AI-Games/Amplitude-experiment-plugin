# Amplitude Experiment Flutter SDK

Flutter SDK for Amplitude Experiment - Feature flagging and A/B testing for Flutter applications.

## Features

- 🚀 Easy integration with Flutter projects
- 📱 Cross-platform support (iOS & Android)
- 💾 Local storage for offline support
- 🔄 Automatic retry with exponential backoff
- 📊 Analytics integration support
- 🎯 User targeting and segmentation
- ⚡ Local and remote evaluation modes

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  amplitude_experiment: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:amplitude_experiment/amplitude_experiment.dart';

// Initialize the client
final client = Experiment.initialize(
  'YOUR_API_KEY',
  config: const ExperimentConfig(
    debug: true,
    fetchOnStart: true,
  ),
);

// Set user context
client.setUser(
  const ExperimentUser(
    userId: 'user123',
    deviceId: 'device456',
    userProperties: {
      'plan': 'premium',
      'accountAge': 30,
    },
  ),
);

// Start the client
await client.start();

// Fetch variants
await client.fetch();

// Get a variant
final variant = client.variant(
  'feature_flag_key',
  fallback: const Variant(value: 'default'),
);

print('Variant value: ${variant.value}');
```

## Configuration

The SDK can be configured with various options:

```dart
const config = ExperimentConfig(
  // Enable debug logging
  debug: true,
  
  // Instance name for multiple clients
  instanceName: 'my_instance',
  
  // Fallback variant for all calls
  fallbackVariant: Variant(value: 'default'),
  
  // Initial variants for bootstrapping
  initialVariants: {'key': Variant(value: 'initial')},
  
  // Data source configuration
  source: Source.localStorageAndServer,
  
  // Server configuration
  serverUrl: 'https://api.lab.amplitude.com',
  serverZone: 'US', // or 'EU'
  
  // Fetch configuration
  fetchTimeoutMillis: 10000,
  retryFetchOnFailure: true,
  fetchOnStart: true,
  
  // Exposure tracking
  automaticExposureTracking: true,
);
```

## User Properties

Set user properties for targeting:

```dart
client.setUser(
  ExperimentUser(
    userId: 'user123',
    deviceId: 'device456',
    
    // Location properties
    country: 'US',
    city: 'San Francisco',
    region: 'CA',
    
    // Device properties
    platform: 'iOS',
    os: '15.0',
    deviceModel: 'iPhone 13',
    
    // Custom properties
    userProperties: {
      'subscription': 'premium',
      'signupDate': '2023-01-01',
      'totalSpent': 99.99,
    },
    
    // Group properties for B2B
    groups: {
      'company': ['amplitude'],
      'team': ['engineering', 'mobile'],
    },
  ),
);
```

## Fetching Variants

```dart
// Fetch all variants
final variants = await client.fetch();

// Fetch with options
final variants = await client.fetch(
  options: FetchOptions(
    flagKeys: ['flag1', 'flag2'], // Fetch specific flags only
    timeout: Duration(seconds: 5),
  ),
);

// Get all current variants
final allVariants = client.all();
```

## Getting Variants

```dart
// Get a single variant
final variant = client.variant('button_color');

// With fallback
final variant = client.variant(
  'button_color',
  fallback: const Variant(value: 'blue'),
);

// Check variant value
if (variant.value == 'red') {
  // Show red button
} else {
  // Show default button
}

// Access payload data
final config = variant.payload as Map<String, dynamic>?;
```

## Storage and Persistence

Variants are automatically persisted to local storage:

```dart
// Clear all stored variants
await client.clear();

// Variants are automatically loaded on start()
await client.start(); // Loads from storage
```

## Exposure Tracking

Track when users are exposed to experiments:

```dart
// Automatic tracking (enabled by default)
final variant = client.variant('feature_flag'); // Automatically tracks exposure

// Custom exposure tracking provider
class MyExposureTracker implements ExposureTrackingProvider {
  @override
  void track(Exposure exposure) {
    // Send to your analytics service
    analytics.track('Experiment Exposure', {
      'flag': exposure.flagKey,
      'variant': exposure.variant,
      'experiment': exposure.experimentKey,
    });
  }
}

// Use custom tracker
final client = Experiment.initialize(
  'API_KEY',
  config: ExperimentConfig(
    exposureTrackingProvider: MyExposureTracker(),
  ),
);
```

## Multiple Instances

You can create multiple client instances:

```dart
// Main instance
final mainClient = Experiment.initialize(
  'MAIN_API_KEY',
  config: const ExperimentConfig(
    instanceName: 'main',
  ),
);

// Test instance
final testClient = Experiment.initialize(
  'TEST_API_KEY',
  config: const ExperimentConfig(
    instanceName: 'test',
  ),
);
```

## Error Handling

```dart
try {
  await client.fetch();
} on FetchTimeoutException catch (e) {
  print('Request timed out: $e');
} on FetchException catch (e) {
  print('Fetch failed: $e');
}

// Or configure to throw errors
final client = Experiment.initialize(
  'API_KEY',
  config: const ExperimentConfig(
    throwOnError: true, // Throw errors instead of silent handling
  ),
);
```

## Example App

See the `example` folder for a complete Flutter app demonstrating the SDK usage.

## API Reference

### ExperimentClient

- `start()` - Initialize and start the client
- `stop()` - Stop the client and clean up
- `fetch()` - Fetch variants from the server
- `variant(key, [fallback])` - Get a variant by key
- `all()` - Get all current variants
- `clear()` - Clear stored variants
- `setUser(user)` - Set the current user
- `dispose()` - Dispose of resources

### ExperimentConfig

- `debug` - Enable debug logging
- `instanceName` - Instance identifier
- `source` - Data source configuration
- `serverUrl` - API server URL
- `serverZone` - Server zone (US/EU)
- `fetchTimeoutMillis` - Request timeout
- `retryFetchOnFailure` - Enable retry on failure
- `automaticExposureTracking` - Auto-track exposures

## Support

For issues and questions, please visit:
- [GitHub Issues](https://github.com/amplitude/experiment-flutter-client/issues)
- [Amplitude Documentation](https://docs.amplitude.com/experiment)

## License

MIT License - see LICENSE file for details