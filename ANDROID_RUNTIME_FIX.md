# Android Runtime Fix - Initialization Race Condition

## Problem
The fetch was being called before initialization completed, causing "AmplitudeExperiment not initialized" error even though initialization was called.

## Fixes Applied

### 1. Removed Async UI Thread Wrapper
**File:** `AmplitudeExperimentUnityPlugin.java`
- Changed from `runOnUiThread` to direct synchronous call
- The Amplitude SDK handles its own threading internally

### 2. Added Retry Logic in Fetch
**File:** `AmplitudeExperimentBridge.java`
- Added up to 1 second wait (10 retries × 100ms) for initialization to complete
- This handles cases where fetch is called immediately after init

## Testing Steps

1. **Rebuild the APK** with the updated Java files
2. **Deploy to device/emulator**
3. **Check logcat** for proper initialization:
   ```bash
   adb logcat -s AmplitudeExperiment:V AmplitudeExpUnity:V Unity:V
   ```

## Expected Log Flow

```
AmplitudeExpUnity: Setting Unity GameObject to: AmplitudeExperimentManager
AmplitudeExpUnity: Initializing AmplitudeExperiment with deployment key
AmplitudeExperiment: AmplitudeExperiment initialized successfully
Unity: AmplitudeExperiment: Initialized with API key (Android)
Unity: Fetching experiment variants...
AmplitudeExpUnity: Fetching variants for user: test_user_123
AmplitudeExperiment: Fetch successful
Unity: ✅ Variants fetched successfully!
```

## Best Practices

### In Unity Code
Always add a small delay between initialization and fetch:
```csharp
void Start()
{
    AmplitudeExperiment.Instance.Initialize(deploymentKey);
    // Wait at least 0.5-1 second before fetching
    Invoke(nameof(FetchVariants), 1f);
}
```

### Or Use Coroutine
```csharp
IEnumerator InitializeAndFetch()
{
    AmplitudeExperiment.Instance.Initialize(deploymentKey);
    yield return new WaitForSeconds(1f);
    FetchVariants();
}
```

## Alternative Solution (If Still Having Issues)

If initialization still fails, check:

1. **API Key is valid** - Verify your deployment key
2. **Network permissions** - Check AndroidManifest has INTERNET permission
3. **Network connectivity** - Ensure device has internet access
4. **ProGuard** - Ensure ProGuard rules are applied if minification is enabled

## Debugging

Enable debug logging in the bridge:
```java
// In AmplitudeExperimentBridge.java
ExperimentConfig config = ExperimentConfig.builder()
    .debug(true)  // Enable debug logs
    // ... other config
    .build();
```

Then check full logs:
```bash
adb logcat | grep -E "Amplitude|Unity"
```

## Clean Rebuild If Needed

If changes don't take effect:
1. Delete `Library/Bee/Android/`
2. In Unity: File > Build Settings > Build (new APK)
3. Install fresh APK on device