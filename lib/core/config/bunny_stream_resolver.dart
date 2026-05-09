import 'package:flutter/foundation.dart';

import 'bunny_stream_config.dart';

class BunnyResolvedStream {
  const BunnyResolvedStream({
    required this.url,
    required this.isHls,
    this.headers = const <String, String>{},
  });

  final String url;
  final bool isHls;
  final Map<String, String> headers;
}

class BunnyStreamResolver {
  BunnyStreamResolver._();

  static BunnyResolvedStream resolve(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const BunnyResolvedStream(url: '', isHls: false);
    }

    final lower = trimmed.toLowerCase();
    final headers = _buildHeaders();

    if (lower.contains('.m3u8')) {
      return BunnyResolvedStream(url: trimmed, isHls: true, headers: headers);
    }

    if (lower.contains('.mp4')) {
      return BunnyResolvedStream(url: trimmed, isHls: false, headers: headers);
    }

    final hlsUrl = toHlsUrl(trimmed);
    if (hlsUrl != null) {
      return BunnyResolvedStream(url: hlsUrl, isHls: true, headers: headers);
    }

    return BunnyResolvedStream(url: trimmed, isHls: false, headers: headers);
  }

  static String? toHlsUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().contains('.m3u8')) return trimmed;
    if (!trimmed.contains('/play/')) return null;
    if (!BunnyStreamConfig.hasPullZoneHost) {
      debugPrint(
        'BunnyStreamResolver: BUNNY_STREAM_PULL_ZONE_HOST missing. '
        'Cannot build Bunny HLS URL for $trimmed',
      );
      return null;
    }

    try {
      final uri = Uri.parse(trimmed);
      final segments = uri.pathSegments;
      final playIndex = segments.indexOf('play');
      if (playIndex == -1 || playIndex >= segments.length - 1) {
        return null;
      }

      final videoId = segments.last;
      if (videoId.isEmpty) return null;

      return Uri.https(
        BunnyStreamConfig.pullZoneHost,
        '/$videoId/playlist.m3u8',
        uri.queryParameters.isEmpty ? null : uri.queryParameters,
      ).toString();
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _buildHeaders() {
    if (!BunnyStreamConfig.hasReferer) {
      return const <String, String>{};
    }

    final headers = <String, String>{
      'Referer': BunnyStreamConfig.referer,
    };

    final origin = _tryBuildOrigin(BunnyStreamConfig.referer);
    if (origin != null) {
      headers['Origin'] = origin;
    }
    return headers;
  }

  static String? _tryBuildOrigin(String value) {
    try {
      final uri = Uri.parse(value);
      if (uri.scheme.isEmpty || uri.host.isEmpty) return null;
      return uri.origin;
    } catch (_) {
      return null;
    }
  }
}
