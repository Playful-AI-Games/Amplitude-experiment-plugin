import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../config/experiment_config.dart';
import '../models/exposure.dart';
import '../models/fetch_options.dart';
import '../models/source.dart';
import '../models/user.dart';
import '../models/variant.dart';
import '../providers/analytics_provider.dart';
import '../storage/storage.dart';
import '../transport/http_client.dart';
import '../utils/backoff.dart';
import '../utils/base64.dart';

/// The main client for interacting with Amplitude Experiment
class ExperimentClient {
  final ExperimentConfig _config;
  final Logger _logger;
  final HttpClient _httpClient;
  final VariantStorage _variantStorage;
  final FlagStorage _flagStorage;
  final List<Function(ExperimentUser)> _userListeners = [];
  
  ExperimentUser? _user;
  Variants _variants = {};
  String? _flags;
  bool _isRunning = false;
  Timer? _pollingTimer;
  Backoff? _retriesBackoff;

  ExperimentClient(
    String apiKey, {
    ExperimentConfig? config,
    Logger? logger,
  })  : _config = config ?? const ExperimentConfig(),
        _logger = logger ?? Logger(),
        _httpClient = config?.httpClient ??
            DefaultHttpClient(
              apiKey: apiKey,
              logger: logger,
            ),
        _variantStorage = VariantStorage(),
        _flagStorage = FlagStorage() {
    // Initialize with initial variants if provided
    if (_config.initialVariants != null) {
      _variants = Map.from(_config.initialVariants!);
    }
    
    // Initialize with initial flags if provided
    if (_config.initialFlags != null) {
      _flags = _config.initialFlags;
    }
  }

  /// Get the current user
  ExperimentUser? get user => _user;

  /// Set the current user
  void setUser(ExperimentUser user) {
    _user = user;
    // Notify listeners
    for (final listener in _userListeners) {
      listener(user);
    }
  }

  /// Start the client and perform initial fetch if configured
  Future<void> start() async {
    if (_isRunning) {
      _logger.w('Client already started');
      return;
    }
    
    _isRunning = true;
    
    // Load stored variants based on source configuration
    if (_config.source == Source.localStorage ||
        _config.source == Source.localStorageAndServer) {
      try {
        final storedVariants = await _variantStorage.loadVariants();
        _variants = {...storedVariants, ..._variants};
      } catch (e) {
        _logger.e('Failed to load variants from storage', error: e);
      }
    }
    
    // Fetch on start if configured
    if (_config.fetchOnStart ?? true) {
      try {
        await fetch();
      } catch (e) {
        if (_config.throwOnError) {
          rethrow;
        }
        _logger.e('Failed to fetch on start', error: e);
      }
    }
    
    // Start polling if configured for local evaluation
    if (_config.pollOnStart && _isLocalEvaluationMode()) {
      _startPolling();
    }
  }

  /// Stop the client and clean up resources
  void stop() {
    _isRunning = false;
    _stopPolling();
  }

  /// Fetch variants from the server
  Future<Variants> fetch({
    ExperimentUser? user,
    FetchOptions? options,
  }) async {
    final fetchUser = user ?? _user;
    
    // Apply user provider if available
    final enrichedUser = _enrichUserWithProvider(fetchUser);
    
    try {
      final variants = await _fetchInternal(enrichedUser, options);
      
      // Store variants
      _variants = {..._variants, ...variants};
      
      // Save to storage if configured
      if (_config.source == Source.localStorage ||
          _config.source == Source.localStorageAndServer) {
        await _variantStorage.saveVariants(_variants);
      }
      
      return variants;
    } catch (e) {
      if (_config.retryFetchOnFailure) {
        _startRetries(enrichedUser, options);
      }
      
      if (_config.throwOnError) {
        rethrow;
      }
      
      _logger.e('Fetch failed', error: e);
      return {};
    }
  }

  /// Get a variant by key
  Variant variant(String key, {Variant? fallback}) {
    final variant = _variants[key];
    
    if (variant != null) {
      // Track exposure if configured
      if (_config.automaticExposureTracking) {
        _trackExposure(Exposure(
          flagKey: key,
          variant: variant.value,
          experimentKey: variant.expKey,
        ));
      }
      return variant;
    }
    
    return fallback ?? _config.fallbackVariant ?? const Variant();
  }

  /// Get all variants
  Variants all() {
    return Map.from(_variants);
  }

  /// Clear stored variants
  Future<void> clear() async {
    _variants = {};
    await _variantStorage.clearVariants();
    await _flagStorage.clearFlags();
  }

  /// Subscribe to user changes
  void addUserListener(Function(ExperimentUser) listener) {
    _userListeners.add(listener);
  }

  /// Unsubscribe from user changes
  void removeUserListener(Function(ExperimentUser) listener) {
    _userListeners.remove(listener);
  }

  // Private methods

  ExperimentUser? _enrichUserWithProvider(ExperimentUser? user) {
    if (_config.userProvider == null) {
      return user;
    }
    
    final providerUser = _config.userProvider!.getUser();
    if (user == null) {
      return providerUser;
    }
    
    return providerUser.merge(user);
  }

  Future<Variants> _fetchInternal(
    ExperimentUser? user,
    FetchOptions? options,
  ) async {
    // For remote evaluation, we use GET with headers
    // For local evaluation, we use POST with body
    if (_isLocalEvaluationMode()) {
      final url = '${_config.getFlagsServerUrl()}/sdk/v2/flags?v=0';
      final body = {
        'user': user?.toJson(),
        'flag_keys': options?.flagKeys,
      };
      
      final response = await _httpClient.request(
        HttpRequest(
          url: url,
          method: 'POST',
          body: body,
          timeout: options?.timeout ?? 
                   Duration(milliseconds: _config.fetchTimeoutMillis),
        ),
      );
      
      if (response.statusCode != 200) {
        throw FetchException(
          'Failed to fetch flags',
          response.statusCode,
        );
      }
      
      final Map<String, dynamic> data = response.body;
      
      // Store flags for local evaluation
      _flags = jsonEncode(data);
      await _flagStorage.saveFlags(_flags!);
      
      // Evaluate flags locally
      return _evaluateFlags(data, user);
    } else {
      // Remote evaluation uses GET with user data in headers
      final url = '${_config.getServerUrl()}/sdk/v2/vardata?v=0';
      
      // Prepare headers with base64 encoded user data
      final headers = <String, String>{};
      if (user != null) {
        final userJson = jsonEncode(user.toJson());
        headers['X-Amp-Exp-User'] = Base64Utils.encodeURL(userJson);
      }
      if (options?.flagKeys != null) {
        final flagKeysJson = jsonEncode(options!.flagKeys);
        headers['X-Amp-Exp-Flag-Keys'] = Base64Utils.encodeURL(flagKeysJson);
      }
      
      final response = await _httpClient.request(
        HttpRequest(
          url: url,
          method: 'GET',
          headers: headers,
          timeout: options?.timeout ?? 
                   Duration(milliseconds: _config.fetchTimeoutMillis),
        ),
      );
      
      if (response.statusCode != 200) {
        throw FetchException(
          'Failed to fetch variants',
          response.statusCode,
        );
      }
      
      final Map<String, dynamic> data = response.body;
      
      // Parse remote evaluation response
      return _parseRemoteResponse(data);
    }
  }

  Variants _evaluateFlags(Map<String, dynamic> flags, ExperimentUser? user) {
    // TODO: Implement local evaluation engine
    // This is a placeholder - actual implementation would evaluate flags
    // based on user properties and flag rules
    return {};
  }

  Variants _parseRemoteResponse(Map<String, dynamic> data) {
    final Variants variants = {};
    
    // The API returns variants directly as a map, not nested under 'variants'
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        variants[key] = Variant.fromJson(value);
      }
    });
    
    return variants;
  }

  bool _isLocalEvaluationMode() {
    // Check if we have flags for local evaluation
    return _flags != null && _flags!.isNotEmpty;
  }

  void _startPolling() {
    _stopPolling();
    
    final interval = Duration(
      milliseconds: _config.flagConfigPollingIntervalMillis,
    );
    
    _pollingTimer = Timer.periodic(interval, (_) async {
      try {
        await fetch(user: _user);
      } catch (e) {
        _logger.e('Polling fetch failed', error: e);
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _startRetries(ExperimentUser? user, FetchOptions? options) {
    _retriesBackoff ??= Backoff(
      attempts: 8,
      min: const Duration(milliseconds: 500),
      max: const Duration(seconds: 10),
      scalar: 1.5,
    );
    
    _retriesBackoff!.start(() async {
      try {
        await _fetchInternal(user, options);
        _retriesBackoff!.cancel();
      } catch (e) {
        // Continue retrying
      }
    });
  }

  void _trackExposure(Exposure exposure) {
    // Use exposure tracking provider if available
    if (_config.exposureTrackingProvider != null) {
      _config.exposureTrackingProvider!.track(exposure);
      return;
    }
    
    // Fall back to analytics provider if available (deprecated)
    // ignore: deprecated_member_use_from_same_package
    if (_config.analyticsProvider != null) {
      // ignore: deprecated_member_use_from_same_package
      _config.analyticsProvider!.track(
        AnalyticsEvent(
          name: ExperimentAnalyticsEvent.exposure,
          properties: exposure.toJson(),
          userId: _user?.userId,
          deviceId: _user?.deviceId,
        ),
      );
    }
  }

  void dispose() {
    stop();
    _retriesBackoff?.cancel();
    if (_httpClient is DefaultHttpClient) {
      _httpClient.dispose();
    }
  }
}