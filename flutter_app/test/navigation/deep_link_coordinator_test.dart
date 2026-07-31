import 'package:flutter_app/navigation/deep_link_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoDeepLink.parse', () {
    test('accepts the canonical custom scheme route', () {
      final link = VideoDeepLink.parse(
        Uri.parse('zhangyuzhixue://video/123'),
      );

      expect(link?.videoId, 123);
      expect(link?.internalLocation, '/videos/detail?videoId=123');
    });

    test('rejects unknown hosts, extra paths and invalid ids', () {
      expect(
        VideoDeepLink.parse(Uri.parse('zhangyuzhixue://lecture/123')),
        isNull,
      );
      expect(
        VideoDeepLink.parse(Uri.parse('zhangyuzhixue://video/123/edit')),
        isNull,
      );
      expect(
        VideoDeepLink.parse(Uri.parse('zhangyuzhixue://video/0')),
        isNull,
      );
      expect(
        VideoDeepLink.parse(Uri.parse('https://example.com/video/123')),
        isNull,
      );
    });
  });
}
