class BunnyStreamConfig {
  BunnyStreamConfig._();

  static const String pullZoneHost = String.fromEnvironment(
    'BUNNY_STREAM_PULL_ZONE_HOST',
    defaultValue: '',
  );

  static const String referer = String.fromEnvironment(
    'BUNNY_STREAM_REFERER',
    defaultValue: '',
  );

  static bool get hasPullZoneHost => pullZoneHost.trim().isNotEmpty;
  static bool get hasReferer => referer.trim().isNotEmpty;
}
