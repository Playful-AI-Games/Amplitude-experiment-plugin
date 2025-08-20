package com.amplitude.experiment.unity;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.util.Log;

import com.amplitude.experiment.Experiment;
import com.amplitude.experiment.ExperimentClient;
import com.amplitude.experiment.ExperimentConfig;
import com.amplitude.experiment.ExperimentUser;
import com.amplitude.experiment.Variant;
import com.unity3d.player.UnityPlayer;

import org.json.JSONObject;
import org.json.JSONException;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class AmplitudeExperimentBridge {
    private static final String TAG = "AmplitudeExperiment";
    private static ExperimentClient experimentClient;
    private static String unityGameObjectName = "AmplitudeExperimentManager";
    private static boolean isInitialized = false;

    // Initialize the Amplitude Experiment client (try Analytics first, then standalone)
    public static void initialize(String deploymentKey, String instanceName) {
        initialize(deploymentKey, instanceName, true);  // Default to trying Analytics first
    }
    
    // Initialize with option to use Analytics integration
    public static void initialize(String deploymentKey, String instanceName, boolean useAnalyticsIntegration) {
        if (isInitialized) {
            Log.w(TAG, "AmplitudeExperiment already initialized");
            return;
        }

        Context context = UnityPlayer.currentActivity.getApplicationContext();
        Application application = (Application) context;
        
        // Build configuration
        ExperimentConfig.Builder configBuilder = ExperimentConfig.builder()
            .debug(true)  // Enable debug logging
            .fallbackVariant(new Variant("control", null, null, null, null))
            .automaticExposureTracking(true)
            .fetchTimeoutMillis(10000)
            .retryFetchOnFailure(true);

        if (instanceName != null && !instanceName.isEmpty()) {
            configBuilder.instanceName(instanceName);
        }
        
        ExperimentConfig config = configBuilder.build();

        // Smart initialization: Try Analytics if available, otherwise use standalone
        boolean successfullyInitialized = false;
        
        // Check if we should attempt Analytics integration
        boolean shouldTryAnalytics = useAnalyticsIntegration && isAnalyticsAvailable();
        
        // Try 1: Attempt Analytics integration if it's available
        if (shouldTryAnalytics) {
            try {
                Log.d(TAG, "Analytics SDK detected - attempting integration...");
                experimentClient = Experiment.initializeWithAmplitudeAnalytics(
                    application,
                    deploymentKey,
                    config
                );
                
                if (experimentClient != null) {
                    successfullyInitialized = true;
                    Log.d(TAG, "✓ Successfully initialized WITH Analytics integration");
                }
            } catch (Exception e) {
                Log.w(TAG, "Analytics integration failed, will fall back to standalone: " + e.getMessage());
            }
        } else if (useAnalyticsIntegration) {
            Log.d(TAG, "Analytics integration requested but Analytics SDK not available/initialized");
        }
        
        // Try 2: Use standalone mode if Analytics didn't work or wasn't available
        if (!successfullyInitialized) {
            try {
                Log.d(TAG, "Initializing in STANDALONE mode (no Analytics integration)...");
                experimentClient = Experiment.initialize(
                    application,
                    deploymentKey,
                    config
                );
                
                if (experimentClient != null) {
                    successfullyInitialized = true;
                    Log.d(TAG, "✓ Successfully initialized in STANDALONE mode");
                }
            } catch (Exception e) {
                Log.e(TAG, "Standalone initialization also failed", e);
                sendErrorToUnity("OnInitializeError", "Failed to initialize: " + e.getMessage());
                return;
            }
        }
        
        if (!successfullyInitialized || experimentClient == null) {
            Log.e(TAG, "Failed to initialize Experiment client - all methods failed");
            sendErrorToUnity("OnInitializeError", "Failed to initialize Experiment client");
            return;
        }
        
        isInitialized = true;
        Log.d(TAG, "AmplitudeExperiment initialized successfully with client: " + experimentClient);
    }

    // Fetch variants for a user
    public static void fetch(String userId, String deviceId, String userPropertiesJson) {
        // Add a small delay to ensure initialization completes
        // This handles the case where fetch is called immediately after init
        int retryCount = 0;
        while ((!isInitialized || experimentClient == null) && retryCount < 10) {
            try {
                Thread.sleep(100); // Wait 100ms
                retryCount++;
            } catch (InterruptedException e) {
                // Ignore
            }
        }
        
        if (!isInitialized || experimentClient == null) {
            Log.e(TAG, "AmplitudeExperiment not initialized after waiting");
            sendErrorToUnity("OnFetchError", "AmplitudeExperiment not initialized");
            return;
        }

        // Check network connectivity
        if (!isNetworkAvailable()) {
            Log.e(TAG, "No network connection - cannot fetch variants");
            sendErrorToUnity("OnFetchError", "No network connection available");
            return;
        }

        // Log important debugging info
        Log.d(TAG, "Starting fetch with:");
        Log.d(TAG, "  userId: " + (userId != null ? userId : "null"));
        Log.d(TAG, "  deviceId: " + (deviceId != null ? deviceId : "null"));
        Log.d(TAG, "  userProperties: " + (userPropertiesJson != null ? userPropertiesJson : "null"));
        Log.d(TAG, "  experimentClient: " + experimentClient);

        try {
            ExperimentUser.Builder userBuilder = ExperimentUser.builder();
            
            if (userId != null && !userId.isEmpty()) {
                userBuilder.userId(userId);
            }
            
            if (deviceId != null && !deviceId.isEmpty()) {
                userBuilder.deviceId(deviceId);
            }
            
            // Parse user properties if provided
            if (userPropertiesJson != null && !userPropertiesJson.isEmpty()) {
                try {
                    JSONObject properties = new JSONObject(userPropertiesJson);
                    Map<String, Object> userProperties = new HashMap<>();
                    
                    // Convert JSON to Map - fix for iterator
                    Iterator<String> keys = properties.keys();
                    while (keys.hasNext()) {
                        String key = keys.next();
                        userProperties.put(key, properties.get(key));
                    }
                    
                    userBuilder.userProperties(userProperties);
                } catch (JSONException e) {
                    Log.w(TAG, "Failed to parse user properties JSON", e);
                }
            }
            
            ExperimentUser user = userBuilder.build();
            
            // Fetch variants asynchronously
            final Future<ExperimentClient> future = experimentClient.fetch(user);
            
            if (future == null) {
                Log.e(TAG, "Fetch returned null future");
                sendErrorToUnity("OnFetchError", "Failed to start fetch operation");
                return;
            }
            
            // Handle the future in a separate thread
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        Log.d(TAG, "Waiting for fetch to complete (timeout: 30 seconds)...");
                        // Increased timeout to 30 seconds
                        ExperimentClient client = future.get(30, TimeUnit.SECONDS);
                        Log.d(TAG, "Fetch successful - client returned: " + client);
                        sendMessageToUnity("OnFetchSuccess", "Fetch completed successfully");
                    } catch (TimeoutException e) {
                        Log.e(TAG, "Fetch timed out after 30 seconds. Check:");
                        Log.e(TAG, "  1. Is your deployment key correct?");
                        Log.e(TAG, "  2. Is the device connected to the internet?");
                        Log.e(TAG, "  3. Can the device reach api.lab.amplitude.com?");
                        Log.e(TAG, "  4. Are there any firewall/proxy issues?");
                        sendErrorToUnity("OnFetchError", "Fetch request timed out after 30 seconds - check network and API key");
                    } catch (Exception e) {
                        Log.e(TAG, "Fetch failed with exception: " + e.getClass().getName(), e);
                        String errorMsg = e.getMessage() != null ? e.getMessage() : "Unknown error: " + e.getClass().getSimpleName();
                        sendErrorToUnity("OnFetchError", errorMsg);
                    }
                }
            }).start();
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to fetch variants", e);
            sendErrorToUnity("OnFetchError", e.getMessage());
        }
    }

    // Get a variant for a specific flag key
    public static String getVariant(String flagKey) {
        if (!isInitialized || experimentClient == null) {
            Log.e(TAG, "AmplitudeExperiment not initialized");
            return null;
        }

        try {
            Variant variant = experimentClient.variant(flagKey);
            
            if (variant != null) {
                // Convert variant to JSON string
                JSONObject json = new JSONObject();
                json.put("value", variant.value != null ? variant.value : "control");
                
                if (variant.payload != null) {
                    // Try to convert payload to appropriate format
                    if (variant.payload instanceof String) {
                        json.put("payload", variant.payload);
                    } else if (variant.payload instanceof Map) {
                        json.put("payload", new JSONObject((Map<?, ?>) variant.payload));
                    } else {
                        json.put("payload", variant.payload.toString());
                    }
                }
                
                return json.toString();
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to get variant for flag: " + flagKey, e);
        }
        
        return null;
    }

    // Clear all cached variants
    public static void clear() {
        if (!isInitialized || experimentClient == null) {
            Log.w(TAG, "AmplitudeExperiment not initialized");
            return;
        }

        try {
            experimentClient.clear();
            Log.d(TAG, "Cleared all variants");
        } catch (Exception e) {
            Log.e(TAG, "Failed to clear variants", e);
        }
    }

    // Set the Unity GameObject name for callbacks
    public static void setUnityGameObject(String gameObjectName) {
        unityGameObjectName = gameObjectName;
        Log.d(TAG, "Unity GameObject set to: " + gameObjectName);
    }

    // Helper method to send messages back to Unity
    private static void sendMessageToUnity(String methodName, String message) {
        try {
            UnityPlayer.UnitySendMessage(unityGameObjectName, methodName, message);
        } catch (Exception e) {
            Log.e(TAG, "Failed to send message to Unity", e);
        }
    }

    // Helper method to send error messages back to Unity
    private static void sendErrorToUnity(String methodName, String error) {
        try {
            UnityPlayer.UnitySendMessage(unityGameObjectName, methodName, error != null ? error : "Unknown error");
        } catch (Exception e) {
            Log.e(TAG, "Failed to send error to Unity", e);
        }
    }

    // Get all variants (for debugging)
    public static String getAllVariants() {
        if (!isInitialized || experimentClient == null) {
            return "{}";
        }

        try {
            Map<String, Variant> allVariants = experimentClient.all();
            JSONObject json = new JSONObject();
            
            for (Map.Entry<String, Variant> entry : allVariants.entrySet()) {
                JSONObject variantJson = new JSONObject();
                Variant variant = entry.getValue();
                
                variantJson.put("value", variant.value != null ? variant.value : "control");
                if (variant.payload != null) {
                    variantJson.put("payload", variant.payload);
                }
                
                json.put(entry.getKey(), variantJson);
            }
            
            return json.toString();
        } catch (Exception e) {
            Log.e(TAG, "Failed to get all variants", e);
            return "{}";
        }
    }

    // Check if initialized
    public static boolean isInitialized() {
        return isInitialized;
    }
    
    // Check if Amplitude Analytics SDK is available and initialized
    private static boolean isAnalyticsAvailable() {
        try {
            // Try to check if Analytics SDK class exists and is initialized
            Class<?> amplitudeClass = Class.forName("com.amplitude.api.Amplitude");
            Object instance = amplitudeClass.getMethod("getInstance").invoke(null);
            if (instance != null) {
                // Check if it's initialized by checking if userId or deviceId is set
                Object userId = amplitudeClass.getMethod("getUserId").invoke(instance);
                Object deviceId = amplitudeClass.getMethod("getDeviceId").invoke(instance);
                boolean hasIdentity = (userId != null && !userId.toString().isEmpty()) || 
                                     (deviceId != null && !deviceId.toString().isEmpty());
                Log.d(TAG, "Analytics SDK found, initialized: " + hasIdentity);
                return hasIdentity;
            }
        } catch (ClassNotFoundException e) {
            Log.d(TAG, "Analytics SDK not found in classpath");
        } catch (Exception e) {
            Log.d(TAG, "Error checking Analytics SDK: " + e.getMessage());
        }
        return false;
    }
    
    // Check network connectivity
    private static boolean isNetworkAvailable() {
        try {
            ConnectivityManager cm = (ConnectivityManager) UnityPlayer.currentActivity
                .getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo activeNetwork = cm.getActiveNetworkInfo();
            boolean isConnected = activeNetwork != null && activeNetwork.isConnectedOrConnecting();
            Log.d(TAG, "Network available: " + isConnected);
            if (!isConnected) {
                Log.e(TAG, "No network connection available!");
            }
            return isConnected;
        } catch (Exception e) {
            Log.e(TAG, "Failed to check network connectivity", e);
            return true; // Assume connected if we can't check
        }
    }
}