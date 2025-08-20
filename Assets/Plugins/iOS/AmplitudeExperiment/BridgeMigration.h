//
//  BridgeMigration.h
//  Unity-iPhone
//
//  Migration helper to switch between old reflection-based and new direct bridge
//

#ifndef BridgeMigration_h
#define BridgeMigration_h

// Define this to use the new simplified bridge
// Comment out to use the old reflection-based bridge
// Note: Unity doesn't enable modules, so we need to use legacy for now
// #define USE_SIMPLIFIED_BRIDGE 1

#if USE_SIMPLIFIED_BRIDGE
    #warning "Using new simplified AmplitudeExperiment bridge (recommended)"
#else
    #warning "Using old reflection-based AmplitudeExperiment bridge (deprecated)"
#endif

#endif /* BridgeMigration_h */