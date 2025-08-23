# Amplitude Experiment ProGuard Rules
# Keep Amplitude Experiment classes
-keep class com.amplitude.experiment.** { *; }
-keepclassmembers class com.amplitude.experiment.** { *; }

# Keep Unity plugin bridge classes
-keep class com.amplitude.experiment.unity.** { *; }
-keepclassmembers class com.amplitude.experiment.unity.** { *; }

# Keep Amplitude Analytics classes (if using integration)
-keep class com.amplitude.android.** { *; }
-keepclassmembers class com.amplitude.android.** { *; }
-keep class com.amplitude.api.** { *; }
-keepclassmembers class com.amplitude.api.** { *; }

# Keep JSON classes
-keep class org.json.** { *; }
-keepclassmembers class org.json.** { *; }

# Keep OkHttp (used by Amplitude)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Keep Kotlin classes (if using Kotlin)
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Keep Unity classes
-keep class com.unity3d.player.** { *; }
-keepclassmembers class com.unity3d.player.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep CompletableFuture for async operations
-keep class java.util.concurrent.CompletableFuture { *; }
-keepclassmembers class java.util.concurrent.CompletableFuture { *; }

# Suppress warnings for missing classes
-dontwarn com.amplitude.experiment.**
-dontwarn com.amplitude.android.**

# Keep attributes for debugging
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions