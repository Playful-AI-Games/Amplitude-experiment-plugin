# Clean Build Instructions for Android

## Problem
The AndroidManifest.xml in the build cache contains a metadata entry with a placeholder `${AMPLITUDE_EXPERIMENT_API_KEY}` from a previous build attempt. This needs to be cleared.

## Solution - Clean Build Steps

### 1. Close Unity Editor
First, close Unity to ensure no files are locked.

### 2. Delete Build Cache Folders
Delete these folders from your project directory:

```bash
# From your project root directory
rm -rf Library/Bee/Android
rm -rf Library/BuildCache
rm -rf Temp
rm -rf Library/Artifacts
```

Or manually delete these folders in Finder:
- `Library/Bee/Android/` 
- `Library/BuildCache/`
- `Temp/`
- `Library/Artifacts/`

### 3. Reopen Unity
Open Unity and let it reimport assets.

### 4. Verify Player Settings
Go to **File > Build Settings > Player Settings**:
- Ensure **Custom Main Gradle Template** is enabled ✅
- Ensure **Custom Gradle Properties Template** is enabled ✅

### 5. Clean Build
1. **File > Build Settings**
2. Select **Android** platform
3. Click **Switch Platform** if needed
4. Click **Build** (choose a new folder or delete contents of existing build folder)

## Alternative Method: Manual Fix

If you want to fix without full clean:

1. Navigate to: `Library/Bee/Android/Prj/IL2CPP/Gradle/unityLibrary/src/main/`
2. Edit `AndroidManifest.xml`
3. Remove this line:
   ```xml
   <meta-data android:name="com.amplitude.experiment.api_key" android:value="${AMPLITUDE_EXPERIMENT_API_KEY}" />
   ```
4. Save and rebuild

## Verification

After successful build, check that:
1. No placeholder errors appear
2. The app initializes Amplitude Experiment correctly
3. Check logcat: `adb logcat -s AmplitudeExperiment:V`

## Why This Happened

The post-processor was previously adding metadata to the AndroidManifest, but we've since removed that because the API key is passed programmatically. The cached manifest still had the old metadata entry.

## Prevention

The updated `AmplitudeExperimentAndroidPostProcessor.cs` no longer adds this metadata, so future builds won't have this issue.