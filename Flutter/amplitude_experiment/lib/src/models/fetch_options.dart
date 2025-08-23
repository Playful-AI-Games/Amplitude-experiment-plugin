/// Options for the fetch() method
class FetchOptions {
  /// Optional flag keys to fetch specific flags only
  final List<String>? flagKeys;
  
  /// Optional timeout override for this fetch request
  final Duration? timeout;
  
  const FetchOptions({
    this.flagKeys,
    this.timeout,
  });
}