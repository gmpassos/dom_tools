
import 'dart:html';
import 'dart:math' as math ;

import 'package:intl/intl.dart';

////////////////////////////////////////////////////////////////////////////////
// Class Color from  'dart:ui' (Flutter):
////////////////////////////////////////////////////////////////////////////////

class Color {
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
  const Color.fromRGBO(int r, int g, int b, double opacity) :
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
    if (component <= 0.03928)
      return component / 12.92;
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
    final double R = _linearizeColorComponent(red / 0xFF);
    final double G = _linearizeColorComponent(green / 0xFF);
    final double B = _linearizeColorComponent(blue / 0xFF);
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
    final int alpha = foreground.alpha;
    if (alpha == 0x00) { // Foreground completely transparent.
      return background;
    }
    final int invAlpha = 0xff - alpha;
    int backAlpha = background.alpha;
    if (backAlpha == 0xff) { // Opaque background case
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    } else { // General case
      backAlpha = (backAlpha * invAlpha) ~/ 0xff;
      final int outAlpha = alpha + backAlpha;
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
// Image Viewer using Canvas and highlight elements (Clip and Rectangles)
////////////////////////////////////////////////////////////////////////////////

typedef ImageFilter = CanvasImageSource Function(CanvasImageSource image, int width, int height) ;

class CanvasImageViewer {

  static final DATE_FORMAT_YYYY_MM_DD_HH_MM_SS = DateFormat('yyyy/MM/dd HH:mm:ss', Intl.getCurrentLocale()) ;

  final CanvasElement _canvas ;
  int _width ;
  int _height ;

  CanvasImageSource _image ;
  ImageFilter _imageFilter ;

  Rectangle<num> _clip ;
  final Color _clipColor ;

  final List<Rectangle<num>> _rectangles ;
  final Color _rectanglesColor ;

  final DateTime time ;

  final bool _editable ;

  CanvasImageViewer(this._canvas, { int width, int height, bool canvasSizeToImageSize = true , CanvasImageSource image, ImageFilter imageFilter, Rectangle<num> clip , String clipColor, List<Rectangle<num>> rectangles , Color rectanglesColor , this.time , bool editable} ) :
        _clip = clip ,
        _clipColor = Color.parse(clipColor ?? '#0000FF') ,
        _rectangles = rectangles ,
        _rectanglesColor = Color.parse(rectanglesColor ?? '#00FF00') ,
        _editable = editable ?? false
  {

    _imageFilter = imageFilter ;

    if (_imageFilter != null) {
      var imgW = 100 ;
      var imgH = 100 ;

      var wh = getCanvasImageSource_Width_Height(image) ;
      if (wh != null) {
        imgW = wh[0];
        imgH = wh[1];
      }

      _image = _imageFilter(image, imgW, imgH) ?? image ;
    }
    else {
      _image = image ;
    }

    var w = width ;
    var h = height ;

    if (w == null || h == null) {
      var wh = getCanvasImageSource_Width_Height(_image) ;
      if (wh != null) {
        w ??= wh[0];
        h ??= wh[1];
      }
    }

    w ??= 100 ;
    h ??= 100 ;

    _width = w ;
    _height = h ;

    _clip = _clip != null ? _clip.intersection( Rectangle(0,0,w,h) ) : Rectangle(0,0,w,h) ;

    if ( canvasSizeToImageSize ?? true ) {
      _canvas.width = w;
      _canvas.height = h;
    }

    if ( _editable ) {
      _canvas.onMouseDown.listen(_onMouseDown);
      _canvas.onMouseUp.listen(_onMouseUp);
      _canvas.onMouseLeave.listen(_onMouseLeave);
      _canvas.onMouseMove.listen(_onMouseMove);
    }

  }

  static List<int> getCanvasImageSource_Width_Height(CanvasImageSource image) {
    if ( image is ImageElement ) {
      return [ image.naturalWidth , image.naturalHeight ] ;
    }
    else if ( image is CanvasElement ) {
      return [ image.width , image.height ] ;
    }
    else if ( image is VideoElement ) {
      return [ image.width , image.height ] ;
    }
    return null ;
  }

  int get width => _width;
  int get height => _height;

  Rectangle<num> get clip => Rectangle( _clip.left , _clip.top , _clip.width , _clip.height ) ;
  List<Rectangle<num>> get rectangles => _rectangles.map( (r) => Rectangle( r.left , r.top , r.width , r.height ) ).toList() ;

  Point _pressed ;

  void _onMouseDown(MouseEvent event) {
    var mouse = event.offset ;
    _pressed = mouse ;

    adjustClip(_pressed);
    render();
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

    adjustClip(mouse);
    render();
  }

  void adjustClip( Point mouse ) {
    if (!_editable) return ;

    var wRatio = width / _canvas.offset.width ;
    var hRatio = height / _canvas.offset.height ;

    var x = (bound(mouse.x, 0, width) * wRatio).toInt() ;
    var y = (bound(mouse.y, 0, height) * hRatio).toInt() ;

    print('---> xy: $x $y >> ratio: $wRatio $hRatio');

    var edges = _toEdgePoints(_clip) ;
    var target = nearestPoint(edges, Point(x,y)) ;

    print(target);

    var clip2 = Rectangle( _clip.left , _clip.top, _clip.width, _clip.height ) ;

    if ( target == edges[0] || target == edges[1] || target == edges[2] || target == edges[3] || target == edges[4] ) {
      int diffW = x-_clip.left ;
      clip2 = Rectangle( x , _clip.top, _clip.width-diffW, _clip.height ) ;
    }
    else if ( target == edges[5] || target == edges[6] || target == edges[7] || target == edges[8] || target == edges[9] ) {
      int diffH = y-_clip.top ;
      clip2 = Rectangle( _clip.left , y, _clip.width, _clip.height-diffH ) ;
    }
    else if ( target == edges[10] || target == edges[11] || target == edges[12] || target == edges[13] || target == edges[14] ) {
      clip2 = Rectangle( _clip.left , _clip.top, x-_clip.left , _clip.height ) ;
    }
    else if ( target == edges[15] || target == edges[16] || target == edges[17] || target == edges[18] || target == edges[19] ) {
      clip2 = Rectangle( _clip.left , _clip.top, _clip.width, y-_clip.top ) ;
    }

    clip2 = clip2.intersection( Rectangle(0,0,width,height) ) ;

    if (clip2 != null) {
      _clip = clip2;
    }
  }

  int bound(int val, int min, int max) {
    return val < min ? min : (val > max ? max : val) ;
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

  Point nearestPoint(List<Point> points, Point p) {
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

  void render() {
    CanvasRenderingContext2D context = _canvas.getContext('2d');
    context.clearRect(0, 0, width, height) ;

    renderImage(context, _image);
    renderRectangles(context, _rectangles);
    renderClip(context, _clip);
    renderTime(context, time);
  }


  void renderImage(CanvasRenderingContext2D context, CanvasImageSource image) {
    context.drawImageScaledFromSource(image, 0, 0, width, height, 0, 0, width, height);
  }

  void renderClip(CanvasRenderingContext2D context, Rectangle clip) {
    if (clip == null) return ;

    renderShadow(context, clip) ;

    context.setStrokeColorRgb( _clipColor.red , _clipColor.green, _clipColor.blue ) ;
    context.lineWidth = 4;
    _strokeRect(context, clip);
  }

  void renderShadow(CanvasRenderingContext2D context, Rectangle clip) {
    if (clip == null) return ;

    context.setFillColorRgb(0, 0, 0, 0.40);

    context.fillRect(0, 0, width, clip.top);
    context.fillRect(0, clip.top + clip.height, width, height - (clip.top + clip.height));
    context.fillRect(0, clip.top, clip.left, clip.height);
    context.fillRect(clip.left + clip.width, clip.top, width - (clip.left + clip.width), clip.height);
  }

  void renderRectangles(CanvasRenderingContext2D context, List<Rectangle<num>> rectangles) {
    if (rectangles == null || rectangles.isEmpty) return ;

    context.setStrokeColorRgb( _rectanglesColor.red , _rectanglesColor.green, _rectanglesColor.blue ) ;
    context.lineWidth = 3;

    _strokeRects(context, rectangles);
  }

  void _strokeRect(CanvasRenderingContext2D context, Rectangle<num> rect) {
    context.strokeRect(rect.left, rect.top, rect.width, rect.height);
  }

  void _strokeRects(CanvasRenderingContext2D context, List<Rectangle<num>> rects) {
    for (var rect in rects) {
      _strokeRect(context, rect);
    }
  }

  void renderTime(CanvasRenderingContext2D context, DateTime time) {
    if (time == null) return ;

    var timeStr = DATE_FORMAT_YYYY_MM_DD_HH_MM_SS.format( time.toLocal() ) ;

    context.font = '30px Arial';

    var margin = 4 ;
    var shadow = 2 ;

    context.setFillColorRgb(0, 0, 0, 0.60);
    context.fillText(timeStr, margin, height-margin) ;

    context.setFillColorRgb(255, 255, 255, 0.70);
    context.fillText(timeStr, margin+shadow, height-(margin+shadow)) ;
  }


}



