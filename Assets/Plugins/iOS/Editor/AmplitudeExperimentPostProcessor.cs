using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using System.IO;

public class AmplitudeExperimentPostProcessor 
{
    [PostProcessBuild(100)]
    public static void OnPostProcessBuild(BuildTarget target, string pathToBuiltProject)
    {
        if (target != BuildTarget.iOS)
            return;

        // Configure Xcode project
        string projPath = PBXProject.GetPBXProjectPath(pathToBuiltProject);
        PBXProject proj = new PBXProject();
        proj.ReadFromFile(projPath);
        
        // Get main target GUID
        string targetGuid = proj.GetUnityMainTargetGuid();
        
        // Enable Swift support
        proj.SetBuildProperty(targetGuid, "SWIFT_VERSION", "5.0");
        proj.SetBuildProperty(targetGuid, "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES", "YES");
        proj.SetBuildProperty(targetGuid, "LD_RUNPATH_SEARCH_PATHS", "$(inherited) @executable_path/Frameworks");
        proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");
        
        // Add Swift bridging header if needed
        proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_BRIDGING_HEADER", "");
        
        // Ensure Objective-C++ compatibility
        proj.SetBuildProperty(targetGuid, "CLANG_ENABLE_MODULES", "YES");
        proj.SetBuildProperty(targetGuid, "CLANG_ENABLE_OBJC_ARC", "YES");
        
        // Write changes
        proj.WriteToFile(projPath);
        
        // Update Info.plist
        string plistPath = Path.Combine(pathToBuiltProject, "Info.plist");
        PlistDocument plist = new PlistDocument();
        plist.ReadFromFile(plistPath);
        
        // Add usage description for tracking (required for iOS 14.5+)
        if (!plist.root.values.ContainsKey("NSUserTrackingUsageDescription"))
        {
            plist.root.SetString("NSUserTrackingUsageDescription", 
                "This app uses tracking for experiments and feature flags to improve your experience.");
        }
        
        // Write plist changes
        plist.WriteToFile(plistPath);
        
        // Ensure Podfile includes use_frameworks! if needed
        string podfilePath = Path.Combine(pathToBuiltProject, "Podfile");
        if (File.Exists(podfilePath))
        {
            string podfileContent = File.ReadAllText(podfilePath);
            
            // Check if we need to add use_frameworks!
            if (!podfileContent.Contains("use_frameworks!"))
            {
                // Find the target block and add use_frameworks!
                string[] lines = podfileContent.Split('\n');
                for (int i = 0; i < lines.Length; i++)
                {
                    if (lines[i].Contains("target 'Unity-iPhone'"))
                    {
                        // Insert use_frameworks! after the target line
                        lines[i] = lines[i] + "\n  use_frameworks!";
                        break;
                    }
                }
                podfileContent = string.Join("\n", lines);
                File.WriteAllText(podfilePath, podfileContent);
            }
        }
    }
}