import 'package:flutter_test/flutter_test.dart';
import 'package:learnify_lms/core/config/bunny_stream_resolver.dart';

const _pullZoneHost = String.fromEnvironment('BUNNY_STREAM_PULL_ZONE_HOST');

void main() {
  group('BunnyStreamResolver', () {
    test('keeps direct hls url unchanged', () {
      const url = 'https://vz-123.b-cdn.net/video123/playlist.m3u8?token=abc';

      final resolved = BunnyStreamResolver.resolve(url);

      expect(resolved.url, url);
      expect(resolved.isHls, isTrue);
    });

    test('keeps mp4 url unchanged', () {
      const url = 'https://vz-123.b-cdn.net/video123/play_720p.mp4';

      final resolved = BunnyStreamResolver.resolve(url);

      expect(resolved.url, url);
      expect(resolved.isHls, isFalse);
    });

    test(
      'falls back when pull zone host missing',
      () {
        const url = 'https://video.bunnycdn.com/play/library123/video456';

        final resolved = BunnyStreamResolver.resolve(url);

        expect(resolved.url, url);
        expect(resolved.isHls, isFalse);
      },
      skip: _pullZoneHost.isNotEmpty,
    );

    test(
      'builds hls url from play url',
      () {
        const url =
            'https://video.bunnycdn.com/play/library123/video456?token=abc';

        final resolved = BunnyStreamResolver.resolve(url);

        expect(
          resolved.url,
          'https://$_pullZoneHost/video456/playlist.m3u8?token=abc',
        );
        expect(resolved.isHls, isTrue);
      },
      skip: _pullZoneHost.isEmpty,
    );
  });
}
