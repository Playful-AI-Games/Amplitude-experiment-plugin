//
//  AmplitudeExperimentBridge_Simplified.mm
//  Unity-iPhone
//
//  Simplified C bridge for Unity to communicate with Amplitude Experiment SDK
//  This replaces the 600-line reflection-heavy implementation with a clean 100-line version
//

#import "AmplitudeExperimentWrapper.h"
#import <Foundation/Foundation.h>

// Unity message sending
extern void UnitySendMessage(const char* obj, const char* method, const char* msg);

// Store Unity GameObject name for callbacks
static NSString* unityGameObjectName = @"AmplitudeExperimentManager";

extern "C" {
    
    void _AmplitudeExperiment_Initialize(const char* apiKey, const char* instanceName) {
        if (!apiKey) {
            NSLog(@"[AmplitudeExperiment Bridge] Error: API key is null");
            return;
        }
        
        NSString *key = [NSString stringWithUTF8String:apiKey];
        [[AmplitudeExperimentWrapper sharedInstance] initializeWithApiKey:key];
    }
    
    void _AmplitudeExperiment_Fetch(const char* userId, 
                                    const char* deviceId, 
                                    const char* userPropertiesJson) {
        
        // Convert C strings to NSString
        NSString *userIdStr = userId ? [NSString stringWithUTF8String:userId] : nil;
        NSString *deviceIdStr = deviceId ? [NSString stringWithUTF8String:deviceId] : nil;
        
        // Parse user properties JSON
        NSDictionary *properties = nil;
        if (userPropertiesJson) {
            NSString *jsonString = [NSString stringWithUTF8String:userPropertiesJson];
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSError *parseError = nil;
            properties = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                        options:0 
                                                          error:&parseError];
            
            if (parseError) {
                NSLog(@"[AmplitudeExperiment Bridge] Error parsing user properties: %@", parseError);
            }
        }
        
        // Perform fetch with completion handler
        [[AmplitudeExperimentWrapper sharedInstance] 
            fetchWithUserId:userIdStr
                   deviceId:deviceIdStr
             userProperties:properties
                 completion:^(BOOL success, NSError *error) {
                     // Send callback to Unity on main thread
                     dispatch_async(dispatch_get_main_queue(), ^{
                         if (success) {
                             UnitySendMessage([unityGameObjectName UTF8String], 
                                            "OnFetchSuccess", 
                                            "");
                         } else {
                             NSString *errorMessage = error.localizedDescription ?: @"Unknown error";
                             UnitySendMessage([unityGameObjectName UTF8String], 
                                            "OnFetchError", 
                                            [errorMessage UTF8String]);
                         }
                     });
                 }];
    }
    
    const char* _AmplitudeExperiment_GetVariant(const char* flagKey) {
        if (!flagKey) {
            return nullptr;
        }
        
        NSString *key = [NSString stringWithUTF8String:flagKey];
        NSDictionary *variant = [[AmplitudeExperimentWrapper sharedInstance] getVariant:key];
        
        // Convert variant dictionary to JSON
        NSError *jsonError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:variant 
                                                          options:0 
                                                            error:&jsonError];
        
        if (jsonError) {
            NSLog(@"[AmplitudeExperiment Bridge] Error serializing variant: %@", jsonError);
            return strdup("{\"value\":\"control\"}");
        }
        
        NSString *jsonString = [[NSString alloc] initWithData:jsonData 
                                                     encoding:NSUTF8StringEncoding];
        
        // Return a copy that Unity will need to free
        return strdup([jsonString UTF8String]);
    }
    
    void _AmplitudeExperiment_Clear() {
        [[AmplitudeExperimentWrapper sharedInstance] clear];
    }
    
    void _AmplitudeExperiment_SetUnityGameObject(const char* gameObjectName) {
        if (gameObjectName) {
            unityGameObjectName = [NSString stringWithUTF8String:gameObjectName];
            NSLog(@"[AmplitudeExperiment Bridge] Unity GameObject set to: %@", unityGameObjectName);
        }
    }
    
    // Additional helper function to check initialization status
    bool _AmplitudeExperiment_IsInitialized() {
        return [[AmplitudeExperimentWrapper sharedInstance] isInitialized];
    }
}

// Total lines: ~110 (vs 600 in the original)