using UnityEngine;
using UnityEditor;
using UnityEditor.Android;
using System.IO;
using System.Text;
using System.Xml;

public class AmplitudeExperimentAndroidPostProcessor : IPostGenerateGradleAndroidProject
{
    public int callbackOrder => 100;

    public void OnPostGenerateGradleAndroidProject(string path)
    {
        Debug.Log("AmplitudeExperiment: Processing Android build...");

        // Update AndroidManifest.xml
        UpdateAndroidManifest(path);

        // Update Gradle files
        UpdateGradleFiles(path);

        // Copy ProGuard rules if they exist
        CopyProGuardRules(path);

        Debug.Log("AmplitudeExperiment: Android post-processing complete");
    }

    private void UpdateAndroidManifest(string basePath)
    {
        string manifestPath = Path.Combine(basePath, "src", "main", "AndroidManifest.xml");
        
        if (!File.Exists(manifestPath))
        {
            Debug.LogWarning($"AndroidManifest.xml not found at {manifestPath}");
            return;
        }

        try
        {
            XmlDocument manifest = new XmlDocument();
            manifest.Load(manifestPath);

            // Create namespace manager for android namespace
            XmlNamespaceManager namespaceManager = new XmlNamespaceManager(manifest.NameTable);
            namespaceManager.AddNamespace("android", "http://schemas.android.com/apk/res/android");

            XmlNode manifestNode = manifest.SelectSingleNode("/manifest");
            if (manifestNode == null)
            {
                Debug.LogError("Could not find manifest node in AndroidManifest.xml");
                return;
            }

            // Add required permissions if not already present
            XmlNode applicationNode = manifest.SelectSingleNode("/manifest/application");
            if (applicationNode != null)
            {
                // Check and add INTERNET permission
                if (!HasPermission(manifest, namespaceManager, "android.permission.INTERNET"))
                {
                    AddPermission(manifest, manifestNode, "android.permission.INTERNET");
                }

                // Check and add ACCESS_NETWORK_STATE permission
                if (!HasPermission(manifest, namespaceManager, "android.permission.ACCESS_NETWORK_STATE"))
                {
                    AddPermission(manifest, manifestNode, "android.permission.ACCESS_NETWORK_STATE");
                }

                // Note: API key is passed programmatically, not through manifest
            }

            // Save the modified manifest
            manifest.Save(manifestPath);
            Debug.Log("AmplitudeExperiment: AndroidManifest.xml updated successfully");
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Failed to update AndroidManifest.xml: {e.Message}");
        }
    }

    private bool HasPermission(XmlDocument manifest, XmlNamespaceManager namespaceManager, string permission)
    {
        XmlNodeList permissions = manifest.SelectNodes($"/manifest/uses-permission[@android:name='{permission}']", namespaceManager);
        return permissions != null && permissions.Count > 0;
    }

    private void AddPermission(XmlDocument manifest, XmlNode manifestNode, string permission)
    {
        XmlElement permissionElement = manifest.CreateElement("uses-permission");
        permissionElement.SetAttribute("name", "http://schemas.android.com/apk/res/android", permission);
        manifestNode.AppendChild(permissionElement);
        Debug.Log($"Added permission: {permission}");
    }


    private void UpdateGradleFiles(string basePath)
    {
        // Update build.gradle (Module: app)
        string gradlePath = Path.Combine(basePath, "build.gradle");
        if (File.Exists(gradlePath))
        {
            try
            {
                string gradleContent = File.ReadAllText(gradlePath);
                bool modified = false;

                // Ensure minSdkVersion is at least 21 (required for Amplitude)
                if (!gradleContent.Contains("minSdkVersion 21") && !gradleContent.Contains("minSdkVersion 22") && 
                    !gradleContent.Contains("minSdkVersion 23") && !gradleContent.Contains("minSdkVersion 24"))
                {
                    // Check if minSdkVersion is less than 21
                    gradleContent = System.Text.RegularExpressions.Regex.Replace(
                        gradleContent,
                        @"minSdkVersion\s+\d+",
                        "minSdkVersion 21"
                    );
                    modified = true;
                    Debug.Log("Updated minSdkVersion to 21");
                }

                // Add Amplitude dependencies if not present
                if (!gradleContent.Contains("com.amplitude:experiment-android-client"))
                {
                    int dependenciesIndex = gradleContent.IndexOf("dependencies {");
                    if (dependenciesIndex > 0)
                    {
                        int insertIndex = gradleContent.IndexOf('\n', dependenciesIndex) + 1;
                        string amplitudeDeps = @"    // Amplitude Experiment SDK
    implementation 'com.amplitude:experiment-android-client:1.12.0'
    implementation 'com.amplitude:analytics-android:1.16.8'
    implementation 'com.squareup.okhttp3:okhttp:4.11.0'
";
                        gradleContent = gradleContent.Insert(insertIndex, amplitudeDeps);
                        modified = true;
                        Debug.Log("Added Amplitude dependencies");
                    }
                }

                // Add Amplitude repository if not present
                if (!gradleContent.Contains("mavenCentral()"))
                {
                    int repositoriesIndex = gradleContent.IndexOf("repositories {");
                    if (repositoriesIndex > 0)
                    {
                        int insertIndex = gradleContent.IndexOf('\n', repositoriesIndex) + 1;
                        gradleContent = gradleContent.Insert(insertIndex, "        mavenCentral()\n");
                        modified = true;
                        Debug.Log("Added Maven Central repository");
                    }
                }

                // Enable multidex if needed
                if (!gradleContent.Contains("multiDexEnabled true"))
                {
                    int defaultConfigIndex = gradleContent.IndexOf("defaultConfig {");
                    if (defaultConfigIndex > 0)
                    {
                        int insertIndex = gradleContent.IndexOf('\n', defaultConfigIndex) + 1;
                        gradleContent = gradleContent.Insert(insertIndex, "        multiDexEnabled true\n");
                        modified = true;
                        Debug.Log("Enabled multidex");
                    }
                }

                // Add compileOptions for Java 8 if not present
                if (!gradleContent.Contains("compileOptions"))
                {
                    int androidIndex = gradleContent.IndexOf("android {");
                    if (androidIndex > 0)
                    {
                        int closingBraceIndex = FindMatchingBrace(gradleContent, androidIndex);
                        if (closingBraceIndex > 0)
                        {
                            string compileOptions = @"
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
";
                            gradleContent = gradleContent.Insert(closingBraceIndex, compileOptions);
                            modified = true;
                            Debug.Log("Added Java 8 compile options");
                        }
                    }
                }

                if (modified)
                {
                    File.WriteAllText(gradlePath, gradleContent);
                    Debug.Log("build.gradle updated successfully");
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to update build.gradle: {e.Message}");
            }
        }
    }

    private int FindMatchingBrace(string content, int startIndex)
    {
        int braceCount = 0;
        bool started = false;
        
        for (int i = startIndex; i < content.Length; i++)
        {
            if (content[i] == '{')
            {
                braceCount++;
                started = true;
            }
            else if (content[i] == '}')
            {
                braceCount--;
                if (started && braceCount == 0)
                {
                    return i;
                }
            }
        }
        
        return -1;
    }

    private void CopyProGuardRules(string basePath)
    {
        string sourceProguardPath = Path.Combine(Application.dataPath, "Plugins/Android/AmplitudeExperiment/proguard-rules.pro");
        string destProguardPath = Path.Combine(basePath, "proguard-user.txt");

        if (File.Exists(sourceProguardPath))
        {
            try
            {
                string proguardContent = File.ReadAllText(sourceProguardPath);
                
                // Append to existing proguard file or create new one
                if (File.Exists(destProguardPath))
                {
                    string existingContent = File.ReadAllText(destProguardPath);
                    if (!existingContent.Contains("# Amplitude Experiment"))
                    {
                        File.AppendAllText(destProguardPath, "\n\n" + proguardContent);
                        Debug.Log("Appended ProGuard rules to existing file");
                    }
                }
                else
                {
                    File.WriteAllText(destProguardPath, proguardContent);
                    Debug.Log("Created ProGuard rules file");
                }
            }
            catch (System.Exception e)
            {
                Debug.LogWarning($"Failed to copy ProGuard rules: {e.Message}");
            }
        }
    }
}