#import <Foundation/Foundation.h>
#import <dlfcn.h>

// This file ensures the AmplitudeExperiment framework is loaded at app startup

__attribute__((constructor))
static void InitializeAmplitudeFramework() {
    NSLog(@"AmplitudeExperiment: Forcing framework load at startup...");
    
    // Force load the framework using dlopen
    void* handle = dlopen("@rpath/AmplitudeExperiment.framework/AmplitudeExperiment", RTLD_NOW);
    if (handle) {
        NSLog(@"AmplitudeExperiment: Framework loaded successfully via dlopen");
    } else {
        const char* error = dlerror();
        NSLog(@"AmplitudeExperiment: Failed to load framework via dlopen: %s", error ? error : "unknown error");
        
        // Try alternative path
        handle = dlopen("AmplitudeExperiment.framework/AmplitudeExperiment", RTLD_NOW);
        if (handle) {
            NSLog(@"AmplitudeExperiment: Framework loaded successfully via alternative path");
        }
    }
    
    // Also try to load the bundle
    NSBundle* frameworkBundle = [NSBundle bundleWithIdentifier:@"com.amplitude.AmplitudeExperiment"];
    if (frameworkBundle) {
        NSLog(@"AmplitudeExperiment: Found framework bundle: %@", frameworkBundle.bundlePath);
        [frameworkBundle load];
    } else {
        NSLog(@"AmplitudeExperiment: Framework bundle not found by identifier");
        
        // Try to find it in the app's Frameworks folder
        NSString* frameworksPath = [[NSBundle mainBundle] privateFrameworksPath];
        NSString* amplitudePath = [frameworksPath stringByAppendingPathComponent:@"AmplitudeExperiment.framework"];
        frameworkBundle = [NSBundle bundleWithPath:amplitudePath];
        if (frameworkBundle) {
            NSLog(@"AmplitudeExperiment: Found framework at: %@", amplitudePath);
            BOOL loaded = [frameworkBundle load];
            NSLog(@"AmplitudeExperiment: Framework load result: %@", loaded ? @"SUCCESS" : @"FAILED");
        } else {
            NSLog(@"AmplitudeExperiment: Framework not found at: %@", amplitudePath);
        }
    }
    
    // List all loaded frameworks for debugging
    NSArray* allFrameworks = [NSBundle allFrameworks];
    for (NSBundle* bundle in allFrameworks) {
        if ([bundle.bundleIdentifier containsString:@"Amplitude"] || 
            [bundle.bundlePath containsString:@"Amplitude"]) {
            NSLog(@"AmplitudeExperiment: Loaded framework: %@ at %@", bundle.bundleIdentifier, bundle.bundlePath);
        }
    }
}