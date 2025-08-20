#ifndef AmplitudeExperimentBridge_h
#define AmplitudeExperimentBridge_h

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    void _AmplitudeExperiment_Initialize(const char* apiKey, const char* instanceName);
    void _AmplitudeExperiment_Fetch(const char* userId, const char* deviceId, const char* userPropertiesJson);
    const char* _AmplitudeExperiment_GetVariant(const char* flagKey);
    void _AmplitudeExperiment_Clear(void);
    void _AmplitudeExperiment_SetUnityGameObject(const char* gameObjectName);
    
#ifdef __cplusplus
}
#endif

#endif /* AmplitudeExperimentBridge_h */