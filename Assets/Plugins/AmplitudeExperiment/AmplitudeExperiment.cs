using System;
using System.Runtime.InteropServices;
using UnityEngine;
using System.Collections.Generic;

namespace Amplitude.Experiment
{
    [Serializable]
    public class Variant
    {
        public string value;
        public object payload;
        
        public Variant()
        {
            value = "control";
            payload = null;
        }
    }

    [Serializable]
    public class ExperimentUser
    {
        public string userId;
        public string deviceId;
        public Dictionary<string, object> userProperties;
        
        public ExperimentUser()
        {
            userProperties = new Dictionary<string, object>();
        }
    }

    public class AmplitudeExperiment : MonoBehaviour
    {
        private static AmplitudeExperiment instance;
        private Action onFetchSuccess;
        private Action<string> onFetchError;
        private bool isInitialized = false;

        #if UNITY_IOS && !UNITY_EDITOR
        [DllImport("__Internal")]
        private static extern void _AmplitudeExperiment_Initialize(string apiKey, string instanceName);
        
        [DllImport("__Internal")]
        private static extern void _AmplitudeExperiment_Fetch(string userId, string deviceId, string userPropertiesJson);
        
        [DllImport("__Internal")]
        private static extern IntPtr _AmplitudeExperiment_GetVariant(string flagKey);
        
        [DllImport("__Internal")]
        private static extern void _AmplitudeExperiment_Clear();
        
        [DllImport("__Internal")]
        private static extern void _AmplitudeExperiment_SetUnityGameObject(string gameObjectName);
        #endif

        #if UNITY_ANDROID && !UNITY_EDITOR
        private static AndroidJavaClass androidPlugin;
        private static AndroidJavaClass AndroidPlugin
        {
            get
            {
                if (androidPlugin == null)
                {
                    androidPlugin = new AndroidJavaClass("com.amplitude.experiment.unity.AmplitudeExperimentUnityPlugin");
                }
                return androidPlugin;
            }
        }
        #endif

        public static AmplitudeExperiment Instance
        {
            get
            {
                if (instance == null)
                {
                    GameObject go = GameObject.Find("AmplitudeExperimentManager");
                    if (go == null)
                    {
                        go = new GameObject("AmplitudeExperimentManager");
                    }
                    
                    instance = go.GetComponent<AmplitudeExperiment>();
                    if (instance == null)
                    {
                        instance = go.AddComponent<AmplitudeExperiment>();
                    }
                    
                    DontDestroyOnLoad(go);
                }
                return instance;
            }
        }

        void Awake()
        {
            if (instance == null)
            {
                instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else if (instance != this)
            {
                Destroy(gameObject);
            }
        }

        public void Initialize(string apiKey, string instanceName = null)
        {
            if (string.IsNullOrEmpty(apiKey))
            {
                Debug.LogError("AmplitudeExperiment: API key cannot be null or empty");
                return;
            }

            if (isInitialized)
            {
                Debug.LogWarning("AmplitudeExperiment: Already initialized");
                return;
            }

            #if UNITY_IOS && !UNITY_EDITOR
            _AmplitudeExperiment_SetUnityGameObject(gameObject.name);
            _AmplitudeExperiment_Initialize(apiKey, instanceName);
            isInitialized = true;
            Debug.Log($"AmplitudeExperiment: Initialized with API key (iOS)");
            #elif UNITY_ANDROID && !UNITY_EDITOR
            AndroidPlugin.CallStatic("setUnityGameObject", gameObject.name);
            if (string.IsNullOrEmpty(instanceName))
            {
                AndroidPlugin.CallStatic("initialize", apiKey);
            }
            else
            {
                AndroidPlugin.CallStatic("initialize", apiKey, instanceName);
            }
            isInitialized = true;
            Debug.Log($"AmplitudeExperiment: Initialized with API key (Android)");
            #else
            Debug.Log($"AmplitudeExperiment: Initialize called with apiKey (Editor/non-supported platform)");
            isInitialized = true;
            #endif
        }

        public void Fetch(ExperimentUser user, Action onSuccess = null, Action<string> onError = null)
        {
            if (!isInitialized)
            {
                string error = "AmplitudeExperiment: Not initialized. Call Initialize() first.";
                Debug.LogError(error);
                onError?.Invoke(error);
                return;
            }

            if (user == null)
            {
                string error = "AmplitudeExperiment: User cannot be null";
                Debug.LogError(error);
                onError?.Invoke(error);
                return;
            }

            onFetchSuccess = onSuccess;
            onFetchError = onError;

            string userPropertiesJson = null;
            if (user.userProperties != null && user.userProperties.Count > 0)
            {
                // Convert dictionary to JSON
                var jsonDict = new Dictionary<string, object>(user.userProperties);
                userPropertiesJson = JsonUtility.ToJson(new Serializable(jsonDict));
            }

            #if UNITY_IOS && !UNITY_EDITOR
            _AmplitudeExperiment_Fetch(user.userId, user.deviceId, userPropertiesJson);
            #elif UNITY_ANDROID && !UNITY_EDITOR
            AndroidPlugin.CallStatic("fetch", user.userId, user.deviceId, userPropertiesJson);
            #else
            Debug.Log($"AmplitudeExperiment: Fetch called for user: {user.userId ?? "anonymous"}");
            onSuccess?.Invoke();
            #endif
        }

        public Variant GetVariant(string flagKey, Variant fallback = null)
        {
            if (!isInitialized)
            {
                Debug.LogError("AmplitudeExperiment: Not initialized. Call Initialize() first.");
                return fallback ?? new Variant();
            }

            if (string.IsNullOrEmpty(flagKey))
            {
                Debug.LogError("AmplitudeExperiment: Flag key cannot be null or empty");
                return fallback ?? new Variant();
            }

            #if UNITY_IOS && !UNITY_EDITOR
            IntPtr jsonPtr = _AmplitudeExperiment_GetVariant(flagKey);
            if (jsonPtr != IntPtr.Zero)
            {
                string jsonString = Marshal.PtrToStringAnsi(jsonPtr);
                Marshal.FreeHGlobal(jsonPtr);
                
                try
                {
                    Variant variant = JsonUtility.FromJson<Variant>(jsonString);
                    if (variant != null)
                    {
                        return variant;
                    }
                }
                catch (Exception e)
                {
                    Debug.LogError($"AmplitudeExperiment: Failed to parse variant JSON: {e.Message}");
                }
            }
            #elif UNITY_ANDROID && !UNITY_EDITOR
            string jsonString = AndroidPlugin.CallStatic<string>("getVariant", flagKey);
            if (!string.IsNullOrEmpty(jsonString))
            {
                try
                {
                    Variant variant = JsonUtility.FromJson<Variant>(jsonString);
                    if (variant != null)
                    {
                        return variant;
                    }
                }
                catch (Exception e)
                {
                    Debug.LogError($"AmplitudeExperiment: Failed to parse variant JSON: {e.Message}");
                }
            }
            #else
            Debug.Log($"AmplitudeExperiment: GetVariant called for flag: {flagKey}");
            #endif
            
            return fallback ?? new Variant();
        }

        public void Clear()
        {
            if (!isInitialized)
            {
                Debug.LogWarning("AmplitudeExperiment: Not initialized");
                return;
            }

            #if UNITY_IOS && !UNITY_EDITOR
            _AmplitudeExperiment_Clear();
            Debug.Log("AmplitudeExperiment: Cleared all variants (iOS)");
            #elif UNITY_ANDROID && !UNITY_EDITOR
            AndroidPlugin.CallStatic("clear");
            Debug.Log("AmplitudeExperiment: Cleared all variants (Android)");
            #else
            Debug.Log("AmplitudeExperiment: Clear called (Editor/non-supported platform)");
            #endif
        }

        // Unity callbacks from native
        private void OnFetchSuccess(string message)
        {
            Debug.Log("AmplitudeExperiment: Fetch successful");
            onFetchSuccess?.Invoke();
            onFetchSuccess = null;
            onFetchError = null;
        }

        private void OnFetchError(string error)
        {
            Debug.LogError($"AmplitudeExperiment: Fetch failed - {error}");
            onFetchError?.Invoke(error);
            onFetchSuccess = null;
            onFetchError = null;
        }

        void OnDestroy()
        {
            if (instance == this)
            {
                instance = null;
            }
        }

        // Helper class for JSON serialization
        [Serializable]
        private class Serializable
        {
            public Dictionary<string, object> data;
            
            public Serializable(Dictionary<string, object> dict)
            {
                data = dict;
            }
        }
    }

    // Extension methods for easier usage
    public static class AmplitudeExperimentExtensions
    {
        public static bool IsOn(this Variant variant)
        {
            return variant != null && variant.value == "on";
        }

        public static bool IsOff(this Variant variant)
        {
            return variant == null || variant.value == "off" || variant.value == "control";
        }

        public static T GetPayload<T>(this Variant variant) where T : class
        {
            if (variant?.payload != null)
            {
                try
                {
                    if (variant.payload is T)
                    {
                        return variant.payload as T;
                    }
                    
                    // Try to deserialize if it's a JSON string
                    if (variant.payload is string jsonString)
                    {
                        return JsonUtility.FromJson<T>(jsonString);
                    }
                }
                catch (Exception e)
                {
                    Debug.LogError($"AmplitudeExperiment: Failed to get payload as {typeof(T).Name}: {e.Message}");
                }
            }
            return null;
        }
    }
}