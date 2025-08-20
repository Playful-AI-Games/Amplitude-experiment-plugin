# Android Timeout Diagnosis Guide

## Changes Made for Better Debugging

1. **Network Connectivity Check** - Added check before fetch to ensure device has internet
2. **Increased Timeout** - Changed from 10 to 30 seconds
3. **Detailed Logging** - Added extensive debug logging
4. **Better Error Messages** - More descriptive error information

## How to Diagnose the Timeout

### 1. Rebuild and Deploy
Rebuild your APK with the updated code and deploy to device.

### 2. Monitor Logs
```bash
adb logcat -c
adb logcat | grep -E "AmplitudeExperiment|Network"
```

### 3. Check These Log Messages

Look for these specific messages:

#### Network Check:
```
AmplitudeExperiment: Network available: true/false
```
If false, the device has no internet connection.

#### Initialization:
```
AmplitudeExperiment: AmplitudeExperiment initialized successfully with client: [object]
```
This confirms initialization worked.

#### Fetch Debug Info:
```
AmplitudeExperiment: Starting fetch with:
AmplitudeExperiment:   userId: test_user_123
AmplitudeExperiment:   deviceId: device_abc123
AmplitudeExperiment:   experimentClient: com.amplitude.experiment.ExperimentClient@XXXXX
```

## Common Causes of Timeout

### 1. Invalid Deployment Key
**Most Common Issue!** The deployment key might be wrong.

**How to verify:**
- Log into Amplitude Experiment dashboard
- Go to your project settings
- Find your deployment key (format: `deployment-XXXXX` or similar)
- Make sure it matches exactly in your Unity code

### 2. Network Issues

**Check network on device:**
```bash
# Test if device can reach Amplitude servers
adb shell ping -c 3 api.lab.amplitude.com
```

**Check if on emulator:**
- Emulators sometimes have DNS issues
- Try on a real device if possible

### 3. Firewall/Proxy
Corporate networks might block Amplitude's servers.

**Test endpoints:**
```bash
# From device browser, try to access:
https://api.lab.amplitude.com
https://flag.lab.amplitude.com
```

### 4. Wrong Server Zone
If using EU data center, you need to configure it:

```java
// In AmplitudeExperimentBridge.java
ExperimentConfig config = ExperimentConfig.builder()
    .serverZone(ServerZone.EU)  // Add this for EU
    // ... other config
```

## Quick Test with curl

Test your deployment key from your computer:
```bash
curl -X POST https://api.lab.amplitude.com/v1/vardata \
  -H "Authorization: Api-Key YOUR_DEPLOYMENT_KEY" \
  -H "Content-Type: application/json" \
  -d '{"user": {"user_id": "test"}}'
```

If this times out or returns an error, the issue is with the key or network.

## Enable More SDK Debug Info

The code now has `.debug(true)` enabled. Look for SDK internal logs:
```bash
adb logcat | grep -i amplitude
```

## Test with Simple Configuration

Try simplifying the fetch to isolate the issue:

```java
// In your Unity code, try fetch with minimal user:
ExperimentUser user = new ExperimentUser
{
    userId = "test"
    // No device ID or properties
};
```

## If Still Timing Out

1. **Try without Analytics integration:**
   Change in `AmplitudeExperimentBridge.java`:
   ```java
   // From: Experiment.initializeWithAmplitudeAnalytics
   // To: Experiment.initialize
   ```

2. **Check Android Permissions:**
   Verify in AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

3. **Test on Different Network:**
   - Try on WiFi vs cellular
   - Try on different WiFi network
   - Use device hotspot

## Expected Success Pattern

When working correctly, you should see:
```
AmplitudeExperiment: Network available: true
AmplitudeExperiment: Starting fetch with: [details]
AmplitudeExperiment: Waiting for fetch to complete (timeout: 30 seconds)...
AmplitudeExperiment: [SDK debug logs about HTTP requests]
AmplitudeExperiment: Fetch successful - client returned: [object]
Unity: OnFetchSuccess
```

## Contact Amplitude Support

If the deployment key is correct and network is working, but still timing out:
- There might be an issue with your Amplitude project configuration
- Contact Amplitude support with your deployment key and project details