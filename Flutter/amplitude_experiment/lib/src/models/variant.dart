import 'package:equatable/equatable.dart';

class Variant extends Equatable {
  /// The key of the variant.
  final String? key;

  /// The value of the variant.
  final String? value;

  /// The attached payload, if any.
  final dynamic payload;

  /// The experiment key. Used to distinguish two experiments associated with the same flag.
  final String? expKey;

  /// Flag, segment, and variant metadata produced as a result of
  /// evaluation for the user. Used for system purposes.
  final Map<String, dynamic>? metadata;

  const Variant({
    this.key,
    this.value,
    this.payload,
    this.expKey,
    this.metadata,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      key: json['key'] as String?,
      value: json['value'] as String?,
      payload: json['payload'],
      expKey: json['expKey'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (payload != null) 'payload': payload,
      if (expKey != null) 'expKey': expKey,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [key, value, payload, expKey, metadata];

  Variant copyWith({
    String? key,
    String? value,
    dynamic payload,
    String? expKey,
    Map<String, dynamic>? metadata,
  }) {
    return Variant(
      key: key ?? this.key,
      value: value ?? this.value,
      payload: payload ?? this.payload,
      expKey: expKey ?? this.expKey,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'Variant(key: $key, value: $value, payload: $payload, expKey: $expKey)';
}

/// Map of variant keys to Variant objects
typedef Variants = Map<String, Variant>;