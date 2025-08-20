//
//  AmplitudeExperimentWrapper.m
//  Unity-iPhone
//
//  Objective-C wrapper implementation for AmplitudeExperiment Swift SDK
//

#import "AmplitudeExperimentWrapper.h"

// Import the Swift framework
#if __has_include(<AmplitudeExperiment/AmplitudeExperiment-Swift.h>)
    #import <AmplitudeExperiment/AmplitudeExperiment-Swift.h>
#elif __has_include("AmplitudeExperiment-Swift.h")
    #import "AmplitudeExperiment-Swift.h"
#else
    // Use forward declarations if Swift header not available yet
    @class Experiment;
    @class ExperimentConfig;
    @class ExperimentConfigBuilder;
    @class ExperimentUser;
    @class ExperimentUserBuilder;
    @class Variant;
    @protocol ExperimentClient;
#endif

@interface AmplitudeExperimentWrapper ()
@property (nonatomic, strong, nullable) id<ExperimentClient> client;
@property (nonatomic, assign) BOOL initialized;
@end

@implementation AmplitudeExperimentWrapper

+ (instancetype)sharedInstance {
    static AmplitudeExperimentWrapper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialized = NO;
        _client = nil;
    }
    return self;
}

- (void)initializeWithApiKey:(NSString *)apiKey {
    if (!apiKey || apiKey.length == 0) {
        NSLog(@"[AmplitudeExperiment] Error: API key is required for initialization");
        return;
    }
    
    if (self.initialized) {
        NSLog(@"[AmplitudeExperiment] Warning: Already initialized");
        return;
    }
    
    // Create configuration
    ExperimentConfig *config = [[[[[ExperimentConfigBuilder builder]
        debug:NO]
        fetchTimeoutMillis:10000]
        retryFetchOnFailure:YES]
        build];
    
    // Initialize the client
    self.client = [Experiment initializeWithApiKey:apiKey config:config];
    
    if (self.client) {
        self.initialized = YES;
        NSLog(@"[AmplitudeExperiment] Successfully initialized with API key");
    } else {
        NSLog(@"[AmplitudeExperiment] Error: Failed to initialize client");
    }
}

- (void)fetchWithUserId:(nullable NSString *)userId 
               deviceId:(nullable NSString *)deviceId 
         userProperties:(nullable NSDictionary *)properties
             completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    if (!self.initialized || !self.client) {
        NSError *error = [NSError errorWithDomain:@"AmplitudeExperiment" 
                                             code:1001 
                                         userInfo:@{NSLocalizedDescriptionKey: @"Client not initialized"}];
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    // Build user object
    ExperimentUserBuilder *userBuilder = [ExperimentUserBuilder builder];
    
    if (userId && userId.length > 0) {
        userBuilder = [userBuilder userId:userId];
    }
    
    if (deviceId && deviceId.length > 0) {
        userBuilder = [userBuilder deviceId:deviceId];
    }
    
    // Add user properties
    if (properties) {
        [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]]) {
                userBuilder = [userBuilder userPropertyWithKey:key value:obj];
            }
        }];
    }
    
    ExperimentUser *user = [userBuilder build];
    
    // Perform fetch
    [self.client fetchWithUser:user 
                      options:nil 
                   completion:^(id<ExperimentClient> client, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(error == nil, error);
            }
            
            if (error) {
                NSLog(@"[AmplitudeExperiment] Fetch failed: %@", error.localizedDescription);
            } else {
                NSLog(@"[AmplitudeExperiment] Fetch completed successfully");
            }
        });
    }];
}

- (NSDictionary *)getVariant:(NSString *)flagKey {
    if (!self.initialized || !self.client) {
        NSLog(@"[AmplitudeExperiment] Warning: Getting variant without initialization");
        return @{@"value": @"control"};
    }
    
    if (!flagKey || flagKey.length == 0) {
        NSLog(@"[AmplitudeExperiment] Error: Flag key is required");
        return @{@"value": @"control"};
    }
    
    Variant *variant = [self.client variant:flagKey fallback:nil];
    
    if (!variant) {
        return @{@"value": @"control"};
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    // Set value
    if (variant.value) {
        result[@"value"] = variant.value;
    } else {
        result[@"value"] = @"control";
    }
    
    // Set payload if exists
    if (variant.payload) {
        // Convert payload to JSON-serializable format
        if ([NSJSONSerialization isValidJSONObject:variant.payload]) {
            result[@"payload"] = variant.payload;
        } else {
            // Try to convert to string representation
            result[@"payload"] = [variant.payload description];
        }
    }
    
    return [result copy];
}

- (void)clear {
    if (!self.initialized || !self.client) {
        NSLog(@"[AmplitudeExperiment] Warning: Clearing without initialization");
        return;
    }
    
    [self.client clear];
    NSLog(@"[AmplitudeExperiment] Cleared all variants");
}

- (BOOL)isInitialized {
    return self.initialized;
}

@end