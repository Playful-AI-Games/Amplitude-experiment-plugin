# Android Debug Instructions

## Changes Made to Fix Runtime Errors

### 1. Replaced Lambda with Anonymous Class
Changed from lambda syntax `() -> {}` to `new Runnable()` for better compatibility with older Android versions.

### 2. Added Debug Logging
Enabled debug mode in ExperimentConfig to see detailed logs from the SDK.

### 3. Added Null Checks
Added checks for null Future return value from fetch().

### 4. Alternative Initialization Method
Added fallback to use `Experiment.initialize()` instead of `initializeWithAmplitudeAnalytics()` if casting fails.

## To Debug the Current Issue

1. **Rebuild and Deploy** the APK with these changes

2. **Clear App Data** on the device:
   ```bash
   adb shell pm clear com.yourcompany.yourapp
   ```

3. **Run with Verbose Logging**:
   ```bash
   adb logcat -c  # Clear old logs
   adb logcat -v time | grep -E "Amplitude|Unity|Experiment"
   ```

4. **Look for These Key Messages**:
   - "AmplitudeExperiment initialized successfully with client: [object]"
   - "Fetch returned null future" (if this appears, initialization failed)
   - Any ClassCastException or other exceptions

## Common Issues and Solutions

### Issue: ClassCastException on Application cast
**Solution**: The code now catches this and uses UnityPlayer.currentActivity directly

### Issue: Null Future from fetch()
**Solution**: This usually means the SDK isn't properly initialized. Check:
- Deployment key is valid
- Network permissions are granted
- Device has internet access

### Issue: Lambda expression errors
**Solution**: Changed to use anonymous inner classes instead of lambdas

## Test with a Simple Deployment Key

If you're still having issues, try:

1. Create a test deployment in Amplitude Experiment
2. Use a simple test flag
3. Verify the deployment key format (should be like "deployment-XXXXX")

## Enable More Detailed Logging

In `AmplitudeExperimentBridge.java`, the debug flag is now `true`:
```java
.debug(true)  // This will show detailed SDK logs
```

## Check Dependencies

Ensure these are in your gradle:
```gradle
implementation 'com.amplitude:experiment-android-client:1.12.0'
implementation 'com.amplitude:analytics-android:1.16.8'
implementation 'com.squareup.okhttp3:okhttp:4.11.0'
```

## Full Clean Build

If still having issues:
1. Delete `Library/Bee/Android/`
2. Delete any previous APK builds
3. In Unity: File > Build Settings > Build (create new APK)
4. Install fresh on device

## Expected Success Log Pattern

```
AmplitudeExpUnity: Initializing AmplitudeExperiment with deployment key
AmplitudeExperiment: AmplitudeExperiment initialized successfully with client: com.amplitude.experiment.ExperimentClient@XXXXX
AmplitudeExpUnity: Fetching variants for user: test_user_123
AmplitudeExperiment: [Debug logs from SDK]
AmplitudeExperiment: Fetch successful
Unity: OnFetchSuccess
```