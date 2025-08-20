# Android Build Fix Instructions

## Issues Fixed

1. ✅ **AndroidManifest XML namespace error** - Added proper namespace manager for XML parsing
2. ✅ **Java compilation errors** - Fixed import statements and JSON iteration
3. ✅ **Dependency resolution** - Added Gradle dependencies directly in post-processor

## Required Steps to Complete Build

### 1. Enable Custom Gradle Template (IMPORTANT)

In Unity:
1. Go to **File > Build Settings > Player Settings**
2. Navigate to **Player > Android Settings > Publishing Settings**
3. Enable **Custom Main Gradle Template** ✅
4. Enable **Custom Gradle Properties Template** ✅

### 2. Install External Dependency Manager (If not installed)

If you don't have EDM4U installed:
1. Download from: https://github.com/googlesamples/unity-jar-resolver/releases
2. Import the `.unitypackage` file
3. Run **Assets > External Dependency Manager > Android Resolver > Force Resolve**

### 3. Clean and Rebuild

1. Delete these folders to ensure clean build:
   - `/Library/Bee/`
   - `/Library/BuildCache/`
   - `/Temp/`

2. In Unity:
   - **File > Build Settings**
   - Select **Android** platform
   - Click **Switch Platform** if needed
   - Click **Build** or **Build and Run**

### 4. Alternative: Manual Gradle Fix

If dependencies still aren't resolved, manually edit the generated gradle file:

After Unity generates the Android project, locate:
`Temp/gradleOut/unityLibrary/build.gradle`

Add these lines in the `dependencies` section:
```gradle
dependencies {
    implementation 'com.amplitude:experiment-android-client:1.12.0'
    implementation 'com.amplitude:analytics-android:1.16.8'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
    // ... other dependencies
}
```

### 5. Verify Build Settings

Ensure these settings in **Player Settings**:
- **Minimum API Level**: Android 5.0 (API level 21) or higher
- **Target API Level**: Automatic (highest installed) or 31+
- **Scripting Backend**: IL2CPP (recommended) or Mono
- **Target Architectures**: ARMv7, ARM64 (both recommended)

## Testing the Build

Once built successfully:

1. Install the APK on a device/emulator
2. Check logcat for initialization:
   ```bash
   adb logcat -s AmplitudeExperiment:V AmplitudeExpUnity:V Unity:V
   ```

3. Look for these success messages:
   - "AmplitudeExperiment: Initialized with API key (Android)"
   - "AmplitudeExperiment initialized successfully"

## Common Issues & Solutions

### Issue: "Package does not exist" errors
**Solution**: Ensure Custom Gradle Template is enabled and rebuild

### Issue: "Class not found" at runtime
**Solution**: Check ProGuard rules are being applied. The proguard-rules.pro file should be included.

### Issue: Network/fetch failures
**Solution**: Verify INTERNET permission in AndroidManifest.xml and network connectivity

### Issue: Multidex errors
**Solution**: Already handled by post-processor, but verify multiDexEnabled is true in gradle

## Files Created/Modified

### New Files:
- `/Assets/Plugins/Android/AmplitudeExperiment/AmplitudeExperimentBridge.java`
- `/Assets/Plugins/Android/AmplitudeExperiment/AmplitudeExperimentUnityPlugin.java`
- `/Assets/Plugins/Android/AmplitudeExperiment/proguard-rules.pro`
- `/Assets/Plugins/Android/Editor/AmplitudeExperimentDependencies.xml`
- `/Assets/Plugins/Android/Editor/AmplitudeExperimentAndroidPostProcessor.cs`
- `/Assets/Plugins/Android/mainTemplate.gradle`

### Modified Files:
- `/Assets/Plugins/AmplitudeExperiment/AmplitudeExperiment.cs` - Added Android platform support

## Next Steps

1. Follow steps 1-3 above to enable gradle templates and rebuild
2. Test with your deployment key
3. Verify variants are fetched correctly

The Android implementation is now complete and should build successfully after following these steps!