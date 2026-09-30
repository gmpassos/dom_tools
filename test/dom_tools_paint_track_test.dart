@TestOn('browser')
library;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dom_tools/dom_tools_kit.dart';
import 'package:test/test.dart';

/// Integration tests (real browser) for `dom_tools_paint.dart`,
/// `perspective_filter.dart` and `dom_tools_track.dart`.

const _red = [255, 0, 0, 255];
const _green = [0, 255, 0, 255];
const _blue = [0, 0, 255, 255];
const _white = [255, 255, 255, 255];

CanvasRenderingContext2D _ctx(HTMLCanvasElement c) =>
    c.getContext('2d') as CanvasRenderingContext2D;

/// A [size]x[size] canvas: top-left red, top-right green, bottom-left blue,
/// bottom-right white.
HTMLCanvasElement _quadrants([int width = 40, int height = 40]) {
  final c = HTMLCanvasElement()
    ..width = width
    ..height = height;
  final ctx = _ctx(c);
  final w = width ~/ 2;
  final h = height ~/ 2;
  void fill(String color, int x, int y) {
    ctx.fillStyle = color.toJS;
    ctx.fillRect(x, y, w, h);
  }

  fill('rgb(255,0,0)', 0, 0);
  fill('rgb(0,255,0)', w, 0);
  fill('rgb(0,0,255)', 0, h);
  fill('rgb(255,255,255)', w, h);
  return c;
}

HTMLCanvasElement _solid(int width, int height, String color) {
  final c = HTMLCanvasElement()
    ..width = width
    ..height = height;
  final ctx = _ctx(c);
  ctx.fillStyle = color.toJS;
  ctx.fillRect(0, 0, width, height);
  return c;
}

List<int> _px(HTMLCanvasElement c, int x, int y) =>
    _ctx(c).getImageData(x, y, 1, 1).data.toDart.toList();

Matcher _closeToPx(List<int> expected, [int tolerance = 40]) =>
    predicate<List<int>>((actual) {
      for (var i = 0; i < 4; i++) {
        if ((actual[i] - expected[i]).abs() > tolerance) return false;
      }
      return true;
    }, 'pixel close to $expected (±$tolerance)');

/// Attaches [c] to the document at a 1:1 CSS size, removed after the test.
HTMLCanvasElement _attach(HTMLCanvasElement c, [int? width, int? height]) {
  final holder = HTMLDivElement()..style.position = 'relative';
  c.style
    ..display = 'block'
    ..width = '${width ?? c.width}px'
    ..height = '${height ?? c.height}px';
  holder.appendChild(c);
  document.body!.appendChild(holder);
  addTearDown(() => holder.remove());
  return c;
}

/// A new attached canvas for a [CanvasImageViewer] of [width]x[height].
HTMLCanvasElement _viewerCanvas([int width = 40, int height = 40]) => _attach(
  HTMLCanvasElement()
    ..width = width
    ..height = height,
  width,
  height,
);

int _changedPixels(
  HTMLCanvasElement before,
  HTMLCanvasElement after,
  Rectangle<int> area,
) {
  var changed = 0;
  for (var y = area.top; y < area.top + area.height; y++) {
    for (var x = area.left; x < area.left + area.width; x++) {
      final a = _px(before, x, y);
      final b = _px(after, x, y);
      for (var i = 0; i < 4; i++) {
        if (a[i] != b[i]) {
          changed++;
          break;
        }
      }
    }
  }
  return changed;
}

Future<void> _delay([int ms = 0]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Future<HTMLImageElement> _loadedImage(HTMLCanvasElement c) async {
  final img = createImageElementFromBase64(c.toDataUrl('image/png'))!;
  if (!img.complete || img.naturalWidth == 0) {
    await img.onLoad.first;
  }
  return img;
}

void main() {
  group('CanvasImageViewer: private named parameters (Dart 3.12)', () {
    test('every named argument is honored', () {
      final filtered = <List<Object?>>[];
      final green = _solid(40, 40, 'rgb(0,255,0)');

      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        imageFilter: (image, w, h) {
          filtered.add([image, w, h]);
          return green;
        },
        clip: CanvasImageViewer.clipViewerElement(Rectangle(1, 2, 3, 4)),
        rectangles: CanvasImageViewer.rectanglesViewerElement([
          Rectangle(5, 6, 7, 8),
        ]),
        points: CanvasImageViewer.pointsViewerElement([Point(9, 10)]),
        labels: CanvasImageViewer.labelsViewerElement([Label('l', 1, 1, 2, 2)]),
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
        gridSize: CanvasImageViewer.gridSizeViewerElement(10),
      );

      expect(filtered.length, equals(1));
      expect(filtered.single.sublist(1), equals([40, 40]));

      expect(viewer.clip, equals(Rectangle(1, 2, 3, 4)));
      expect(viewer.rectangles, equals([Rectangle(5, 6, 7, 8)]));
      expect(viewer.points, equals([Point(9, 10)]));
      expect(viewer.labels!.single.label, equals('l'));
      expect(viewer.perspective!.length, equals(4));
      expect(viewer.gridSize, equals(10));

      expect(viewer.clipKey, equals('clip'));
      expect(viewer.rectanglesKey, equals('rectangles'));
      expect(viewer.pointsKey, equals('points'));
      expect(viewer.labelsKey, equals('labels'));
      expect(viewer.perspectiveKey, equals('perspective'));
      expect(viewer.gridSizeKey, equals('gridSize'));
    });

    test('omitted named arguments are null', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
      );
      expect(viewer.clip, isNull);
      expect(viewer.rectangles, isNull);
      expect(viewer.points, isNull);
      expect(viewer.labels, isNull);
      expect(viewer.perspective, isNull);
      expect(viewer.gridSize, isNull);
      expect(viewer.width, equals(40));
      expect(viewer.height, equals(40));
      expect(viewer.isEditable, isFalse);
      expect(viewer.editionType, isNull);
      expect(viewer.cropPerspective, isTrue);
      expect(viewer.time, isNull);
    });

    test('imageFilter result is rendered', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        imageFilter: (image, w, h) => _solid(w, h, 'rgb(0,255,0)'),
      );
      viewer.render();
      expect(_px(viewer.canvas, 5, 5), equals(_green));
      expect(_px(viewer.canvas, 35, 35), equals(_green));
    });

    test('custom keys', () {
      final clip = CanvasImageViewer.clipViewerElement(Rectangle(0, 0, 5, 5))
        ..key = 'myClip';
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        clip: clip,
      );
      expect(viewer.clipKey, equals('myClip'));
    });
  });

  group('CanvasImageViewer: rendering', () {
    test('plain image', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
      );
      expect(viewer.inDOM, isTrue);
      viewer.render();
      expect(_px(viewer.canvas, 10, 10), equals(_red));
      expect(_px(viewer.canvas, 30, 10), equals(_green));
      expect(_px(viewer.canvas, 10, 30), equals(_blue));
      expect(_px(viewer.canvas, 30, 30), equals(_white));
    });

    test('clip shades the outside and keeps the inside', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        clip: CanvasImageViewer.clipViewerElement(Rectangle(10, 10, 20, 20)),
      );
      viewer.render();
      // Inside the clip:
      expect(_px(viewer.canvas, 15, 15), equals(_red));
      expect(_px(viewer.canvas, 25, 25), equals(_white));
      // Outside: black shadow at 40% over red (255 * 0.6 = 153):
      expect(_px(viewer.canvas, 3, 3), _closeToPx([153, 0, 0, 255], 3));
      expect(_px(viewer.canvas, 36, 36), _closeToPx([153, 153, 153, 255], 3));
    });

    test('clip outside the image is not rendered', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        clip: CanvasImageViewer.clipViewerElement(Rectangle(100, 100, 10, 10)),
      );
      viewer.render();
      expect(_px(viewer.canvas, 3, 3), equals(_red));
    });

    test('rectangles are stroked with their color', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        rectangles: CanvasImageViewer.rectanglesViewerElement([
          Rectangle(5, 5, 20, 20),
        ], Color.BLUE),
      );
      viewer.render();
      expect(_px(viewer.canvas, 5, 15), equals(_blue));
      expect(_px(viewer.canvas, 15, 15), equals(_red));
    });

    test('rectangles default to green', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        rectangles: CanvasImageViewer.rectanglesViewerElement([
          Rectangle(5, 5, 20, 20),
        ]),
      );
      viewer.render();
      expect(_px(viewer.canvas, 5, 15), equals(_green));
    });

    test('labels are stroked (label color over element color)', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        labels: CanvasImageViewer.labelsViewerElement([
          Label('a', 5, 5, 20, 20),
          Label('b', 25, 25, 10, 10, Color.BLUE),
        ], Color.GREEN),
      );
      viewer.render();
      expect(_px(viewer.canvas, 5, 15), equals(_green));
      expect(_px(viewer.canvas, 25, 30), equals(_blue));
      expect(_px(viewer.canvas, 15, 15), equals(_red));
    });

    test('points are drawn around their position only', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        points: CanvasImageViewer.pointsViewerElement([
          Point(10, 10),
        ], Color.BLUE),
      );
      viewer.render();
      final original = _quadrants();
      expect(
        _changedPixels(original, viewer.canvas, Rectangle(4, 4, 13, 13)),
        greaterThan(10),
      );
      expect(_px(viewer.canvas, 30, 30), equals(_white));
      expect(_px(viewer.canvas, 1, 30), equals(_blue));
    });

    test('grid lines (int and ratio sizes)', () {
      for (final gridSize in <num>[10, 0.25]) {
        final viewer = CanvasImageViewer(
          canvas: _viewerCanvas(),
          image: _quadrants(),
          gridSize: CanvasImageViewer.gridSizeViewerElement(
            gridSize,
            Color.BLUE,
          ),
        );
        viewer.render();
        expect(_px(viewer.canvas, 10, 5), equals(_blue), reason: '$gridSize');
        expect(_px(viewer.canvas, 5, 10), equals(_blue), reason: '$gridSize');
        expect(_px(viewer.canvas, 5, 5), equals(_red), reason: '$gridSize');
        expect(_px(viewer.canvas, 15, 5), equals(_red), reason: '$gridSize');
      }
    });

    test('tiny grid sizes are raised to the minimum', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        gridSize: CanvasImageViewer.gridSizeViewerElement(1, Color.BLUE),
      );
      viewer.render();
      // Minimum size is 6 (lineWidth 2 * 3): lines at 6, 12, ...
      expect(_px(viewer.canvas, 6, 3), equals(_blue));
      expect(_px(viewer.canvas, 2, 3), equals(_red));
    });

    test('time is drawn at the bottom', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(200, 60),
        image: _quadrants(200, 60),
        time: DateTime(2024, 1, 2, 3, 4, 5),
      );
      viewer.render();
      expect(
        _changedPixels(
          _quadrants(200, 60),
          viewer.canvas,
          Rectangle(0, 35, 200, 25),
        ),
        greaterThan(50),
      );
      expect(_px(viewer.canvas, 150, 5), equals(_green));
    });

    test('identity perspective keeps the image', () async {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
      );
      viewer.render();
      expect(_px(viewer.canvas, 10, 10), _closeToPx(_red));
      expect(_px(viewer.canvas, 30, 10), _closeToPx(_green));
      expect(_px(viewer.canvas, 10, 30), _closeToPx(_blue));
      expect(_px(viewer.canvas, 30, 30), _closeToPx(_white));

      // A later (higher quality) render keeps the same content:
      await _delay(300);
      expect(_px(viewer.canvas, 10, 10), _closeToPx(_red));
      expect(_px(viewer.canvas, 30, 30), _closeToPx(_white));
    });

    test('perspective with maxWidth/maxHeight limits the rendered size', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        maxWidth: 20,
        maxHeight: 30,
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
      );
      viewer.render();
      expect(viewer.canvas.width, equals(20));
      expect(viewer.canvas.height, equals(30));
    });

    test('perspective with maxWidth centered on the clip', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        maxWidth: 20,
        clip: CanvasImageViewer.clipViewerElement(Rectangle(20, 0, 20, 40)),
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
      );
      viewer.render();
      expect(viewer.canvas.width, equals(20));
    });

    test('non-cropped perspective (editable perspective)', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        editable: EditionType.perspective,
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
      );
      expect(viewer.cropPerspective, isFalse);
      viewer.render();
      expect(_px(viewer.canvas, 10, 10), _closeToPx(_red));
    });

    test(
      'an HTMLImageElement is re-rendered with its size when loaded',
      () async {
        final img = createImageElementFromBase64(
          _quadrants(30, 20).toDataUrl('image/png'),
        )!;
        final viewer = CanvasImageViewer(
          canvas: _viewerCanvas(30, 20),
          image: img,
        );
        await img.onLoad.first;
        await _delay();
        expect(viewer.width, equals(30));
        expect(viewer.height, equals(20));
        expect(viewer.canvas.width, equals(30));
        expect(_px(viewer.canvas, 5, 5), equals(_red));
      },
    );

    test('render() of a detached viewer is deferred', () {
      final viewer = CanvasImageViewer(
        canvas: HTMLCanvasElement()
          ..width = 40
          ..height = 40,
        image: _quadrants(),
      );
      expect(viewer.inDOM, isFalse);
      expect(viewer.offsetWidthRatio, equals(0));
      expect(viewer.offsetHeightRatio, equals(0));
      viewer.render();
      expect(_px(viewer.canvas, 10, 10), equals([0, 0, 0, 0]));
    });

    test('renderAsync', () async {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
      );
      viewer.renderAsync(Duration(milliseconds: 10));
      expect(_px(viewer.canvas, 10, 10), equals([0, 0, 0, 0]));
      await _delay(50);
      expect(_px(viewer.canvas, 10, 10), equals(_red));
    });

    test('render scale getters', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
      );
      expect(viewer.offsetWidthRatio, equals(1));
      expect(viewer.offsetHeightRatio, equals(1));
      expect(viewer.offsetRenderScale, equals(1));
      expect(viewer.isOffsetRenderScaleGoodForHighQuality, isTrue);
      expect(viewer.renderScaleQualityLow, closeTo(0.40, 0.0001));
      expect(viewer.renderScaleQualityMedium, closeTo(1.05, 0.0001));
      expect(viewer.renderScaleQualityHigh, equals(1));
    });

    test('canvasSizeSameOfRenderedImageSize: false keeps the canvas size', () {
      final canvas = _viewerCanvas(50, 50);
      final viewer = CanvasImageViewer(
        canvas: canvas,
        width: 40,
        height: 40,
        canvasSizeSameOfRenderedImageSize: false,
        image: _quadrants(),
      );
      expect(viewer.width, equals(40));
      expect(viewer.canvas.width, equals(40));
    });
  });

  group('CanvasImageViewer: edition', () {
    test('points: click adds, click near removes; onChange fires', () async {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        points: CanvasImageViewer.pointsViewerElement([]),
        editable: EditionType.points,
      );
      final changes = <Object?>[];
      viewer.onChange.listen(changes.add);

      expect(viewer.isEditable, isTrue);
      expect(viewer.editionType, equals(EditionType.points));

      expect(viewer.interact(Point(10, 10), true), equals(Quality.high));
      expect(viewer.points, equals([Point(10, 10)]));

      expect(viewer.interact(Point(30, 30), true), equals(Quality.high));
      expect(viewer.points!.length, equals(2));

      viewer.interact(Point(12, 11), true);
      expect(viewer.points, equals([Point(30, 30)]));

      // Not a click: no edition.
      expect(viewer.interact(Point(5, 5), false), isNull);

      await _delay();
      expect(changes.length, equals(3));
    });

    test('rectangles: click inside removes', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        rectangles: CanvasImageViewer.rectanglesViewerElement([
          Rectangle(0, 0, 10, 10),
          Rectangle(20, 20, 10, 10),
        ]),
        editable: EditionType.rectangles,
      );
      viewer.interact(Point(15, 15), true);
      expect(viewer.rectangles!.length, equals(2));
      viewer.interact(Point(25, 25), true);
      expect(viewer.rectangles, equals([Rectangle(0, 0, 10, 10)]));
      expect(viewer.adjustRectangles(Point(5, 5), false), isNull);
    });

    test('labels: hover shows a hint, click removes', () {
      final canvas = _viewerCanvas();
      final viewer = CanvasImageViewer(
        canvas: canvas,
        image: _quadrants(),
        labels: CanvasImageViewer.labelsViewerElement([
          Label('my-label', 0, 0, 10, 10),
        ]),
        editable: EditionType.labels,
      );

      expect(viewer.interact(Point(5, 5), false), equals(Quality.high));
      expect(canvas.parentElement!.textContent, contains('my-label'));

      viewer.interact(Point(5, 5), true);
      expect(viewer.labels, isEmpty);
      expect(canvas.parentElement!.textContent, isNot(contains('my-label')));
    });

    test('labels: hint follows the pointer (not editable)', () async {
      final canvas = _viewerCanvas();
      final viewer = CanvasImageViewer(
        canvas: canvas,
        image: _quadrants(),
        labels: CanvasImageViewer.labelsViewerElement([
          Label('hover', 0, 0, 10, 10),
        ]),
      );
      viewer.render();

      expect(viewer.showLabel(Point(5, 5)), equals(Quality.high));
      expect(canvas.parentElement!.textContent, contains('hover'));

      viewer.showLabel(Point(30, 30));
      await _delay(500);
      expect(canvas.parentElement!.textContent, isNot(contains('hover')));
    });

    test('showHint / hideHint', () {
      final canvas = _viewerCanvas();
      final viewer = CanvasImageViewer(canvas: canvas, image: _quadrants());
      viewer.showHint('h1', Point(5, 5));
      viewer.showHintAtRectangle('h2', Rectangle(0, 0, 10, 10));
      expect(canvas.parentElement!.textContent, contains('h2'));
      expect(canvas.parentElement!.textContent, isNot(contains('h1')));
      viewer.hideHint();
      expect(canvas.parentElement!.textContent, isNot(contains('h2')));
      viewer.hideHint();
    });

    test('clip: dragging the left edge moves it', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        clip: CanvasImageViewer.clipViewerElement(Rectangle(10, 10, 20, 20)),
        editable: EditionType.clip,
      );
      expect(viewer.interact(Point(5, 15), false), equals(Quality.high));
      expect(viewer.clip, equals(Rectangle(5, 10, 25, 20)));

      // Top edge:
      viewer.interact(Point(15, 4), false);
      expect(viewer.clip, equals(Rectangle(5, 4, 25, 26)));

      // Right edge:
      viewer.interact(Point(36, 15), false);
      expect(viewer.clip, equals(Rectangle(5, 4, 31, 26)));

      // Bottom edge:
      viewer.interact(Point(15, 38), false);
      expect(viewer.clip, equals(Rectangle(5, 4, 31, 34)));

      // A click doesn't edit the clip:
      expect(viewer.adjustClip(Point(1, 1), true), isNull);
    });

    test('perspective: moving a corner', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        perspective: CanvasImageViewer.perspectiveViewerElement([
          Point(0, 0),
          Point(40, 0),
          Point(40, 40),
          Point(0, 40),
        ]),
        editable: EditionType.perspective,
      );
      expect(viewer.interact(Point(8, 6), true), equals(Quality.medium));
      final p = viewer.perspective!;
      expect(p.length, equals(4));
      expect(p[0], isNot(equals(Point(0, 0))));
      expect(p[2], equals(Point(40, 40)));
    });

    test('perspective: default points when missing', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        perspective: CanvasImageViewer.perspectiveViewerElement(null),
        editable: EditionType.perspective,
      );
      expect(viewer.adjustPerspective(Point(20, 2), false), isNotNull);
      expect(viewer.perspective!.length, equals(4));
    });

    test('not editable: edit() returns null', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
        points: CanvasImageViewer.pointsViewerElement([]),
      );
      expect(viewer.edit(Point(1, 1), true), isNull);
      expect(viewer.points, isEmpty);
    });

    test('DOM mouse events drive the edition', () async {
      final canvas = _viewerCanvas();
      final viewer = CanvasImageViewer(
        canvas: canvas,
        image: _quadrants(),
        clip: CanvasImageViewer.clipViewerElement(Rectangle(10, 10, 20, 20)),
        editable: EditionType.clip,
      );
      viewer.render();
      final changes = <Object?>[];
      viewer.onChange.listen(changes.add);

      final r = canvas.getBoundingClientRect();
      MouseEvent mouse(String type, num x, num y) => MouseEvent(
        type,
        MouseEventInit(
          clientX: (r.left + x).toInt(),
          clientY: (r.top + y).toInt(),
        ),
      );

      canvas.dispatchEvent(mouse('mousedown', 5, 15));
      canvas.dispatchEvent(mouse('mousemove', 4, 15));
      canvas.dispatchEvent(mouse('mouseup', 4, 15));
      canvas.dispatchEvent(mouse('mousemove', 1, 15));
      canvas.dispatchEvent(mouse('click', 1, 15));
      canvas.dispatchEvent(mouse('mouseleave', 1, 15));

      await _delay();
      expect(viewer.clip, equals(Rectangle(4, 10, 26, 20)));
      expect(changes.length, equals(2));
    });
  });

  group('CanvasImageViewer: static helpers', () {
    test('clip viewer elements', () {
      expect(
        CanvasImageViewer.clipViewerElementFromNums([1, 2, 3, 4]).value,
        equals(Rectangle(1, 2, 3, 4)),
      );
      expect(
        CanvasImageViewer.clipViewerElementFromNums(['1', '2', '3', '4']).value,
        equals(Rectangle(1, 2, 3, 4)),
      );
      expect(CanvasImageViewer.clipViewerElementFromNums(null).isNull, isTrue);
      expect(
        CanvasImageViewer.clipViewerElementFromMap({
          'x': 1,
          'top': 2,
          'w': 3,
          'height': 4,
        }).value,
        equals(Rectangle(1, 2, 3, 4)),
      );
      expect(CanvasImageViewer.clipViewerElementFromMap(null).isNull, isTrue);

      final e = CanvasImageViewer.clipViewerElement(
        Rectangle(1, 2, 3, 4),
        Color.RED,
      );
      expect(e.color, equals(Color.RED));
      final copy = e.valueCopy!;
      expect(copy, equals(Rectangle(1, 2, 3, 4)));
      expect(identical(copy, e.value), isFalse);
      expect(CanvasImageViewer.clipViewerElement(null).valueCopy, isNull);
    });

    // Regression: a `String` entry ('13,14,15,16') threw a `TypeError`
    // (swiss_knife's `parseNumsFromInlineList`).
    test('rectangles viewer elements', () {
      final e = CanvasImageViewer.rectanglesViewerElementFromNums(
        [
          {'x': 1, 'y': 2, 'width': 3, 'height': 4},
          {'left': 5, 'top': 6, 'w': 7, 'h': 8},
          [9, 10, 11, 12],
          '13,14,15,16',
        ],
        Color.BLUE,
        2,
      );
      expect(e.value, [
        Rectangle(1, 2, 3, 4),
        Rectangle(5, 6, 7, 8),
        Rectangle(9, 10, 11, 12),
        Rectangle(13, 14, 15, 16),
      ]);
      expect(e.strokeSize, equals(2));
      expect(e.color, equals(Color.BLUE));
      expect(
        () => CanvasImageViewer.rectanglesViewerElementFromNums([1]),
        throwsArgumentError,
      );

      final copy = e.valueCopy!;
      copy.clear();
      expect(e.value!.length, equals(4));
    });

    test('labels viewer elements', () {
      final e = CanvasImageViewer.labelsViewerElementFromNums([
        {'label': 'a', 'x': 1, 'y': 2, 'width': 3, 'height': 4},
        {'title': 'b', 'left': 5, 'top': 6, 'w': 7, 'h': 8},
        ['c', 9, 10, 11, 12],
        'd,13,14,15,16',
      ]);
      expect(e.value!.map((l) => l.label), equals(['a', 'b', 'c', 'd']));
      expect(e.value![3], equals(Rectangle(13, 14, 15, 16)));
      expect(
        () => CanvasImageViewer.labelsViewerElementFromNums([1]),
        throwsArgumentError,
      );
      final copy = e.valueCopy!;
      expect(copy.first.label, equals('a'));
      expect(identical(copy.first, e.value!.first), isFalse);
    });

    test('points / grid / perspective viewer elements', () {
      final points = CanvasImageViewer.pointsViewerElement([Point(1, 2)]);
      expect(points.valueCopy, equals([Point(1, 2)]));

      final grid = CanvasImageViewer.gridSizeViewerElement(5, Color.RED);
      expect(grid.valueCopy, equals(5));
      expect(grid.isEmpty, isFalse);

      final perspective = CanvasImageViewer.perspectiveViewerElementFromNums([
        0,
        0,
        10,
        0,
        10,
        10,
        0,
        10,
      ]);
      expect(perspective.value, [
        Point(0, 0),
        Point(10, 0),
        Point(10, 10),
        Point(0, 10),
      ]);
      expect(
        CanvasImageViewer.perspectiveViewerElementFromNums(null).isNull,
        isTrue,
      );
    });

    test('nearestRectangle / nearestPoint / getRectangleCenter', () {
      final viewer = CanvasImageViewer(
        canvas: _viewerCanvas(),
        image: _quadrants(),
      );
      expect(
        CanvasImageViewer.getRectangleCenter(Rectangle(0, 0, 10, 20)),
        equals(Point(5, 10)),
      );
      expect(viewer.nearestRectangle([], Point(0, 0)), isNull);
      expect(
        viewer.nearestRectangle([
          Rectangle(0, 0, 10, 10),
          Rectangle(30, 30, 10, 10),
        ], Point(28, 28)),
        equals(Rectangle(30, 30, 10, 10)),
      );
      expect(viewer.nearestPoint(null, Point(0, 0)), isNull);
      expect(viewer.nearestPoint([], Point(0, 0)), isNull);
      expect(
        viewer.nearestPoint([Point(0, 0), Point(10, 10)], Point(8, 8)),
        equals(Point(10, 10)),
      );
    });
  });

  group('ViewerElement / Label', () {
    test('ViewerElement', () {
      final e = ViewerElement<List<int>>([1], Color.RED, strokeSize: 0);
      expect(e.strokeSize, isNull);
      expect(e.isNull, isFalse);
      expect(e.isNotEmpty, isTrue);
      expect(e.valueCopy, isNull, reason: 'no valueCopier');
      expect(e.toString(), contains('value: [1]'));
      e.key = 'k';
      expect(e.toString(), contains('key: k'));
      expect(ViewerElement<List<int>>([], null).isEmpty, isTrue);
      expect(ViewerElement<int>(1, null, strokeSize: 3).strokeSize, equals(3));
    });

    test('Label', () {
      final l = Label('x', 1, 2, 3, 4);
      expect(
        l.asMap(),
        equals({'label': 'x', 'x': 1, 'y': 2, 'width': 3, 'height': 4}),
      );
      expect(l.toString(), contains('label: x'));
      expect(l.toString(), isNot(contains('color')));

      l.color = Color.RED;
      expect(l.asMap()['color'], equals(Color.RED));
      expect(l.toString(), contains('color:'));
    });
  });

  group('image helpers', () {
    test('getImageDimension', () async {
      expect(getImageDimension(_quadrants(30, 20)), Rectangle(0, 0, 30, 20));

      final img = await _loadedImage(_quadrants(30, 20));
      expect(getImageDimension(img), equals(Rectangle(0, 0, 30, 20)));

      final video = HTMLVideoElement()
        ..width = 12
        ..height = 8;
      expect(getImageDimension(video), equals(Rectangle(0, 0, 12, 8)));
    });

    test('cropImage from a canvas and from an image', () async {
      final fromCanvas = cropImage(_quadrants(), 20, 0, 20, 20)!;
      expect(fromCanvas.width, equals(20));
      expect(_px(fromCanvas, 0, 0), equals(_green));
      expect(_px(fromCanvas, 19, 19), equals(_green));

      final img = await _loadedImage(_quadrants());
      final fromImage = cropImage(img, 0, 20, 20, 20)!;
      expect(_px(fromImage, 5, 5), equals(_blue));
    });

    test('cropImageByRectangle', () {
      expect(cropImageByRectangle(_quadrants(), null), isNull);
      final crop = cropImageByRectangle(
        _quadrants(),
        Rectangle(20, 20, 20, 20),
      )!;
      expect(_px(crop, 10, 10), equals(_white));
    });

    // Regression: `cropImageByRectangle` cast `crop.left`/`top`/`width`/
    // `height` with `as int`, throwing for a `Rectangle<double>` (always with
    // dart2wasm; with dart2js for non-integral values).
    test('cropImageByRectangle with a Rectangle<double>', () {
      final crop = cropImageByRectangle(
        _quadrants(),
        Rectangle<double>(20.0, 0.0, 20.5, 20.5),
      )!;
      expect(crop.width, equals(20));
      expect(crop.height, equals(20));
      expect(_px(crop, 10, 10), equals(_green));
    });

    test('createScaledImage', () {
      final scaled =
          createScaledImage(_quadrants(), 40, 40, 0.5) as HTMLCanvasElement;
      expect(scaled.width, equals(20));
      expect(scaled.height, equals(20));
      expect(_px(scaled, 2, 2), equals(_red));
      expect(_px(scaled, 17, 17), equals(_white));
    });

    test('createImageElementFromBase64', () async {
      expect(createImageElementFromBase64(null), isNull);
      expect(createImageElementFromBase64(''), isNull);

      final dataUrl = _quadrants().toDataUrl('image/png');
      final raw = dataUrl.substring(dataUrl.indexOf(',') + 1);

      expect(
        createImageElementFromBase64(raw)!.src,
        startsWith('data:image/jpeg;base64,'),
      );
      expect(
        createImageElementFromBase64(raw, ' ')!.src,
        startsWith('data:image/jpeg;base64,'),
      );
      final png = createImageElementFromBase64(raw, 'image/png')!;
      expect(png.src, startsWith('data:image/png;base64,'));
      await png.onLoad.first;
      expect(png.naturalWidth, equals(40));

      expect(createImageElementFromBase64(dataUrl)!.src, equals(dataUrl));
    });

    test('createImageElementFromFile', () async {
      final blob = await _quadrants(30, 20).asBlob(type: 'image/png');
      final file = File(
        <JSAny>[blob].toJS,
        'q.png',
        FilePropertyBag(type: 'image/png'),
      );
      final img = await createImageElementFromFile(file);
      expect(img.src, startsWith('data:image/png'));
      if (img.naturalWidth == 0) await img.onLoad.first;
      expect(img.naturalWidth, equals(30));
      expect(img.naturalHeight, equals(20));
    });

    test('points helpers', () {
      expect(numsToPoints([1, 2, 3, 4, 5]), equals([Point(1, 2), Point(3, 4)]));
      final points = [Point<num>(1, 2), Point<num>(3, 4)];
      final copy = copyPoints(points);
      expect(copy, equals(points));
      expect(identical(copy.first, points.first), isFalse);
      expect(scalePoints(points, 2), equals([Point(2, 4), Point(6, 8)]));
      expect(scalePointsXY(points, 2, 3), equals([Point(2, 6), Point(6, 12)]));
      expect(
        translatePoints(points, 10, -1),
        equals([Point(11, 1), Point(13, 3)]),
      );
    });

    test('toCanvasElement / canvasToImageElement', () async {
      final img = await _loadedImage(_quadrants());
      final canvas = toCanvasElement(img, 40, 40);
      expect(_px(canvas, 30, 10), equals(_green));

      final img2 = canvasToImageElement(_quadrants(30, 20));
      expect(img2.src, startsWith('data:image/png'));
      expect(img2.width, equals(30));
      expect(img2.height, equals(20));

      final jpeg = canvasToImageElement(_quadrants(), 'image/jpeg', 0.5);
      expect(jpeg.src, startsWith('data:image/jpeg'));
    });

    test('rotateCanvasImageSource / rotateImageElement (90°)', () async {
      final rotated = rotateCanvasImageSource(_quadrants(), 40, 40);
      // Clockwise: top-left (red) -> top-right; bottom-left (blue) -> top-left.
      expect(_px(rotated, 30, 10), equals(_red));
      expect(_px(rotated, 10, 10), equals(_blue));
      expect(_px(rotated, 10, 30), equals(_white));

      final wide = rotateCanvasImageSource(_quadrants(40, 20), 40, 20, 90);
      expect(wide.width, equals(20));
      expect(wide.height, equals(40));

      final img = canvasToImageElement(_quadrants(40, 20));
      await img.onLoad.first;
      final rotatedImg = rotateImageElement(img);
      expect(rotatedImg.width, equals(20));
      expect(rotatedImg.height, equals(40));
    });
  });

  group('ImageScaledCache', () {
    test('scales, caches and limits entries', () {
      final image = _quadrants();
      final cache = ImageScaledCache(image);
      expect(cache.width, equals(40));
      expect(cache.height, equals(40));
      expect(cache.maxScaleCacheEntries, equals(2));
      expect((cache.image as JSAny).strictEquals(image).toDart, isTrue);

      expect(cache.getImageScaled(0), isNull);
      expect(cache.isImageScaledInCache(-1), isFalse);
      expect(cache.isImageScaledInCache(1.0), isTrue);
      expect(
        (cache.getImageScaled(1.0)! as JSAny).strictEquals(image).toDart,
        isTrue,
      );

      final half = cache.getImageScaled(0.5)! as HTMLCanvasElement;
      expect(half.width, equals(20));
      expect(cache.isImageScaledInCache(0.5), isTrue);
      expect(
        (cache.getImageScaled(0.5)! as JSAny).strictEquals(half).toDart,
        isTrue,
      );

      cache.getImageScaled(0.25);
      cache.getImageScaled(0.75);
      expect(cache.isImageScaledInCache(0.5), isFalse, reason: 'evicted');
      expect(cache.isImageScaledInCache(0.25), isTrue);
      expect(cache.isImageScaledInCache(0.75), isTrue);

      cache.clearScaleCache();
      expect(cache.isImageScaledInCache(0.25), isFalse);
    });

    test('explicit size and max entries', () {
      final cache = ImageScaledCache(_quadrants(), 10, 20, 5);
      expect(cache.width, equals(10));
      expect(cache.height, equals(20));
      expect(cache.maxScaleCacheEntries, equals(5));
      expect(ImageScaledCache(_quadrants(), 1, 1, 0).maxScaleCacheEntries, 2);
    });

    test('limitEntries', () {
      expect(ImageScaledCache.limitEntries({}, 1), equals(0));
      final map = {1: 'a', 2: 'b', 3: 'c'};
      expect(ImageScaledCache.limitEntries(map, 1), equals(2));
      expect(map, equals({3: 'c'}));
      expect(ImageScaledCache.limitEntries(map, -1), equals(1));
      expect(map, isEmpty);
    });
  });

  group('ImagePerspectiveFilter', () {
    // `filter` writes the output pixels with `ImageData.data.set(...)`, from
    // a `Uint8ClampedList` converted with `.toJS` (a JS `Uint8ClampedArray`).
    test('Uint8ClampedList.toJS is a JS Uint8ClampedArray', () {
      final list = Uint8ClampedList.fromList([1, 2, 300]);
      final js = list.toJS;
      expect(js.isA<JSUint8ClampedArray>(), isTrue);
      expect(js.toDart, equals([1, 2, 255]));
    });

    test('identity transform keeps the pixels', () {
      final image = _quadrants();
      final filter = ImagePerspectiveFilter(image, 40, 40)
        ..setCorners(0, 0, 40, 0, 40, 40, 0, 40);
      final result = filter.filter()!;

      expect(result.resultWidth, equals(40));
      expect(result.resultHeight, equals(40));
      expect((result.imageSource! as JSAny).strictEquals(image).toDart, isTrue);

      final out = result.imageResult;
      for (final (x, y, px) in [
        (5, 5, _red),
        (15, 15, _red),
        (25, 5, _green),
        (35, 15, _green),
        (5, 25, _blue),
        (15, 35, _blue),
        (25, 25, _white),
        (35, 35, _white),
      ]) {
        expect(_px(out, x, y), equals(px), reason: '($x, $y)');
      }

      expect(result.crop, equals(Rectangle(0, 0, 40, 40)));
      expect(result.translation, equals(Point(0, 0)));
    });

    test('a horizontal squeeze maps pixels as expected', () {
      // The image is mapped to x = 10..40: the output (30 wide) spans the
      // whole source width, so source x = output x * 40 / 30.
      final filter = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCorners(10, 0, 40, 0, 40, 40, 10, 40);
      final result = filter.filter()!;
      final out = result.imageResult;

      expect(_px(out, 5, 5), equals(_red));
      expect(_px(out, 25, 5), equals(_green));
      expect(_px(out, 5, 30), equals(_blue));
      expect(_px(out, 25, 30), equals(_white));
      // Output is 30 wide; the rest of the (40 wide) result canvas is empty:
      expect(_px(out, 35, 5), equals([0, 0, 0, 0]));

      expect(result.crop, equals(Rectangle(0, 0, 30, 40)));
      final cropped = result.imageResultCropped!;
      expect(cropped.width, equals(30));
      expect(cropped.height, equals(40));
      expect(_px(cropped, 25, 30), equals(_white));
    });

    test('a trapezoid (non-affine) transform', () {
      final filter = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCorners(5, 0, 35, 0, 40, 40, 0, 40);
      final result = filter.filter()!;
      expect(result.resultWidth, equals(40));
      expect(result.resultHeight, equals(40));
      // Image center stays inside the image (between the quadrants):
      expect(_px(result.imageResult, 10, 30), _closeToPx(_blue, 60));
      expect(_px(result.imageResult, 30, 30), _closeToPx(_white, 60));
    });

    test('all corner setters are equivalent', () {
      List<int> sample(ImagePerspectiveFilter f) =>
          _px(f.filter()!.imageResult, 25, 30);

      final a = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCornersFromInts(10, 0, 40, 0, 40, 40, 10, 40);
      final b = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCornersFromPoints(
          Point(10, 0),
          Point(40, 0),
          Point(40, 40),
          Point(10, 40),
        );
      final c = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCornersFromNumList([10, 0, 40, 0, 40, 40, 10, 40]);
      final d = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCornersFromPointsList([
          Point(10, 0),
          Point(40, 0),
          Point(40, 40),
          Point(10, 40),
        ]);
      final e = ImagePerspectiveFilter(_quadrants(), 40, 40)
        ..setCornersFromDimensionRatio(0.25, 0, 1, 0, 1, 1, 0.25, 1);

      for (final f in [a, b, c, d, e]) {
        expect(sample(f), equals(_white));
      }
    });

    test('into a given result canvas', () {
      final target = HTMLCanvasElement()
        ..width = 60
        ..height = 60;
      final result = (ImagePerspectiveFilter(
        _quadrants(),
        40,
        40,
      )..setCorners(0, 0, 40, 0, 40, 40, 0, 40)).filter(target)!;
      expect((result.imageResult as JSAny).strictEquals(target).toDart, isTrue);
      expect(result.resultWidth, equals(60));
      expect(_px(target, 5, 5), equals(_red));
    });

    test('an empty image is not filtered', () {
      final filter = ImagePerspectiveFilter(_quadrants(), 0, 0)
        ..setCorners(0, 0, 0, 0, 0, 0, 0, 0);
      expect(filter.filter(), isNull);
    });

    test('FilterResult', () {
      final image = _quadrants();
      final result = FilterResult(image, _quadrants(), Rectangle(2, 4, 10, 10));
      expect(result.translation, equals(Point(2, 4)));
      expect(result.translationScaled(2), equals(Point(4, 8)));
      expect(result.copyWithoutSource().imageSource, isNull);
      expect(result.copyWithoutSource().crop, equals(result.crop));
      final other = _quadrants();
      expect(
        (result.copyWithSource(other).imageSource! as JSAny)
            .strictEquals(other)
            .toDart,
        isTrue,
      );
      expect(result.imageResultCropped!.width, equals(10));
    });

    test('applyPerspective', () {
      final result = applyPerspective(_quadrants(), [
        Point(0, 0),
        Point(40, 0),
        Point(40, 40),
        Point(0, 40),
      ])!;
      expect(_px(result.imageResult, 35, 35), equals(_white));
    });
  });

  group('ImagePerspectiveFilterCache', () {
    final points = <Point<num>>[
      Point(0, 0),
      Point(40, 0),
      Point(40, 40),
      Point(0, 40),
    ];

    test('caches by scale and points', () {
      final cache = ImagePerspectiveFilterCache(_quadrants());
      expect(cache.maxPerspectiveCacheEntries, equals(2));

      expect(cache.getImageWithPerspective(points, 0), isNull);
      expect(cache.isImageWithPerspectiveInCache(points, 0), isFalse);
      expect(cache.isImageWithPerspectiveInCache(points, 1.0), isFalse);

      final r1 = cache.getImageWithPerspective(points, 1.0)!;
      expect(cache.isImageWithPerspectiveInCache(points, 1.0), isTrue);
      expect(identical(cache.getImageWithPerspective(points, 1.0), r1), isTrue);
      expect(_px(r1.imageResult, 5, 5), equals(_red));

      final half = cache.getImageWithPerspective(points, 0.5)!;
      expect(half.resultWidth, equals(20));

      cache.getImageWithPerspective(points, 0.25);
      expect(
        cache.isImageWithPerspectiveInCache(points, 1.0),
        isFalse,
        reason: 'evicted',
      );

      cache.clearCaches();
      expect(cache.isImageWithPerspectiveInCache(points, 0.25), isFalse);
      expect(cache.isImageScaledInCache(0.5), isFalse);
    });

    test('custom max entries', () {
      final cache = ImagePerspectiveFilterCache(_quadrants(), 40, 40, 3, 5);
      expect(cache.maxPerspectiveCacheEntries, equals(5));
      expect(cache.maxScaleCacheEntries, equals(3));
      cache.getImageWithPerspective(points, 1.0);
      cache.clearPerspectiveCache();
      expect(cache.isImageWithPerspectiveInCache(points, 1.0), isFalse);
    });
  });

  group('Color', () {
    test('components', () {
      final c = Color(0xFF112233);
      expect(c.alpha, equals(0xFF));
      expect(c.red, equals(0x11));
      expect(c.green, equals(0x22));
      expect(c.blue, equals(0x33));
      expect(c.hasAlpha, isFalse);
      expect(c.opacity, equals(1.0));
      expect(c.alphaRatio, equals(1.0));
      expect(c.toString(), equals('Color(0xff112233)'));
      expect(c.toHex(), equals('#ff112233'));

      final t = Color.fromARGB(128, 1, 2, 3);
      expect(t.alpha, equals(128));
      expect(t.hasAlpha, isTrue);
      expect(t.alphaRatio, closeTo(128 / 255, 0.0001));

      expect(Color.fromRGBO(1, 2, 3, 0.5).alpha, equals(127));
      expect(Color.fromRGBO(1, 2, 3).alpha, equals(255));
      expect(Color(0x1FFFFFFFF).value, equals(0xFFFFFFFF));
    });

    test('with*', () {
      final c = Color(0xFF112233);
      expect(c.withAlpha(0).alpha, equals(0));
      expect(c.withAlphaRatio(0.5).alpha, equals(127));
      expect(c.withOpacity(0.5).alpha, equals(128));
      expect(c.withRed(9).red, equals(9));
      expect(c.withGreen(9).green, equals(9));
      expect(c.withBlue(9).blue, equals(9));
      expect(c.withBlue(9).red, equals(0x11));
    });

    test('equality / hashCode', () {
      expect(Color(0xFF000000), equals(Color.black));
      expect(Color(0xFF000000).hashCode, equals(Color.black.hashCode));
      expect(Color(0xFF000001), isNot(equals(Color.black)));
      expect(Color.RED, equals(Color(0xFFFF0000)));
      expect(Color.GREEN, equals(Color(0xFF00FF00)));
      expect(Color.BLUE, equals(Color(0xFF0000FF)));
      expect(Color.cyan, equals(Color(0xFF00FFFF)));
      expect(Color.grey.red, equals(128));
    });

    test('computeLuminance', () {
      expect(Color.black.computeLuminance(), equals(0));
      expect(Color.white.computeLuminance(), closeTo(1, 0.0001));
      expect(Color.GREEN.computeLuminance(), closeTo(0.7152, 0.0001));
      expect(Color(0xFF050505).computeLuminance(), greaterThan(0));
    });

    test('alphaBlend', () {
      expect(Color.alphaBlend(Color(0x00FF0000), Color.white), Color.white);

      final opaque = Color.alphaBlend(
        Color.fromARGB(128, 255, 0, 0),
        Color.white,
      );
      expect(opaque, equals(Color.fromARGB(255, 255, 127, 127)));

      final general = Color.alphaBlend(
        Color.fromARGB(128, 255, 0, 0),
        Color.fromARGB(128, 0, 0, 255),
      );
      expect(general.alpha, equals(191));
      expect(general.red, equals(170));
      expect(general.blue, equals(84));
    });

    test('getAlphaFromOpacity', () {
      expect(Color.getAlphaFromOpacity(2), equals(255));
      expect(Color.getAlphaFromOpacity(-1), equals(0));
      expect(Color.getAlphaFromOpacity(0.5), equals(128));
    });

    test('fromHex / parse', () {
      expect(Color.fromHex('#FF0000'), equals(Color(0xFFFF0000)));
      expect(Color.fromHex('80ff0000').alpha, equals(0x80));
      expect(Color.parse(null), equals(Color(0)));
      expect(Color.parse(' #00FF00 '), equals(Color(0xFF00FF00)));
      expect(Color.parse('4278190335'), equals(Color(0xFF0000FF)));

      final rgb = Color.parse('1, 2, 3');
      expect([rgb.red, rgb.green, rgb.blue], equals([1, 2, 3]));
    });

    // Regression: an "r, g, b" string was parsed with alpha 0 (transparent).
    test('parse of an "r, g, b" string is opaque', () {
      expect(Color.parse('1, 2, 3'), equals(Color(0xFF010203)));
      expect(Color.parse('1,2,3').hasAlpha, isFalse);
      expect(Color.parse('rgb(10, 20, 30)'), equals(Color(0xFF0A141E)));
    });

    test('parse with an alpha component', () {
      expect(Color.parse('1, 2, 3, 0.5').alpha, equals(128));
      expect(Color.parse('rgba(1, 2, 3, 0)').alpha, equals(0));
      expect(Color.parse('rgba(1, 2, 3, 1)').alpha, equals(255));
      expect(Color.parse('1, 2, 3, .25').alpha, equals(64));
      expect(Color.parse('1, 2, 3, 200').alpha, equals(200));
      final c = Color.parse('rgba(10, 20, 30, 0.5)');
      expect([c.red, c.green, c.blue], equals([10, 20, 30]));
    });
  });

  group('HSVColor / HSLColor', () {
    test('HSVColor.fromColor / toColor', () {
      final red = HSVColor.fromColor(Color.RED);
      expect([red.alpha, red.hue, red.saturation, red.value], [1, 0, 1, 1]);
      expect(red.toColor(), equals(Color.RED));
      expect(HSVColor.fromColor(Color.GREEN).hue, equals(120));
      expect(HSVColor.fromColor(Color.BLUE).hue, equals(240));
      expect(HSVColor.fromColor(Color(0xFFFF00FF)).hue, equals(300));

      final grey = HSVColor.fromColor(Color.grey);
      expect(grey.saturation, equals(0));
      expect(grey.hue, equals(0));
      expect(HSVColor.fromColor(Color.black).value, equals(0));
    });

    test('hue sextants', () {
      final expected = <double, List<int>>{
        30: [255, 128, 0],
        90: [128, 255, 0],
        150: [0, 255, 128],
        210: [0, 128, 255],
        270: [128, 0, 255],
        330: [255, 0, 128],
      };
      for (final e in expected.entries) {
        final c = HSVColor.fromAHSV(1, e.key, 1, 1).toColor();
        expect([c.red, c.green, c.blue], equals(e.value), reason: '${e.key}');
        final l = HSLColor.fromAHSL(1, e.key, 1, 0.5).toColor();
        expect([l.red, l.green, l.blue], equals(e.value), reason: '${e.key}');
      }
    });

    test('HSVColor with* / lerp / equality', () {
      const c = HSVColor.fromAHSV(1, 100, 0.5, 0.5);
      expect(c.withAlpha(0.5).alpha, equals(0.5));
      expect(c.withHue(10).hue, equals(10));
      expect(c.withSaturation(1).saturation, equals(1));
      expect(c.withValue(1).value, equals(1));

      expect(HSVColor.lerp(null, null, 0.5), isNull);
      expect(HSVColor.lerp(c, null, 0.25)!.alpha, equals(0.75));
      expect(HSVColor.lerp(null, c, 0.25)!.alpha, equals(0.25));
      final mid = HSVColor.lerp(
        const HSVColor.fromAHSV(1, 0, 0, 0),
        const HSVColor.fromAHSV(1, 240, 1, 1),
        0.5,
      )!;
      expect([mid.hue, mid.saturation, mid.value], equals([120, 0.5, 0.5]));

      expect(c, equals(const HSVColor.fromAHSV(1, 100, 0.5, 0.5)));
      expect(c.hashCode, const HSVColor.fromAHSV(1, 100, 0.5, 0.5).hashCode);
      expect(c, isNot(equals(c.withHue(1))));
      expect(c.toString(), startsWith('HSVColor('));
    });

    test('HSLColor.fromColor / toColor', () {
      final red = HSLColor.fromColor(Color.RED);
      expect([red.hue, red.saturation, red.lightness], equals([0, 1, 0.5]));
      expect(red.toColor(), equals(Color.RED));

      final white = HSLColor.fromColor(Color.white);
      expect(white.lightness, equals(1));
      expect(white.saturation, equals(0));
      expect(white.toColor(), equals(Color.white));
    });

    test('HSLColor with* / lerp / equality', () {
      const c = HSLColor.fromAHSL(1, 100, 0.5, 0.5);
      expect(c.withAlpha(0.5).alpha, equals(0.5));
      expect(c.withHue(10).hue, equals(10));
      expect(c.withSaturation(1).saturation, equals(1));
      expect(c.withLightness(1).lightness, equals(1));

      expect(HSLColor.lerp(null, null, 0.5), isNull);
      expect(HSLColor.lerp(c, null, 0.25)!.alpha, equals(0.75));
      expect(HSLColor.lerp(null, c, 0.25)!.alpha, equals(0.25));
      final mid = HSLColor.lerp(
        const HSLColor.fromAHSL(0, 0, 0, 0),
        const HSLColor.fromAHSL(1, 200, 1, 1),
        0.5,
      )!;
      expect([
        mid.alpha,
        mid.hue,
        mid.saturation,
        mid.lightness,
      ], equals([0.5, 100, 0.5, 0.5]));

      expect(c, equals(const HSLColor.fromAHSL(1, 100, 0.5, 0.5)));
      expect(c.hashCode, const HSLColor.fromAHSL(1, 100, 0.5, 0.5).hashCode);
      expect(c, isNot(equals(c.withLightness(0.1))));
      expect(c.toString(), startsWith('hsl('));
      expect(c.toString(), contains(', 50, 50, '));
    });

    test('lerpDouble', () {
      expect(lerpDouble(0, 10, 0.5), equals(5));
      expect(lerpDouble(10, 0, 0.25), equals(7.5));
    });
  });

  group('TrackElementValue', () {
    test('track: initial value, periodic changes, untrack', () async {
      final tracker = TrackElementValue(Duration(milliseconds: 20));
      final element = HTMLDivElement();
      var value = 1;
      final events = <int?>[];

      final initial = tracker.track<int>(element, (_) => value, (e, v) {
        events.add(v);
        return true;
      }, periodicTracking: true);
      expect(initial, equals(1));
      expect(events, equals([1]));

      value = 2;
      await _delay(80);
      value = 3;
      await _delay(80);
      expect(events, equals([1, 2, 3]));

      expect(tracker.untrack<int>(element), equals(3));
      value = 4;
      await _delay(80);
      expect(events, equals([1, 2, 3]));
    });

    test('track: invalid arguments / duplicates', () {
      final tracker = TrackElementValue();
      final element = HTMLDivElement();
      expect(tracker.track<int>(null, (_) => 1, (e, v) => true), isNull);
      expect(tracker.track<int>(element, null, (e, v) => true), isNull);
      expect(tracker.track<int>(element, (_) => 1, null), isNull);

      expect(tracker.track<int>(element, (_) => 1, (e, v) => true), 1);
      expect(tracker.track<int>(element, (_) => 2, (e, v) => true), isNull);
      tracker.untrack<int>(element);
    });

    test('callback returning false (or throwing) stops tracking', () async {
      final tracker = TrackElementValue(Duration(milliseconds: 20));
      final a = HTMLDivElement();
      final b = HTMLDivElement();
      var value = 1;
      final eventsA = <int?>[];
      final eventsB = <int?>[];

      tracker.track<int>(a, (_) => value, (e, v) {
        eventsA.add(v);
        return eventsA.length < 2;
      }, periodicTracking: true);
      tracker.track<int>(b, (_) => value, (e, v) {
        eventsB.add(v);
        throw StateError('x');
      }, periodicTracking: true);

      value = 2;
      await _delay(60);
      value = 3;
      await _delay(60);
      expect(eventsA, equals([1, 2]));
      expect(eventsB, equals([1]));
    });

    // Regression: non-periodic tracking was dropped by the first check even
    // when the value didn't change, so a change after the first check
    // interval was never notified.
    test('non-periodic tracking survives checks without changes', () async {
      final tracker = TrackElementValue(Duration(milliseconds: 20));
      final element = HTMLDivElement();
      var value = 'a';
      final events = <String?>[];

      tracker.track<String>(element, (_) => value, (e, v) {
        events.add(v);
        return true;
      });
      expect(events, equals(['a']));

      await _delay(100);
      value = 'b';
      await _delay(100);
      expect(events, equals(['a', 'b']));

      // Non-periodic: stops after the first change event.
      value = 'c';
      await _delay(100);
      expect(events, equals(['a', 'b']));
    });

    test('checkElements / properties', () {
      final tracker = TrackElementValue(Duration(hours: 1));
      final element = HTMLDivElement();
      var value = 1;
      final events = <int?>[];
      tracker.track<int>(element, (_) => value, (e, v) {
        events.add(v);
        return true;
      }, periodicTracking: true);

      value = 2;
      tracker.checkElements();
      expect(events, equals([1, 2]));
      tracker.checkElements();
      expect(events, equals([1, 2]));

      expect(tracker.setProperty(element, 'k', 1), isNull);
      expect(tracker.setProperty(element, 'k', 2), equals(1));
      expect(tracker.getProperty(element, 'k'), equals(2));
      expect(tracker.getProperty(HTMLDivElement(), 'k'), isNull);

      tracker.untrack<int>(element);
      expect(tracker.getProperty(element, 'k'), isNull);
      TrackElementValue().checkElements();
    });
  });

  group('TrackElementInViewport', () {
    HTMLDivElement fixedElement(int top) {
      final element = HTMLDivElement()
        ..style.position = 'fixed'
        ..style.left = '0px'
        ..style.top = '${top}px'
        ..style.width = '10px'
        ..style.height = '10px';
      document.body!.appendChild(element);
      addTearDown(() => element.remove());
      return element;
    }

    test('no callbacks: not tracked', () {
      final tracker = TrackElementInViewport();
      expect(tracker.track(fixedElement(0)), isFalse);
    });

    // Regression: an element entering the viewport after the first check
    // interval (e.g. due to scrolling) was never notified.
    test('onEnterViewport after the first check interval', () async {
      final tracker = TrackElementInViewport(Duration(milliseconds: 20));
      final element = fixedElement(100000);
      final entered = <Element>[];

      expect(tracker.track(element, onEnterViewport: entered.add), isFalse);
      await _delay(100);
      expect(entered, isEmpty);

      element.style.top = '0px';
      await _delay(100);
      expect(entered.length, equals(1));
    });

    // Regression: with `onLeaveViewport`, leaving the viewport was never
    // notified (tracking was dropped by the first check).
    test('onEnterViewport + onLeaveViewport', () async {
      final tracker = TrackElementInViewport(Duration(milliseconds: 20));
      final element = fixedElement(0);
      final entered = <Element>[];
      final left = <Element>[];

      expect(
        tracker.track(
          element,
          onEnterViewport: entered.add,
          onLeaveViewport: left.add,
        ),
        isTrue,
      );
      expect(entered.length, equals(1));

      await _delay(100);
      element.style.top = '100000px';
      await _delay(100);
      expect(left.length, equals(1));

      // Not periodic: stops after leaving once viewed.
      element.style.top = '0px';
      await _delay(100);
      expect(entered.length, equals(1));
    });

    test('periodic tracking', () async {
      final tracker = TrackElementInViewport(Duration(milliseconds: 20));
      final element = fixedElement(0);
      final entered = <Element>[];
      final left = <Element>[];

      tracker.track(
        element,
        onEnterViewport: entered.add,
        onLeaveViewport: left.add,
        periodicTracking: true,
      );
      for (var i = 0; i < 2; i++) {
        element.style.top = '100000px';
        await _delay(80);
        element.style.top = '0px';
        await _delay(80);
      }
      expect(entered.length, equals(3));
      expect(left.length, equals(2));

      tracker.untrack(element);
      element.style.top = '100000px';
      await _delay(80);
      expect(left.length, equals(2));
    });
  });

  group('TrackElementResize', () {
    test('notifies size changes until untracked', () async {
      final element = HTMLDivElement()
        ..style.width = '10px'
        ..style.height = '10px';
      document.body!.appendChild(element);
      addTearDown(() => element.remove());

      final tracker = TrackElementResize();
      final resized = <Element>[];
      tracker.track(element, resized.add);

      await _delay(100);
      final initial = resized.length;

      element.style.width = '30px';
      await _delay(100);
      expect(resized.length, greaterThan(initial));
      expect((resized.last as JSAny).strictEquals(element).toDart, isTrue);

      tracker.untrack(element);
      final afterUntrack = resized.length;
      element.style.width = '50px';
      await _delay(100);
      expect(resized.length, equals(afterUntrack));
    });

    test('listener errors are caught', () async {
      final a = HTMLDivElement()..style.width = '10px';
      final b = HTMLDivElement()..style.width = '10px';
      document.body!
        ..appendChild(a)
        ..appendChild(b);
      addTearDown(() {
        a.remove();
        b.remove();
      });

      final tracker = TrackElementResize();
      final resizedB = <Element>[];
      tracker.track(a, (_) => throw StateError('x'));
      tracker.track(b, resizedB.add);
      await _delay(100);
      a.style.width = '20px';
      b.style.width = '20px';
      await _delay(100);
      expect(resizedB, isNotEmpty);
    });
  });
}
