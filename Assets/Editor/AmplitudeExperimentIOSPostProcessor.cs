using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using UnityEngine;

public class AmplitudeExperimentIOSPostProcessor
{
    [PostProcessBuild(100)]
    public static void OnPostProcessBuild(BuildTarget buildTarget, string pathToBuiltProject)
    {
        if (buildTarget != BuildTarget.iOS)
            return;

        Debug.Log("AmplitudeExperiment iOS Post Process: Starting...");
        
        ConfigureXcodeProject(pathToBuiltProject);
        ConfigureInfoPlist(pathToBuiltProject);
        ConfigurePodfile(pathToBuiltProject);
        RunPodInstall(pathToBuiltProject);
        
        Debug.Log("AmplitudeExperiment iOS Post Process: Completed");
    }
    
    private static void ConfigureXcodeProject(string pathToBuiltProject)
    {
        string projPath = PBXProject.GetPBXProjectPath(pathToBuiltProject);
        PBXProject proj = new PBXProject();
        proj.ReadFromFile(projPath);
        
        string targetGuid = proj.GetUnityMainTargetGuid();
        string frameworkGuid = proj.GetUnityFrameworkTargetGuid();
        
        proj.SetBuildProperty(targetGuid, "SWIFT_VERSION", "5.0");
        proj.SetBuildProperty(targetGuid, "ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES", "YES");
        proj.SetBuildProperty(targetGuid, "LD_RUNPATH_SEARCH_PATHS", "$(inherited) @executable_path/Frameworks");
        proj.SetBuildProperty(targetGuid, "ENABLE_BITCODE", "NO");
        proj.SetBuildProperty(targetGuid, "SWIFT_OBJC_BRIDGING_HEADER", "");
        proj.SetBuildProperty(targetGuid, "CLANG_ENABLE_MODULES", "YES");
        proj.SetBuildProperty(targetGuid, "CLANG_ENABLE_OBJC_ARC", "YES");
        proj.SetBuildProperty(targetGuid, "DEFINES_MODULE", "YES");
        proj.SetBuildProperty(targetGuid, "CLANG_MODULES_AUTOLINK", "YES");
        proj.SetBuildProperty(targetGuid, "ENABLE_MODULES", "YES");
        
        proj.SetBuildProperty(frameworkGuid, "CLANG_ENABLE_MODULES", "YES");
        proj.SetBuildProperty(frameworkGuid, "CLANG_ENABLE_OBJC_ARC", "YES");
        proj.SetBuildProperty(frameworkGuid, "DEFINES_MODULE", "YES");
        proj.SetBuildProperty(frameworkGuid, "CLANG_MODULES_AUTOLINK", "YES");
        proj.SetBuildProperty(frameworkGuid, "ENABLE_MODULES", "YES");
        proj.SetBuildProperty(frameworkGuid, "SWIFT_VERSION", "5.0");
        proj.SetBuildProperty(frameworkGuid, "GCC_ENABLE_OBJC_EXCEPTIONS", "YES");
        
        proj.WriteToFile(projPath);
        Debug.Log("AmplitudeExperiment iOS Post Process: Xcode project configured");
    }
    
    private static void ConfigureInfoPlist(string pathToBuiltProject)
    {
        string plistPath = Path.Combine(pathToBuiltProject, "Info.plist");
        PlistDocument plist = new PlistDocument();
        plist.ReadFromFile(plistPath);
        
        if (!plist.root.values.ContainsKey("NSUserTrackingUsageDescription"))
        {
            plist.root.SetString("NSUserTrackingUsageDescription", 
                "This app uses tracking for experiments and feature flags to improve your experience.");
        }
        
        plist.WriteToFile(plistPath);
        Debug.Log("AmplitudeExperiment iOS Post Process: Info.plist configured");
    }
    
    private static void ConfigurePodfile(string pathToBuiltProject)
    {
        string podfilePath = Path.Combine(pathToBuiltProject, "Podfile");
        
        if (!File.Exists(podfilePath))
        {
            Debug.Log("AmplitudeExperiment iOS Post Process: Creating Podfile...");
            CreatePodfile(pathToBuiltProject);
        }
        else
        {
            Debug.Log("AmplitudeExperiment iOS Post Process: Updating existing Podfile...");
            UpdateExistingPodfile(podfilePath);
        }
    }
    
    private static void CreatePodfile(string projectPath)
    {
        string podfileContent = @"platform :ios, '12.0'

target 'Unity-iPhone' do
  use_frameworks!
  
  # Amplitude Experiment SDK for A/B testing and feature flags
  pod 'AmplitudeExperiment', '~> 1.13'
  
  # Optional: Amplitude Analytics SDK if you want to track analytics events
  # pod 'Amplitude', '~> 8.0'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
";
        
        string podfilePath = Path.Combine(projectPath, "Podfile");
        File.WriteAllText(podfilePath, podfileContent);
        Debug.Log($"AmplitudeExperiment iOS Post Process: Podfile created at {podfilePath}");
    }
    
    private static void UpdateExistingPodfile(string podfilePath)
    {
        string podfileContent = File.ReadAllText(podfilePath);
        
        bool hasUseFrameworks = podfileContent.Contains("use_frameworks!");
        bool hasAmplitudeExperiment = podfileContent.Contains("AmplitudeExperiment");
        
        if (!hasUseFrameworks)
        {
            string[] lines = podfileContent.Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                if (lines[i].Contains("target 'Unity-iPhone'"))
                {
                    lines[i] = lines[i] + "\n  use_frameworks!";
                    break;
                }
            }
            podfileContent = string.Join("\n", lines);
        }
        
        if (!hasAmplitudeExperiment)
        {
            string[] lines = podfileContent.Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                if (lines[i].Contains("use_frameworks!"))
                {
                    lines[i] = lines[i] + "\n  \n  # Amplitude Experiment SDK for A/B testing and feature flags\n  pod 'AmplitudeExperiment', '~> 1.13'";
                    break;
                }
            }
            podfileContent = string.Join("\n", lines);
        }
        
        if (!hasUseFrameworks || !hasAmplitudeExperiment)
        {
            File.WriteAllText(podfilePath, podfileContent);
            Debug.Log("AmplitudeExperiment iOS Post Process: Podfile updated");
        }
    }
    
    private static void RunPodInstall(string projectPath)
    {
        Debug.Log($"AmplitudeExperiment iOS Post Process: Running pod install in {projectPath}");
        
        try
        {
            string podPath = FindPodExecutable();
            
            if (string.IsNullOrEmpty(podPath))
            {
                Debug.LogError("AmplitudeExperiment iOS Post Process: Could not find CocoaPods installation");
                Debug.LogError("Please install CocoaPods: sudo gem install cocoapods");
                return;
            }
            
            Debug.Log($"AmplitudeExperiment iOS Post Process: Using pod at {podPath}");
            
            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = $"-l -c \"export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && cd '{projectPath}' && '{podPath}' install\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            
            startInfo.EnvironmentVariables["LANG"] = "en_US.UTF-8";
            startInfo.EnvironmentVariables["LC_ALL"] = "en_US.UTF-8";
            startInfo.EnvironmentVariables["LC_CTYPE"] = "en_US.UTF-8";
            
            using (System.Diagnostics.Process process = System.Diagnostics.Process.Start(startInfo))
            {
                string output = process.StandardOutput.ReadToEnd();
                string error = process.StandardError.ReadToEnd();
                process.WaitForExit();
                
                if (!string.IsNullOrEmpty(output))
                {
                    Debug.Log($"AmplitudeExperiment iOS Post Process - pod install output:\n{output}");
                }
                
                if (!string.IsNullOrEmpty(error))
                {
                    if (process.ExitCode != 0)
                    {
                        Debug.LogError($"AmplitudeExperiment iOS Post Process - pod install error:\n{error}");
                    }
                    else
                    {
                        Debug.LogWarning($"AmplitudeExperiment iOS Post Process - pod install warning:\n{error}");
                    }
                }
                
                if (process.ExitCode == 0)
                {
                    Debug.Log("AmplitudeExperiment iOS Post Process: pod install completed successfully");
                    
                    string workspacePath = Path.Combine(projectPath, "Unity-iPhone.xcworkspace");
                    if (Directory.Exists(workspacePath))
                    {
                        Debug.Log($"AmplitudeExperiment iOS Post Process: Workspace created at {workspacePath}");
                        Debug.Log("IMPORTANT: Open Unity-iPhone.xcworkspace (not .xcodeproj) in Xcode to build");
                    }
                }
                else
                {
                    Debug.LogError($"AmplitudeExperiment iOS Post Process: pod install failed with exit code {process.ExitCode}");
                    Debug.LogError("Make sure CocoaPods is installed: sudo gem install cocoapods");
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"AmplitudeExperiment iOS Post Process: Failed to run pod install - {e.Message}");
            Debug.LogError("Make sure CocoaPods is installed: sudo gem install cocoapods");
        }
    }
    
    private static string FindPodExecutable()
    {
        string[] possiblePaths = new string[]
        {
            "/Users/scritch/.rbenv/shims/pod",
            "/usr/local/bin/pod",
            "/opt/homebrew/bin/pod",
            "/usr/bin/pod",
            "/opt/local/bin/pod",
            "~/.gem/ruby/*/bin/pod",
            "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/pod"
        };
        
        foreach (string path in possiblePaths)
        {
            string expandedPath = path.Replace("~", System.Environment.GetEnvironmentVariable("HOME"));
            
            if (expandedPath.Contains("*"))
            {
                string directory = Path.GetDirectoryName(expandedPath);
                string pattern = Path.GetFileName(expandedPath);
                
                if (Directory.Exists(directory))
                {
                    string[] matches = Directory.GetFiles(directory, pattern);
                    if (matches.Length > 0 && File.Exists(matches[0]))
                    {
                        return matches[0];
                    }
                }
            }
            else if (File.Exists(expandedPath))
            {
                return expandedPath;
            }
        }
        
        try
        {
            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = "-l -c \"which pod\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            
            using (System.Diagnostics.Process process = System.Diagnostics.Process.Start(startInfo))
            {
                string output = process.StandardOutput.ReadToEnd().Trim();
                process.WaitForExit();
                
                if (process.ExitCode == 0 && !string.IsNullOrEmpty(output) && File.Exists(output))
                {
                    return output;
                }
            }
        }
        catch
        {
        }
        
        return null;
    }
}