# Amplitude Experiment Flutter SDK - Usage Guide

## Integration in Your Flutter Project

### Step 1: Add Dependency

Choose one of the following methods to add the SDK to your project:

#### Local Path (Recommended for Internal Development)

```yaml
# pubspec.yaml
dependencies:
  amplitude_experiment:
    path: /Users/scritch/Projects/Amp-experiment/Flutter/amplitude_experiment
    # Or relative path: ../Amp-experiment/Flutter/amplitude_experiment
```

#### Git Repository

```yaml
# pubspec.yaml
dependencies:
  amplitude_experiment:
    git:
      url: https://your-internal-git-repository.git
      path: Flutter/amplitude_experiment  # Path to Flutter SDK within the repo
      ref: main  # or specific branch/tag/commit
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:amplitude_experiment/amplitude_experiment.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ExperimentClient _experimentClient;
  
  @override
  void initState() {
    super.initState();
    _initializeExperiment();
  }
  
  Future<void> _initializeExperiment() async {
    // Initialize client
    _experimentClient = Experiment.initialize(
      'YOUR_DEPLOYMENT_KEY',
      config: const ExperimentConfig(
        debug: true,
        fetchOnStart: true,
      ),
    );
    
    // Set user context
    _experimentClient.setUser(
      const ExperimentUser(
        userId: 'user_123',
        userProperties: {
          'premium': true,
          'country': 'US',
        },
      ),
    );
    
    // Start client and fetch variants
    await _experimentClient.start();
  }
  
  @override
  Widget build(BuildContext context) {
    // Get variant for feature flag
    final buttonVariant = _experimentClient.variant(
      'new_button_design',
      fallback: const Variant(value: 'control'),
    );
    
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            // Use variant to control UI
            style: buttonVariant.value == 'variant_a' 
              ? ElevatedButton.styleFrom(backgroundColor: Colors.blue)
              : ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              // Your button action
            },
            child: Text('Click Me'),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _experimentClient.dispose();
    super.dispose();
  }
}
```

## Common Use Cases

### 1. Feature Flags

```dart
// Simple on/off feature flag
final isFeatureEnabled = _experimentClient.variant(
  'new_feature_enabled',
  fallback: const Variant(value: 'false'),
).value == 'true';

if (isFeatureEnabled) {
  // Show new feature
} else {
  // Show old feature
}
```

### 2. A/B Testing

```dart
// Multi-variant testing
final variant = _experimentClient.variant('checkout_flow');

switch (variant.value) {
  case 'variant_a':
    return CheckoutFlowA();
  case 'variant_b':
    return CheckoutFlowB();
  case 'variant_c':
    return CheckoutFlowC();
  default:
    return CheckoutFlowDefault();
}
```

### 3. Configuration Management

```dart
// Use payload for complex configurations
final configVariant = _experimentClient.variant('app_config');
final config = configVariant.payload as Map<String, dynamic>?;

final maxRetries = config?['max_retries'] ?? 3;
final timeout = config?['timeout_ms'] ?? 5000;
final apiEndpoint = config?['api_endpoint'] ?? 'https://api.example.com';
```

### 4. User Segmentation

```dart
// Update user properties for segmentation
void onUserUpgrade() {
  _experimentClient.setUser(
    ExperimentUser(
      userId: currentUserId,
      userProperties: {
        'plan': 'premium',
        'upgrade_date': DateTime.now().toIso8601String(),
      },
    ),
  );
  
  // Fetch new variants based on updated user
  _experimentClient.fetch();
}
```

### 5. Gradual Rollout

```dart
// Percentage-based rollout
final rolloutVariant = _experimentClient.variant(
  'feature_rollout',
  fallback: const Variant(value: 'disabled'),
);

// Server controls the percentage of users who get 'enabled'
if (rolloutVariant.value == 'enabled') {
  enableNewFeature();
}
```

## Best Practices

### 1. Initialize Early

Initialize the Experiment client as early as possible in your app lifecycle:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Experiment before runApp
  final client = Experiment.initialize('YOUR_KEY');
  await client.start();
  
  runApp(MyApp());
}
```

### 2. Handle Loading States

```dart
class FeatureWidget extends StatelessWidget {
  final ExperimentClient client;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Variants>(
      future: client.fetch(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        final variant = client.variant('feature_key');
        return buildFeature(variant);
      },
    );
  }
}
```

### 3. Use Fallbacks

Always provide sensible fallback values:

```dart
// Good - always has a default
final variant = client.variant(
  'feature_key',
  fallback: const Variant(value: 'default'),
);

// Also good - handle null case
final variant = client.variant('feature_key');
final value = variant.value ?? 'default';
```

### 4. Clean Up Resources

```dart
class MyStatefulWidget extends StatefulWidget {
  @override
  void dispose() {
    // Clean up when done
    _experimentClient.dispose();
    super.dispose();
  }
}
```

### 5. Error Handling

```dart
Future<void> fetchVariants() async {
  try {
    await _experimentClient.fetch();
  } catch (e) {
    // Log error but don't crash the app
    print('Failed to fetch variants: $e');
    // Use fallback values
  }
}
```

## Environment Configuration

### Development vs Production

```dart
class ExperimentService {
  static ExperimentClient initialize() {
    final isDev = const bool.fromEnvironment('dart.vm.product') == false;
    
    return Experiment.initialize(
      isDev ? 'DEV_DEPLOYMENT_KEY' : 'PROD_DEPLOYMENT_KEY',
      config: ExperimentConfig(
        debug: isDev,
        serverUrl: isDev 
          ? 'https://api.lab.amplitude.com'
          : 'https://api.amplitude.com',
      ),
    );
  }
}
```

### Using Environment Variables

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  
  final client = Experiment.initialize(
    dotenv.env['AMPLITUDE_DEPLOYMENT_KEY'] ?? '',
    config: ExperimentConfig(
      debug: dotenv.env['DEBUG_MODE'] == 'true',
    ),
  );
  
  runApp(MyApp());
}
```

## Troubleshooting

### Variants Not Fetching

1. Check your deployment key is correct
2. Verify network connectivity
3. Enable debug mode to see logs
4. Check if user context is set properly

```dart
// Enable debug logging
final client = Experiment.initialize(
  'YOUR_KEY',
  config: const ExperimentConfig(debug: true),
);
```

### Variants Not Updating

```dart
// Force refresh variants
await client.fetch();

// Or clear cache and fetch
await client.clear();
await client.fetch();
```

### Platform-Specific Issues

#### Web CORS Issues

If variants aren't fetching on web, check browser console for CORS errors. You may need to configure your Amplitude deployment to allow your domain.

#### Mobile Network Permissions

Ensure your app has internet permissions:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

## Migration from Other SDKs

### From JavaScript SDK

```javascript
// JavaScript
const client = Experiment.initialize('KEY');
await client.fetch();
const variant = client.variant('flag_key');
```

```dart
// Flutter - Very similar API
final client = Experiment.initialize('KEY');
await client.fetch();
final variant = client.variant('flag_key');
```

### Key Differences

1. **Typed Models**: Flutter SDK uses strongly typed models
2. **Async/Await**: All network operations are async
3. **Null Safety**: Dart's null safety ensures safer code
4. **Platform Integration**: Native performance on mobile platforms

## Support

For internal support, contact your development team or refer to the internal documentation portal.