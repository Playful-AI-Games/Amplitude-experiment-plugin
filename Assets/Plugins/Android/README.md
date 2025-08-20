# Amplitude Experiment Unity Plugin - Android Implementation

## Overview
This Android implementation provides native support for the Amplitude Experiment SDK in Unity applications targeting Android devices.

## Features
- ✅ Full Amplitude Experiment SDK integration
- ✅ Seamless Unity-Android communication via JNI
- ✅ Automatic dependency management
- ✅ ProGuard configuration included
- ✅ Support for both remote and local evaluation
- ✅ Integration with Amplitude Analytics SDK
- ✅ Async variant fetching with callbacks

## Requirements
- Unity 2020.3 or higher
- Android minimum SDK version 21 (Android 5.0)
- Android target SDK version 31+ recommended
- External Dependency Manager for Unity (EDM4U) recommended

## Installation

### 1. Import the Plugin
The Android plugin files are already in place:
- `/Assets/Plugins/Android/AmplitudeExperiment/` - Java bridge classes
- `/Assets/Plugins/Android/Editor/` - Build configuration files

### 2. Configure Dependencies
The plugin uses External Dependency Manager (EDM4U) to manage Android dependencies automatically through `AmplitudeExperimentDependencies.xml`.

If EDM4U is not installed:
1. Download from: https://github.com/googlesamples/unity-jar-resolver
2. Import the `.unitypackage` file
3. Run `Assets > External Dependency Manager > Android Resolver > Resolve`

### 3. Set Up Your Deployment Key
In your Unity script:
```csharp
AmplitudeExperiment.Instance.Initialize("YOUR_DEPLOYMENT_KEY");
```

## Usage

### Basic Implementation
```csharp
using Amplitude.Experiment;
using System.Collections.Generic;

public class MyGameManager : MonoBehaviour
{
    void Start()
    {
        // Initialize
        AmplitudeExperiment.Instance.Initialize("deployment-key");
        
        // Create user
        var user = new ExperimentUser
        {
            userId = "user123",
            deviceId = "device456",
            userProperties = new Dictionary<string, object>
            {
                { "level", 10 },
                { "premium", true }
            }
        };
        
        // Fetch variants
        AmplitudeExperiment.Instance.Fetch(user,
            onSuccess: () => {
                Debug.Log("Variants fetched!");
                CheckFeatureFlags();
            },
            onError: (error) => {
                Debug.LogError($"Fetch failed: {error}");
            }
        );
    }
    
    void CheckFeatureFlags()
    {
        var variant = AmplitudeExperiment.Instance.GetVariant("new-feature");
        if (variant.IsOn())
        {
            // Enable feature
        }
    }
}
```

## Architecture

### Components
1. **AmplitudeExperimentBridge.java** - Core JNI bridge handling SDK operations
2. **AmplitudeExperimentUnityPlugin.java** - Unity-specific wrapper for easy C# integration
3. **AmplitudeExperiment.cs** - C# interface with platform-specific implementations
4. **AmplitudeExperimentAndroidPostProcessor.cs** - Build-time configuration

### Data Flow
1. Unity C# → AndroidJavaClass → Java Plugin
2. Java Plugin → Amplitude SDK → Network Request
3. Response → Callback → Unity GameObject Message → C# Callback

## Build Settings

### AndroidManifest.xml
The post-processor automatically adds required permissions:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### ProGuard
ProGuard rules are automatically included to prevent code obfuscation issues.

### Gradle Configuration
The post-processor ensures:
- minSdkVersion 21+
- Java 8 compatibility
- Multidex enabled
- Maven Central repository added

## Troubleshooting

### Common Issues

1. **"Class not found" errors**
   - Ensure EDM4U has resolved dependencies
   - Check that Java files are in the correct package structure
   - Verify ProGuard rules are applied

2. **Initialization failures**
   - Verify deployment key is correct
   - Check network permissions in AndroidManifest
   - Ensure minimum SDK version is 21+

3. **Callbacks not working**
   - Verify GameObject name matches in Unity
   - Check that callbacks are on the main thread
   - Ensure AmplitudeExperiment instance persists

4. **Build failures**
   - Run Android Resolver: `Assets > External Dependency Manager > Android Resolver > Force Resolve`
   - Clean and rebuild project
   - Check for conflicting dependencies

### Debug Logging
Enable debug mode:
```java
// In AmplitudeExperimentBridge.java
ExperimentConfig config = ExperimentConfig.builder()
    .debug(true)  // Enable debug logging
    .build();
```

## API Reference

### C# Methods
- `Initialize(string deploymentKey, string instanceName = null)` - Initialize SDK
- `Fetch(ExperimentUser user, Action onSuccess, Action<string> onError)` - Fetch variants
- `GetVariant(string flagKey, Variant fallback = null)` - Get variant for flag
- `Clear()` - Clear all cached variants

### Java Bridge Methods
- `initialize(String deploymentKey, String instanceName)` - Initialize native SDK
- `fetch(String userId, String deviceId, String userPropertiesJson)` - Fetch with user data
- `getVariant(String flagKey)` - Get variant as JSON string
- `clear()` - Clear variant cache

## Testing

### Local Testing
1. Use the included `ExampleUsage.cs` script
2. Set your deployment key in the Inspector
3. Run on an Android device or emulator
4. Check logcat for debug output:
   ```bash
   adb logcat -s AmplitudeExperiment:V AmplitudeExpUnity:V
   ```

### Unit Tests
Test the integration using Unity Test Framework with Android build target.

## Performance Considerations
- Fetch operations are async and non-blocking
- Variants are cached locally after fetch
- Network requests timeout after 10 seconds (configurable)
- Minimal impact on app startup time

## Security
- API keys are compiled into the APK (consider using server-side evaluation for sensitive flags)
- ProGuard obfuscates code but preserves necessary classes
- Network requests use HTTPS

## Support
For issues or questions:
- Check Amplitude documentation: https://amplitude.com/docs/sdks/experiment-sdks/experiment-android
- Unity-specific issues: Review this README and example code
- File issues in your project repository

## Version Compatibility
- Amplitude Experiment Android SDK: 1.12.0+
- Amplitude Analytics Android SDK: 1.16.8+ (optional)
- Unity: 2020.3+
- Android: API 21+