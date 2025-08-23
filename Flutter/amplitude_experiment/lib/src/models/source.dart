/// Determines the primary source of variants before falling back.
enum Source {
  /// Fetch variants from local storage only.
  localStorage,

  /// Fetch variants from the initial variants configuration provided on initialization.
  initialVariants,

  /// Fetch variants from the server. If no variants are returned, fallback
  /// to local storage. If an error occurs, fetch variants from local storage
  /// instead.
  /// 
  /// Uses the fetch() API to retrieve variants from the server.
  localStorageAndServer,
}

/// The source of the variant.
enum VariantSource {
  localEvaluation,
  remoteEvaluation,
  secondaryLocalEvaluation,
  fallback,
  localStorage,
  initialVariants,
}

/// Check if the variant source is a fallback
bool isFallback(VariantSource? source) {
  return source == VariantSource.fallback;
}

/// Check if the variant source is from local evaluation
bool isLocalEvaluation(VariantSource? source) {
  return source == VariantSource.localEvaluation ||
      source == VariantSource.secondaryLocalEvaluation;
}

/// Check if the variant source is from remote evaluation
bool isRemoteEvaluation(VariantSource? source) {
  return source == VariantSource.remoteEvaluation;
}