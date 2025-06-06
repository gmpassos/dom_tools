import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' hide Float32List;

import 'dom_tools_paint.dart';

class _Rect {
  int x;
  int y;
  int width;
  int height;

  _Rect(this.x, this.y, this.width, this.height);
}

/// Filter result.
///
/// Used by [ImagePerspectiveFilter].
class FilterResult {
  final CanvasImageSource? imageSource;

  final HTMLCanvasElement imageResult;

  final Rectangle<num> crop;

  FilterResult(this.imageSource, this.imageResult, this.crop);

  FilterResult copyWithSource(CanvasImageSource? imageSource) =>
      FilterResult(imageSource, imageResult, crop);

  FilterResult copyWithoutSource() => FilterResult(null, imageResult, crop);

  Point<num> get translation => Point(crop.left, crop.top);

  Point<num> translationScaled(double scale) =>
      Point(crop.left * scale, crop.top * scale);

  HTMLCanvasElement? _imageResultCropped;

  HTMLCanvasElement? get imageResultCropped {
    _imageResultCropped ??= cropImageByRectangle(imageResult, crop);
    return _imageResultCropped;
  }

  int get resultWidth => imageResult.width;

  int get resultHeight => imageResult.height;
}

/// A filter that applies a perspective to an image.
class ImagePerspectiveFilter {
  /// The image to filter.
  final CanvasImageSource image;

  /// Image width.
  final int width;

  /// Image height.
  final int height;

  late double _x0;
  late double _y0;
  late double _x1;
  late double _y1;
  late double _x2;
  late double _y2;
  late double _x3;
  late double _y3;
  late double _dx1;
  late double _dy1;
  late double _dx2;
  late double _dy2;
  double? _dx3;
  double? _dy3;
  late double _a;
  late double _b;
  late double _c;
  late double _d;
  late double _e;
  late double _f;
  late double _g;
  late double _h;
  late double _i;

  ImagePerspectiveFilter(this.image, this.width, this.height);

  void setCornersFromDimensionRatio(double x0, double y0, double x1, double y1,
      double x2, double y2, double x3, double y3) {
    setCorners(width * x0, height * y0, width * x1, height * y1, width * x2,
        height * y2, width * x3, height * y3);
  }

  void setCornersFromPoints(
      Point<num> p0, Point<num> p1, Point<num> p2, Point<num> p3) {
    setCornersFromInts(p0.x.toInt(), p0.y.toInt(), p1.x.toInt(), p1.y.toInt(),
        p2.x.toInt(), p2.y.toInt(), p3.x.toInt(), p3.y.toInt());
  }

  void setCornersFromNumList(List<num> points) {
    setCornersFromInts(
        points[0].toInt(),
        points[1].toInt(),
        points[2].toInt(),
        points[3].toInt(),
        points[4].toInt(),
        points[5].toInt(),
        points[6].toInt(),
        points[7].toInt());
  }

  void setCornersFromPointsList(List<Point<num>> points) {
    setCornersFromPoints(points[0], points[1], points[2], points[3]);
  }

  void setCornersFromInts(
      int x0, int y0, int x1, int y1, int x2, int y2, int x3, int y3) {
    setCorners(x0.toDouble(), y0.toDouble(), x1.toDouble(), y1.toDouble(),
        x2.toDouble(), y2.toDouble(), x3.toDouble(), y3.toDouble());
  }

  void setCorners(double x0, double y0, double x1, double y1, double x2,
      double y2, double x3, double y3) {
    _x0 = x0;
    _y0 = y0;
    _x1 = x1;
    _y1 = y1;
    _x2 = x2;
    _y2 = y2;
    _x3 = x3;
    _y3 = y3;
    _dx1 = x1 - x2;
    _dy1 = y1 - y2;
    _dx2 = x3 - x2;
    _dy2 = y3 - y2;
    _dx3 = ((x0 - x1) + x2) - x3;
    _dy3 = ((y0 - y1) + y2) - y3;

    double a11;
    double a12;
    double a13;
    double a21;
    double a22;
    double a23;
    double a31;
    double a32;

    if (_dx3 == 0.0 && _dy3 == 0.0) {
      a11 = x1 - x0;
      a21 = x2 - x1;
      a31 = x0;
      a12 = y1 - y0;
      a22 = y2 - y1;
      a32 = y0;
      a13 = a23 = 0.0;
    } else {
      a13 = (_dx3! * _dy2 - _dx2 * _dy3!) / (_dx1 * _dy2 - _dy1 * _dx2);
      a23 = (_dx1 * _dy3! - _dy1 * _dx3!) / (_dx1 * _dy2 - _dy1 * _dx2);
      a11 = (x1 - x0) + a13 * x1;
      a21 = (x3 - x0) + a23 * x3;
      a31 = x0;
      a12 = (y1 - y0) + a13 * y1;
      a22 = (y3 - y0) + a23 * y3;
      a32 = y0;
    }

    _a = a22 - a32 * a23;
    _b = a31 * a23 - a21;
    _c = a21 * a32 - a31 * a22;
    _d = a32 * a13 - a12;
    _e = a11 - a31 * a13;
    _f = a31 * a12 - a11 * a32;
    _g = a12 * a23 - a22 * a13;
    _h = a21 * a13 - a11 * a23;
    _i = a11 * a22 - a21 * a12;

    _updateSpaces();
  }

  late _Rect _originalSpace;
  late _Rect _transformedSpace;

  void _updateSpaces() {
    _originalSpace = _Rect(0, 0, width, height);
    _transformedSpace = _Rect(0, 0, width, height);

    _transformSpace(_transformedSpace);
  }

  void _transformSpace(_Rect rect) {
    rect.x = math.min(math.min(_x0, _x1), math.min(_x2, _x3)).toInt();
    rect.y = math.min(math.min(_y0, _y1), math.min(_y2, _y3)).toInt();
    rect.width =
        (math.max(math.max(_x0, _x1), math.max(_x2, _x3)) - rect.x).toInt();
    rect.height =
        (math.max(math.max(_y0, _y1), math.max(_y2, _y3)) - rect.y).toInt();
  }

  void _transformInverse(_Rect originalSpace, int x, int y, Float32List out) {
    out[0] =
        (originalSpace.width * (_a * x + _b * y + _c)) / (_g * x + _h * y + _i);
    out[1] = (originalSpace.height * (_d * x + _e * y + _f)) /
        (_g * x + _h * y + _i);
  }

  void _getPixel(Uint8ClampedList pixels, int x, int y, int width, int height,
      Uint8ClampedList rgba) {
    _getPixelEdgeBlack(pixels, x, y, width, height, rgba);
  }

  void _getPixelRGBA(Uint8ClampedList pixels, int idx, Uint8ClampedList rgba) {
    rgba[0] = pixels[idx];
    rgba[1] = pixels[idx + 1];
    rgba[2] = pixels[idx + 2];
    rgba[3] = pixels[idx + 3];
  }

  void _getPixelEdgeBlack(Uint8ClampedList pixels, int x, int y, int width,
      int height, Uint8ClampedList rgba) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      rgba[0] = 0;
      rgba[1] = 0;
      rgba[2] = 0;
      rgba[3] = 255;
    } else {
      var idx = (y * (width * 4)) + (x * 4);

      rgba[0] = pixels[idx];
      rgba[1] = pixels[idx + 1];
      rgba[2] = pixels[idx + 2];
      rgba[3] = pixels[idx + 3];
    }
  }

  Uint8ClampedList? _getImagePixels() {
    if (width == 0 || height == 0) return null;
    var selectedImgCanvas = HTMLCanvasElement()
      ..width = width
      ..height = height;

    var context =
        selectedImgCanvas.getContext('2d') as CanvasRenderingContext2D;

    context.clearRect(0, 0, width, height);
    context.drawImage(image, 0, 0);

    var imageData = context.getImageData(0, 0, width, height);

    return imageData.data.toDart;
  }

  /// Filters the image into [resultCanvas].
  FilterResult? filter([HTMLCanvasElement? resultCanvas]) {
    // ignore: omit_local_variable_types
    Uint8ClampedList? inPixels = _getImagePixels();
    if (inPixels == null) return null;

    var srcWidth = _originalSpace.width;
    var srcHeight = _originalSpace.height;
    var srcWidth1 = srcWidth - 1;
    var srcHeight1 = srcHeight - 1;

    var outWidth = _transformedSpace.width;
    var outHeight = _transformedSpace.height;
    var outX = _transformedSpace.x;
    var outY = _transformedSpace.y;
    var outArea = outWidth * outHeight * 4;
    var outWidth4 = outWidth * 4;

    var out = Float32List(2);
    var outPixels = Uint8ClampedList(outArea);

    var pNW = Uint8ClampedList(4);

    for (var y = 0; y < outHeight; y++) {
      var outLineIdx = (outWidth * 4) * y;

      for (var xIdx = 0; xIdx < outWidth4; xIdx += 4) {
        var x = xIdx ~/ 4;

        _transformInverse(_originalSpace, outX + x, outY + y, out);

        var srcX = out[0].toInt();
        var srcY = out[1].toInt();

        if (srcX >= 0 && srcX < srcWidth1 && srcY >= 0 && srcY < srcHeight1) {
          var i = (srcWidth * 4) * srcY + (srcX * 4);

          _getPixelRGBA(inPixels, i, pNW);
        } else {
          _getPixel(inPixels, srcX, srcY, srcWidth, srcHeight, pNW);
        }

        var idx = outLineIdx + xIdx;

        outPixels[idx] = pNW[0];
        outPixels[idx + 1] = pNW[1];
        outPixels[idx + 2] = pNW[2];
        outPixels[idx + 3] = pNW[3];
      }
    }

    var canvasW = max(srcWidth, outWidth);
    var canvasH = max(srcHeight, outHeight);

    resultCanvas ??= HTMLCanvasElement()
      ..width = canvasW
      ..height = canvasH;

    var context = resultCanvas.getContext('2d') as CanvasRenderingContext2D;

    var imgData = context.createImageData(outWidth.toJS, outHeight);
    imgData.data.callMethod('set'.toJS, outPixels.toJS, 0.toJS);

    context.putImageData(imgData, 0, 0, 0, 0, outWidth, outHeight);

    var crop = _computeCrop();

    return FilterResult(image, resultCanvas, crop);
  }

  Rectangle<int> _computeCrop() {
    var x0 = math.min(_x0, _x3).toInt();
    var y0 = math.min(_y0, _y1).toInt();

    var xA = math.max(_x0, _x3).toInt();
    var yA = math.max(_y0, _y1).toInt();

    var xB = math.min(_x1, _x2).toInt();
    var yB = math.min(_y2, _y3).toInt();

    var x = xA - x0;
    var y = yA - y0;

    var w = xB - xA;
    var h = yB - yA;

    return Rectangle(x, y, w, h);
  }
}

/// Apply [perspective] filter to [image].
FilterResult? applyPerspective(
    CanvasImageSource image, List<Point<num>> perspective) {
  var wh = getImageDimension(image)!;

  var w = wh.width;
  var h = wh.height;

  var filter = ImagePerspectiveFilter(image, w, h);
  filter.setCornersFromPointsList(perspective);

  return filter.filter();
}

/// A cache for perspective filers.
///
/// Useful for consecutive calls to perspective on the same image.
class ImagePerspectiveFilterCache extends ImageScaledCache {
  final int _maxPerspectiveCacheEntries;

  ImagePerspectiveFilterCache(super.image,
      [super.width,
      super.height,
      super.maxScaleCacheEntries,
      int? maxPerspectiveCacheEntries])
      : _maxPerspectiveCacheEntries =
            maxPerspectiveCacheEntries != null && maxPerspectiveCacheEntries > 0
                ? maxPerspectiveCacheEntries
                : 2;

  int? get maxPerspectiveCacheEntries => _maxPerspectiveCacheEntries;

  final Map<String, FilterResult?> _perspectiveCache = {};

  void clearPerspectiveCache() {
    _perspectiveCache.clear();
  }

  void clearCaches() {
    clearScaleCache();
    clearPerspectiveCache();
  }

  bool isImageWithPerspectiveInCache(List<Point<num>>? points, double scale) {
    if (scale <= 0) return false;

    var cacheKey = '$scale > $points';

    var imageWithPerspective = _perspectiveCache[cacheKey];
    return imageWithPerspective != null;
  }

  FilterResult? getImageWithPerspective(
      List<Point<num>>? points, double scale) {
    if (scale <= 0) return null;

    var cacheKey = '$scale > $points';

    var imageWithPerspective = _perspectiveCache[cacheKey];

    if (imageWithPerspective == null) {
      var imageScaled = getImageScaled(scale)!;
      var imageScaledDim = getImageDimension(imageScaled);
      if (imageScaledDim == null ||
          imageScaledDim.width == 0 ||
          imageScaledDim.height == 0) {
        getImageScaled(scale);
      }

      var perspective = scalePoints(points!, scale);

      imageWithPerspective = applyPerspective(imageScaled, perspective);

      ImageScaledCache.limitEntries(
          _perspectiveCache, _maxPerspectiveCacheEntries - 1);

      _perspectiveCache[cacheKey] = imageWithPerspective;
    }

    return imageWithPerspective;
  }
}
