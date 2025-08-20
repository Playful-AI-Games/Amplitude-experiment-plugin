# Namespace Migration Guide

## Change Summary
To avoid conflicts with the Amplitude Analytics SDK, the Experiment plugin namespace has been changed:

- **Old:** `Amplitude.Experiment`
- **New:** `AmplitudeUnityPlugin.Experiment`

## Migration Steps

### 1. Update Your Using Statements

In all your scripts that use the Experiment SDK, change:

```csharp
// OLD
using Amplitude.Experiment;

// NEW
using AmplitudeUnityPlugin.Experiment;
```

### 2. Update Any Fully Qualified References

If you have any fully qualified type references, update them:

```csharp
// OLD
Amplitude.Experiment.Variant variant = ...

// NEW
AmplitudeUnityPlugin.Experiment.Variant variant = ...
```

### 3. Files Already Updated

The following files have been updated with the new namespace:
- `/Assets/Plugins/AmplitudeExperiment/AmplitudeExperiment.cs`
- `/Assets/Plugins/AmplitudeExperiment/ExampleUsage.cs`
- `/Assets/Scripts/AmplitudeExperimentExample.cs`
- `/Assets/Plugins/Android/README.md`

## Why This Change?

The Amplitude Analytics Unity SDK uses the namespace `Amplitude`, which was conflicting with our `Amplitude.Experiment` namespace. By changing to `AmplitudeUnityPlugin.Experiment`, we can now use both SDKs together without conflicts.

## Using Both SDKs Together

You can now use both the Analytics and Experiment SDKs in the same project:

```csharp
using Amplitude;  // Analytics SDK
using AmplitudeUnityPlugin.Experiment;  // Experiment SDK

public class MyClass : MonoBehaviour
{
    void Start()
    {
        // Initialize Analytics
        Amplitude.Instance.init("ANALYTICS_API_KEY");
        
        // Initialize Experiment
        AmplitudeExperiment.Instance.Initialize("EXPERIMENT_DEPLOYMENT_KEY");
    }
}
```

## Class Names Remain the Same

Only the namespace has changed. All class names remain the same:
- `AmplitudeExperiment`
- `ExperimentUser`
- `Variant`
- `AmplitudeExperimentExtensions`

## Rebuild Required

After updating your code, you'll need to:
1. Clean your build cache
2. Rebuild your project for the target platform

## Troubleshooting

If you see errors like:
- `CS0434: The namespace 'Amplitude' conflicts with...` - You have old references to update
- `CS0246: The type or namespace name 'Amplitude' could not be found` - Update to `AmplitudeUnityPlugin`

Search your project for any remaining references:
```bash
# Find old namespace references
grep -r "using Amplitude.Experiment" Assets/
grep -r "namespace Amplitude.Experiment" Assets/
```