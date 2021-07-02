import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/src/picture_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

class MockPictureStreamCompleter extends PictureStreamCompleter {}

void main() {
  const String svgString = '''
<svg viewBox="0 0 10 10">
  <rect x="1" y="1" width="5" height="5" fill="black" />
</svg>
''';

  const String svgString2 = '''
<svg viewBox="0 0 10 10">
  <rect x="1" y="1" width="6" height="5" fill="black" />
</svg>
''';

  const String svgString3 = '''
<svg viewBox="0 0 10 10">
  <rect x="1" y="1" width="7" height="5" fill="black" />
</svg>
''';

  late int previousMaximumSize;
  setUp(() {
    PictureProvider.cache.clear();
    previousMaximumSize = PictureProvider.cache.maximumSize;
  });

  tearDown(() {
    PictureProvider.cache.maximumSize = previousMaximumSize;
  });

  testWidgets('Can set a limit on the PictureCache',
      (WidgetTester tester) async {
    expect(PictureProvider.cache.count, 0);

    PictureProvider.cache.maximumSize = 2;
    expect(PictureProvider.cache.count, 0);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SvgPicture.string(svgString),
    ));
    expect(PictureProvider.cache.count, 1);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SvgPicture.string(svgString2),
    ));
    expect(PictureProvider.cache.count, 2);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SvgPicture.string(svgString3),
    ));
    expect(PictureProvider.cache.count, 2);

    PictureProvider.cache.maximumSize = 1;
    expect(PictureProvider.cache.count, 1);
  });

  testWidgets('Precache test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('test_text'),
      ),
    );

    expect(PictureProvider.cache.count, 0);
    await precachePicture(
      const StringPicture(
        SvgPicture.svgStringDecoder,
        svgString,
      ),
      tester.element(find.text('test_text')),
    );
    expect(PictureProvider.cache.count, 1);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SvgPicture.string(svgString),
      ),
    );
    expect(PictureProvider.cache.count, 1);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SvgPicture.string(svgString2),
      ),
    );
    expect(PictureProvider.cache.count, 2);

    PictureProvider.cache.clear();
    expect(PictureProvider.cache.count, 0);
  });

  testWidgets('Precache - null context', (WidgetTester tester) async {
    const String svgString = '''<svg viewBox="0 0 10 10">
<rect x="1" y="1" width="5" height="5" fill="black" />
</svg>''';

    expect(PictureProvider.cache.count, 0);
    await precachePicture(
      const StringPicture(
        SvgPicture.svgStringDecoder,
        svgString,
      ),
      null,
    );
    expect(PictureProvider.cache.count, 1);
  });

  testWidgets('Precache with error', (WidgetTester tester) async {
    const String svgString = '<svg';
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text('test_text'),
      ),
    );

    bool gotError = false;
    void errorListener(Object error, StackTrace stackTrace) {
      gotError = true;
      expect(error, isInstanceOf<XmlParserException>());
    }

    await precachePicture(
      const StringPicture(
        SvgPicture.svgStringDecoder,
        svgString,
      ),
      tester.element(find.text('test_text')),
      onError: errorListener,
    );

    await null;
    expect(tester.takeException(), isInstanceOf<XmlParserException>());
    expect(gotError, isTrue);
  });

  test('Cache Tests', () {
    final PictureCache cache = PictureCache();
    expect(cache.maximumSize, equals(1000));
    cache.maximumSize = 1;
    expect(cache.maximumSize, equals(1));

    expect(() => cache.maximumSize = -1, throwsAssertionError);

    final MockPictureStreamCompleter completer1 = MockPictureStreamCompleter();
    final MockPictureStreamCompleter completer2 = MockPictureStreamCompleter();
    expect(cache.putIfAbsent(1, () => completer1), completer1);
    expect(cache.putIfAbsent(1, () => completer1), completer1);
    expect(cache.putIfAbsent(2, () => completer2), completer2);

    cache.clear();
  });
}
