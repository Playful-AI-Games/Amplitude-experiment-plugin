//
//  AmplitudeExperimentWrapper.h
//  Unity-iPhone
//
//  Objective-C wrapper for AmplitudeExperiment Swift SDK
//  Provides a clean interface for the Unity bridge
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AmplitudeExperimentWrapper : NSObject

/**
 * Shared singleton instance
 */
+ (instancetype)sharedInstance;

/**
 * Initialize the Amplitude Experiment client with an API key
 * @param apiKey The deployment/API key from Amplitude Experiment
 */
- (void)initializeWithApiKey:(NSString *)apiKey;

/**
 * Fetch experiment variants for a user
 * @param userId Optional user identifier
 * @param deviceId Optional device identifier
 * @param properties Optional user properties dictionary
 * @param completion Callback with success status and optional error
 */
- (void)fetchWithUserId:(nullable NSString *)userId 
               deviceId:(nullable NSString *)deviceId 
         userProperties:(nullable NSDictionary *)properties
             completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

/**
 * Get a variant for a specific feature flag
 * @param flagKey The feature flag key
 * @return Dictionary containing variant value and optional payload
 */
- (NSDictionary *)getVariant:(NSString *)flagKey;

/**
 * Clear all cached variants
 */
- (void)clear;

/**
 * Check if the client is initialized
 * @return YES if initialized, NO otherwise
 */
- (BOOL)isInitialized;

@end

NS_ASSUME_NONNULL_END