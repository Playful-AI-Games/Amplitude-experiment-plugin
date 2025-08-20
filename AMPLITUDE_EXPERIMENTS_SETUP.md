# Amplitude Experiments iOS SDK Unity Integration

## Overview
This integration allows you to use Amplitude Experiments SDK in your Unity iOS builds through a native bridge implementation.

## Prerequisites
1. Unity 2019.4 or later
2. iOS deployment target 12.0 or higher
3. External Dependency Manager for Unity (EDM4U) - Install from: https://github.com/googlesamples/unity-jar-resolver

## Setup Instructions

### 1. Install External Dependency Manager for Unity (EDM4U)
- Download the latest .unitypackage from the EDM4U releases page
- Import it into your Unity project via Assets → Import Package

### 2. Configure Unity Build Settings
- Switch platform to iOS (File → Build Settings → iOS → Switch Platform)
- Player Settings:
  - Set Minimum iOS Version to 12.0
  - Set Architecture to ARM64
  - Ensure Scripting Backend is set to IL2CPP

### 3. Get Your Deployment Key
- Log into your Amplitude Experiment account
- Navigate to your project settings
- Copy your Deployment Key (also called API Key)

### 4. Initialize the SDK
```csharp
using Amplitude.Experiment;

// Initialize on app start
AmplitudeExperiment.Instance.Initialize("YOUR_DEPLOYMENT_KEY");

// Create user
var user = new ExperimentUser 
{
    userId = "user123",
    deviceId = SystemInfo.deviceUniqueIdentifier,
    userProperties = new Dictionary<string, object> 
    {
        { "premium", true },
        { "country", "US" }
    }
};

// Fetch variants
AmplitudeExperiment.Instance.Fetch(user, 
    onSuccess: () => {
        // Get variant
        var variant = AmplitudeExperiment.Instance.GetVariant("feature_flag_key");
        if (variant.IsOn()) {
            // Feature is enabled
        }
    },
    onError: (error) => {
        Debug.LogError($"Fetch failed: {error}");
    }
);
```

## File Structure
```
Assets/
├── Plugins/
│   ├── iOS/
│   │   ├── AmplitudeExperiment/
│   │   │   ├── AmplitudeExperimentBridge.mm    # Native bridge
│   │   │   └── AmplitudeExperimentBridge.h     # Bridge header
│   │   └── Editor/
│   │       ├── AmplitudeExperimentDependencies.xml  # CocoaPods config
│   │       └── AmplitudeExperimentPostProcessor.cs  # Build processor
│   └── AmplitudeExperiment/
│       └── AmplitudeExperiment.cs               # C# API
└── Scripts/
    └── AmplitudeExperimentExample.cs            # Usage example
```

## Building for iOS

### First Build
1. Build your Unity project (File → Build Settings → Build)
2. Open the generated Xcode workspace (not the .xcodeproj):
   - The workspace file will be `Unity-iPhone.xcworkspace`
3. EDM4U will automatically run `pod install` to fetch the Amplitude SDK
4. Build and run from Xcode

### Subsequent Builds
- Use "Build And Run" or "Replace" to update existing Xcode project
- CocoaPods dependencies will be preserved

## Troubleshooting

### CocoaPods Not Installing
- Ensure EDM4U is properly installed
- Check Assets → External Dependency Manager → iOS Resolver → Settings
- Enable "Enable Auto-Resolution"
- Try manually running: Assets → External Dependency Manager → iOS Resolver → Force Resolve

### Build Errors in Xcode
- Always open the `.xcworkspace` file, not `.xcodeproj`
- Ensure you're building for a real device or "Any iOS Device" (not simulator with Swift dependencies)
- Check that Swift support is enabled in build settings

### Runtime Issues
- Verify your Deployment Key is correct
- Check console logs for initialization errors
- Ensure you're calling Initialize before Fetch
- Test on a real device for accurate behavior

## API Reference

### Initialize
```csharp
AmplitudeExperiment.Instance.Initialize(string apiKey, string instanceName = null)
```

### Fetch Variants
```csharp
AmplitudeExperiment.Instance.Fetch(ExperimentUser user, Action onSuccess, Action<string> onError)
```

### Get Variant
```csharp
Variant variant = AmplitudeExperiment.Instance.GetVariant(string flagKey, Variant fallback = null)
```

### Clear Variants
```csharp
AmplitudeExperiment.Instance.Clear()
```

### Variant Extensions
```csharp
variant.IsOn()        // Returns true if value is "on"
variant.IsOff()       // Returns true if value is "off" or "control"
variant.GetPayload<T>() // Get typed payload data
```

## Testing in Unity Editor
The SDK includes editor-safe code that logs actions without making actual network calls. This allows you to:
- Test your integration logic in the Unity Editor
- See debug logs for all SDK calls
- Switch between editor and device testing seamlessly

## Support
For issues specific to this Unity integration, check the implementation files.
For Amplitude Experiments SDK documentation, visit: https://amplitude.com/docs/sdks/experiment-sdks/experiment-ios