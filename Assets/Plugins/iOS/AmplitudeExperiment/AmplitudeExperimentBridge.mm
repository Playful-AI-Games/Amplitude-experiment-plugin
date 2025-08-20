#import "AmplitudeExperimentBridge.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Unity message sending
extern void UnitySendMessage(const char* obj, const char* method, const char* msg);

// Store reference to the experiment client
static id experimentClient = nil;
static NSString* unityGameObjectName = @"AmplitudeExperimentManager";

// C interface for Unity
extern "C" {
    
    void _AmplitudeExperiment_Initialize(const char* apiKey, const char* instanceName) {
        if (!apiKey) return;
        
        NSString* key = [NSString stringWithUTF8String:apiKey];
        
        // Use runtime to get the classes
        Class ExperimentClass = NSClassFromString(@"AmplitudeExperiment.Experiment");
        Class ConfigBuilderClass = NSClassFromString(@"AmplitudeExperiment.ExperimentConfigBuilder");
        
        // Try without module prefix if not found
        if (!ExperimentClass) {
            ExperimentClass = NSClassFromString(@"Experiment");
        }
        if (!ConfigBuilderClass) {
            ConfigBuilderClass = NSClassFromString(@"ExperimentConfigBuilder");
        }
        
        if (!ExperimentClass) {
            NSLog(@"AmplitudeExperiment: ExperimentClass not found with module prefix, trying without...");
            ExperimentClass = NSClassFromString(@"Experiment");
        }
        if (!ConfigBuilderClass) {
            NSLog(@"AmplitudeExperiment: ConfigBuilderClass not found with module prefix, trying without...");
            ConfigBuilderClass = NSClassFromString(@"ExperimentConfigBuilder");
        }
        
        if (!ExperimentClass || !ConfigBuilderClass) {
            NSLog(@"AmplitudeExperiment: Failed to load Swift classes. Looking for available classes...");
            // Debug: List all loaded classes to find the right name
            int numClasses = objc_getClassList(NULL, 0);
            Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            
            BOOL foundAny = NO;
            for (int i = 0; i < numClasses; i++) {
                NSString *className = NSStringFromClass(classes[i]);
                if ([className containsString:@"Experiment"] || [className containsString:@"Amplitude"]) {
                    NSLog(@"  Found class: %@", className);
                    foundAny = YES;
                }
            }
            
            if (!foundAny) {
                NSLog(@"AmplitudeExperiment: No Amplitude/Experiment classes found. Framework may not be linked.");
                NSLog(@"AmplitudeExperiment: Checking if Pods framework is loaded...");
                
                // Try to force load the framework
                NSBundle* podsBundle = [NSBundle bundleWithPath:@"Frameworks/AmplitudeExperiment.framework"];
                if (podsBundle) {
                    NSLog(@"AmplitudeExperiment: Found framework bundle at %@", podsBundle.bundlePath);
                    [podsBundle load];
                    
                    // Try again after loading
                    ExperimentClass = NSClassFromString(@"AmplitudeExperiment.Experiment");
                    ConfigBuilderClass = NSClassFromString(@"AmplitudeExperiment.ExperimentConfigBuilder");
                    
                    if (!ExperimentClass) {
                        ExperimentClass = NSClassFromString(@"Experiment");
                    }
                    if (!ConfigBuilderClass) {
                        ConfigBuilderClass = NSClassFromString(@"ExperimentConfigBuilder");
                    }
                    
                    if (ExperimentClass && ConfigBuilderClass) {
                        NSLog(@"AmplitudeExperiment: Classes found after loading framework!");
                    }
                } else {
                    NSLog(@"AmplitudeExperiment: Framework bundle not found");
                }
            }
            
            free(classes);
            
            if (!ExperimentClass || !ConfigBuilderClass) {
                NSLog(@"AmplitudeExperiment: Still couldn't find classes. Aborting initialization.");
                return;
            }
        }
        
        // Create config - try different initialization methods
        id configBuilder = nil;
        
        // Try 'builder' class method
        SEL builderSelector = @selector(builder);
        if ([ConfigBuilderClass respondsToSelector:builderSelector]) {
            configBuilder = [ConfigBuilderClass performSelector:builderSelector];
            NSLog(@"AmplitudeExperiment: Created config builder using 'builder' method");
        }
        
        // If that didn't work, try alloc/init
        if (!configBuilder) {
            SEL allocSelector = @selector(alloc);
            SEL initSelector = @selector(init);
            
            if ([ConfigBuilderClass respondsToSelector:allocSelector]) {
                id allocatedBuilder = [ConfigBuilderClass performSelector:allocSelector];
                if (allocatedBuilder && [allocatedBuilder respondsToSelector:initSelector]) {
                    configBuilder = [allocatedBuilder performSelector:initSelector];
                    NSLog(@"AmplitudeExperiment: Created config builder using alloc/init");
                }
            }
        }
        
        // If still no builder, try 'new'
        if (!configBuilder) {
            SEL newSelector = @selector(new);
            if ([ConfigBuilderClass respondsToSelector:newSelector]) {
                configBuilder = [ConfigBuilderClass performSelector:newSelector];
                NSLog(@"AmplitudeExperiment: Created config builder using 'new'");
            }
        }
        
        if (!configBuilder) {
            NSLog(@"AmplitudeExperiment: Failed to create config builder - trying direct config creation");
            
            // Try creating ExperimentConfig directly
            Class ConfigClass = NSClassFromString(@"AmplitudeExperiment.ExperimentConfig");
            if (!ConfigClass) {
                ConfigClass = NSClassFromString(@"ExperimentConfig");
            }
            
            if (ConfigClass) {
                // Try default initializer
                SEL allocSelector = @selector(alloc);
                SEL initSelector = @selector(init);
                
                if ([ConfigClass respondsToSelector:allocSelector]) {
                    id allocatedConfig = [ConfigClass performSelector:allocSelector];
                    if (allocatedConfig && [allocatedConfig respondsToSelector:initSelector]) {
                        id config = [allocatedConfig performSelector:initSelector];
                        if (config) {
                            NSLog(@"AmplitudeExperiment: Created default config directly");
                            
                            // Skip to initialization with this config
                            SEL initSelector = NSSelectorFromString(@"initializeWithApiKey:config:");
                            if ([ExperimentClass respondsToSelector:initSelector]) {
                                NSMethodSignature* sig = [ExperimentClass methodSignatureForSelector:initSelector];
                                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                                [invocation setTarget:ExperimentClass];
                                [invocation setSelector:initSelector];
                                [invocation setArgument:&key atIndex:2];
                                [invocation setArgument:&config atIndex:3];
                                [invocation invoke];
                                
                                id __unsafe_unretained tempClient;
                                [invocation getReturnValue:&tempClient];
                                experimentClient = tempClient;
                                
                                if (experimentClient) {
                                    NSLog(@"AmplitudeExperiment: Initialized successfully with default config");
                                    return;
                                }
                            }
                        }
                    }
                }
            }
            
            NSLog(@"AmplitudeExperiment: Could not create config - aborting");
            return;
        }
        
        // Set debug to false
        SEL debugSelector = NSSelectorFromString(@"debug:");
        if ([configBuilder respondsToSelector:debugSelector]) {
            NSMethodSignature* sig = [configBuilder methodSignatureForSelector:debugSelector];
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:configBuilder];
            [invocation setSelector:debugSelector];
            BOOL debugValue = NO;
            [invocation setArgument:&debugValue atIndex:2];
            [invocation invoke];
            id __unsafe_unretained tempResult;
            [invocation getReturnValue:&tempResult];
            configBuilder = tempResult;
        }
        
        // Set timeout
        SEL timeoutSelector = NSSelectorFromString(@"fetchTimeoutMillis:");
        if ([configBuilder respondsToSelector:timeoutSelector]) {
            NSMethodSignature* sig = [configBuilder methodSignatureForSelector:timeoutSelector];
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:configBuilder];
            [invocation setSelector:timeoutSelector];
            NSInteger timeout = 10000;
            [invocation setArgument:&timeout atIndex:2];
            [invocation invoke];
            id __unsafe_unretained tempResult;
            [invocation getReturnValue:&tempResult];
            configBuilder = tempResult;
        }
        
        // Build config
        SEL buildSelector = @selector(build);
        if (![configBuilder respondsToSelector:buildSelector]) {
            NSLog(@"AmplitudeExperiment: ConfigBuilder doesn't respond to 'build' selector");
            return;
        }
        
        id config = [configBuilder performSelector:buildSelector];
        if (!config) {
            NSLog(@"AmplitudeExperiment: Failed to build config");
            return;
        }
        
        // Initialize client
        SEL initSelector = NSSelectorFromString(@"initializeWithApiKey:config:");
        if (![ExperimentClass respondsToSelector:initSelector]) {
            NSLog(@"AmplitudeExperiment: Experiment class doesn't respond to initialization selector");
            return;
        }
        
        NSMethodSignature* sig = [ExperimentClass methodSignatureForSelector:initSelector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:ExperimentClass];
        [invocation setSelector:initSelector];
        [invocation setArgument:&key atIndex:2];
        [invocation setArgument:&config atIndex:3];
        [invocation invoke];
        
        id __unsafe_unretained tempClient;
        [invocation getReturnValue:&tempClient];
        experimentClient = tempClient;
        
        if (experimentClient) {
            NSLog(@"AmplitudeExperiment: Initialized successfully");
        } else {
            NSLog(@"AmplitudeExperiment: Initialization failed - client is nil");
        }
    }
    
    void _AmplitudeExperiment_Fetch(const char* userId, const char* deviceId, const char* userPropertiesJson) {
        if (!experimentClient) {
            NSLog(@"AmplitudeExperiment: Client not initialized");
            return;
        }
        
        // Get user builder class
        Class UserBuilderClass = NSClassFromString(@"AmplitudeExperiment.ExperimentUserBuilder");
        if (!UserBuilderClass) {
            UserBuilderClass = NSClassFromString(@"ExperimentUserBuilder");
        }
        
        if (!UserBuilderClass) {
            NSLog(@"AmplitudeExperiment: Failed to load ExperimentUserBuilder class");
            return;
        }
        
        // Create user builder - try different initialization methods
        id userBuilder = nil;
        
        // Try 'builder' class method
        SEL builderSelector = @selector(builder);
        if ([UserBuilderClass respondsToSelector:builderSelector]) {
            userBuilder = [UserBuilderClass performSelector:builderSelector];
            NSLog(@"AmplitudeExperiment: Created user builder using 'builder' method");
        }
        
        // If that didn't work, try alloc/init
        if (!userBuilder) {
            SEL allocSelector = @selector(alloc);
            SEL initSelector = @selector(init);
            
            if ([UserBuilderClass respondsToSelector:allocSelector]) {
                id allocatedBuilder = [UserBuilderClass performSelector:allocSelector];
                if (allocatedBuilder && [allocatedBuilder respondsToSelector:initSelector]) {
                    userBuilder = [allocatedBuilder performSelector:initSelector];
                    NSLog(@"AmplitudeExperiment: Created user builder using alloc/init");
                }
            }
        }
        
        // If still no builder, try 'new'
        if (!userBuilder) {
            SEL newSelector = @selector(new);
            if ([UserBuilderClass respondsToSelector:newSelector]) {
                userBuilder = [UserBuilderClass performSelector:newSelector];
                NSLog(@"AmplitudeExperiment: Created user builder using 'new'");
            }
        }
        
        if (!userBuilder) {
            NSLog(@"AmplitudeExperiment: Failed to create user builder - trying direct user creation");
            
            // Try creating ExperimentUser directly
            Class UserClass = NSClassFromString(@"AmplitudeExperiment.ExperimentUser");
            if (!UserClass) {
                UserClass = NSClassFromString(@"ExperimentUser");
            }
            
            if (UserClass) {
                // Try default initializer
                SEL allocSelector = @selector(alloc);
                SEL initSelector = @selector(init);
                
                if ([UserClass respondsToSelector:allocSelector]) {
                    id allocatedUser = [UserClass performSelector:allocSelector];
                    if (allocatedUser && [allocatedUser respondsToSelector:initSelector]) {
                        id user = [allocatedUser performSelector:initSelector];
                        
                        // Set userId and deviceId directly if possible
                        if (userId) {
                            SEL setUserIdSelector = NSSelectorFromString(@"setUserId:");
                            if ([user respondsToSelector:setUserIdSelector]) {
                                NSString* userIdStr = [NSString stringWithUTF8String:userId];
                                [user performSelector:setUserIdSelector withObject:userIdStr];
                            }
                        }
                        
                        if (deviceId) {
                            SEL setDeviceIdSelector = NSSelectorFromString(@"setDeviceId:");
                            if ([user respondsToSelector:setDeviceIdSelector]) {
                                NSString* deviceIdStr = [NSString stringWithUTF8String:deviceId];
                                [user performSelector:setDeviceIdSelector withObject:deviceIdStr];
                            }
                        }
                        
                        if (user) {
                            NSLog(@"AmplitudeExperiment: Created user directly without builder");
                            
                            // Skip to fetch with this user
                            void (^completionBlock)(id, NSError*) = ^(id client, NSError* error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (error) {
                                        NSString* errorMessage = [error localizedDescription];
                                        UnitySendMessage([unityGameObjectName UTF8String], 
                                                       "OnFetchError", 
                                                       [errorMessage UTF8String]);
                                    } else {
                                        UnitySendMessage([unityGameObjectName UTF8String], 
                                                       "OnFetchSuccess", 
                                                       "");
                                    }
                                });
                            };
                            
                            // Perform fetch
                            SEL fetchSelector = NSSelectorFromString(@"fetchWithUser:options:completion:");
                            if ([experimentClient respondsToSelector:fetchSelector]) {
                                NSMethodSignature* sig = [experimentClient methodSignatureForSelector:fetchSelector];
                                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                                [invocation setTarget:experimentClient];
                                [invocation setSelector:fetchSelector];
                                [invocation setArgument:&user atIndex:2];
                                id nilOptions = nil;
                                [invocation setArgument:&nilOptions atIndex:3];
                                [invocation setArgument:&completionBlock atIndex:4];
                                [invocation invoke];
                                NSLog(@"AmplitudeExperiment: Fetch initiated with direct user");
                                return;
                            }
                        }
                    }
                }
            }
            
            NSLog(@"AmplitudeExperiment: Could not create user - aborting fetch");
            return;
        }
        
        if (userId) {
            NSString* userIdStr = [NSString stringWithUTF8String:userId];
            SEL userIdSelector = NSSelectorFromString(@"userId:");
            if ([userBuilder respondsToSelector:userIdSelector]) {
                NSMethodSignature* sig = [userBuilder methodSignatureForSelector:userIdSelector];
                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                [invocation setTarget:userBuilder];
                [invocation setSelector:userIdSelector];
                [invocation setArgument:&userIdStr atIndex:2];
                [invocation invoke];
                id __unsafe_unretained tempResult;
                [invocation getReturnValue:&tempResult];
                userBuilder = tempResult;
            }
        }
        
        if (deviceId) {
            NSString* deviceIdStr = [NSString stringWithUTF8String:deviceId];
            SEL deviceIdSelector = NSSelectorFromString(@"deviceId:");
            if ([userBuilder respondsToSelector:deviceIdSelector]) {
                NSMethodSignature* sig = [userBuilder methodSignatureForSelector:deviceIdSelector];
                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                [invocation setTarget:userBuilder];
                [invocation setSelector:deviceIdSelector];
                [invocation setArgument:&deviceIdStr atIndex:2];
                [invocation invoke];
                id __unsafe_unretained tempResult;
                [invocation getReturnValue:&tempResult];
                userBuilder = tempResult;
            }
        }
        
        // Parse and add user properties
        if (userPropertiesJson) {
            NSString* jsonString = [NSString stringWithUTF8String:userPropertiesJson];
            NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSError* error;
            NSDictionary* properties = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                                      options:0 
                                                                        error:&error];
            
            if (!error && properties) {
                SEL propSelector = NSSelectorFromString(@"userPropertyWithKey:value:");
                if ([userBuilder respondsToSelector:propSelector]) {
                    for (NSString* propKey in properties) {
                        NSMethodSignature* sig = [userBuilder methodSignatureForSelector:propSelector];
                        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                        [invocation setTarget:userBuilder];
                        [invocation setSelector:propSelector];
                        NSString* keyArg = propKey;
                        id valueArg = properties[propKey];
                        [invocation setArgument:&keyArg atIndex:2];
                        [invocation setArgument:&valueArg atIndex:3];
                        [invocation invoke];
                        id __unsafe_unretained tempResult;
                        [invocation getReturnValue:&tempResult];
                        userBuilder = tempResult;
                    }
                }
            }
        }
        
        // Build user
        SEL buildSelector = @selector(build);
        if (![userBuilder respondsToSelector:buildSelector]) {
            NSLog(@"AmplitudeExperiment: UserBuilder doesn't respond to 'build' selector");
            return;
        }
        
        id user = [userBuilder performSelector:buildSelector];
        if (!user) {
            NSLog(@"AmplitudeExperiment: Failed to build user");
            return;
        }
        
        // Create fetch completion block
        void (^completionBlock)(id, NSError*) = ^(id client, NSError* error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    NSString* errorMessage = [error localizedDescription];
                    UnitySendMessage([unityGameObjectName UTF8String], 
                                   "OnFetchError", 
                                   [errorMessage UTF8String]);
                } else {
                    UnitySendMessage([unityGameObjectName UTF8String], 
                                   "OnFetchSuccess", 
                                   "");
                }
            });
        };
        
        // Perform fetch
        SEL fetchSelector = NSSelectorFromString(@"fetchWithUser:options:completion:");
        if ([experimentClient respondsToSelector:fetchSelector]) {
            NSMethodSignature* sig = [experimentClient methodSignatureForSelector:fetchSelector];
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:experimentClient];
            [invocation setSelector:fetchSelector];
            [invocation setArgument:&user atIndex:2];
            id nilOptions = nil;
            [invocation setArgument:&nilOptions atIndex:3];
            [invocation setArgument:&completionBlock atIndex:4];
            [invocation invoke];
            NSLog(@"AmplitudeExperiment: Fetch initiated");
        } else {
            NSLog(@"AmplitudeExperiment: fetchWithUser:options:completion: selector not found");
        }
    }
    
    const char* _AmplitudeExperiment_GetVariant(const char* flagKey) {
        if (!experimentClient || !flagKey) {
            return nullptr;
        }
        
        NSString* key = [NSString stringWithUTF8String:flagKey];
        
        // Try different variant method signatures
        id variant = nil;
        
        // First try variant:fallback:
        SEL variantSelector = NSSelectorFromString(@"variant:fallback:");
        if ([experimentClient respondsToSelector:variantSelector]) {
            NSMethodSignature* sig = [experimentClient methodSignatureForSelector:variantSelector];
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:experimentClient];
            [invocation setSelector:variantSelector];
            [invocation setArgument:&key atIndex:2];
            id nilFallback = nil;
            [invocation setArgument:&nilFallback atIndex:3];
            [invocation invoke];
            
            id __unsafe_unretained tempVariant;
            [invocation getReturnValue:&tempVariant];
            variant = tempVariant;
        } else {
            // Try just variant:
            SEL simpleVariantSelector = NSSelectorFromString(@"variant:");
            if ([experimentClient respondsToSelector:simpleVariantSelector]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                variant = [experimentClient performSelector:simpleVariantSelector withObject:key];
                #pragma clang diagnostic pop
            } else {
                NSLog(@"AmplitudeExperiment: No variant selector found");
            }
        }
        
        if (variant) {
            NSMutableDictionary* variantDict = [NSMutableDictionary dictionary];
            
            // Get value
            SEL valueSelector = @selector(value);
            if ([variant respondsToSelector:valueSelector]) {
                id value = [variant performSelector:valueSelector];
                if (value) {
                    if ([value isKindOfClass:[NSString class]]) {
                        variantDict[@"value"] = value;
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        variantDict[@"value"] = [value stringValue];
                    } else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
                        NSError* error;
                        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
                        if (!error && jsonData) {
                            variantDict[@"value"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        } else {
                            variantDict[@"value"] = @"";
                        }
                    } else {
                        variantDict[@"value"] = [value description];
                    }
                } else {
                    variantDict[@"value"] = @"control";
                }
            } else {
                variantDict[@"value"] = @"control";
            }
            
            // Get payload
            SEL payloadSelector = @selector(payload);
            if ([variant respondsToSelector:payloadSelector]) {
                id payload = [variant performSelector:payloadSelector];
                if (payload) {
                    variantDict[@"payload"] = payload;
                } else {
                    variantDict[@"payload"] = [NSNull null];
                }
            } else {
                variantDict[@"payload"] = [NSNull null];
            }
            
            // Convert to JSON
            NSError* error;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:variantDict 
                                                              options:0 
                                                                error:&error];
            
            if (!error && jsonData) {
                NSString* jsonString = [[NSString alloc] initWithData:jsonData 
                                                            encoding:NSUTF8StringEncoding];
                return strdup([jsonString UTF8String]);
            } else {
                NSLog(@"AmplitudeExperiment: Failed to serialize variant to JSON");
            }
        }
        
        return nullptr;
    }
    
    void _AmplitudeExperiment_Clear() {
        if (experimentClient) {
            SEL clearSelector = @selector(clear);
            if ([experimentClient respondsToSelector:clearSelector]) {
                [experimentClient performSelector:clearSelector];
                NSLog(@"AmplitudeExperiment: Cleared variants");
            } else {
                NSLog(@"AmplitudeExperiment: Clear selector not found");
            }
        }
    }
    
    void _AmplitudeExperiment_SetUnityGameObject(const char* gameObjectName) {
        if (gameObjectName) {
            unityGameObjectName = [NSString stringWithUTF8String:gameObjectName];
        }
    }
}