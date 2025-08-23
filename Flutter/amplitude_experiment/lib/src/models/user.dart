import 'package:equatable/equatable.dart';

/// Device categories for targeting
enum DeviceCategory {
  mobile,
  tablet,
  desktop,
  wearable,
  console,
  smarttv,
  embedded,
}

/// User properties type definition
typedef UserProperties = Map<String, dynamic>;

/// Defines a user context for evaluation.
/// [deviceId] and [userId] are used for identity resolution.
/// All other predefined fields and user properties are used for
/// rule based user targeting.
class ExperimentUser extends Equatable {
  /// Device ID for associating with an identity in Amplitude
  final String? deviceId;

  /// User ID for associating with an identity in Amplitude
  final String? userId;

  /// Predefined field, can be manually provided
  final String? country;

  /// Predefined field, can be manually provided
  final String? city;

  /// Predefined field, can be manually provided
  final String? region;

  /// Predefined field, can be manually provided
  final String? dma;

  /// Predefined field, auto populated via a ExperimentUserProvider
  /// or can be manually provided
  final String? language;

  /// Predefined field, auto populated via a ExperimentUserProvider
  /// or can be manually provided
  final String? platform;

  /// Predefined field, auto populated via a ExperimentUserProvider
  /// or can be manually provided
  final String? version;

  /// Predefined field, auto populated via a ExperimentUserProvider
  /// or can be manually provided
  final String? os;

  /// Predefined field, auto populated via a ExperimentUserProvider
  /// or can be manually provided
  final String? deviceModel;

  /// Predefined field, can be manually provided
  final String? carrier;

  /// Predefined field, auto populated, can be manually overridden
  final String? library;

  /// Predefined field, can be manually provided
  final String? ipAddress;

  /// The time first saw this user, stored in local storage, can be manually overridden
  final String? firstSeen;

  /// The device category of the device, auto populated via a ExperimentUserProvider,
  /// can be manually overridden
  final String? deviceCategory;

  /// The referring url that redirected to this page, auto populated via a ExperimentUserProvider,
  /// can be manually overridden
  final String? referringUrl;

  /// The cookies, auto populated via a ExperimentUserProvider, can be manually overridden
  /// Local evaluation only. Stripped before remote evaluation.
  final Map<String, String>? cookie;

  /// The browser used, auto populated via a ExperimentUserProvider, can be manually overridden
  final String? browser;

  /// The landing page of the user, the first page that this user sees for this deployment
  /// Auto populated via a ExperimentUserProvider, can be manually overridden
  final String? landingUrl;

  /// The url params of the page, for one param, value is string if single value,
  /// array of string if multiple values
  /// Auto populated via a ExperimentUserProvider, can be manually overridden
  final Map<String, dynamic>? urlParam;

  /// The user agent string.
  final String? userAgent;

  /// Custom user properties
  final UserProperties? userProperties;

  /// User groups
  final Map<String, List<String>>? groups;

  /// Group properties
  final Map<String, Map<String, Map<String, dynamic>>>? groupProperties;

  const ExperimentUser({
    this.deviceId,
    this.userId,
    this.country,
    this.city,
    this.region,
    this.dma,
    this.language,
    this.platform,
    this.version,
    this.os,
    this.deviceModel,
    this.carrier,
    this.library,
    this.ipAddress,
    this.firstSeen,
    this.deviceCategory,
    this.referringUrl,
    this.cookie,
    this.browser,
    this.landingUrl,
    this.urlParam,
    this.userAgent,
    this.userProperties,
    this.groups,
    this.groupProperties,
  });

  factory ExperimentUser.fromJson(Map<String, dynamic> json) {
    return ExperimentUser(
      deviceId: json['device_id'] as String?,
      userId: json['user_id'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      dma: json['dma'] as String?,
      language: json['language'] as String?,
      platform: json['platform'] as String?,
      version: json['version'] as String?,
      os: json['os'] as String?,
      deviceModel: json['device_model'] as String?,
      carrier: json['carrier'] as String?,
      library: json['library'] as String?,
      ipAddress: json['ip_address'] as String?,
      firstSeen: json['first_seen'] as String?,
      deviceCategory: json['device_category'] as String?,
      referringUrl: json['referring_url'] as String?,
      cookie: json['cookie'] as Map<String, String>?,
      browser: json['browser'] as String?,
      landingUrl: json['landing_url'] as String?,
      urlParam: json['url_param'] as Map<String, dynamic>?,
      userAgent: json['user_agent'] as String?,
      userProperties: json['user_properties'] as Map<String, dynamic>?,
      groups: (json['groups'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
      groupProperties: json['group_properties'] as Map<String, Map<String, Map<String, dynamic>>>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      if (country != null) 'country': country,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (dma != null) 'dma': dma,
      if (language != null) 'language': language,
      if (platform != null) 'platform': platform,
      if (version != null) 'version': version,
      if (os != null) 'os': os,
      if (deviceModel != null) 'device_model': deviceModel,
      if (carrier != null) 'carrier': carrier,
      if (library != null) 'library': library,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (deviceCategory != null) 'device_category': deviceCategory,
      if (referringUrl != null) 'referring_url': referringUrl,
      if (cookie != null) 'cookie': cookie,
      if (browser != null) 'browser': browser,
      if (landingUrl != null) 'landing_url': landingUrl,
      if (urlParam != null) 'url_param': urlParam,
      if (userAgent != null) 'user_agent': userAgent,
      if (userProperties != null) 'user_properties': userProperties,
      if (groups != null) 'groups': groups,
      if (groupProperties != null) 'group_properties': groupProperties,
    };
  }

  ExperimentUser copyWith({
    String? deviceId,
    String? userId,
    String? country,
    String? city,
    String? region,
    String? dma,
    String? language,
    String? platform,
    String? version,
    String? os,
    String? deviceModel,
    String? carrier,
    String? library,
    String? ipAddress,
    String? firstSeen,
    String? deviceCategory,
    String? referringUrl,
    Map<String, String>? cookie,
    String? browser,
    String? landingUrl,
    Map<String, dynamic>? urlParam,
    String? userAgent,
    UserProperties? userProperties,
    Map<String, List<String>>? groups,
    Map<String, Map<String, Map<String, dynamic>>>? groupProperties,
  }) {
    return ExperimentUser(
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      country: country ?? this.country,
      city: city ?? this.city,
      region: region ?? this.region,
      dma: dma ?? this.dma,
      language: language ?? this.language,
      platform: platform ?? this.platform,
      version: version ?? this.version,
      os: os ?? this.os,
      deviceModel: deviceModel ?? this.deviceModel,
      carrier: carrier ?? this.carrier,
      library: library ?? this.library,
      ipAddress: ipAddress ?? this.ipAddress,
      firstSeen: firstSeen ?? this.firstSeen,
      deviceCategory: deviceCategory ?? this.deviceCategory,
      referringUrl: referringUrl ?? this.referringUrl,
      cookie: cookie ?? this.cookie,
      browser: browser ?? this.browser,
      landingUrl: landingUrl ?? this.landingUrl,
      urlParam: urlParam ?? this.urlParam,
      userAgent: userAgent ?? this.userAgent,
      userProperties: userProperties ?? this.userProperties,
      groups: groups ?? this.groups,
      groupProperties: groupProperties ?? this.groupProperties,
    );
  }

  /// Merge another user into this one, with the other user's properties taking precedence
  ExperimentUser merge(ExperimentUser? other) {
    if (other == null) return this;
    
    return ExperimentUser(
      deviceId: other.deviceId ?? deviceId,
      userId: other.userId ?? userId,
      country: other.country ?? country,
      city: other.city ?? city,
      region: other.region ?? region,
      dma: other.dma ?? dma,
      language: other.language ?? language,
      platform: other.platform ?? platform,
      version: other.version ?? version,
      os: other.os ?? os,
      deviceModel: other.deviceModel ?? deviceModel,
      carrier: other.carrier ?? carrier,
      library: other.library ?? library,
      ipAddress: other.ipAddress ?? ipAddress,
      firstSeen: other.firstSeen ?? firstSeen,
      deviceCategory: other.deviceCategory ?? deviceCategory,
      referringUrl: other.referringUrl ?? referringUrl,
      cookie: {...?cookie, ...?other.cookie},
      browser: other.browser ?? browser,
      landingUrl: other.landingUrl ?? landingUrl,
      urlParam: {...?urlParam, ...?other.urlParam},
      userAgent: other.userAgent ?? userAgent,
      userProperties: {...?userProperties, ...?other.userProperties},
      groups: {...?groups, ...?other.groups},
      groupProperties: {...?groupProperties, ...?other.groupProperties},
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        userId,
        country,
        city,
        region,
        dma,
        language,
        platform,
        version,
        os,
        deviceModel,
        carrier,
        library,
        ipAddress,
        firstSeen,
        deviceCategory,
        referringUrl,
        cookie,
        browser,
        landingUrl,
        urlParam,
        userAgent,
        userProperties,
        groups,
        groupProperties,
      ];
}