/// Event types for experiment analytics
class ExperimentAnalyticsEvent {
  static const String exposure = r'$exposure';
  static const String flag = r'$flag';
}

/// Analytics event for tracking
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic>? properties;
  final String? userId;
  final String? deviceId;
  
  const AnalyticsEvent({
    required this.name,
    this.properties,
    this.userId,
    this.deviceId,
  });
}

/// Interface for providing analytics tracking
abstract class ExperimentAnalyticsProvider {
  /// Track an analytics event
  void track(AnalyticsEvent event);
  
  /// Set user ID
  void setUserId(String? userId);
  
  /// Set device ID
  void setDeviceId(String? deviceId);
  
  /// Get current user ID
  String? getUserId();
  
  /// Get current device ID
  String? getDeviceId();
}