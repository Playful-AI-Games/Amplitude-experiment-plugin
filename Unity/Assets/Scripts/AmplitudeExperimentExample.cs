using UnityEngine;
using AmplitudeUnityPlugin.Experiment;
using System.Collections.Generic;

public class AmplitudeExperimentExample : MonoBehaviour
{
    [Header("Configuration")]
    [SerializeField] private string deploymentKey = "YOUR_DEPLOYMENT_KEY_HERE";
    
    [Header("Test Settings")]
    [SerializeField] private string testUserId = "test_user_123";
    [SerializeField] private string testFlagKey = "new_feature_flag";

    [SerializeField] private bool initializeAnalyticsStack = false;
    
    private AmplitudeExperiment experiment;

    void Awake()
    {
        if (initializeAnalyticsStack)
        {
            Amplitude amplitude = Amplitude.getInstance();
            amplitude.setServerUrl("https://api2.amplitude.com");
            amplitude.logging = true;
            amplitude.trackSessionEvents(true);
            amplitude.useAdvertisingIdForDeviceId();
            amplitude.setUseDynamicConfig(true);
            amplitude.setServerZone(AmplitudeServerZone.US);
            amplitude.init(deploymentKey);
        }
    }

    void Start()
    {
        // Get the singleton instance
        experiment = AmplitudeExperiment.Instance;
        
        // Initialize the SDK
        InitializeExperiment();
    }
    
    void InitializeExperiment()
    {
        Debug.Log("Initializing Amplitude Experiment SDK...");
        
        // Initialize with your deployment key
        // Pass true as the third parameter if you've initialized Amplitude Analytics
        // Pass false (or omit) for standalone mode
        bool useAnalyticsIntegration = initializeAnalyticsStack;
        experiment.Initialize(deploymentKey, null, useAnalyticsIntegration);
        
        // Fetch variants for the current user
        FetchVariants();
    }
    
    void FetchVariants()
    {
        Debug.Log("Fetching experiment variants...");
        
        // Create user object with properties
        var user = new ExperimentUser
        {
            userId = testUserId,
            deviceId = SystemInfo.deviceUniqueIdentifier,
            userProperties = new Dictionary<string, object>
            {
                { "platform", Application.platform.ToString() },
                { "app_version", Application.version },
                { "premium_user", false },
                { "country", "US" },
                { "language", Application.systemLanguage.ToString() }
            }
        };
        
        // Fetch with callbacks
        experiment.Fetch(user, 
            onSuccess: () => {
                Debug.Log("Successfully fetched experiment variants!");
                CheckFeatureFlags();
            },
            onError: (error) => {
                Debug.LogError($"Failed to fetch variants: {error}");
            }
        );
    }
    
    void CheckFeatureFlags()
    {
        // Get a variant for a feature flag
        Variant variant = experiment.GetVariant(testFlagKey);
        
        Debug.Log($"Feature flag '{testFlagKey}' value: {variant.value}");
        
        // Use extension methods for easier checking
        if (variant.IsOn())
        {
            Debug.Log("Feature is ENABLED!");
            EnableNewFeature();
        }
        else if (variant.IsOff())
        {
            Debug.Log("Feature is DISABLED");
        }
        else
        {
            // Check for custom variant values
            switch (variant.value)
            {
                case "variant_a":
                    Debug.Log("Variant A selected");
                    ShowVariantA();
                    break;
                case "variant_b":
                    Debug.Log("Variant B selected");
                    ShowVariantB();
                    break;
                default:
                    Debug.Log($"Unknown variant: {variant.value}");
                    break;
            }
        }
        
        // Check if variant has payload data
        if (variant.payload != null)
        {
            Debug.Log($"Variant payload: {variant.payload}");
            
            // Example of getting typed payload
            var config = variant.GetPayload<FeatureConfig>();
            if (config != null)
            {
                Debug.Log($"Feature config - Color: {config.color}, Size: {config.size}");
            }
        }
    }
    
    void EnableNewFeature()
    {
        Debug.Log("Enabling new feature based on experiment flag...");
        // Your feature implementation here
    }
    
    void ShowVariantA()
    {
        Debug.Log("Showing Variant A UI...");
        // Variant A implementation
    }
    
    void ShowVariantB()
    {
        Debug.Log("Showing Variant B UI...");
        // Variant B implementation
    }
    
    // Example: Refresh variants when user logs in
    public void OnUserLogin(string userId)
    {
        Debug.Log($"User logged in: {userId}");
        
        var user = new ExperimentUser
        {
            userId = userId,
            deviceId = SystemInfo.deviceUniqueIdentifier
        };
        
        experiment.Fetch(user, 
            onSuccess: () => {
                Debug.Log("Variants refreshed for logged-in user");
                CheckFeatureFlags();
            },
            onError: (error) => {
                Debug.LogError($"Failed to refresh variants: {error}");
            }
        );
    }
    
    // Example: Clear variants on logout
    public void OnUserLogout()
    {
        Debug.Log("User logged out, clearing variants...");
        experiment.Clear();
    }
    
    // Example payload class
    [System.Serializable]
    public class FeatureConfig
    {
        public string color;
        public int size;
        public bool enabled;
    }
    
    void OnGUI()
    {
        // Scale GUI for mobile devices
        float scaleFactor = 4.0f;
        int buttonWidth = 300 * (int)scaleFactor;
        int buttonHeight = 80 * (int)scaleFactor;
        int spacing = 20 * (int)scaleFactor;
        int startY = 40 * (int)scaleFactor;
        
        // Set larger font size
        GUIStyle buttonStyle = new GUIStyle(GUI.skin.button);
        buttonStyle.fontSize = 14 * (int)scaleFactor;
        
        // Simple debug UI with larger buttons
        if (GUI.Button(new Rect(40, startY, buttonWidth, buttonHeight), "Fetch Variants", buttonStyle))
        {
            FetchVariants();
        }
        
        if (GUI.Button(new Rect(40, startY + buttonHeight + spacing, buttonWidth, buttonHeight), "Check Feature Flag", buttonStyle))
        {
            CheckFeatureFlags();
        }
        
        if (GUI.Button(new Rect(40, startY + (buttonHeight + spacing) * 2, buttonWidth, buttonHeight), "Clear Variants", buttonStyle))
        {
            experiment.Clear();
        }
    }
}