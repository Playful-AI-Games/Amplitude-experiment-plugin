import 'package:equatable/equatable.dart';

/// Exposure tracking data
class Exposure extends Equatable {
  /// The flag key
  final String flagKey;

  /// The variant value
  final String? variant;

  /// The experiment key
  final String? experimentKey;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const Exposure({
    required this.flagKey,
    this.variant,
    this.experimentKey,
    this.metadata,
  });

  factory Exposure.fromJson(Map<String, dynamic> json) {
    return Exposure(
      flagKey: json['flag_key'] as String,
      variant: json['variant'] as String?,
      experimentKey: json['experiment_key'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flag_key': flagKey,
      if (variant != null) 'variant': variant,
      if (experimentKey != null) 'experiment_key': experimentKey,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [flagKey, variant, experimentKey, metadata];
}

/// Interface for tracking exposure events
abstract class ExposureTrackingProvider {
  /// Track an exposure event
  void track(Exposure exposure);
}