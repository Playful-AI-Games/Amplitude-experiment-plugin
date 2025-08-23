package com.amplitude.experiment.unity;

import android.util.Log;
import com.unity3d.player.UnityPlayer;

/**
 * Unity-specific wrapper for AmplitudeExperiment
 * This class provides static methods that can be easily called from Unity C# code
 */
public class AmplitudeExperimentUnityPlugin {
    private static final String TAG = "AmplitudeExpUnity";

    /**
     * Initialize the Amplitude Experiment SDK with explicit Analytics integration control
     * @param deploymentKey The deployment key for your Amplitude Experiment project
     * @param instanceName Optional instance name for multiple instances
     * @param useAnalyticsIntegration Whether to integrate with Amplitude Analytics SDK
     */
    public static void initialize(String deploymentKey, String instanceName, boolean useAnalyticsIntegration) {
        Log.d(TAG, "Initializing AmplitudeExperiment with deployment key (Analytics integration: " + useAnalyticsIntegration + ")");
        
        // Initialize synchronously to avoid race conditions
        // The SDK handles its own threading internally
        AmplitudeExperimentBridge.initialize(deploymentKey, instanceName, useAnalyticsIntegration);
    }

    /**
     * Initialize the Amplitude Experiment SDK (defaults to standalone mode)
     * @param deploymentKey The deployment key for your Amplitude Experiment project
     * @param instanceName Optional instance name for multiple instances
     */
    public static void initialize(String deploymentKey, String instanceName) {
        Log.d(TAG, "Initializing AmplitudeExperiment with deployment key (standalone mode)");
        
        // Default to standalone mode (no Analytics integration)
        AmplitudeExperimentBridge.initialize(deploymentKey, instanceName, false);
    }

    /**
     * Initialize with just deployment key (no instance name, standalone mode)
     * @param deploymentKey The deployment key for your Amplitude Experiment project
     */
    public static void initialize(String deploymentKey) {
        initialize(deploymentKey, null);
    }

    /**
     * Fetch variants for a user
     * @param userId User ID (can be null)
     * @param deviceId Device ID (can be null)
     * @param userPropertiesJson JSON string of user properties (can be null)
     */
    public static void fetch(String userId, String deviceId, String userPropertiesJson) {
        Log.d(TAG, "Fetching variants for user: " + (userId != null ? userId : "anonymous"));
        
        // Run fetch on background thread to avoid blocking Unity main thread
        new Thread(new Runnable() {
            @Override
            public void run() {
                AmplitudeExperimentBridge.fetch(userId, deviceId, userPropertiesJson);
            }
        }).start();
    }

    /**
     * Get a variant for a specific flag
     * @param flagKey The flag key to get variant for
     * @return JSON string representation of the variant, or null if not found
     */
    public static String getVariant(String flagKey) {
        Log.d(TAG, "Getting variant for flag: " + flagKey);
        return AmplitudeExperimentBridge.getVariant(flagKey);
    }

    /**
     * Clear all cached variants
     */
    public static void clear() {
        Log.d(TAG, "Clearing all variants");
        AmplitudeExperimentBridge.clear();
    }

    /**
     * Set the Unity GameObject name for callbacks
     * @param gameObjectName Name of the GameObject to receive callbacks
     */
    public static void setUnityGameObject(String gameObjectName) {
        Log.d(TAG, "Setting Unity GameObject to: " + gameObjectName);
        AmplitudeExperimentBridge.setUnityGameObject(gameObjectName);
    }

    /**
     * Get all variants (for debugging purposes)
     * @return JSON string of all variants
     */
    public static String getAllVariants() {
        return AmplitudeExperimentBridge.getAllVariants();
    }

    /**
     * Check if the SDK is initialized
     * @return true if initialized, false otherwise
     */
    public static boolean isInitialized() {
        return AmplitudeExperimentBridge.isInitialized();
    }

    /**
     * Helper method to validate input parameters
     * @param deploymentKey The deployment key to validate
     * @return true if valid, false otherwise
     */
    private static boolean validateDeploymentKey(String deploymentKey) {
        if (deploymentKey == null || deploymentKey.trim().isEmpty()) {
            Log.e(TAG, "Invalid deployment key: null or empty");
            return false;
        }
        return true;
    }

    /**
     * Helper method to safely parse user properties
     * @param userPropertiesJson JSON string of user properties
     * @return true if valid JSON or null/empty, false if invalid JSON
     */
    private static boolean validateUserProperties(String userPropertiesJson) {
        if (userPropertiesJson == null || userPropertiesJson.trim().isEmpty()) {
            return true; // null or empty is valid
        }
        
        try {
            // Try to parse to validate JSON format
            new org.json.JSONObject(userPropertiesJson);
            return true;
        } catch (Exception e) {
            Log.e(TAG, "Invalid user properties JSON: " + e.getMessage());
            return false;
        }
    }
}