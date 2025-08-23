# Amplitude Experiment Flutter SDK

A Flutter SDK for Amplitude Experiment - Feature flagging and A/B testing for Flutter applications.

## Features

- 🚀 **Cross-platform Support**: iOS, Android, and Web
- 🔄 **Remote Evaluation**: Fetch variants from Amplitude servers
- 💾 **Local Storage**: Persist variants across app sessions
- 🔁 **Automatic Retries**: Built-in exponential backoff for network requests
- 👤 **User Context**: Set user properties for targeted experiments
- 📦 **Singleton Pattern**: Easy integration with single client instance

## Installation

### Option 1: Local Path Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  amplitude_experiment:
    path: ../path/to/Amp-experiment/Flutter/amplitude_experiment
```

### Option 2: Git Dependency

```yaml
dependencies:
  amplitude_experiment:
    git:
      url: https://your-git-repository.git
      path: Flutter/amplitude_experiment  # Path to Flutter SDK in the repo
      ref: main  # or specific branch/tag
```

Then run:
```bash
flutter pub get
```

## Quick Start

### 1. Initialize the Client

```dart
import 'package:amplitude_experiment/amplitude_experiment.dart';

void main() {
  // Initialize the Experiment client
  final client = Experiment.initialize(
    'YOUR_API_KEY',
    config: const ExperimentConfig(
      debug: true,
      fetchOnStart: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Set User Context

```dart
// Set user properties for targeted experiments
client.setUser(
  const ExperimentUser(
    userId: 'user_123',
    deviceId: 'device_456',
    userProperties: {
      'plan': 'premium',
      'accountAge': 30,
    },
  ),
);
```

### 3. Start the Client

```dart
// Start the client and fetch initial variants
await client.start();
```

### 4. Fetch and Use Variants

```dart
// Fetch latest variants
final variants = await client.fetch();

// Get a specific variant
final buttonColor = client.variant(
  'button_color',
  fallback: const Variant(value: 'blue'),
);

// Use the variant value
print('Button color: ${buttonColor.value}');
```

## Configuration Options

```dart
const ExperimentConfig(
  // Enable debug logging
  debug: true,
  
  // Fetch variants on client start
  fetchOnStart: true,
  
  // Polling interval in milliseconds (0 to disable)
  fetchPollingInterval: 0,
  
  // Server URL (defaults to Amplitude's servers)
  serverUrl: 'https://api.lab.amplitude.com',
  
  // Request timeout in milliseconds
  fetchTimeoutMs: 10000,
  
  // Retry configuration
  retryFetchOnFailure: true,
  retryMaxAttempts: 5,
  retryTimeoutMs: 10000,
  retryMinDelayMs: 500,
  retryMaxDelayMs: 10000,
);
```

## Platform-Specific Setup

### iOS
No additional setup required.

### Android
No additional setup required.

### Web
Ensure CORS is properly configured on your Amplitude deployment if using custom server URLs.

## API Reference

### ExperimentClient

#### `initialize(apiKey, config)`
Creates or returns existing client instance.

#### `setUser(user)`
Sets the user context for variant evaluation.

#### `start()`
Starts the client and optionally fetches initial variants.

#### `fetch()`
Fetches variants from the server.

#### `variant(key, fallback)`
Gets a specific variant by key.

#### `all()`
Returns all stored variants.

#### `clear()`
Clears all stored variants.

#### `dispose()`
Cleans up resources and removes from singleton cache.

### ExperimentUser

```dart
const ExperimentUser({
  String? userId,
  String? deviceId,
  String? country,
  String? region,
  String? dma,
  String? city,
  String? language,
  String? platform,
  String? version,
  String? os,
  String? deviceManufacturer,
  String? deviceBrand,
  String? deviceModel,
  String? carrier,
  String? library,
  Map<String, dynamic>? userProperties,
  Map<String, dynamic>? groups,
  Map<String, Map<String, dynamic>>? groupProperties,
});
```

### Variant

```dart
const Variant({
  String? key,
  String? value,
  dynamic payload,
  String? expKey,
  Map<String, dynamic>? metadata,
});
```

## Example Application

See the `/example` folder for a complete Flutter application demonstrating:

- Client initialization
- User context setup
- Variant fetching
- Error handling
- UI integration

Run the example:

```bash
cd example
flutter run
```

## Testing

```bash
flutter test
```

## Internal Development

This SDK is for internal commercial use only. For questions or support, contact your internal development team.

## Version

Current version: 1.0.0

See [CHANGELOG.md](CHANGELOG.md) for release history.