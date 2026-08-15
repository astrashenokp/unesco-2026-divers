import 'package:evidence_gym_learner/features/mission/mission_media.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pack addresses media as `asset://p0-demo-pack/media/…`, which is
/// not a URL anything can fetch — it names a file inside a content pack.
/// The client shipped for days rendering only the alt text and never the
/// image, because nothing resolved that scheme.
void main() {
  test('a demo-pack reference resolves to a bundled asset', () {
    expect(
      MissionMediaView.bundledAssetFor(
          'asset://p0-demo-pack/media/flood-context-card.jpg'),
      'assets/media/flood-context-card.jpg',
    );
  });

  test('anything else resolves to nothing rather than to a guess', () {
    // A pack the app does not carry, an ordinary URL, or no media at
    // all. Each returns null so the image is simply not drawn — better
    // than a broken-image glyph implying something was lost.
    expect(MissionMediaView.bundledAssetFor(null), isNull);
    expect(MissionMediaView.bundledAssetFor('https://example.org/a.jpg'),
        isNull);
    expect(MissionMediaView.bundledAssetFor('asset://some-other-pack/a.jpg'),
        isNull);
    expect(MissionMediaView.bundledAssetFor(''), isNull);
  });
}
