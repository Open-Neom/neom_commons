import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/widgets/giglist/youtube_preview_embed.dart';

void main() {
  group('YouTube preview embed helpers', () {
    test('extractYoutubeVideoId handles raw IDs, watch URLs, music URLs, and youtu.be', () {
      expect(extractYoutubeVideoId('IibXYWSBpZw'), 'IibXYWSBpZw');
      expect(
        extractYoutubeVideoId('https://music.youtube.com/watch?v=IibXYWSBpZw&list=PL123'),
        'IibXYWSBpZw',
      );
      expect(
        extractYoutubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        extractYoutubeVideoId('https://youtu.be/dQw4w9WgXcQ?t=30'),
        'dQw4w9WgXcQ',
      );
      expect(extractYoutubeVideoId('javascript:alert(1)'), '');
      expect(extractYoutubeVideoId('https://evil.example.com/watch?v=IibXYWSBpZw'), '');
    });

    test('buildYoutubePreviewEmbedUrl caps preview strictly to max 30 seconds', () {
      final url = buildYoutubePreviewEmbedUrl(
        'IibXYWSBpZw',
        startSeconds: 30,
        durationSeconds: 120, // should clamp to 30s!
      );
      expect(url, contains('https://www.youtube.com/embed/IibXYWSBpZw'));
      expect(url, contains('start=30'));
      expect(url, contains('end=60'));
      expect(url, contains('fs=0'));
      expect(url, contains('rel=0'));
    });
  });
}
