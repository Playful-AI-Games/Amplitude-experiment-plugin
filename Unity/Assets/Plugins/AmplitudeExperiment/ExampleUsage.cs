using UnityEngine;
using AmplitudeUnityPlugin.Experiment;
using System.Collections.Generic;

/// <summary>
/// Example usage of the Amplitude Experiment SDK for both iOS and Android
/// </summary>
public class ExampleUsage : MonoBehaviour
{
    [Header("Amplitude Experiment Configuration")]
    [SerializeField] private string deploymentKey = "YOUR_DEPLOYMENT_KEY_HERE";
    [SerializeField] private string instanceName = ""; // Optional instance name
    
    [Header("Test User Configuration")]
    [SerializeField] private string testUserId = "test_user_123";
    [SerializeField] private string testDeviceId = "device_abc123";
    [SerializeField] private string testFlagKey = "test-flag";
    
    private AmplitudeExperiment experiment;
    
    void Start()
    {
        // Initialize Amplitude Experiment
        InitializeExperiment();
    }
    
    private void InitializeExperiment()
    {
        // Get the singleton instance
        experiment = AmplitudeExperiment.Instance;
        
        // Initialize with deployment key
        if (string.IsNullOrEmpty(instanceName))
        {
            experiment.Initialize(deploymentKey);
        }
        else
        {
            experiment.Initialize(deploymentKey, instanceName);
        }
        
        Debug.Log("Amplitude Experiment initialization started");
        
        // Fetch variants after a short delay to ensure initialization
        Invoke(nameof(FetchVariants), 1f);
    }
    
    private void FetchVariants()
    {
        // Create a user object
        ExperimentUser user = new ExperimentUser
        {
            userId = testUserId,
            deviceId = testDeviceId,
            userProperties = new Dictionary<string, object>
            {
                { "premium", true },
                { "accountType", "enterprise" },
                { "signupDate", "2024-01-01" }
            }
        };
        
        // Fetch variants with callbacks
        experiment.Fetch(
            user,
            onSuccess: () => {
                Debug.Log("✅ Variants fetched successfully!");
                CheckVariant();
            },
            onError: (error) => {
                Debug.LogError($"❌ Failed to fetch variants: {error}");
            }
        );
    }
    
    private void CheckVariant()
    {
        // Get variant for a specific flag
        Variant variant = experiment.GetVariant(testFlagKey);
        
        Debug.Log($"Flag '{testFlagKey}' variant value: {variant.value}");
        
        // Check if variant is on/off using extension methods
        if (variant.IsOn())
        {
            Debug.Log($"✅ Flag '{testFlagKey}' is ON");
            EnableFeature();
        }
        else if (variant.IsOff())
        {
            Debug.Log($"❌ Flag '{testFlagKey}' is OFF");
            DisableFeature();
        }
        else
        {
            Debug.Log($"Flag '{testFlagKey}' has custom value: {variant.value}");
            HandleCustomVariant(variant);
        }
        
        // Try to get payload if available
        if (variant.payload != null)
        {
            Debug.Log($"Variant payload: {variant.payload}");
        }
    }
    
    private void EnableFeature()
    {
        Debug.Log("Feature enabled based on experiment variant");
        // Implement your feature logic here
    }
    
    private void DisableFeature()
    {
        Debug.Log("Feature disabled based on experiment variant");
        // Implement your feature logic here
    }
    
    private void HandleCustomVariant(Variant variant)
    {
        // Handle custom variant values
        switch (variant.value)
        {
            case "variant_a":
                Debug.Log("Using variant A");
                break;
            case "variant_b":
                Debug.Log("Using variant B");
                break;
            default:
                Debug.Log($"Using default behavior for variant: {variant.value}");
                break;
        }
    }
    
    // UI Button handlers for testing
    public void OnRefreshButtonClicked()
    {
        Debug.Log("Refreshing variants...");
        FetchVariants();
    }
    
    public void OnClearButtonClicked()
    {
        Debug.Log("Clearing all variants...");
        experiment.Clear();
    }
    
    public void OnCheckVariantButtonClicked()
    {
        CheckVariant();
    }
    
    void OnDestroy()
    {
        // Clean up if needed
        if (experiment != null)
        {
            experiment.Clear();
        }
    }
    
    void OnGUI()
    {
        // Simple GUI for testing
        GUI.Label(new Rect(10, 10, 300, 20), "Amplitude Experiment Test");
        
        if (GUI.Button(new Rect(10, 40, 150, 30), "Fetch Variants"))
        {
            OnRefreshButtonClicked();
        }
        
        if (GUI.Button(new Rect(10, 80, 150, 30), "Check Variant"))
        {
            OnCheckVariantButtonClicked();
        }
        
        if (GUI.Button(new Rect(10, 120, 150, 30), "Clear Variants"))
        {
            OnClearButtonClicked();
        }
    }
}