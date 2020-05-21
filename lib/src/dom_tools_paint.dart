
import 'dart:async';
import 'dart:html';
import 'dart:math' as math ;
import 'dart:math';

import 'package:dom_tools/dom_tools.dart';
import 'package:intl/intl.dart';

import 'perspective_filter.dart';

////////////////////////////////////////////////////////////////////////////////
// Class Color from  'dart:ui' (Flutter):
////////////////////////////////////////////////////////////////////////////////

class Color {

  static final Color BLACK = Color.fromRGBO(0, 0, 0);
  static final Color WHITE = Color.fromRGBO(255, 255, 255);

  static final Color RED = Color.fromRGBO(255, 0, 0);
  static final Color GREEN = Color.fromRGBO(0, 255, 0);
  static final Color BLUE = Color.fromRGBO(0, 0, 255);

  static final Color CYAN = Color.fromRGBO(0, 255, 255);

  /// Construct a color from the lower 32 bits of an [int].
  ///
  /// The bits are interpreted as follows:
  ///
  /// * Bits 24-31 are the alpha value.
  /// * Bits 16-23 are the red value.
  /// * Bits 8-15 are the green value.
  /// * Bits 0-7 are the blue value.
  ///
  /// In other words, if AA is the alpha value in hex, RR the red value in hex,
  /// GG the green value in hex, and BB the blue value in hex, a color can be
  /// expressed as `const Color(0xAARRGGBB)`.
  ///
  /// For example, to get a fully opaque orange, you would use `const
  /// Color(0xFFFF9000)` (`FF` for the alpha, `FF` for the red, `90` for the
  /// green, and `00` for the blue).
  @pragma('vm:entry-point')
  const Color(int value) : value = value & 0xFFFFFFFF;

  /// Construct a color from the lower 8 bits of four integers.
  ///
  /// * `a` is the alpha value, with 0 being transparent and 255 being fully
  ///   opaque.
  /// * `r` is [red], from 0 to 255.
  /// * `g` is [green], from 0 to 255.
  /// * `b` is [blue], from 0 to 255.
  ///
  /// Out of range values are brought into range using modulo 255.
  ///
  /// See also [fromRGBO], which takes the alpha value as a floating point
  /// value.
  const Color.fromARGB(int a, int r, int g, int b) :
        value = (((a & 0xff) << 24) |
        ((r & 0xff) << 16) |
        ((g & 0xff) << 8)  |
        ((b & 0xff) << 0)) & 0xFFFFFFFF;

  /// Create a color from red, green, blue, and opacity, similar to `rgba()` in CSS.
  ///
  /// * `r` is [red], from 0 to 255.
  /// * `g` is [green], from 0 to 255.
  /// * `b` is [blue], from 0 to 255.
  /// * `opacity` is alpha channel of this color as a double, with 0.0 being
  ///   transparent and 1.0 being fully opaque.
  ///
  /// Out of range values are brought into range using modulo 255.
  ///
  /// See also [fromARGB], which takes the opacity as an integer value.
  const Color.fromRGBO(int r, int g, int b, [double opacity = 1.0]) :
        value = ((((opacity * 0xff ~/ 1) & 0xff) << 24) |
        ((r                    & 0xff) << 16) |
        ((g                    & 0xff) << 8)  |
        ((b                    & 0xff) << 0)) & 0xFFFFFFFF;


  factory Color.fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    while (hexColor.length <  8) {
      hexColor = 'FF' + hexColor ;
    }
    var color = int.parse(hexColor, radix: 16);
    return Color(color) ;
  }

  factory Color.parse(String colorStr) {
    if (colorStr ==  null) return Color(0) ;
    colorStr = colorStr.trim() ;

    if ( RegExp(r'\d+\s*,\s*\d+\s*,\s*\d+').hasMatch(colorStr) ) {
      var parts = colorStr.split('\D+') ;
      var r = int.parse(parts[0]) ;
      var g = int.parse(parts[1]) ;
      var b = int.parse(parts[2]) ;
      return Color.fromARGB(0, r, g, b) ;
    }
    else if ( colorStr.startsWith('#') ) {
      return Color.fromHex(colorStr) ;
    }
    else {
      var argb = int.parse(colorStr) ;
      return Color(argb) ;
    }

  }

  /// A 32 bit value representing this color.
  ///
  /// The bits are assigned as follows:
  ///
  /// * Bits 24-31 are the alpha value.
  /// * Bits 16-23 are the red value.
  /// * Bits 8-15 are the green value.
  /// * Bits 0-7 are the blue value.
  final int value;

  /// The alpha channel of this color in an 8 bit value.
  ///
  /// A value of 0 means this color is fully transparent. A value of 255 means
  /// this color is fully opaque.
  int get alpha => (0xff000000 & value) >> 24;

  /// The alpha channel of this color as a double.
  ///
  /// A value of 0.0 means this color is fully transparent. A value of 1.0 means
  /// this color is fully opaque.
  double get opacity => alpha / 0xFF;

  /// The red channel of this color in an 8 bit value.
  int get red => (0x00ff0000 & value) >> 16;

  /// The green channel of this color in an 8 bit value.
  int get green => (0x0000ff00 & value) >> 8;

  /// The blue channel of this color in an 8 bit value.
  int get blue => (0x000000ff & value) >> 0;

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with `a` (which ranges from 0 to 255).
  ///
  /// Out of range values will have unexpected effects.
  Color withAlpha(int a) {
    return Color.fromARGB(a, red, green, blue);
  }

  /// Returns a new color that matches this color with the alpha channel
  /// replaced with the given `opacity` (which ranges from 0.0 to 1.0).
  ///
  /// Out of range values will have unexpected effects.
  Color withOpacity(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }

  /// Returns a new color that matches this color with the red channel replaced
  /// with `r` (which ranges from 0 to 255).
  ///
  /// Out of range values will have unexpected effects.
  Color withRed(int r) {
    return Color.fromARGB(alpha, r, green, blue);
  }

  /// Returns a new color that matches this color with the green channel
  /// replaced with `g` (which ranges from 0 to 255).
  ///
  /// Out of range values will have unexpected effects.
  Color withGreen(int g) {
    return Color.fromARGB(alpha, red, g, blue);
  }

  /// Returns a new color that matches this color with the blue channel replaced
  /// with `b` (which ranges from 0 to 255).
  ///
  /// Out of range values will have unexpected effects.
  Color withBlue(int b) {
    return Color.fromARGB(alpha, red, green, b);
  }

  // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    }
    return math.pow((component + 0.055) / 1.055, 2.4) as double;
  }

  /// Returns a brightness value between 0 for darkest and 1 for lightest.
  ///
  /// Represents the relative luminance of the color. This value is computationally
  /// expensive to calculate.
  ///
  /// See <https://en.wikipedia.org/wiki/Relative_luminance>.
  double computeLuminance() {
    // See <https://www.w3.org/TR/WCAG20/#relativeluminancedef>
    var R = _linearizeColorComponent(red / 0xFF);
    var G = _linearizeColorComponent(green / 0xFF);
    var B = _linearizeColorComponent(blue / 0xFF);
    return 0.2126 * R + 0.7152 * G + 0.0722 * B;
  }

  /// Combine the foreground color as a transparent color over top
  /// of a background color, and return the resulting combined color.
  ///
  /// This uses standard alpha blending ("SRC over DST") rules to produce a
  /// blended color from two colors. This can be used as a performance
  /// enhancement when trying to avoid needless alpha blending compositing
  /// operations for two things that are solid colors with the same shape, but
  /// overlay each other: instead, just paint one with the combined color.
  static Color alphaBlend(Color foreground, Color background) {
    var alpha = foreground.alpha;
    if (alpha == 0x00) { // Foreground completely transparent.
      return background;
    }
    var invAlpha = 0xff - alpha;
    var backAlpha = background.alpha;
    if (backAlpha == 0xff) { // Opaque background case
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    } else { // General case
      backAlpha = (backAlpha * invAlpha) ~/ 0xff;
      var outAlpha = alpha + backAlpha;
      assert(outAlpha != 0x00);
      return Color.fromARGB(
        outAlpha,
        (foreground.red * alpha + background.red * backAlpha) ~/ outAlpha,
        (foreground.green * alpha + background.green * backAlpha) ~/ outAlpha,
        (foreground.blue * alpha + background.blue * backAlpha) ~/ outAlpha,
      );
    }
  }

  /// Returns an alpha value representative of the provided [opacity] value.
  ///
  /// The [opacity] value may not be null.
  static int getAlphaFromOpacity(double opacity) {
    assert(opacity != null);
    return (opacity.clamp(0.0, 1.0) * 255).round();
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Color && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';

  String toHex() => '#${value.toRadixString(16).padLeft(8, '0')}';

}

////////////////////////////////////////////////////////////////////////////////

Rectangle<int> getImageDimension(CanvasImageSource image) {
  if ( image is ImageElement ) {
    return Rectangle(0,0, image.naturalWidth , image.naturalHeight ) ;
  }
  else if ( image is CanvasElement ) {
    return Rectangle(0,0, image.width , image.height ) ;
  }
  else if ( image is VideoElement ) {
    return Rectangle(0,0, image.width , image.height ) ;
  }
  return null ;
}

CanvasElement cropImageByRectangle(CanvasImageSource image, Rectangle crop) {
  if (crop == null) return null ;
  return cropImage(image, crop.left, crop.top, crop.width, crop.height) ;
}

CanvasElement cropImage(CanvasImageSource image, int x, int y, int width, int height) {
  if ( !(image is CanvasElement) ) {
    var imgDim = getImageDimension(image);
    var imgCanvas = CanvasElement(width: imgDim.width, height: imgDim.height) ;
    CanvasRenderingContext2D context = imgCanvas.getContext('2d') ;
    context.drawImage(image, 0, 0) ;
    image = imgCanvas ;
  }

  var imgCropData ;

  if ( image is CanvasElement ) {
    CanvasRenderingContext2D imgContext = image.getContext('2d') ;
    imgCropData = imgContext.getImageData(x,y, width, height) ;
  }
  else {
    return null ;
  }

  var canvasCrop = CanvasElement(width: width, height: height) ;
  CanvasRenderingContext2D contextCrop = canvasCrop.getContext('2d') ;
  contextCrop.putImageData(imgCropData, 0, 0, 0, 0, width, height);

  return canvasCrop ;
}

CanvasImageSource createScaledImage(CanvasImageSource image, int w, int h, double scale) {
  var w2 = (w * scale).toInt();
  var h2 = (h * scale).toInt();

  var canvas = CanvasElement(width: w2, height: h2);

  CanvasRenderingContext2D context = canvas.getContext('2d');

  context.drawImageScaledFromSource(image, 0, 0, w, h, 0, 0, w2, h2);

  return canvas;
}

Future<ImageElement> createImageElementFromFile(File file) {
  var reader = FileReader();

  var completer = Completer<ImageElement>();

  reader.onLoadEnd.listen((e) {
    completer.complete(createImageElementFromBase64(reader.result));
  });

  reader.readAsDataUrl(file);

  return completer.future;
}

ImageElement createImageElementFromBase64(String base64, [String mimeType]) {
  if (base64 == null || base64.isEmpty) return null ;
  if (!base64.startsWith('data:')) {
    if (mimeType == null || mimeType.trim().isEmpty) mimeType = 'image/jpeg' ;
    base64 = 'data:$mimeType;base64,$base64' ;
  }

  var imgElement = ImageElement();
  imgElement.src = base64;

  return imgElement;
}

////////////////////////////////////////////////////////////////////////////////


List<Point<num>> numsToPoints(List<num> perspective, [Color color]) {
  // ignore: omit_local_variable_types
  List< Point<num> > points = [] ;

  for (var i = 1; i < perspective.length; i+=2) {
    var x = perspective[i-1];
    var y = perspective[i];
    points.add( Point(x,y) ) ;
  }

  return points ;
}

List< Point<num> > copyPoints( List< Point<num> > points ) {
  return points.map( (p) => Point( p.x , p.y )  ).toList() ;
}

List< Point<num> > scalePoints( List< Point<num> > points , double scale ) {
  return points.map( (p) => Point( p.x*scale , p.y*scale )  ).toList() ;
}

List< Point<num> > scalePointsXY( List< Point<num> > points , double scaleX, double scaleY ) {
  return points.map( (p) => Point( p.x*scaleX , p.y*scaleY )  ).toList() ;
}

List< Point<num> > translatePoints( List< Point<num> > points , num x, num y ) {
  return points.map( (p) => Point( p.x+x , p.y+y )  ).toList() ;
}

////////////////////////////////////////////////////////////////////////////////

class ImageScaledCache {

  final CanvasImageSource _image ;
  int _width ;
  int _height ;
  int _maxScaleCacheEntries ;

  ImageScaledCache(this._image, [int width, int height, int maxScaleCacheEntries]) {
    if (width == null || height == null) {
      var wh = getImageDimension(_image) ;

      width ??= wh.width ;
      height ??= wh.height ;
    }

    _width = width ;
    _height = height ;

    _maxScaleCacheEntries = maxScaleCacheEntries != null && maxScaleCacheEntries > 0 ? maxScaleCacheEntries : 2 ;

  }

  CanvasImageSource get image => _image;
  int get width => _width;
  int get height => _height;

  int get maxScaleCacheEntries => _maxScaleCacheEntries ;

  /////

  final Map<double, CanvasImageSource> _scaleCache = {} ;

  void clearScaleCache() {
    _scaleCache.clear() ;
  }

  bool isImageScaledInCache(double scale) {
    if (scale <= 0) return false ;
    if (scale == 1.0) return true ;

    var scaledImage = _scaleCache[scale] ;
    return scaledImage != null ;
  }

  CanvasImageSource getImageScaled(double scale) {
    if (scale <= 0) return null ;
    if (scale == 1.0) return _image ;

    var scaledImage = _scaleCache[scale] ;

    if (scaledImage == null) {
      scaledImage = createScaledImage(_image, _width, _height, scale);

      limitEntries(_scaleCache, _maxScaleCacheEntries-1);

      _scaleCache[scale] = scaledImage ;
    }

    return scaledImage ;
  }

  static int limitEntries(Map cache, int maxCacheEntries) {
    if (cache == null || cache.isEmpty) return 0 ;

    if (maxCacheEntries < 0) maxCacheEntries = 0 ;
    var removed = 0 ;
    while ( cache.length > maxCacheEntries ) {
      var key = cache.keys.first;
      print('-- removing from cache: $key > ${ cache.length } / $maxCacheEntries');
      cache.remove( key ) ;
      removed++ ;
    }
    return removed ;
  }

}

////////////////////////////////////////////////////////////////////////////////
// Image Viewer using Canvas and highlight elements (Clip and Rectangles)
////////////////////////////////////////////////////////////////////////////////

typedef ImageFilter = CanvasImageSource Function(CanvasImageSource image, int width, int height) ;

enum Quality {
  HIGH,
  MEDIUM,
  LOW
}

enum EditionType {
  CLIP,
  POINTS,
  PERSPECTIVE
}

typedef ValueCopier<T> = T Function(T value) ;

class ViewerValue<T> {

  static T copyValue<T>(ViewerValue<T> viewerValue) {
    return viewerValue != null ? viewerValue.valueCopy : null ;
  }

  static T getValue<T>(ViewerValue<T> viewerValue) {
    return viewerValue != null ? viewerValue.value : null ;
  }

  static Color getColor(ViewerValue viewerValue, [Color defaultColor]) {
    return viewerValue != null ? viewerValue.color ?? defaultColor : defaultColor ;
  }

  static String getKey(ViewerValue viewerValue, [String defaultKey]) {
    return viewerValue != null ? viewerValue.key ?? defaultKey : defaultKey ;
  }

  //////////////////////////////////

  T _value ;
  final Color color ;
  final ValueCopier<T> _copier ;

  ViewerValue(this._value, this.color, [this._copier]);

  bool get isNull => _value == null ;

  T get value => _value;

  set value(T value) {
    _value = value;
  }

  T get valueCopy => _copier != null ? _copier(_value) : null ;

  String key ;

  @override
  String toString() {
    return key != null ? '{value: $_value, color: $color, key: $key}' : '{value: $_value, color: $color}' ;
  }
}

class _RenderImageResult {
  final Quality quality ;
  Point translate ;

  _RenderImageResult(this.quality, this.translate) ;
}

class CanvasImageViewer {

  static final DATE_FORMAT_YYYY_MM_DD_HH_MM_SS = DateFormat('yyyy/MM/dd HH:mm:ss', Intl.getCurrentLocale()) ;

  final CanvasElement _canvas ;
  int _width ;
  int _height ;

  CanvasImageSource _image ;
  ImageFilter _imageFilter ;

  ViewerValue<Rectangle<num>> _clip ;
  final ViewerValue<List<Rectangle<num>>> _rectangles ;
  final ViewerValue<List<Point<num>>> _points ;
  final ViewerValue<List<Point<num>>> _perspective ;
  final ViewerValue<num> _gridSize ;

  bool _cropPerspective ;

  final DateTime time ;

  final EditionType _editionType ;

  ImagePerspectiveFilterCache _imagePerspectiveFilterCache ;

  CanvasImageViewer(this._canvas, { int width, int height, bool canvasSizeToImageSize = true , CanvasImageSource image, ImageFilter imageFilter,
    ViewerValue< Rectangle<num> > clip ,
    ViewerValue< List<Rectangle<num>> > rectangles ,
    ViewerValue< List<Point<num>> > points ,
    ViewerValue<List<Point<num>>> perspective ,
    ViewerValue<num> gridSize,
    bool cropPerspective,
    this.time , EditionType editable
  } ) :
        _clip = clip ,
        _rectangles = rectangles ,
        _points = points ,
        _perspective = perspective ,
        _gridSize = gridSize ,
        _editionType = editable
  {

    _imageFilter = imageFilter ;

    if (_imageFilter != null) {
      var imgW = 100 ;
      var imgH = 100 ;

      var wh = getImageDimension(image) ;
      if (wh != null) {
        imgW = wh.width ;
        imgH = wh.height ;
      }

      _image = _imageFilter(image, imgW, imgH) ?? image ;
    }
    else {
      _image = image ;
    }

    var w = width ;
    var h = height ;

    if (w == null || h == null) {
      var wh = getImageDimension(_image) ;
      if (wh != null) {
        w ??= wh.width ;
        h ??= wh.height ;
      }
    }

    w ??= 100 ;
    h ??= 100 ;

    _width = w ;
    _height = h ;

    _imagePerspectiveFilterCache = ImagePerspectiveFilterCache(_image, w, h) ;

    if ( _clip != null && !_clip.isNull ) {
      _clip.value = _normalizeClip(_clip.value) ;
    }

    if ( canvasSizeToImageSize ?? true ) {
      _canvas.width = w;
      _canvas.height = h;
    }

    if ( isEditable ) {
      _canvas.onMouseDown.listen(_onMouseDown);
      _canvas.onMouseUp.listen(_onMouseUp);
      _canvas.onClick.listen(_onMouseClick);
      _canvas.onMouseLeave.listen(_onMouseLeave);
      _canvas.onMouseMove.listen(_onMouseMove);
    }

    cropPerspective ??= !isEditable || editable != EditionType.PERSPECTIVE ;

    _cropPerspective = cropPerspective ;

  }

  Rectangle<num> _defaultClip() {
    var border = min(10 , min(_width~/10,_height~/10) ) ;
    return Rectangle(border,border, _width-(border*2), _height-(border*2)) ;
  }

  Rectangle<num> _normalizeClip(Rectangle<num> clip) {
    return _clip.value.intersection( Rectangle(0,0, _width, _height) ) ;
  }

  List< Point<num> > _defaultPerspective() {
    return [ Point(0,0) , Point(width,0) , Point(width,height) , Point(0,height) ] ;
  }

  bool get cropPerspective => _cropPerspective;

  EditionType get editionType => _editionType;
  bool get isEditable => _editionType != null ;

  int get width => _width;
  int get height => _height;

  //////

  static ViewerValue<Rectangle<num>> clipViewerValue(Rectangle<num> clip, [Color color]) {
    return ViewerValue<Rectangle<num>>(clip, color, (v) => Rectangle<num>( v.left , v.top , v.width , v.height ) ) ;
  }

  Rectangle<num> get clip => ViewerValue.copyValue(_clip) ;
  String get clipKey => ViewerValue.getKey(_clip, 'clip') ;

  //////

  static ViewerValue< List<Rectangle<num>> > rectanglesViewerValue(List<Rectangle<num>> rectangles, [Color color]) {
    return ViewerValue< List<Rectangle<num>> >(rectangles, color, (value) => value.map( (r) => Rectangle<num>( r.left , r.top , r.width , r.height ) ).toList() ) ;
  }

  List<Rectangle<num>> get rectangles => ViewerValue.copyValue(_rectangles) ;
  String get rectanglesKey => ViewerValue.getKey(_rectangles, 'rectangles') ;

  //////

  static ViewerValue< List<Point<num>> > pointsViewerValue(List<Point<num>> points, [Color color]) {
    return ViewerValue< List<Point<num>> >(points, color, (value) => value.map( (p) => Point<num>( p.x , p.y ) ).toList() ) ;
  }

  List<Point<num>> get points => ViewerValue.copyValue(_points) ;
  String get pointsKey => ViewerValue.getKey(_points, 'points') ;

  //////

  static ViewerValue<num> gridSizeViewerValue(num gridSize, [Color color]) {
    return ViewerValue<num>(gridSize, color, (value) => value) ;
  }

  num get gridSize => ViewerValue.copyValue(_gridSize) ;
  String get gridSizeKey => ViewerValue.getKey(_gridSize, 'gridSize') ;

  //////

  static ViewerValue< List<Point<num>> > perspectiveViewerValueFromNums(List<num> perspective, [Color color]) {
    if (perspective == null) {
      return perspectiveViewerValue(null, color) ;
    }

    // ignore: omit_local_variable_types
    List< Point<num> > points = [] ;

    for (var i = 1; i < perspective.length; i+=2) {
      var x = perspective[i-1];
      var y = perspective[i];
      points.add( Point(x,y) ) ;
    }

    return perspectiveViewerValue(points, color) ;
  }

  static ViewerValue< List<Point<num>> > perspectiveViewerValue(List< Point<num> > perspective, [Color color]) {
    return ViewerValue< List<Point<num>> >(perspective, color, (value) => value.map( (p) => Point<num>( p.x , p.y ) ).toList() ) ;
  }

  List<Point<num>> get perspective => ViewerValue.copyValue(_perspective) ;
  String get perspectiveKey => ViewerValue.getKey(_perspective, 'perspective') ;

  //////

  void _deselectDOM() {
    var selection = window.getSelection() ;
    if ( selection != null ) {
      selection.empty() ;
    }
  }

  Point _pressed ;

  void _onMouseDown(MouseEvent event) {
    _deselectDOM() ;

    var mouse = event.offset ;
    _pressed = mouse ;

    var edited = edit(mouse, false);
    if (edited != null) {
      _renderImpl( edited , false ) ;
    }
  }

  void _onMouseClick(MouseEvent event) {
    var mouse = event.offset ;

    var edited = edit(mouse, true);
    if (edited != null) {
      _renderImpl( edited , false ) ;
    }
  }

  void _onMouseUp(MouseEvent event) {
    _pressed = null ;
  }

  void _onMouseLeave(MouseEvent event) {
    _pressed = null ;
  }

  void _onMouseMove(MouseEvent event) {
    if ( _pressed == null ) return ;

    var mouse = event.offset ;

    var edited = edit(mouse, false);
    if (edited != null) {
      _renderImpl( edited , false ) ;
    }
  }

  ///////////////////////////////////

  double get offsetWidthRatio {
    var offsetW = _canvas.offset.width;
    return width / offsetW;
  }
  double get offsetHeightRatio {
    var offsetH = _canvas.offset.height;
    return height / offsetH;
  }

  Point _getMousePointInCanvas(Point<num> mouse, [bool fixTranslation = true]) {
    var wRatio = offsetWidthRatio ;
    var hRatio = offsetHeightRatio ;

    var x = (_bound(mouse.x, 0, width) * wRatio).toInt() ;
    var y = (_bound(mouse.y, 0, height) * hRatio).toInt() ;

    if ( fixTranslation && _renderedTranslation != null ) {
      x -= _renderedTranslation.x.toInt() ;
      y -= _renderedTranslation.y.toInt() ;
    }

    print('mouse> xy: $x $y >> ratio: $wRatio $hRatio');

    return Point(x,y) ;
  }

  Quality edit( Point mouse , bool click ) {
    if ( !isEditable ) return null ;

    switch ( _editionType ) {
      case EditionType.CLIP: return adjustClip(mouse, click) ;
      case EditionType.POINTS: return adjustPoints(mouse, click) ;
      case EditionType.PERSPECTIVE: return adjustPerspective(mouse, click) ;
      default: return null ;
    }
  }

  Quality adjustClip( Point mouse , bool click ) {
    if (click) return null ;

    print('--- adjustClip ---') ;
    if (_clip == null) return null ;

    var point = _getMousePointInCanvas(mouse) ;

    var clip = _clip.value ?? _defaultClip() ;
    var edges = _toEdgePoints(clip) ;

    var target = nearestPoint(edges, point) ;

    print(target);

    var clip2 ;

    if ( target == edges[0] || target == edges[1] || target == edges[2] || target == edges[3] || target == edges[4] ) {
      int diffW = point.x-clip.left ;
      clip2 = Rectangle( point.x , clip.top, clip.width-diffW, clip.height ) ;
    }
    else if ( target == edges[5] || target == edges[6] || target == edges[7] || target == edges[8] || target == edges[9] ) {
      int diffH = point.y-clip.top ;
      clip2 = Rectangle( clip.left , point.y, clip.width, clip.height-diffH ) ;
    }
    else if ( target == edges[10] || target == edges[11] || target == edges[12] || target == edges[13] || target == edges[14] ) {
      clip2 = Rectangle( clip.left , clip.top, point.x-clip.left , clip.height ) ;
    }
    else if ( target == edges[15] || target == edges[16] || target == edges[17] || target == edges[18] || target == edges[19] ) {
      clip2 = Rectangle( clip.left , clip.top, clip.width, point.y-clip.top ) ;
    }
    else {
      clip2 = Rectangle<num>( clip.left , clip.top, clip.width, clip.height ) ;
    }

    clip2 = clip2.intersection( Rectangle(0,0,width,height) ) ;

    if (clip2 != null) {
      var clipArea = clip2.width * clip2.height ;
      if (clipArea > 1) {
        _clip = clipViewerValue(clip2 , ViewerValue.getColor(_clip) ) ;
        return Quality.HIGH ;
      }
    }

    return Quality.HIGH ;
  }

  num _bound(num val, num min, num max) {
    return val < min ? min : (val > max ? max : val) ;
  }

  Point<num> _boundPoint(Point<num> val, Point<num> min, Point<num> max) {
    return Point( _bound(val.x, min.x, max.x) , _bound(val.y, min.y, max.y) ) ;
  }

  List<Point> _toEdgePoints( Rectangle r ) {
    var wPart0 = r.width ~/ 8 ;
    var wPart1 = r.width ~/ 4 ;
    var wPart2 = r.width ~/ 2 ;
    var wPart3 = wPart2+wPart1 ;
    var wPart4 = wPart2+wPart1+wPart0 ;

    var hPart0 = r.height ~/ 8 ;
    var hPart1 = r.height ~/ 4 ;
    var hPart2 = r.height ~/ 2 ;
    var hPart3 = hPart2+hPart1 ;
    var hPart4 = hPart2+hPart1+hPart0 ;

    return [
      Point( r.left , r.top+hPart0 ) ,
      Point( r.left , r.top+hPart1 ) ,
      Point( r.left , r.top+hPart2 ) ,
      Point( r.left , r.top+hPart3 ) ,
      Point( r.left , r.top+hPart4 ) ,

      Point( r.left+wPart0 , r.top ) ,
      Point( r.left+wPart1 , r.top ) ,
      Point( r.left+wPart2 , r.top ) ,
      Point( r.left+wPart3 , r.top ) ,
      Point( r.left+wPart4 , r.top ) ,

      Point( r.left+r.width , r.top+hPart0 ) ,
      Point( r.left+r.width , r.top+hPart1 ) ,
      Point( r.left+r.width , r.top+hPart2 ) ,
      Point( r.left+r.width , r.top+hPart3 ) ,
      Point( r.left+r.width , r.top+hPart4 ) ,

      Point( r.left+wPart0 , r.top+r.height ) ,
      Point( r.left+wPart1 , r.top+r.height ) ,
      Point( r.left+wPart2 , r.top+r.height ) ,
      Point( r.left+wPart3 , r.top+r.height ) ,
      Point( r.left+wPart4 , r.top+r.height ) ,
    ] ;
  }

  Point nearestPoint(List<Point<num>> points, Point<num> p) {
    if (points == null || points.isEmpty) return null ;

    Point nearest ;
    double nearestDistance ;

    for (var point in points) {
      var distance = point.distanceTo(p) ;
      if ( nearestDistance == null || distance < nearestDistance ) {
        nearest = point ;
        nearestDistance = distance ;
      }
    }

    return nearest ;
  }

  /////

  Quality adjustPoints( Point mouse , bool click ) {
    if (!click) return null ;

    print('--- adjustPoints ---') ;
    if (_points == null) return null ;

    var point = _getMousePointInCanvas(mouse) ;

    var points = _points.value ?? [] ;

    var target = nearestPoint(points, point) ;

    if (target == null) {
      points.add(point) ;
    }
    else {
      var distance = target.distanceTo(point) ;

      if (distance <= 10) {
        points.remove(target) ;
      }
      else {
        points.add(point) ;
      }
    }

    _points.value = points ;

    return Quality.HIGH ;
  }

  /////

  Quality adjustPerspective(Point<num> mouse, bool click) {
    //if (click) return null ;

    print('--- adjustPerspective ---') ;
    if (_perspective == null) return null ;

    var point = _getMousePointInCanvas(mouse, false) ;

    var points = _perspective.value ?? _defaultPerspective() ;

    if ( points.length != 4 ) points = _defaultPerspective() ;

    var initialBounds = _getPointsBounds(points) ;

    var target = nearestPoint(points, point) ;
    var targetIdx = points.indexOf(target) ;

    print('target: $target #$targetIdx') ;

    var pointsAdjusted = copyPoints(points) ;
    pointsAdjusted[targetIdx] = point ;

    var bounds = _getPointsBounds(pointsAdjusted) ;

    if ( bounds != initialBounds ) {
      var tolerance = max(10, max(width,height)/50) ;

      var wDiff = initialBounds.width - bounds.width ;
      var hDiff = initialBounds.height - bounds.height ;

      var xDiff = target.x - point.x ;
      var yDiff = target.y - point.y ;

      if (wDiff < 0) wDiff = -wDiff ;
      if (hDiff < 0) hDiff = -hDiff ;

      if (xDiff < 0) xDiff = -xDiff ;
      if (yDiff < 0) yDiff = -yDiff ;

      //print('Changing bounds> tolerance: $tolerance > whDiff: $wDiff , $hDiff > xyDiff: $xDiff , $yDiff >> $bounds != $initialBounds') ;

      var pointFixed = point ;

      if (xDiff < tolerance && yDiff < tolerance) {
        if (wDiff > 0 && xDiff < yDiff || xDiff < tolerance) {
          pointFixed = Point(target.x, point.y) ;
        }
        else if (hDiff > 0 && yDiff < xDiff || yDiff < tolerance) {
          pointFixed = Point(point.x, target.y);
        }
      }

      if ( point != pointFixed ) {
        pointsAdjusted[targetIdx] = pointFixed;
        bounds = _getPointsBounds(pointsAdjusted);
        point = pointFixed ;
      }
    }

    var scaleX = width / bounds.width ;
    var scaleY = height / bounds.height ;

    print('scaleX: $scaleX ; scaleY: $scaleY >> $bounds') ;

    var pointsScaled = translatePoints(pointsAdjusted, -bounds.left , -bounds.top) ;
    pointsScaled = scalePointsXY(pointsScaled, scaleX, scaleY) ;

    var spaceW = max(5 , width/20) ;
    var spaceH = max(5 , height/20) ;

    var pointsInBounds = [
      _boundPoint( pointsScaled[0] , Point(0,0) , Point(width/2-spaceW,height/2-spaceH) ) ,
      _boundPoint( pointsScaled[1] , Point(width/2+spaceW,0) , Point(width,height/2-spaceH) ) ,
      _boundPoint( pointsScaled[2] , Point(width/2+spaceW,height/2+spaceH) , Point(width,height) ) ,
      _boundPoint( pointsScaled[3] , Point(0,height/2+spaceH) , Point(width/2-spaceW,height) ) ,
    ] ;

    print('points: $points >> ${ _getPointsBounds(points) }');
    print('pointsAdjusted: $pointsAdjusted >> ${ _getPointsBounds(pointsAdjusted) }');
    print('pointsScaled: $pointsScaled >> ${ _getPointsBounds(pointsScaled) }');
    print('pointsInBounds: $pointsInBounds >> ${ _getPointsBounds(pointsInBounds) }');

    _perspective.value = pointsInBounds ;

    return Quality.MEDIUM ;
  }

  Rectangle<num> _getPointsBounds( List<Point<num>> points ) {
    var p0 = points[0] ;

    var minX = p0.x ;
    var maxX = p0.x ;

    var minY = p0.y ;
    var maxY = p0.y ;

    for (var p in points) {
      if ( p.x < minX ) minX = p.x ;
      if ( p.y < minY ) minY = p.y ;

      if ( p.x > maxX ) maxX = p.x ;
      if ( p.y > maxY ) maxY = p.y ;
    }

    return Rectangle( minX , minY , maxX-minX , maxY-minY ) ;
  }

  /////////////////////////////////////////////////

  void renderAsync( Duration delay ) {
    _renderAsyncImpl( delay , Quality.HIGH , false ) ;
  }

  void _renderAsyncImpl( Duration delay , Quality quality , bool forceQuality ) {
    if ( delay != null ) {
      Future.delayed( delay , () => _renderImpl(quality, forceQuality) ) ;
    }
    else {
      Future.microtask( () => _renderImpl(quality, forceQuality) ) ;
    }
  }

  bool get inDOM {
    return isInDOM(_canvas) ;
  }

  void render() {
    if ( !inDOM ) {
      Future.delayed( Duration(seconds: 1) , () => render()) ;
      return ;
    }

    _renderImpl( Quality.HIGH , false ) ;
  }

  Point<num> _renderedTranslation ;

  void _renderImpl( Quality quality , bool forceQuality ) {
    quality ??= Quality.HIGH ;

    CanvasRenderingContext2D context = _canvas.getContext('2d');

    var renderImageResult = _renderImage(context, quality, forceQuality);

    if ( renderImageResult == null ) {
      return ;
    }

    var translate = renderImageResult.translate ;

    _renderGrid(context, translate, ViewerValue.getValue(_gridSize) , ViewerValue.getColor(_gridSize, Color.CYAN.withOpacity(0.70) ) , 2) ;

    _renderRectangles(context, translate, ViewerValue.getValue(_rectangles) , ViewerValue.getColor(_rectangles, Color.GREEN ) );
    _renderPoints(context, translate, ViewerValue.getValue(_points) , ViewerValue.getColor(_points, Color.RED ) );
    _renderClip(context, translate, ViewerValue.getValue(_clip) , ViewerValue.getColor(_clip, Color.BLUE ) );

    _renderTime(context, translate, time);

    _renderedTranslation = translate ;
  }

  //////////////////////////////////////////

  _RenderImageResult _renderImage(CanvasRenderingContext2D context, Quality quality , bool forceQuality) {
    if ( _perspective != null && !_perspective.isNull ) {
      return _renderImageWithPerspective(context, quality, forceQuality) ;
    }
    else {
      return _renderImageImpl(context);
    }
  }

  _RenderImageResult _renderImageImpl(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height) ;
    context.drawImageScaledFromSource(_image, 0, 0, width, height, 0, 0, width, height);
    return _RenderImageResult( Quality.HIGH , Point(0,0) ) ;
  }

  DateTime renderImageWithPerspective_lastTime = DateTime.now() ;
  Quality renderImageWithPerspective_lastQuality ;
  String renderImageWithPerspective_renderSign ;

  _RenderImageResult _renderImageWithPerspective(CanvasRenderingContext2D context, Quality quality , bool forceQuality) {
    if ( forceQuality && quality == renderImageWithPerspective_lastQuality ) {
      return null ;
    }

    var requestedRenderSign = '$quality > ${ _perspective.value }' ;

    if ( renderImageWithPerspective_renderSign == requestedRenderSign ) {
      return null ;
    }

    var now = DateTime.now() ;

    var renderInterval = now.millisecondsSinceEpoch - renderImageWithPerspective_lastTime.millisecondsSinceEpoch ;
    //renderInterval -= renderImageWithPerspective_renderTime ;
    var shortRenderTime = renderInterval < 100 ;

    var renderQuality = shortRenderTime ? Quality.LOW : quality ;

    if (_forceImageQualityHigh) renderQuality = Quality.HIGH ;

    if ( renderQuality == Quality.LOW && _isImageWithPerspectiveInCache_QualityMedium ) {
      renderQuality = Quality.MEDIUM ;
    }
    else if ( renderQuality == Quality.MEDIUM && _isImageWithPerspectiveInCache_QualityHigh ) {
      renderQuality = Quality.HIGH ;
    }

    if ( forceQuality && quality != renderQuality ) {
      return null ;
    }

    var renderSign = '$renderQuality > ${ _perspective.value }' ;

    if ( renderImageWithPerspective_renderSign == renderSign ) {
      return null ;
    }

    print('-------------------- _renderImageWithPerspective>>>> ') ;
    print('forceQuality: $forceQuality') ;
    print('quality: $quality') ;
    print('renderQuality: $renderQuality') ;
    print('renderInterval: $renderInterval') ;
    print('shortRenderTime: $shortRenderTime') ;

    context.clearRect(0, 0, width, height) ;

    _RenderImageResult renderImageResult ;

    if ( renderQuality == Quality.LOW ) {
      renderImageResult = _renderImageWithPerspective_qualityLow(context);
    }
    else if ( renderQuality == Quality.MEDIUM ) {
      renderImageResult = _renderImageWithPerspective_qualityMedium(context);
    }
    else {
      renderImageResult = _renderImageWithPerspective_qualityHigh(context);
    }

    var renderedQuality = renderImageResult.quality ;

    renderImageWithPerspective_lastTime = DateTime.now() ;
    renderImageWithPerspective_lastQuality = renderedQuality ;

    print('renderedQuality: $renderedQuality') ;

    var renderedSign = '$renderedQuality > ${ _perspective.value }' ;
    renderImageWithPerspective_renderSign = renderedSign ;

    {
      var scheduleDelay ;
      var scheduleQuality ;

      if (renderedQuality == Quality.LOW && !forceQuality) {
        if ( isOffsetRenderScaleGoodForHighQuality ) {
          scheduleDelay = Duration(milliseconds: 200);
          scheduleQuality = Quality.MEDIUM;
        }
        else {
          scheduleDelay = Duration(milliseconds: 500);
          scheduleQuality = Quality.MEDIUM;
        }
      }
      else if (renderedQuality == Quality.MEDIUM ) {
        if ( isOffsetRenderScaleGoodForHighQuality ) {
          scheduleDelay = Duration(milliseconds: 2000);
          scheduleQuality = Quality.HIGH;
        }
      }

      if (scheduleDelay != null && scheduleQuality != null) {
        _renderAsyncImpl(scheduleDelay, scheduleQuality, true) ;
        print('schedulled render> scheduleDelay: $scheduleDelay ; scheduleQuality: $scheduleQuality') ;
      }
    }

    return renderImageResult ;
  }

  double get offsetRenderScale => max( 1/offsetWidthRatio , 1/offsetHeightRatio ) ;
  bool get isOffsetRenderScaleGoodForHighQuality => offsetRenderScale > 0.70 || _forceImageQualityHigh ;

  double get renderScale_QualityLow => offsetRenderScale * 0.40 ;
  double get renderScale_QualityMedium => offsetRenderScale * 1.05 ;
  double get renderScale_QualityHigh => 1 ;

  //bool get _isImageWithPerspectiveInCache_QualityLow => _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(_perspective.value, renderScale_QualityLow) ;
  bool get _isImageWithPerspectiveInCache_QualityMedium => _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(_perspective.value, renderScale_QualityMedium) ;
  bool get _isImageWithPerspectiveInCache_QualityHigh => _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(_perspective.value, renderScale_QualityHigh) ;

  _RenderImageResult _renderImageWithPerspective_qualityLow(CanvasRenderingContext2D context) {
    var scaleOffset = offsetRenderScale ;
    var scale = renderScale_QualityLow ;

    print('_renderImageWithPerspective_qualityLow> scale: $scale ; scaleOffset: $scaleOffset') ;

    if (scaleOffset < 0.30) {
      return _renderImageWithPerspective_qualityMedium(context) ;
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(_perspective.value , scale) ;

    return _buildRenderImageResult( context, Quality.LOW , scale , filterResult ) ;
  }


  _RenderImageResult _renderImageWithPerspective_qualityMedium(CanvasRenderingContext2D context) {
    var scaleOffset = offsetRenderScale ;
    var scale = renderScale_QualityMedium ;

    print('_renderImageWithPerspective_qualityMedium> scale: $scale ; scaleOffset: $scaleOffset') ;

    if (scale > 0.80) {
      return _renderImageWithPerspective_qualityHigh(context) ;
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(_perspective.value , scale) ;

    return _buildRenderImageResult( context, Quality.MEDIUM , scale , filterResult ) ;
  }

  final bool _forceImageQualityHigh = false ;

  _RenderImageResult _renderImageWithPerspective_qualityHigh(CanvasRenderingContext2D context) {
    var scaleOffset = offsetRenderScale ;
    var scale = renderScale_QualityHigh ;

    print('_renderImageWithPerspective_qualityHigh> scale: $scale ; scaleOffset: $scaleOffset') ;

    if ( !isOffsetRenderScaleGoodForHighQuality ) {
      return _renderImageWithPerspective_qualityMedium(context) ;
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(_perspective.value , scale) ;

    return _buildRenderImageResult( context, Quality.HIGH , scale , filterResult ) ;
  }

  _RenderImageResult _buildRenderImageResult(CanvasRenderingContext2D context, Quality quality, double scale, FilterResult filterResult ) {

    if ( _cropPerspective ) {
      var imageResult = filterResult.imageResult ;
      var imageResultCropped = filterResult.imageResultCropped ;

      var w = imageResultCropped.width ;
      var h = imageResultCropped.height ;

      var cropWRatio = imageResultCropped.width / imageResult.width ;
      var cropHRatio = imageResultCropped.height / imageResult.height ;

      var w2 = (width * cropWRatio).toInt() ;
      var h2 = (height * cropHRatio).toInt() ;

      context.drawImageScaledFromSource(imageResultCropped, 0, 0, w, h, 0, 0, w2, h2);

      return _RenderImageResult( quality , Point(0,0) ) ;
    }
    else {
      var imageFiltered = filterResult.imageResult ;

      var w = imageFiltered.width ;
      var h = imageFiltered.height ;

      context.drawImageScaledFromSource(imageFiltered, 0, 0, w, h, 0, 0, width, height);

      return _RenderImageResult( quality , filterResult.translationScaled(1/scale) ) ;
    }

  }

  void _renderClip(CanvasRenderingContext2D context, Point<num> translate, Rectangle clip, Color color) {
    if (clip == null) return ;

    _renderShadow(context, translate, clip) ;

    _translate(context, translate);

    _strokeRect(context, clip, color, 3);
  }

  void _renderShadow(CanvasRenderingContext2D context, Point<num> translate, Rectangle clip) {
    if (clip == null) return ;

    context.setFillColorRgb(0, 0, 0, 0.40);

    _translate(context, null);

    if (translate != null && (translate.x != 0 || translate.y != 0) ) {
      var x = translate.x;
      var y = translate.y;

      context.fillRect(0, 0, x, height);
      context.fillRect(x, 0, width-x, y);
    }

    _translate(context, translate);

    context.fillRect(0, 0, width, clip.top);
    context.fillRect(0, clip.top + clip.height, width, height - (clip.top + clip.height));
    context.fillRect(0, clip.top, clip.left, clip.height);
    context.fillRect(clip.left + clip.width, clip.top, width - (clip.left + clip.width), clip.height);
  }

  void _renderRectangles(CanvasRenderingContext2D context, Point<num> translate, List<Rectangle<num>> rectangles, Color color) {
    if (rectangles == null || rectangles.isEmpty) return ;

    _translate(context, translate);

    _strokeRects(context, rectangles, color, 3);
  }

  void _renderPoints(CanvasRenderingContext2D context, Point<num> translate, List<Point<num>> points, Color color) {
    if (points == null || points.isEmpty) return ;

    _translate(context, translate);

    _strokePoints(context, points, color, 3);
  }

  void _renderGrid(CanvasRenderingContext2D context, Point<num> translate, num gridSize, Color color, int lineWidth) {
    if (gridSize == null || gridSize <= 0 || lineWidth == null || lineWidth < 1) return ;

    _translate(context, null);

    context.setStrokeColorRgb( color.red , color.green, color.blue , color.opacity ) ;
    context.lineWidth = lineWidth;

    // ignore: omit_local_variable_types
    int size = gridSize is double ? ( gridSize < 1 ? min( (width*gridSize).toInt() , (height*gridSize).toInt() ) : gridSize.toInt() ) : gridSize.toInt() ;
    var minSize = max(2, lineWidth*3) ;
    if (size < minSize) size = minSize ;

    for (var x = size ; x < width ; x += size) {
      context.beginPath();
      context.moveTo(x, 0);
      context.lineTo(x, height);
      context.stroke();
    }

    for (var y = size ; y < height ; y += size) {
      context.beginPath();
      context.moveTo(0, y);
      context.lineTo(width, y);
      context.stroke();
    }

  }

  void _renderTime(CanvasRenderingContext2D context, Point<num> translate, DateTime time) {
    if (time == null) return ;

    _translate(context, null);

    var timeStr = DATE_FORMAT_YYYY_MM_DD_HH_MM_SS.format( time.toLocal() ) ;

    context.font = '30px Arial';

    var margin = 4 ;
    var shadow = 2 ;

    context.setFillColorRgb(0, 0, 0, 0.60);
    context.fillText(timeStr, margin, height-margin) ;

    context.setFillColorRgb(255, 255, 255, 0.70);
    context.fillText(timeStr, margin+shadow, height-(margin+shadow)) ;
  }

  /////////////////////////////////////////////////////

  void _translate(CanvasRenderingContext2D context, Point<num> translate) {
    context.resetTransform() ;
    if (translate != null) {
      context.translate(translate.x, translate.y);
    }
  }

  void _strokeRects(CanvasRenderingContext2D context, List<Rectangle<num>> rects, Color color, int lineWidth) {
    for (var rect in rects) {
      _strokeRect(context, rect, color, lineWidth);
    }
  }

  void _strokeRect(CanvasRenderingContext2D context, Rectangle<num> rect, Color color, int lineWidth) {
    context.setStrokeColorRgb( color.red , color.green, color.blue , 0.40) ;
    context.lineWidth = lineWidth;
    context.strokeRect(rect.left, rect.top, rect.width, rect.height);

    context.setStrokeColorRgb( color.red , color.green, color.blue ) ;
    context.lineWidth = 1;
    context.strokeRect(rect.left, rect.top, rect.width, rect.height);
  }

  void _strokePoints(CanvasRenderingContext2D context, List<Point<num>> points, Color color, int lineWidth) {
    for (var p in points) {
      _strokePoint(context, p, color, lineWidth);
    }
  }

  void _strokePoint(CanvasRenderingContext2D context, Point<num> p, Color color, int lineWidth) {
    var b = 3 ;
    var l = b*2;

    context.setStrokeColorRgb( Color.BLACK.red , Color.BLACK.green, Color.BLACK.blue) ;
    context.lineWidth = lineWidth;
    context.strokeRect(p.x-b-1, p.y-b+1, l, l);

    context.setStrokeColorRgb( Color.WHITE.red , Color.WHITE.green, Color.WHITE.blue) ;
    context.lineWidth = lineWidth;
    context.strokeRect(p.x-b+1, p.y-b-1, l, l);

    context.setStrokeColorRgb( color.red , color.green, color.blue ) ;
    context.lineWidth = lineWidth;
    context.strokeRect(p.x-b, p.y-b, l, l);
  }


}


CanvasElement toCanvasElement( CanvasImageSource imageSource , int width, int height ) {
  var canvas = CanvasElement( width: width , height: height ) ;
  CanvasRenderingContext2D context = canvas.getContext('2d');

  context.drawImage(imageSource, 0, 0);

  return canvas ;
}

ImageElement canvasToImageElement( CanvasElement canvas , [String mimeType, num quality] ) {
  mimeType ??= 'image/png' ;
  quality ??= 0.99 ;

  var dataUrl = canvas.toDataUrl(mimeType) ;
  var img = ImageElement(src: dataUrl) ;
  img.width = canvas.width ;
  img.height = canvas.height ;
  return img ;
}

CanvasElement rotateImageElement( ImageElement image, [ angleDegree = 90 ] ) {
  var w = image.width ;
  var h = image.height ;
  return rotateCanvasImageSource( image , w, h, angleDegree) ;
}

CanvasElement rotateCanvasImageSource( CanvasImageSource image , int width, int height, [ angleDegree = 90 ]) {
  angleDegree ??= 90 ;

  var canvas = CanvasElement( width: height , height: width ) ;
  CanvasRenderingContext2D context = canvas.getContext('2d');

  context.translate(canvas.width/2 , canvas.height/2);
  context.rotate(angleDegree*math.pi/180);
  context.drawImage(image,-width/2,-height/2);

  return canvas ;
}
