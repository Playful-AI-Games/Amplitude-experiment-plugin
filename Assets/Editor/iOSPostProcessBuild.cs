using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;
using UnityEngine;

public class iOSPostProcessBuild
{
    [PostProcessBuild(999)]
    public static void OnPostProcessBuild(BuildTarget buildTarget, string path)
    {
        if (buildTarget != BuildTarget.iOS)
            return;

        Debug.Log("iOS Post Process Build: Starting...");
        
        // Get the path to the Xcode project
        string projectPath = PBXProject.GetPBXProjectPath(path);
        
        // Check if Podfile exists
        string podfilePath = Path.Combine(path, "Podfile");
        
        if (!File.Exists(podfilePath))
        {
            Debug.Log("iOS Post Process Build: Creating Podfile...");
            CreatePodfile(path);
        }
        else
        {
            Debug.Log("iOS Post Process Build: Podfile already exists");
        }
        
        // Run pod install
        RunPodInstall(path);
        
        Debug.Log("iOS Post Process Build: Completed");
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
        Debug.Log($"iOS Post Process Build: Podfile created at {podfilePath}");
    }
    
    private static void RunPodInstall(string projectPath)
    {
        Debug.Log($"iOS Post Process Build: Running pod install in {projectPath}");
        
        try
        {
            // Try to find pod command in common locations
            string podPath = FindPodExecutable();
            
            if (string.IsNullOrEmpty(podPath))
            {
                Debug.LogError("iOS Post Process Build: Could not find CocoaPods installation");
                Debug.LogError("Please install CocoaPods: sudo gem install cocoapods");
                return;
            }
            
            Debug.Log($"iOS Post Process Build: Using pod at {podPath}");
            
            // Create a process to run pod install with full environment and UTF-8 encoding
            System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "/bin/bash",
                Arguments = $"-l -c \"export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && cd '{projectPath}' && '{podPath}' install\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };
            
            // Set environment variables for UTF-8 encoding
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
                    Debug.Log($"iOS Post Process Build - pod install output:\n{output}");
                }
                
                if (!string.IsNullOrEmpty(error))
                {
                    if (process.ExitCode != 0)
                    {
                        Debug.LogError($"iOS Post Process Build - pod install error:\n{error}");
                    }
                    else
                    {
                        Debug.LogWarning($"iOS Post Process Build - pod install warning:\n{error}");
                    }
                }
                
                if (process.ExitCode == 0)
                {
                    Debug.Log("iOS Post Process Build: pod install completed successfully");
                    
                    // Check if .xcworkspace was created
                    string workspacePath = Path.Combine(projectPath, "Unity-iPhone.xcworkspace");
                    if (Directory.Exists(workspacePath))
                    {
                        Debug.Log($"iOS Post Process Build: Workspace created at {workspacePath}");
                        Debug.Log("IMPORTANT: Open Unity-iPhone.xcworkspace (not .xcodeproj) in Xcode to build");
                    }
                }
                else
                {
                    Debug.LogError($"iOS Post Process Build: pod install failed with exit code {process.ExitCode}");
                    Debug.LogError("Make sure CocoaPods is installed: sudo gem install cocoapods");
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"iOS Post Process Build: Failed to run pod install - {e.Message}");
            Debug.LogError("Make sure CocoaPods is installed: sudo gem install cocoapods");
        }
    }
    
    private static string FindPodExecutable()
    {
        // Common locations for pod executable
        string[] possiblePaths = new string[]
        {
            "/Users/scritch/.rbenv/shims/pod", // rbenv installation (found on your system)
            "/usr/local/bin/pod",  // Homebrew or standard installation
            "/opt/homebrew/bin/pod", // Homebrew on Apple Silicon
            "/usr/bin/pod",         // System installation
            "/opt/local/bin/pod",   // MacPorts
            "~/.gem/ruby/*/bin/pod", // User gem installation
            "/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/pod" // System Ruby
        };
        
        foreach (string path in possiblePaths)
        {
            string expandedPath = path.Replace("~", System.Environment.GetEnvironmentVariable("HOME"));
            
            // Handle wildcards in path
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
        
        // Try to find pod using 'which' command as fallback
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
            // Ignore errors from which command
        }
        
        return null;
    }
}