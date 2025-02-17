import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:swiss_knife/swiss_knife.dart';
import 'package:web_utils/web_utils.dart';

import 'dom_tools_base.dart';
import 'perspective_filter.dart';

/// Represents a color.
///
/// This class is based into `dart:ui` (Flutter) implementation.
class Color {
  static final Color black = Color.fromRGBO(0, 0, 0);
  static final Color white = Color.fromRGBO(255, 255, 255);

  static final Color grey = Color.fromRGBO(128, 128, 128);
  static final Color greyLight = Color.fromRGBO(160, 160, 160);
  static final Color greyLighter = Color.fromRGBO(192, 192, 192);
  static final Color greyDark = Color.fromRGBO(96, 96, 96);

  static final Color greyDarker = Color.fromRGBO(64, 64, 64);

  // ignore: non_constant_identifier_names
  static final Color RED = Color.fromRGBO(255, 0, 0);

  // ignore: non_constant_identifier_names
  static final Color GREEN = Color.fromRGBO(0, 255, 0);

  // ignore: non_constant_identifier_names
  static final Color BLUE = Color.fromRGBO(0, 0, 255);

  static final Color cyan = Color.fromRGBO(0, 255, 255);

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
  const Color.fromARGB(int a, int r, int g, int b)
      : value = (((a & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

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
  const Color.fromRGBO(int r, int g, int b, [double opacity = 1.0])
      : value = ((((opacity * 0xff ~/ 1) & 0xff) << 24) |
                ((r & 0xff) << 16) |
                ((g & 0xff) << 8) |
                ((b & 0xff) << 0)) &
            0xFFFFFFFF;

  factory Color.fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    while (hexColor.length < 8) {
      hexColor = 'FF$hexColor';
    }
    var color = int.parse(hexColor, radix: 16);
    return Color(color);
  }

  factory Color.parse(String? colorStr) {
    if (colorStr == null) return Color(0);
    colorStr = colorStr.trim();

    if (RegExp(r'\d+\s*,\s*\d+\s*,\s*\d+').hasMatch(colorStr)) {
      var parts = colorStr.split(RegExp(r'\D+'));
      var r = int.parse(parts[0]);
      var g = int.parse(parts[1]);
      var b = int.parse(parts[2]);
      return Color.fromARGB(0, r, g, b);
    } else if (colorStr.startsWith('#')) {
      return Color.fromHex(colorStr);
    } else {
      var argb = int.parse(colorStr);
      return Color(argb);
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

  /// Returns [alpha] in range of 0 .. 1 value.
  double get alphaRatio => alpha / 255;

  /// Returns [true] if colors has alpha != 255 value.
  bool get hasAlpha => alpha != 255;

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

  /// Returns a new color with alpha value [aRatio] * 255.
  Color withAlphaRatio(double aRatio) {
    return Color.fromARGB((255 * aRatio).toInt(), red, green, blue);
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
    if (alpha == 0x00) {
      // Foreground completely transparent.
      return background;
    }
    var invAlpha = 0xff - alpha;
    var backAlpha = background.alpha;
    if (backAlpha == 0xff) {
      // Opaque background case
      return Color.fromARGB(
        0xff,
        (alpha * foreground.red + invAlpha * background.red) ~/ 0xff,
        (alpha * foreground.green + invAlpha * background.green) ~/ 0xff,
        (alpha * foreground.blue + invAlpha * background.blue) ~/ 0xff,
      );
    } else {
      // General case
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
  static int getAlphaFromOpacity(double opacity) =>
      (opacity.clamp(0.0, 1.0) * 255).round();

  @override
  bool operator ==(Object other) {
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

/// A color represented using [alpha], [hue], [saturation], and [value].
///
/// An [HSVColor] is represented in a parameter space that's based on human
/// perception of color in pigments (e.g. paint and printer's ink). The
/// representation is useful for some color computations (e.g. rotating the hue
/// through the colors), because interpolation and picking of
/// colors as red, green, and blue channels doesn't always produce intuitive
/// results.
///
/// The HSV color space models the way that different pigments are perceived
/// when mixed. The hue describes which pigment is used, the saturation
/// describes which shade of the pigment, and the value resembles mixing the
/// pigment with different amounts of black or white pigment.
///
/// See also:
///
///  * [HSLColor], a color that uses a color space based on human perception of
///    colored light.
///  * [HSV and HSL](https://en.wikipedia.org/wiki/HSL_and_HSV) Wikipedia
///    article, which this implementation is based upon.
///
///  Based into:
///  https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/painting/colors.dart
class HSVColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSVColor.fromAHSV(this.alpha, this.hue, this.saturation, this.value)
      : assert(alpha >= 0.0),
        assert(alpha <= 1.0),
        assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 1.0),
        assert(value >= 0.0),
        assert(value <= 1.0);

  /// Creates an [HSVColor] from an RGB [Color].
  ///
  /// This constructor does not necessarily round-trip with [toColor] because
  /// of floating point imprecision.
  factory HSVColor.fromColor(Color color) {
    var red = color.red / 0xFF;
    var green = color.green / 0xFF;
    var blue = color.blue / 0xFF;

    var max = math.max(red, math.max(green, blue));
    var min = math.min(red, math.min(green, blue));
    var delta = max - min;

    var alpha = color.alpha / 0xFF;
    var hue = _getHue(red, green, blue, max, delta);
    var saturation = max == 0.0 ? 0.0 : delta / max;

    return HSVColor.fromAHSV(alpha, hue, saturation, max);
  }

  /// Alpha, from 0.0 to 1.0. The describes the transparency of the color.
  /// A value of 0.0 is fully transparent, and 1.0 is fully opaque.
  final double alpha;

  /// Hue, from 0.0 to 360.0. Describes which color of the spectrum is
  /// represented. A value of 0.0 represents red, as does 360.0. Values in
  /// between go through all the hues representable in RGB. You can think of
  /// this as selecting which pigment will be added to a color.
  final double hue;

  /// Saturation, from 0.0 to 1.0. This describes how colorful the color is.
  /// 0.0 implies a shade of grey (i.e. no pigment), and 1.0 implies a color as
  /// vibrant as that hue gets. You can think of this as the equivalent of
  /// how much of a pigment is added.
  final double saturation;

  /// Value, from 0.0 to 1.0. The "value" of a color that, in this context,
  /// describes how bright a color is. A value of 0.0 indicates black, and 1.0
  /// indicates full intensity color. You can think of this as the equivalent of
  /// removing black from the color as value increases.
  final double value;

  /// Returns a copy of this color with the [alpha] parameter replaced with the
  /// given value.
  HSVColor withAlpha(double alpha) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the [hue] parameter replaced with the
  /// given value.
  HSVColor withHue(double hue) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the [saturation] parameter replaced with
  /// the given value.
  HSVColor withSaturation(double saturation) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns a copy of this color with the [value] parameter replaced with the
  /// given value.
  HSVColor withValue(double value) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  /// Returns this color in RGB.
  Color toColor() {
    var chroma = saturation * value;
    var secondary = chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    var match = value - chroma;

    return _colorFromHue(alpha, hue, chroma, secondary, match);
  }

  HSVColor _scaleAlpha(double factor) {
    return withAlpha(alpha * factor);
  }

  /// Linearly interpolate between two HSVColors.
  ///
  /// The colors are interpolated by interpolating the [alpha], [hue],
  /// [saturation], and [value] channels separately, which usually leads to a
  /// more pleasing effect than [Color.lerp] (which interpolates the red, green,
  /// and blue channels separately).
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color. This is usually preferable to
  /// interpolating from [Colors.transparent] (`const Color(0x00000000)`) since
  /// that will interpolate from a transparent red and cycle through the hues to
  /// match the target color, regardless of what that color's hue is.
  ///
  /// {@macro dart.ui.shadow.lerp}
  ///
  /// Values outside of the valid range for each channel will be clamped.
  static HSVColor? lerp(HSVColor? a, HSVColor? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!._scaleAlpha(t);
    if (b == null) return a._scaleAlpha(1.0 - t);
    return HSVColor.fromAHSV(
      lerpDouble(a.alpha, b.alpha, t)!.clamp(0.0, 1.0),
      lerpDouble(a.hue, b.hue, t)! % 360.0,
      lerpDouble(a.saturation, b.saturation, t)!.clamp(0.0, 1.0),
      lerpDouble(a.value, b.value, t)!.clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HSVColor &&
        other.alpha == alpha &&
        other.hue == hue &&
        other.saturation == saturation &&
        other.value == value;
  }

  @override
  int get hashCode => deepHashCodeList([alpha, hue, saturation, value]);

  @override
  String toString() =>
      'HSVColor($hue, ${saturation * 100}, ${value * 100}, $alpha)';
}

/// A color represented using [alpha], [hue], [saturation], and [lightness].
///
/// An [HSLColor] is represented in a parameter space that's based up human
/// perception of colored light. The representation is useful for some color
/// computations (e.g., combining colors of light), because interpolation and
/// picking of colors as red, green, and blue channels doesn't always produce
/// intuitive results.
///
/// HSL is a perceptual color model, placing fully saturated colors around a
/// circle (conceptually) at a lightness of ​0.5, with a lightness of 0.0 being
/// completely black, and a lightness of 1.0 being completely white. As the
/// lightness increases or decreases from 0.5, the apparent saturation decreases
/// proportionally (even though the [saturation] parameter hasn't changed).
///
/// See also:
///
///  * [HSVColor], a color that uses a color space based on human perception of
///    pigments (e.g. paint and printer's ink).
///  * [HSV and HSL](https://en.wikipedia.org/wiki/HSL_and_HSV) Wikipedia
///    article, which this implementation is based upon.
///
///  Based into:
///  https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/painting/colors.dart
class HSLColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSLColor.fromAHSL(this.alpha, this.hue, this.saturation, this.lightness)
      : assert(alpha >= 0.0),
        assert(alpha <= 1.0),
        assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 1.0),
        assert(lightness >= 0.0),
        assert(lightness <= 1.0);

  /// Creates an [HSLColor] from an RGB [Color].
  ///
  /// This constructor does not necessarily round-trip with [toColor] because
  /// of floating point imprecision.
  factory HSLColor.fromColor(Color color) {
    var red = color.red / 0xFF;
    var green = color.green / 0xFF;
    var blue = color.blue / 0xFF;

    var max = math.max(red, math.max(green, blue));
    var min = math.min(red, math.min(green, blue));
    var delta = max - min;

    var alpha = color.alpha / 0xFF;
    var hue = _getHue(red, green, blue, max, delta);
    var lightness = (max + min) / 2.0;
    // Saturation can exceed 1.0 with rounding errors, so clamp it.
    var saturation = lightness == 1.0
        ? 0.0
        : (delta / (1.0 - (2.0 * lightness - 1.0).abs())).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  /// Alpha, from 0.0 to 1.0. The describes the transparency of the color.
  /// A value of 0.0 is fully transparent, and 1.0 is fully opaque.
  final double alpha;

  /// Hue, from 0.0 to 360.0. Describes which color of the spectrum is
  /// represented. A value of 0.0 represents red, as does 360.0. Values in
  /// between go through all the hues representable in RGB. You can think of
  /// this as selecting which color filter is placed over a light.
  final double hue;

  /// Saturation, from 0.0 to 1.0. This describes how colorful the color is.
  /// 0.0 implies a shade of grey (i.e. no pigment), and 1.0 implies a color as
  /// vibrant as that hue gets. You can think of this as the purity of the
  /// color filter over the light.
  final double saturation;

  /// Lightness, from 0.0 to 1.0. The lightness of a color describes how bright
  /// a color is. A value of 0.0 indicates black, and 1.0 indicates white. You
  /// can think of this as the intensity of the light behind the filter. As the
  /// lightness approaches 0.5, the colors get brighter and appear more
  /// saturated, and over 0.5, the colors start to become less saturated and
  /// approach white at 1.0.
  final double lightness;

  /// Returns a copy of this color with the alpha parameter replaced with the
  /// given value.
  HSLColor withAlpha(double alpha) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  /// Returns a copy of this color with the [hue] parameter replaced with the
  /// given value.
  HSLColor withHue(double hue) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  /// Returns a copy of this color with the [saturation] parameter replaced with
  /// the given value.
  HSLColor withSaturation(double saturation) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  /// Returns a copy of this color with the [lightness] parameter replaced with
  /// the given value.
  HSLColor withLightness(double lightness) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  /// Returns this HSL color in RGB.
  Color toColor() {
    var chroma = (1.0 - (2.0 * lightness - 1.0).abs()) * saturation;
    var secondary = chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    var match = lightness - chroma / 2.0;

    return _colorFromHue(alpha, hue, chroma, secondary, match);
  }

  HSLColor _scaleAlpha(double factor) {
    return withAlpha(alpha * factor);
  }

  /// Linearly interpolate between two HSLColors.
  ///
  /// The colors are interpolated by interpolating the [alpha], [hue],
  /// [saturation], and [lightness] channels separately, which usually leads to
  /// a more pleasing effect than [Color.lerp] (which interpolates the red,
  /// green, and blue channels separately).
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color. This is usually preferable to
  /// interpolating from [Colors.transparent] (`const Color(0x00000000)`) since
  /// that will interpolate from a transparent red and cycle through the hues to
  /// match the target color, regardless of what that color's hue is.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values between them
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid
  /// (and can easily be generated by curves such as [Curves.elasticInOut]).
  ///
  /// Values outside of the valid range for each channel will be clamped.
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an [AnimationController].
  static HSLColor? lerp(HSLColor? a, HSLColor? b, double t) {
    if (a == null && b == null) return null;
    if (a == null) return b!._scaleAlpha(t);
    if (b == null) return a._scaleAlpha(1.0 - t);
    return HSLColor.fromAHSL(
      lerpDouble(a.alpha, b.alpha, t)!.clamp(0.0, 1.0),
      lerpDouble(a.hue, b.hue, t)! % 360.0,
      lerpDouble(a.saturation, b.saturation, t)!.clamp(0.0, 1.0),
      lerpDouble(a.lightness, b.lightness, t)!.clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HSLColor &&
        other.alpha == alpha &&
        other.hue == hue &&
        other.saturation == saturation &&
        other.lightness == lightness;
  }

  @override
  int get hashCode => deepHashCodeList([alpha, hue, saturation, lightness]);

  @override
  String toString() =>
      'hsl($hue, ${Math.round(saturation * 100)}, ${Math.round(lightness * 100)}, $alpha)';
}

double _getHue(
    double red, double green, double blue, double max, double delta) {
  var hue = 0.0;
  if (max == 0.0) {
    hue = 0.0;
  } else if (max == red) {
    hue = 60.0 * (((green - blue) / delta) % 6);
  } else if (max == green) {
    hue = 60.0 * (((blue - red) / delta) + 2);
  } else if (max == blue) {
    hue = 60.0 * (((red - green) / delta) + 4);
  }

  /// Set hue to 0.0 when red == green == blue.
  hue = hue.isNaN ? 0.0 : hue;
  return hue;
}

double? lerpDouble(num a, num b, double t) {
  return a + (b - a) * t;
}

Color _colorFromHue(
  double alpha,
  double hue,
  double chroma,
  double secondary,
  double match,
) {
  double red;
  double green;
  double blue;
  if (hue < 60.0) {
    red = chroma;
    green = secondary;
    blue = 0.0;
  } else if (hue < 120.0) {
    red = secondary;
    green = chroma;
    blue = 0.0;
  } else if (hue < 180.0) {
    red = 0.0;
    green = chroma;
    blue = secondary;
  } else if (hue < 240.0) {
    red = 0.0;
    green = secondary;
    blue = chroma;
  } else if (hue < 300.0) {
    red = secondary;
    green = 0.0;
    blue = chroma;
  } else {
    red = chroma;
    green = 0.0;
    blue = secondary;
  }
  return Color.fromARGB((alpha * 0xFF).round(), ((red + match) * 0xFF).round(),
      ((green + match) * 0xFF).round(), ((blue + match) * 0xFF).round());
}

/// Gets the width and height from [image] ([CanvasImageSource]).
Rectangle<int>? getImageDimension(CanvasImageSource image) {
  if (image.isA<HTMLImageElement>()) {
    final img = image as HTMLImageElement;
    return Rectangle(0, 0, img.naturalWidth, img.naturalHeight);
  } else if (image.isA<HTMLCanvasElement>()) {
    final canvas = image as HTMLCanvasElement;
    return Rectangle(0, 0, canvas.width, canvas.height);
  } else if (image.isA<HTMLVideoElement>()) {
    final video = image as HTMLVideoElement;
    return Rectangle(0, 0, video.width, video.height);
  }
  return null;
}

/// Crops an image using a [Rectangle] ([crop]),
/// delegating to method [cropImage],
HTMLCanvasElement? cropImageByRectangle(
    CanvasImageSource image, Rectangle? crop) {
  if (crop == null) return null;
  return cropImage(image, crop.left as int, crop.top as int, crop.width as int,
      crop.height as int);
}

/// Crops the [image] using coordinates [x], [y], [width] and [height],
/// returning new image ([HTMLCanvasElement]).
HTMLCanvasElement? cropImage(
    CanvasImageSource image, int x, int y, int width, int height) {
  HTMLCanvasElement canvas;
  if (image.isA<HTMLCanvasElement>()) {
    canvas = image as HTMLCanvasElement;
  } else {
    var imgDim = getImageDimension(image)!;
    var imgCanvas = HTMLCanvasElement()
      ..width = imgDim.width
      ..height = imgDim.height;
    var context = imgCanvas.getContext('2d') as CanvasRenderingContext2D;
    context.drawImage(image, 0, 0);
    canvas = imgCanvas;
  }

  var imgContext = canvas.getContext('2d') as CanvasRenderingContext2D;
  var imgCropData = imgContext.getImageData(x, y, width, height);

  var canvasCrop = HTMLCanvasElement()
    ..width = width
    ..height = height;
  var contextCrop = canvasCrop.getContext('2d') as CanvasRenderingContext2D;
  contextCrop.putImageData(imgCropData, 0, 0, 0, 0, width, height);

  return canvasCrop;
}

/// Creates a new image from [image], of [width] and [height],
/// to a [scale].
CanvasImageSource createScaledImage(
    CanvasImageSource image, int width, int height, double scale) {
  var w2 = (width * scale).toInt();
  var h2 = (height * scale).toInt();

  var canvas = HTMLCanvasElement()
    ..width = w2
    ..height = h2;
  var context = canvas.getContext('2d') as CanvasRenderingContext2D;

  context.drawImage(image, 0, 0, width, height, 0, 0, w2, h2);

  return canvas;
}

/// Creates an image from a [file].
Future<HTMLImageElement> createImageElementFromFile(File file) {
  var reader = FileReader();

  var completer = Completer<HTMLImageElement>();

  reader.onLoadEnd.listen((e) {
    var base64 = reader.result.dartify()?.toString();
    completer.complete(createImageElementFromBase64(base64));
  });

  reader.readAsDataURL(file);

  return completer.future;
}

/// Creates an image from a Base-64 with [mimeType].
HTMLImageElement? createImageElementFromBase64(String? base64,
    [String? mimeType]) {
  if (base64 == null || base64.isEmpty) return null;

  if (!base64.startsWith('data:')) {
    if (mimeType == null || mimeType.trim().isEmpty) mimeType = 'image/jpeg';
    base64 = 'data:$mimeType;base64,$base64';
  }

  var imgElement = HTMLImageElement();
  // ignore: unsafe_html
  imgElement.src = base64;

  return imgElement;
}

/// Converts a [List<num>], as pairs, to a [List<Point>].
List<Point<num>> numsToPoints(List<num> perspective) {
  var points = <Point<num>>[];

  for (var i = 1; i < perspective.length; i += 2) {
    var x = perspective[i - 1];
    var y = perspective[i];
    points.add(Point(x, y));
  }

  return points;
}

/// Makes a copy of [points].
List<Point<num>> copyPoints(List<Point<num>> points) {
  return points.map((p) => Point(p.x, p.y)).toList();
}

/// Scales [points] to [scale].
List<Point<num>> scalePoints(List<Point<num>> points, double scale) {
  return points.map((p) => Point(p.x * scale, p.y * scale)).toList();
}

/// Scales [points] to [scaleX] and [scaleY].
List<Point<num>> scalePointsXY(
    List<Point<num>> points, double scaleX, double scaleY) {
  return points.map((p) => Point(p.x * scaleX, p.y * scaleY)).toList();
}

/// Translate [pints] in [x] and [y].
List<Point<num>> translatePoints(List<Point<num>> points, num x, num y) {
  return points.map((p) => Point(p.x + x, p.y + y)).toList();
}

/// A cache for scaled images.
class ImageScaledCache {
  final CanvasImageSource _image;

  late final int _width;
  late final int _height;
  late final int _maxScaleCacheEntries;

  ImageScaledCache(this._image,
      [int? width, int? height, int? maxScaleCacheEntries]) {
    if (width == null || height == null) {
      var wh = getImageDimension(_image)!;

      width ??= wh.width;
      height ??= wh.height;
    }

    _width = width;
    _height = height;

    _maxScaleCacheEntries =
        maxScaleCacheEntries != null && maxScaleCacheEntries > 0
            ? maxScaleCacheEntries
            : 2;
  }

  /// Main image for scale.
  CanvasImageSource get image => _image;

  /// Width of the main [image].
  int get width => _width;

  /// Height of the main [image].
  int get height => _height;

  /// Maximum number of entries in the cache.
  int get maxScaleCacheEntries => _maxScaleCacheEntries;

  final Map<double, CanvasImageSource> _scaleCache = {};

  /// Clears the cache.
  void clearScaleCache() {
    _scaleCache.clear();
  }

  /// Returns [true] if a [scale] is in cache.
  bool isImageScaledInCache(double scale) {
    if (scale <= 0) return false;
    if (scale == 1.0) return true;

    var scaledImage = _scaleCache[scale];
    return scaledImage != null;
  }

  /// Returns a cached image in [scale].
  CanvasImageSource? getImageScaled(double scale) {
    if (scale <= 0) return null;
    if (scale == 1.0) return _image;

    var scaledImage = _scaleCache[scale];

    if (scaledImage == null) {
      scaledImage = createScaledImage(_image, _width, _height, scale);

      limitEntries(_scaleCache, _maxScaleCacheEntries - 1);

      _scaleCache[scale] = scaledImage;
    }

    return scaledImage;
  }

  static int limitEntries(Map cache, int maxCacheEntries) {
    if (cache.isEmpty) return 0;

    // Cache limit is never unlimited
    if (maxCacheEntries < 0) maxCacheEntries = 0;

    var removed = 0;
    while (cache.length > maxCacheEntries) {
      var key = cache.keys.first;
      print(
          '-- removing from cache: $key > ${cache.length} / $maxCacheEntries');
      cache.remove(key);
      removed++;
    }
    return removed;
  }
}

/// Applies a filter to [image], of [width] and [height].
typedef ImageFilter = CanvasImageSource Function(
    CanvasImageSource? image, int width, int height);

/// Quality of an image.
enum Quality { high, medium, low }

/// The type of edition for [CanvasImageViewer].
enum EditionType { clip, points, perspective, rectangles, labels }

typedef ValueCopier<T> = T? Function(T? value);

/// Represents an element in the [CanvasImageViewer].
class ViewerElement<T> {
  T? value;

  final Color? color;
  final int? strokeSize;

  final ValueCopier<T>? valueCopier;

  ViewerElement(this.value, this.color, {this.valueCopier, int? strokeSize})
      : strokeSize = strokeSize != null && strokeSize > 0 ? strokeSize : null;

  bool get isNull => value == null;

  T? get valueCopy => valueCopier != null ? valueCopier!(value) : null;

  String? key;

  bool get isEmpty => isEmptyObject(value);

  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return key != null
        ? '{value: $value, color: $color, key: $key}'
        : '{value: $value, color: $color}';
  }
}

class _RenderImageResult {
  final Quality quality;

  Point translate;

  _RenderImageResult(this.quality, this.translate);
}

class Label<T extends num> extends Rectangle<T> {
  final String label;

  Color? color;

  Label(this.label, T left, T top, T width, T height, [this.color])
      : super(left, top, width, height);

  @override
  String toString() {
    var colorStr = color != null ? ', color: $color' : '';
    return 'Label{label: $label, left: $left, top: $top, width: $width, height: $height$colorStr}';
  }

  Map asMap() {
    return {
      'label': label,
      'x': left,
      'y': top,
      'width': width,
      'height': height,
      if (color != null) 'color': color
    };
  }
}

/// An image viewer that can render points, rectangles, clip and grid over.
class CanvasImageViewer {
  static final dateFormatYYYYMMDDHHMMSS =
      DateFormat('yyyy/MM/dd HH:mm:ss', Intl.getCurrentLocale());

  late final HTMLCanvasElement _canvas;

  final bool canvasSizeSameOfRenderedImageSize;

  late int _width;
  late int _height;
  late int _renderedImageWidth;
  late int _renderedImageHeight;

  final int? _maxWidth;
  final int? _maxHeight;

  late final CanvasImageSource? _image;

  final ImageFilter? _imageFilter;

  ViewerElement<Rectangle<num>>? _clip;

  final ViewerElement<List<Rectangle<num>>>? _rectangles;

  final ViewerElement<List<Point<num>>>? _points;

  final ViewerElement<List<Label<num>>>? _labels;

  final ViewerElement<List<Point<num>>>? _perspective;

  final ViewerElement<num>? _gridSize;

  late final bool _cropPerspective;

  /// Time of the image.
  final DateTime? time;

  final EditionType? _editionType;

  late ImagePerspectiveFilterCache _imagePerspectiveFilterCache;

  CanvasImageViewer(
      {HTMLCanvasElement? canvas,
      int? width,
      int? height,
      int? maxWidth,
      int? maxHeight,
      this.canvasSizeSameOfRenderedImageSize = true,
      CanvasImageSource? image,
      ImageFilter? imageFilter,
      ViewerElement<Rectangle<num>>? clip,
      ViewerElement<List<Rectangle<num>>>? rectangles,
      ViewerElement<List<Point<num>>>? points,
      ViewerElement<List<Label<num>>>? labels,
      ViewerElement<List<Point<num>>>? perspective,
      ViewerElement<num>? gridSize,
      bool? cropPerspective,
      this.time,
      EditionType? editable})
      : _clip = clip,
        _rectangles = rectangles,
        _points = points,
        _labels = labels,
        _perspective = perspective,
        _gridSize = gridSize,
        _editionType = editable,
        _maxWidth = isPositiveNumber(maxWidth) ? maxWidth : null,
        _maxHeight = isPositiveNumber(maxHeight) ? maxHeight : null,
        _imageFilter = imageFilter {
    if (_imageFilter != null) {
      var imgW = 100;
      var imgH = 100;

      var wh = getImageDimension(image!);
      if (wh != null) {
        imgW = wh.width;
        imgH = wh.height;
      }

      image = _imageFilter(image, imgW, imgH);
    }

    _image = image;

    var w = width;
    var h = height;

    if (w == null || h == null) {
      var wh = getImageDimension(_image!);
      if (wh != null) {
        w ??= wh.width;
        h ??= wh.height;
      }
    }

    w ??= 100;
    h ??= 100;

    if (_image.isA<HTMLImageElement>()) {
      var img = _image as HTMLImageElement;
      img.onLoad.listen((_) => _onLoadImage());
    }

    _renderedImageWidth = _width = w;
    _renderedImageHeight = _height = h;

    _canvas = canvas ?? HTMLCanvasElement()
      ..width = w
      ..height = h;

    _imagePerspectiveFilterCache = ImagePerspectiveFilterCache(_image!, w, h);

    _setCanvasSizeSameOfRenderedImageSize(w, h);

    if (isEditable) {
      _canvas.onMouseDown.listen(_onMouseDown);
      _canvas.onMouseUp.listen(_onMouseUp);
      _canvas.onClick.listen(_onMouseClick);
      _canvas.onMouseLeave.listen(_onMouseLeave);
      _canvas.onMouseMove.listen(_onMouseMove);
    } else if (_labels != null && _labels.isNotEmpty) {
      _canvas.onMouseMove.listen(_onMouseMove);
    }

    cropPerspective ??= !isEditable || editable != EditionType.perspective;

    _cropPerspective = cropPerspective;
  }

  void _onLoadImage() {
    print('IMAGE LOADED> $_image');
    _updateImageDimension();
    render();
  }

  void _updateImageDimension() {
    var wh = getImageDimension(_image!);
    if (wh != null) {
      var w = wh.width;
      var h = wh.height;

      if (w > 0 && h > 0) {
        _renderedImageWidth = _width = w;
        _renderedImageHeight = _height = h;
        _checkImagePerspectiveFilterCache();
        _setCanvasSizeSameOfRenderedImageSize(w, h);
      }
    }
  }

  void _checkImagePerspectiveFilterCache() {
    if (_imagePerspectiveFilterCache.width != _width ||
        _imagePerspectiveFilterCache.height != _height) {
      _imagePerspectiveFilterCache.clearCaches();

      _imagePerspectiveFilterCache =
          ImagePerspectiveFilterCache(_image!, _width, _height);
    }
  }

  void _setCanvasSizeSameOfRenderedImageSize(int imgWidth, int imgHeight) {
    if (canvasSizeSameOfRenderedImageSize) {
      _canvas.width = imgWidth;
      _canvas.height = imgHeight;
    }
  }

  void _updateRenderedImageDimension(int imgWidth, int imgHeight) {
    _renderedImageWidth = imgWidth;
    _renderedImageHeight = imgHeight;

    _setCanvasSizeSameOfRenderedImageSize(imgWidth, imgHeight);
  }

  EventStream<dynamic> onChange = EventStream();

  void _notifyOnChange() {
    onChange.add(this);
  }

  HTMLCanvasElement get canvas => _canvas;

  Rectangle<num> _defaultClip() {
    var border = min(10, min(_width ~/ 10, _height ~/ 10));
    return Rectangle(
        border, border, _width - (border * 2), _height - (border * 2));
  }

  Rectangle<num>? _normalizeClip(Rectangle<num> clip) {
    var rectangle = Rectangle<int>(0, 0, _width, _height);
    var intersection = clip.intersection(rectangle);
    return intersection;
  }

  List<Point<num>> _defaultPerspective() {
    return [
      Point(0, 0),
      Point(width, 0),
      Point(width, height),
      Point(0, height)
    ];
  }

  bool get cropPerspective => _cropPerspective;

  /// Type of edition (EditionType). If null edition is not enabled.
  EditionType? get editionType => _editionType;

  /// Returns [true] if edition is enable. See [editionType].
  bool get isEditable => _editionType != null;

  /// Width of the image.
  int get width => _width;

  /// Height of the image.
  int get height => _height;

  /// Converts [Rectangle<num>] to [ViewerElement<Rectangle<num>>].
  static ViewerElement<Rectangle<num>> clipViewerElement(Rectangle<num>? clip,
      [Color? color]) {
    return ViewerElement<Rectangle<num>>(clip, color,
        valueCopier: (v) => v == null
            ? null
            : Rectangle<num>(v.left, v.top, v.width, v.height));
  }

  static ViewerElement<Rectangle<num>> clipViewerElementFromNums(List? clip,
      [Color? color]) {
    if (clip == null) {
      return clipViewerElement(null, color);
    }

    var clipNums = parseNumsFromList(clip);

    var x = clipNums[0];
    var y = clipNums[1];
    var w = clipNums[2];
    var h = clipNums[3];

    var rect = Rectangle(x, y, w, h);
    return clipViewerElement(rect, color);
  }

  static ViewerElement<Rectangle<num>> clipViewerElementFromMap(Map? clip,
      [Color? color]) {
    if (clip == null) {
      return clipViewerElement(null, color);
    }

    var x = parseInt(findKeyValue(clip, ['x', 'left'], true))!;
    var y = parseInt(findKeyValue(clip, ['y', 'top'], true))!;
    var w = parseInt(findKeyValue(clip, ['w', 'width'], true))!;
    var h = parseInt(findKeyValue(clip, ['h', 'height'], true))!;

    var rect = Rectangle(x, y, w, h);
    return clipViewerElement(rect, color);
  }

  /// Clip area element rendered in the image.
  Rectangle<num>? get clip => _clip?.valueCopy;

  String get clipKey => _clip?.key ?? 'clip';

  /// Converts a [List] if rectangles to [ViewerElement< List<Rectangle<num>> >].
  ///
  /// [color] Optional color to render the element.
  /// [strokeSize] Optional stroke size to render the element.
  static ViewerElement<List<Rectangle<num>>> rectanglesViewerElementFromNums(
      List rectangles,
      [Color? color,
      int? strokeSize]) {
    var mapped = rectangles.map((e) {
      if (e is Map) {
        return Rectangle<num>(
            parseNum(e['x'] ?? e['left'])!,
            parseNum(e['y'] ?? e['top'])!,
            parseNum(e['width'] ?? e['w'])!,
            parseNum(e['height'] ?? e['h'])!);
      } else if (e is List) {
        return Rectangle<num>(
            parseNum(e[0])!, parseNum(e[1])!, parseNum(e[2])!, parseNum(e[3])!);
      } else if (e is String) {
        var ns = parseNumsFromInlineList(e)!;
        return Rectangle<num>(parseNum(ns[0])!, parseNum(ns[1])!,
            parseNum(ns[2])!, parseNum(ns[3])!);
      } else {
        throw ArgumentError('Invalid rectangles parameter: $rectangles');
      }
    }).toList();

    return rectanglesViewerElement(mapped, color, strokeSize);
  }

  /// Converts a [List<Rectangle<num>>] to [ViewerElement< List<Rectangle<num>> >].
  ///
  /// [color] Optional color to render the element.
  /// [strokeSize] Optional stroke size to render the element.
  static ViewerElement<List<Rectangle<num>>> rectanglesViewerElement(
      List<Rectangle<num>> rectangles,
      [Color? color,
      int? strokeSize]) {
    return ViewerElement<List<Rectangle<num>>>(rectangles, color,
        strokeSize: strokeSize,
        valueCopier: (value) => value
            ?.map((r) => Rectangle<num>(r.left, r.top, r.width, r.height))
            .toList());
  }

  /// Rectangle elements rendered in the image.
  List<Rectangle<num>>? get rectangles => _rectangles?.valueCopy;

  String get rectanglesKey => _rectangles?.key ?? 'rectangles';

  /// Converts a [List] if labels to [ViewerElement< List<Label<num>> >].
  ///
  /// [color] Optional color to render the element.
  /// [strokeSize] Optional stroke size to render the element.
  static ViewerElement<List<Label<num>>> labelsViewerElementFromNums(
      List labels,
      [Color? color,
      int? strokeSize]) {
    var mapped = labels.map((e) {
      if (e is Map) {
        return Label<num>(
            e['label'] ?? e['title'] ?? e['name'] ?? e['id'],
            parseNum(e['x'] ?? e['left'])!,
            parseNum(e['y'] ?? e['top'])!,
            parseNum(e['width'] ?? e['w'])!,
            parseNum(e['height'] ?? e['h'])!);
      } else if (e is List) {
        return Label<num>(parseString(e[0])!, parseNum(e[1])!, parseNum(e[2])!,
            parseNum(e[3])!, parseNum(e[4])!);
      } else if (e is String) {
        var list = parseStringFromInlineList(e)!;
        var label = list.removeAt(0);
        var ns = parseNumsFromList(list);
        return Label<num>(label, parseNum(ns[0])!, parseNum(ns[1])!,
            parseNum(ns[2])!, parseNum(ns[3])!);
      } else {
        throw ArgumentError('Invalid rectangles parameter: $labels');
      }
    }).toList();

    return labelsViewerElement(mapped, color, strokeSize);
  }

  /// Converts a [List<Rectangle<num>>] to [ViewerElement< List<Rectangle<num>> >].
  ///
  /// [color] Optional color to render the element.
  /// [strokeSize] Optional stroke size to render the element.
  static ViewerElement<List<Label<num>>> labelsViewerElement(
      List<Label<num>> labels,
      [Color? color,
      int? strokeSize]) {
    return ViewerElement<List<Label<num>>>(labels, color,
        strokeSize: strokeSize,
        valueCopier: (value) => value
            ?.map((l) =>
                Label<num>(l.label, l.left, l.top, l.width, l.height, l.color))
            .toList());
  }

  /// Labels elements rendered in the image.
  List<Label<num>>? get labels => _labels?.valueCopy;

  String get labelsKey => _labels?.key ?? 'labels';

  /// Converts a [List<Point<num>> ] to [ViewerElement< List<Point<num>> >].
  ///
  /// [color] Optional color to render the element.
  static ViewerElement<List<Point<num>>> pointsViewerElement(
      List<Point<num>> points,
      [Color? color]) {
    return ViewerElement<List<Point<num>>>(points, color,
        valueCopier: (value) =>
            value?.map((p) => Point<num>(p.x, p.y)).toList());
  }

  /// Point elements rendered in the image.
  List<Point<num>>? get points => _points?.valueCopy;

  String get pointsKey => _points?.key ?? 'points';

  static ViewerElement<num> gridSizeViewerElement(num gridSize,
      [Color? color]) {
    return ViewerElement<num>(gridSize, color, valueCopier: (value) => value);
  }

  /// The size of grid boxes when rendering the grid.
  num? get gridSize => _gridSize?.valueCopy;

  String get gridSizeKey => _gridSize?.key ?? 'gridSize';

  /// Converts a [List<num>] (pairs of perspective points) to [ViewerElement< List<Point<num>> >].
  static ViewerElement<List<Point<num>>> perspectiveViewerElementFromNums(
      List? perspective,
      [Color? color]) {
    if (perspective == null) {
      return perspectiveViewerElement(null, color);
    }

    var perspectiveNums = parseNumsFromList(perspective);

    // ignore: omit_local_variable_types
    List<Point<num>> points = [];

    for (var i = 1; i < perspectiveNums.length; i += 2) {
      var x = perspectiveNums[i - 1];
      var y = perspectiveNums[i];
      points.add(Point(x, y));
    }

    return perspectiveViewerElement(points, color);
  }

  /// Converts [List< Point<num> >] (perspective points) to [ViewerElement< List<Point<num>> >].
  static ViewerElement<List<Point<num>>> perspectiveViewerElement(
      List<Point<num>>? perspective,
      [Color? color]) {
    return ViewerElement<List<Point<num>>>(perspective, color,
        valueCopier: (value) =>
            value?.map((p) => Point<num>(p.x, p.y)).toList());
  }

  /// The perspective points to use in the Perspective filter of the image.
  List<Point<num>>? get perspective => _perspective?.valueCopy;

  String get perspectiveKey => _perspective?.key ?? 'perspective';

  void _deselectDOM() {
    var selection = window.getSelection();
    if (selection != null) {
      selection.empty();
    }
  }

  Point? _pressed;

  void _onMouseDown(MouseEvent event) {
    _deselectDOM();

    var mouse = Point(event.offsetX, event.offsetY);
    _pressed = mouse;

    var needRender = interact(mouse, false);
    if (needRender != null) {
      _renderImpl(needRender, false);
    }
  }

  void _onMouseClick(MouseEvent event) {
    var mouse = Point(event.offsetX, event.offsetY);

    var needRender = interact(mouse, true);
    if (needRender != null) {
      _renderImpl(needRender, false);
    }
  }

  void _onMouseUp(MouseEvent event) {
    _pressed = null;
  }

  void _onMouseLeave(MouseEvent event) {
    _pressed = null;
  }

  void _onMouseMove(MouseEvent event) {
    if (_pressed == null) {
      if (_labels != null) {
        var mouse = Point(event.offsetX, event.offsetY);
        var quality = showLabel(mouse);
        _renderImpl(quality, true);
      }
      return;
    }

    var mouse = Point(event.offsetX, event.offsetY);

    var needRender = interact(mouse, false);
    if (needRender != null) {
      _renderImpl(needRender, false);
    }
  }

  double get offsetWidthRatio {
    var offsetW = _canvas.offsetWidth;
    if (offsetW == 0) return 0;
    return _renderedImageWidth / offsetW;
  }

  double get offsetHeightRatio {
    var offsetH = _canvas.offsetHeight;
    if (offsetH == 0) return 0;
    return _renderedImageHeight / offsetH;
  }

  Point<int> _getMousePointInCanvas(Point<num> mouse,
      [bool fixTranslation = true]) {
    var wRatio = offsetWidthRatio;
    var hRatio = offsetHeightRatio;

    var x = (clipNumber(mouse.x, 0, width)! * wRatio).toInt();
    var y = (clipNumber(mouse.y, 0, height)! * hRatio).toInt();

    //print('mouse> xy: $x $y >> ratio: $wRatio $hRatio');

    if (fixTranslation &&
        _renderedTranslation != null &&
        (_renderedTranslation!.x != 0 || _renderedTranslation!.y != 0)) {
      x -= (_renderedTranslation!.x * wRatio).toInt();
      y -= (_renderedTranslation!.y * hRatio).toInt();

      //print('mouse[fixTranslation: $_renderedTranslation]> xy: $x $y >> ratio: $wRatio $hRatio');
    }

    return Point<int>(x, y);
  }

  Rectangle<int> _getElementRectangleInCanvas(Rectangle<num> element,
      [bool fixTranslation = true]) {
    var wRatio = 1 / offsetWidthRatio;
    var hRatio = 1 / offsetHeightRatio;

    var x = clipNumber(element.left * wRatio, 0, width)!.toInt();
    var y = clipNumber(element.top * hRatio, 0, height)!.toInt();
    var w = (element.width * wRatio).toInt();
    var h = (element.height * hRatio).toInt();

    //print('mouse> xy: $x $y >> ratio: $wRatio $hRatio');

    if (fixTranslation &&
        _renderedTranslation != null &&
        (_renderedTranslation!.x != 0 || _renderedTranslation!.y != 0)) {
      x += (_renderedTranslation!.x * wRatio).toInt();
      y += (_renderedTranslation!.y * hRatio).toInt();

      //print('mouse[fixTranslation: $_renderedTranslation]> xy: $x $y >> ratio: $wRatio $hRatio');
    }

    return Rectangle<int>(x, y, w, h);
  }

  Quality? interact(Point mouse, bool click) {
    Quality? labelRender;

    if (!click) {
      labelRender = showLabel(mouse);
    }

    var editRender = edit(mouse, click);

    if (editRender != null) {
      _notifyOnChange();
    }

    if (editRender != null) return editRender;
    return labelRender;
  }

  Quality? edit(Point mouse, bool click) {
    if (!isEditable) return null;

    switch (_editionType) {
      case EditionType.clip:
        return adjustClip(mouse, click);
      case EditionType.points:
        return adjustPoints(mouse, click);
      case EditionType.perspective:
        return adjustPerspective(mouse, click);
      case EditionType.rectangles:
        return adjustRectangles(mouse, click);
      case EditionType.labels:
        return adjustLabels(mouse, click);
      default:
        return null;
    }
  }

  Quality? adjustClip(Point mouse, bool click) {
    if (click) return null;
    if (_clip == null) return null;

    //print('--- adjustClip ---');

    var point = _getMousePointInCanvas(mouse);

    var clip = _clip?.value ?? _defaultClip();
    var edges = _toEdgePoints(clip);

    var target = nearestPoint(edges, point);

    //print(target);

    Rectangle? clip2;

    if (target == edges[0] ||
        target == edges[1] ||
        target == edges[2] ||
        target == edges[3] ||
        target == edges[4]) {
      var diffW = point.x - clip.left as int;
      clip2 = Rectangle(point.x, clip.top, clip.width - diffW, clip.height);
    } else if (target == edges[5] ||
        target == edges[6] ||
        target == edges[7] ||
        target == edges[8] ||
        target == edges[9]) {
      var diffH = point.y - clip.top as int;
      clip2 = Rectangle(clip.left, point.y, clip.width, clip.height - diffH);
    } else if (target == edges[10] ||
        target == edges[11] ||
        target == edges[12] ||
        target == edges[13] ||
        target == edges[14]) {
      clip2 = Rectangle(clip.left, clip.top, point.x - clip.left, clip.height);
    } else if (target == edges[15] ||
        target == edges[16] ||
        target == edges[17] ||
        target == edges[18] ||
        target == edges[19]) {
      clip2 = Rectangle(clip.left, clip.top, clip.width, point.y - clip.top);
    } else {
      clip2 = Rectangle<num>(clip.left, clip.top, clip.width, clip.height);
    }

    clip2 = clip2.intersection(Rectangle(0, 0, width, height));

    if (clip2 != null) {
      var clipArea = clip2.width * clip2.height;
      if (clipArea > 1) {
        _clip = clipViewerElement(clip2, _clip?.color);
        return Quality.high;
      }
    }

    return Quality.high;
  }

  Point<num> _boundPoint(Point<num> val, Point<num> min, Point<num> max) {
    return Point(
        clipNumber(val.x, min.x, max.x)!, clipNumber(val.y, min.y, max.y)!);
  }

  List<Point> _toEdgePoints(Rectangle r) {
    var wPart0 = r.width ~/ 8;
    var wPart1 = r.width ~/ 4;
    var wPart2 = r.width ~/ 2;
    var wPart3 = wPart2 + wPart1;
    var wPart4 = wPart2 + wPart1 + wPart0;

    var hPart0 = r.height ~/ 8;
    var hPart1 = r.height ~/ 4;
    var hPart2 = r.height ~/ 2;
    var hPart3 = hPart2 + hPart1;
    var hPart4 = hPart2 + hPart1 + hPart0;

    return [
      Point(r.left, r.top + hPart0),
      Point(r.left, r.top + hPart1),
      Point(r.left, r.top + hPart2),
      Point(r.left, r.top + hPart3),
      Point(r.left, r.top + hPart4),
      Point(r.left + wPart0, r.top),
      Point(r.left + wPart1, r.top),
      Point(r.left + wPart2, r.top),
      Point(r.left + wPart3, r.top),
      Point(r.left + wPart4, r.top),
      Point(r.left + r.width, r.top + hPart0),
      Point(r.left + r.width, r.top + hPart1),
      Point(r.left + r.width, r.top + hPart2),
      Point(r.left + r.width, r.top + hPart3),
      Point(r.left + r.width, r.top + hPart4),
      Point(r.left + wPart0, r.top + r.height),
      Point(r.left + wPart1, r.top + r.height),
      Point(r.left + wPart2, r.top + r.height),
      Point(r.left + wPart3, r.top + r.height),
      Point(r.left + wPart4, r.top + r.height),
    ];
  }

  Rectangle<num>? nearestRectangle(
      List<Rectangle<num>> rectangles, Point<num> p) {
    if (rectangles.isEmpty) return null;

    Rectangle<num>? nearest;
    double? nearestDistance;

    for (var rect in rectangles) {
      var rectCenter = getRectangleCenter(rect);
      var distance = rectCenter.distanceTo(p);
      if (nearestDistance == null || distance < nearestDistance) {
        nearest = rect;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  static Point<num> getRectangleCenter(Rectangle<num> r) =>
      Point<num>(r.left + (r.width / 2), r.top + (r.height / 2));

  Quality? adjustRectangles(Point mouse, bool click) {
    if (!click) return null;
    if (_rectangles == null) return null;

    //print('--- adjustRectangles ---');

    var point = _getMousePointInCanvas(mouse);

    var rectangles = _rectangles.value ?? [];

    var target = nearestRectangle(rectangles, point);

    if (target == null) {
      //rectangles.add(point);
    } else {
      if (target.containsPoint(point)) {
        rectangles.remove(target);
      }
    }

    _rectangles.value = rectangles;

    return Quality.high;
  }

  Quality? adjustLabels(Point mouse, bool click) {
    if (!click) return null;
    if (_labels == null) return null;

    //print('--- adjustLabels ---');

    var point = _getMousePointInCanvas(mouse);

    var labels = _labels.value ?? [];

    var target = nearestRectangle(labels, point) as Label?;

    if (target == null) {
      //rectangles.add(point);
      hideHint();
    } else {
      if (target.containsPoint(point)) {
        if (click) {
          labels.remove(target);
          hideHint();
        } else {
          showHintAtRectangle(
              target.label, _getElementRectangleInCanvas(target));
        }
      } else {
        hideHint();
      }
    }

    _labels.value = labels;

    return Quality.high;
  }

  Label? _pointerLabel;

  Quality? showLabel(Point mouse) {
    if (_labels == null) return null;

    //print('--- showLabels ---');

    var point = _getMousePointInCanvas(mouse);

    var labels = _labels.value ?? [];

    var target = nearestRectangle(labels, point) as Label?;

    if (target == null) {
      _hideLabel();
    } else if (target.containsPoint(point)) {
      _pointerLabel = _selectedLabel = target;
      showHintAtRectangle(target.label, _getElementRectangleInCanvas(target));
    } else {
      _hideLabel();
    }

    return Quality.high;
  }

  void _hideLabel() {
    _pointerLabel = null;

    var selLabel = _selectedLabel;
    if (selLabel == null) return;

    Future.delayed(Duration(milliseconds: 400), () {
      if (_selectedLabel == selLabel && _pointerLabel == null) {
        _selectedLabel = null;
        hideHint();
        _renderImpl(Quality.high, true);
      }
    });
  }

  Point<num>? nearestPoint(List<Point<num>>? points, Point<num> p) {
    if (points == null || points.isEmpty) return null;

    Point<num>? nearest;
    double? nearestDistance;

    for (var point in points) {
      var distance = point.distanceTo(p);
      if (nearestDistance == null || distance < nearestDistance) {
        nearest = point;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  Quality? adjustPoints(Point mouse, bool click) {
    if (!click) return null;
    if (_points == null) return null;

    //print('--- adjustPoints ---');

    var point = _getMousePointInCanvas(mouse);

    var points = _points.value ?? [];

    var target = nearestPoint(points, point);

    if (target == null) {
      points.add(point);
    } else {
      var distance = target.distanceTo(point);

      if (distance <= 10) {
        points.remove(target);
      } else {
        points.add(point);
      }
    }

    _points.value = points;

    return Quality.high;
  }

  Quality? adjustPerspective(Point<num> mouse, bool click) {
    //if (click) return null ;
    if (_perspective == null) return null;

    //print('--- adjustPerspective ---');

    Point<num> point = _getMousePointInCanvas(mouse, false);

    var points = _perspective.value ?? _defaultPerspective();

    if (points.length != 4) points = _defaultPerspective();

    var initialBounds = _getPointsBounds(points);

    var target = nearestPoint(points, point)!;
    var targetIdx = points.indexOf(target);

    //print('target: $target #$targetIdx');

    var pointsAdjusted = copyPoints(points);
    pointsAdjusted[targetIdx] = point;

    var bounds = _getPointsBounds(pointsAdjusted);

    if (bounds != initialBounds) {
      var tolerance = max(10, max(width, height) / 50);

      var wDiff = initialBounds.width - bounds.width;
      var hDiff = initialBounds.height - bounds.height;

      var xDiff = target.x - point.x;
      var yDiff = target.y - point.y;

      if (wDiff < 0) wDiff = -wDiff;
      if (hDiff < 0) hDiff = -hDiff;

      if (xDiff < 0) xDiff = -xDiff;
      if (yDiff < 0) yDiff = -yDiff;

      //print('Changing bounds> tolerance: $tolerance > whDiff: $wDiff , $hDiff > xyDiff: $xDiff , $yDiff >> $bounds != $initialBounds') ;

      var pointFixed = point;

      if (xDiff < tolerance && yDiff < tolerance) {
        if (wDiff > 0 && xDiff < yDiff || xDiff < tolerance) {
          pointFixed = Point<num>(target.x, point.y);
        } else if (hDiff > 0 && yDiff < xDiff || yDiff < tolerance) {
          pointFixed = Point<num>(point.x, target.y);
        }
      }

      if (point != pointFixed) {
        pointsAdjusted[targetIdx] = pointFixed;
        bounds = _getPointsBounds(pointsAdjusted);
        point = pointFixed;
      }
    }

    var scaleX = width / bounds.width;
    var scaleY = height / bounds.height;

    //print('scaleX: $scaleX ; scaleY: $scaleY >> $bounds');

    var pointsScaled =
        translatePoints(pointsAdjusted, -bounds.left, -bounds.top);
    pointsScaled = scalePointsXY(pointsScaled, scaleX, scaleY);

    var spaceW = max(5, width / 20);
    var spaceH = max(5, height / 20);

    var pointsInBounds = [
      _boundPoint(pointsScaled[0], Point(0, 0),
          Point(width / 2 - spaceW, height / 2 - spaceH)),
      _boundPoint(pointsScaled[1], Point(width / 2 + spaceW, 0),
          Point(width, height / 2 - spaceH)),
      _boundPoint(pointsScaled[2],
          Point(width / 2 + spaceW, height / 2 + spaceH), Point(width, height)),
      _boundPoint(pointsScaled[3], Point(0, height / 2 + spaceH),
          Point(width / 2 - spaceW, height)),
    ];

    /*
    print('points: $points >> ${_getPointsBounds(points)}');
    print(
        'pointsAdjusted: $pointsAdjusted >> ${_getPointsBounds(pointsAdjusted)}');
    print('pointsScaled: $pointsScaled >> ${_getPointsBounds(pointsScaled)}');
    print(
        'pointsInBounds: $pointsInBounds >> ${_getPointsBounds(pointsInBounds)}');
     */

    _perspective.value = pointsInBounds;

    return Quality.medium;
  }

  Rectangle<num> _getPointsBounds(List<Point<num>> points) {
    var p0 = points[0];

    var minX = p0.x;
    var maxX = p0.x;

    var minY = p0.y;
    var maxY = p0.y;

    for (var p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;

      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }

    return Rectangle(minX, minY, maxX - minX, maxY - minY);
  }

  /// Renders this component asynchronously.
  void renderAsync(Duration delay) {
    _renderAsyncImpl(delay, Quality.high, false);
  }

  void _renderAsyncImpl(Duration? delay, Quality quality, bool forceQuality) {
    if (delay != null) {
      Future.delayed(delay, () => _renderImpl(quality, forceQuality, true));
    } else {
      Future.microtask(() => _renderImpl(quality, forceQuality, true));
    }
  }

  /// Returns [true] if this component is in DOM.
  bool get inDOM {
    return isInDOM(_canvas);
  }

  /// Renders this component.
  void render() {
    if (!inDOM) {
      Future.delayed(Duration(seconds: 1), () => render());
      return;
    }

    _renderImpl(Quality.high, false);
  }

  Point<num>? _renderedTranslation;

  void _renderImpl(Quality? quality, bool forceQuality,
      [bool scheduledRender = false]) {
    quality ??= Quality.high;

    var context = _canvas.context2D;

    var renderImageResult =
        _renderImage(context, quality, forceQuality, scheduledRender);

    if (renderImageResult == null) {
      return;
    }

    var translate = renderImageResult.translate;

    _renderGrid(context, translate, _gridSize?.value,
        _gridSize?.color ?? Color.cyan.withOpacity(0.70), 2);

    _renderRectangles(
      context,
      translate,
      _rectangles?.value,
      _rectangles?.color ?? Color.GREEN,
      _rectangles?.strokeSize ?? 3,
    );

    _renderPoints(
      context,
      translate,
      _points?.value,
      _points?.color ?? Color.RED,
      _points?.strokeSize ?? 1,
    );

    _renderLabels(
      context,
      translate,
      _labels?.value,
      _labels?.color ?? Color.GREEN,
      _labels?.strokeSize ?? 3,
    );

    _renderClip(
      context,
      translate,
      _clip?.value,
      _clip?.color ?? Color.BLUE,
      _clip?.strokeSize ?? 1,
    );

    _renderTime(context, translate, time);

    _renderedTranslation = translate;
  }

  _RenderImageResult? _renderImage(CanvasRenderingContext2D context,
      Quality quality, bool forceQuality, bool scheduledRender) {
    if (_image == null) {
      print('** IMAGE NOT LOADED: $_image');
      return null;
    }

    if (_perspective != null && !_perspective.isNull) {
      return _renderImageWithPerspective(
          context, quality, forceQuality, scheduledRender);
    } else {
      return _renderImageImpl(context);
    }
  }

  _RenderImageResult _renderImageImpl(CanvasRenderingContext2D context) {
    context.clearRect(0, 0, width, height);
    context.drawImage(_image!, 0, 0, width, height, 0, 0, width, height);
    return _RenderImageResult(Quality.high, Point(0, 0));
  }

  DateTime _renderImageWithPerspectiveLastTime = DateTime.now();

  Quality? _renderImageWithPerspectiveLastQuality;

  String? _renderImageWithPerspectiveRenderSign;

  String _renderSign(Quality quality) {
    var perspectiveValue = _perspective?.value;
    var rectanglesValue = _rectangles?.value;
    var pointsValue = _points?.value;
    var labelsValue = _labels?.value;
    var gridSizeValue = _gridSize?.value;
    var clipSizeValue = _clip?.value;
    var selectedLabel = _selectedLabel;

    return '$quality > $perspectiveValue > $rectanglesValue > $pointsValue > $labelsValue > $clipSizeValue > $gridSizeValue > $selectedLabel';
  }

  _RenderImageResult? _renderImageWithPerspective(
      CanvasRenderingContext2D context,
      Quality quality,
      bool forceQuality,
      bool scheduledRender) {
    if (forceQuality &&
        scheduledRender &&
        quality == _renderImageWithPerspectiveLastQuality) {
      return null;
    }

    var requestedRenderSign = _renderSign(quality);

    if (_renderImageWithPerspectiveRenderSign == requestedRenderSign) {
      return null;
    }

    var now = DateTime.now();

    var renderInterval = now.millisecondsSinceEpoch -
        _renderImageWithPerspectiveLastTime.millisecondsSinceEpoch;
    //renderInterval -= renderImageWithPerspective_renderTime ;
    var shortRenderTime = renderInterval < 100;

    var renderQuality = shortRenderTime ? Quality.low : quality;

    if (_forceImageQualityHigh) renderQuality = Quality.high;

    if (renderQuality == Quality.low &&
        _isImageWithPerspectiveInCacheQualityMedium) {
      renderQuality = Quality.medium;
    } else if (renderQuality == Quality.medium &&
        _isImageWithPerspectiveInCacheQualityHigh) {
      renderQuality = Quality.high;
    }

    if (forceQuality && quality != renderQuality) {
      return null;
    }

    var renderSign = _renderSign(renderQuality);

    if (_renderImageWithPerspectiveRenderSign == renderSign) {
      return null;
    }

    /*
    print('-------------------- _renderImageWithPerspective>>>> ');
    print('forceQuality: $forceQuality');
    print('quality: $quality');
    print('renderQuality: $renderQuality');
    print('renderInterval: $renderInterval');
    print('shortRenderTime: $shortRenderTime');
     */

    context.clearRect(0, 0, width, height);

    _RenderImageResult? renderImageResult;

    if (renderQuality == Quality.low) {
      renderImageResult = _renderImageWithPerspectiveQualityLow(context);
    } else if (renderQuality == Quality.medium) {
      renderImageResult = _renderImageWithPerspectiveQualityMedium(context);
    } else {
      renderImageResult = _renderImageWithPerspectiveQualityHigh(context);
    }

    if (renderImageResult == null) {
      print('** Rendered NULL image with perspective: $renderImageResult');
      return null;
    }

    var renderedQuality = renderImageResult.quality;

    _renderImageWithPerspectiveLastTime = DateTime.now();
    _renderImageWithPerspectiveLastQuality = renderedQuality;

    //print('renderedQuality: $renderedQuality');

    var renderedSign = _renderSign(renderedQuality);
    _renderImageWithPerspectiveRenderSign = renderedSign;

    {
      Duration? scheduleDelay;
      Quality? scheduleQuality;

      if (renderedQuality == Quality.low && !forceQuality) {
        if (isOffsetRenderScaleGoodForHighQuality) {
          scheduleDelay = Duration(milliseconds: 200);
          scheduleQuality = Quality.medium;
        } else {
          scheduleDelay = Duration(milliseconds: 500);
          scheduleQuality = Quality.medium;
        }
      } else if (renderedQuality == Quality.medium) {
        if (isOffsetRenderScaleGoodForHighQuality) {
          scheduleDelay = Duration(milliseconds: 2000);
          scheduleQuality = Quality.high;
        }
      }

      if (scheduleDelay != null && scheduleQuality != null) {
        _renderAsyncImpl(scheduleDelay, scheduleQuality, true);
        //print('CanvasImageViewer[RENDER SCHEDULED]> scheduleDelay: $scheduleDelay ; scheduleQuality: $scheduleQuality');
      }
    }

    return renderImageResult;
  }

  double get offsetRenderScale =>
      max(1 / offsetWidthRatio, 1 / offsetHeightRatio);

  bool get isOffsetRenderScaleGoodForHighQuality =>
      offsetRenderScale > 0.70 || _forceImageQualityHigh;

  double get renderScaleQualityLow => offsetRenderScale * 0.40;

  double get renderScaleQualityMedium => offsetRenderScale * 1.05;

  double get renderScaleQualityHigh => 1;

  //bool get _isImageWithPerspectiveInCache_QualityLow => _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(_perspective.value, renderScale_QualityLow) ;
  bool get _isImageWithPerspectiveInCacheQualityMedium =>
      _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(
          _perspective!.value, renderScaleQualityMedium);

  bool get _isImageWithPerspectiveInCacheQualityHigh =>
      _imagePerspectiveFilterCache.isImageWithPerspectiveInCache(
          _perspective!.value, renderScaleQualityHigh);

  _RenderImageResult? _renderImageWithPerspectiveQualityLow(
      CanvasRenderingContext2D context) {
    var scaleOffset = offsetRenderScale;
    var scale = renderScaleQualityLow;

    //print('_renderImageWithPerspective_qualityLow> scale: $scale ; scaleOffset: $scaleOffset');

    if (scaleOffset < 0.30) {
      return _renderImageWithPerspectiveQualityMedium(context);
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(
        _perspective!.value, scale);

    return _renderImageResult(context, Quality.low, scale, filterResult);
  }

  _RenderImageResult? _renderImageWithPerspectiveQualityMedium(
      CanvasRenderingContext2D context) {
    //var scaleOffset = offsetRenderScale;
    var scale = renderScaleQualityMedium;

    //print('_renderImageWithPerspective_qualityMedium> scale: $scale ; scaleOffset: $scaleOffset');

    if (scale > 0.80) {
      return _renderImageWithPerspectiveQualityHigh(context);
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(
        _perspective!.value, scale);

    return _renderImageResult(context, Quality.medium, scale, filterResult);
  }

  final bool _forceImageQualityHigh = false;

  _RenderImageResult? _renderImageWithPerspectiveQualityHigh(
      CanvasRenderingContext2D context) {
    var scaleOffset = offsetRenderScale;
    var scale = renderScaleQualityHigh;

    print(
        '_renderImageWithPerspective_qualityHigh> scale: $scale ; scaleOffset: $scaleOffset');

    if (!isOffsetRenderScaleGoodForHighQuality) {
      return _renderImageWithPerspectiveQualityMedium(context);
    }

    var filterResult = _imagePerspectiveFilterCache.getImageWithPerspective(
        _perspective!.value, scale);

    return _renderImageResult(context, Quality.high, scale, filterResult);
  }

  _RenderImageResult? _renderImageResult(CanvasRenderingContext2D context,
      Quality quality, double scale, FilterResult? filterResult) {
    if (filterResult == null) {
      print(
          '** _renderImageResult> quality: $quality ; scale: $scale ; filterResult: $filterResult');
      return null;
    }

    Point<num> translate;
    HTMLCanvasElement srcImage;
    Rectangle<int> dstCoords;

    if (_cropPerspective) {
      var image = filterResult.imageResult;
      var imageCropped = filterResult.imageResultCropped!;
      var cropWRatio = imageCropped.width / image.width;
      var cropHRatio = imageCropped.height / image.height;

      srcImage = imageCropped;
      translate = Point(0, 0);
      var dstW = (width * cropWRatio).toInt();
      var dstH = (height * cropHRatio).toInt();
      dstCoords = Rectangle(0, 0, dstW, dstH);
    } else {
      srcImage = filterResult.imageResult;
      translate = filterResult.translationScaled(1 / scale);
      dstCoords = Rectangle(0, 0, width, height);
    }

    var srcCoords = Rectangle(0, 0, srcImage.width, srcImage.height);

    var srWRatio = srcCoords.width / dstCoords.width;
    var srHRatio = srcCoords.height / dstCoords.height;

    if (_maxWidth != null || _maxHeight != null) {
      var maxWidth = _maxWidth ?? dstCoords.width;
      var maxHeight = _maxHeight ?? dstCoords.height;

      var maxW = Math.min(maxWidth, dstCoords.width);
      var maxH = Math.min(maxHeight, dstCoords.height);

      var x = (dstCoords.width - maxW) ~/ 2;
      var y = (dstCoords.height - maxH) ~/ 2;

      if (_clip != null && !_clip!.isNull) {
        var clipW = _clip!.value!.width;
        var clipH = _clip!.value!.height;
        var cX = _clip!.value!.left;
        var cY = _clip!.value!.top;

        x = cX - ((maxW - clipW) ~/ 2) as int;
        y = cY - ((maxH - clipH) ~/ 2) as int;
      }

      x = clipNumber(x, 0, maxWidth)!;
      y = clipNumber(y, 0, maxHeight)!;

      var srcW = (maxW * srWRatio).toInt();
      var srcH = (maxH * srHRatio).toInt();
      var srcX = (x * srWRatio).toInt();
      var srcY = (y * srHRatio).toInt();

      srcCoords = Rectangle(srcX, srcY, srcW, srcH);
      dstCoords = Rectangle(0, 0, maxW, maxH);

      translate = Point(-x, -y);
    }

    _updateRenderedImageDimension(dstCoords.width, dstCoords.height);
    context.drawImage(
        srcImage,
        srcCoords.left,
        srcCoords.top,
        srcCoords.width,
        srcCoords.height,
        dstCoords.left,
        dstCoords.top,
        dstCoords.width,
        dstCoords.height);

    return _RenderImageResult(quality, translate);
  }

  void _renderClip(CanvasRenderingContext2D context, Point<num> translate,
      Rectangle? clip, Color color, int strokeSize) {
    if (clip == null) return;
    clip = _normalizeClip(clip);
    if (clip == null) return;

    _renderShadow(context, translate, clip);

    _translate(context, translate);

    _strokeRect(context, clip, color, strokeSize, strokeSize + 2);
  }

  void _renderShadow(
      CanvasRenderingContext2D context, Point<num> translate, Rectangle clip) {
    context.setFillColorRgb(0, 0, 0, 0.40);

    _translate(context, null);

    if (translate.x != 0 || translate.y != 0) {
      var x = translate.x;
      var y = translate.y;

      context.fillRect(0, 0, x, height);
      context.fillRect(x, 0, width - x, y);
    }

    _translate(context, translate);

    context.fillRect(0, 0, width, clip.top);
    context.fillRect(
        0, clip.top + clip.height, width, height - (clip.top + clip.height));
    context.fillRect(0, clip.top, clip.left, clip.height);
    context.fillRect(clip.left + clip.width, clip.top,
        width - (clip.left + clip.width), clip.height);
  }

  Label<num>? _selectedLabel;

  void _renderLabels(CanvasRenderingContext2D context, Point<num> translate,
      List<Label<num>>? rectangles, Color color, int strokeSize) {
    if (isEmptyObject(rectangles)) return;

    _translate(context, translate);
    _strokeLabels(context, rectangles!, color, strokeSize, _selectedLabel,
        strokeSize * 2);
  }

  void _renderRectangles(CanvasRenderingContext2D context, Point<num> translate,
      List<Rectangle<num>>? rectangles, Color color, int strokeSize) {
    if (isEmptyObject(rectangles)) return;

    _translate(context, translate);
    _strokeRects(context, rectangles!, color, strokeSize);
  }

  void _renderPoints(CanvasRenderingContext2D context, Point<num> translate,
      List<Point<num>>? points, Color color, int strokeSize) {
    if (isEmptyObject(points)) return;

    _translate(context, translate);

    _strokePoints(context, points!, color, strokeSize);
  }

  void _renderGrid(CanvasRenderingContext2D context, Point<num> translate,
      num? gridSize, Color color, int lineWidth) {
    if (gridSize == null || gridSize <= 0 || lineWidth < 1) {
      return;
    }

    _translate(context, null);

    context.setStrokeColorRgb(
        color.red, color.green, color.blue, color.opacity);

    context.lineWidth = lineWidth;

    // ignore: omit_local_variable_types
    int size = gridSize is double
        ? (gridSize < 1
            ? min((width * gridSize).toInt(), (height * gridSize).toInt())
            : gridSize.toInt())
        : gridSize.toInt();
    var minSize = max(2, lineWidth * 3);
    if (size < minSize) size = minSize;

    for (var x = size; x < width; x += size) {
      context.beginPath();
      context.moveTo(x, 0);
      context.lineTo(x, height);
      context.stroke();
    }

    for (var y = size; y < height; y += size) {
      context.beginPath();
      context.moveTo(0, y);
      context.lineTo(width, y);
      context.stroke();
    }
  }

  void _renderTime(
      CanvasRenderingContext2D context, Point<num> translate, DateTime? time) {
    if (time == null) return;

    _translate(context, null);

    var timeStr = dateFormatYYYYMMDDHHMMSS.format(time.toLocal());

    context.font = '30px Arial';

    var margin = 4;
    var shadow = 2;

    context.setFillColorRgb(0, 0, 0, 0.60);
    context.fillText(timeStr, margin, height - margin);

    context.setFillColorRgb(255, 255, 255, 0.70);
    context.fillText(timeStr, margin + shadow, height - (margin + shadow));
  }

  void _translate(CanvasRenderingContext2D context, Point<num>? translate) {
    context.resetTransform();
    if (translate != null) {
      context.translate(translate.x, translate.y);
    }
  }

  void _strokeLabels(CanvasRenderingContext2D context, List<Label<num>> labels,
      Color color, int lineWidth, Label? sel, int selLineWidth) {
    var hasSel = sel != null;
    var selHasColor = sel != null && sel.color != null;

    //print('>> ${labels.runtimeType} > $labels ');

    // Render non selected labels first:
    for (var label in labels) {
      var isSelectedLabel = label == sel;
      if (isSelectedLabel) continue;
      var isSelectedGroup = hasSel && label.label == sel.label;
      if (isSelectedGroup) continue;

      var labelColor = label.color ?? color;
      if (selHasColor) {
        labelColor = Color.greyDark;
      }
      _strokeRect(context, label, labelColor, lineWidth);
    }

    // Render selected label and label group later:
    if (hasSel) {
      for (var label in labels) {
        var isSelectedLabel = label == sel;
        var isSelectedGroup = hasSel && label.label == sel.label;
        if (!isSelectedLabel && !isSelectedGroup) continue;

        var labelColor = label.color ?? color;
        var labelLineWidth = isSelectedLabel ? selLineWidth : lineWidth;
        _strokeRect(context, label, labelColor, labelLineWidth);
      }
    }
  }

  void _strokeRects(CanvasRenderingContext2D context,
      List<Rectangle<num>> rects, Color? color, int lineWidth) {
    for (var rect in rects) {
      if (rect is Label && rect.color != null) {
        color = rect.color;
      }
      _strokeRect(context, rect, color, lineWidth);
    }
  }

  void _strokeRect(CanvasRenderingContext2D context, Rectangle<num> rect,
      Color? color, int lineWidth,
      [int? lineAlphaWidth]) {
    if (color == null) return;

    if (lineAlphaWidth != null) {
      context.setStrokeColorRgb(color.red, color.green, color.blue, 0.40);
      context.lineWidth = lineWidth;
      context.strokeRect(rect.left, rect.top, rect.width, rect.height);
    }

    if (color.hasAlpha) {
      context.setStrokeColorRgb(
          color.red, color.green, color.blue, color.alphaRatio);
    } else {
      context.setStrokeColorRgb(color.red, color.green, color.blue);
    }

    context.lineWidth = lineWidth;
    context.strokeRect(rect.left, rect.top, rect.width, rect.height);
  }

  void _strokePoints(CanvasRenderingContext2D context, List<Point<num>> points,
      Color color, int lineWidth) {
    for (var p in points) {
      _strokePoint(context, p, color, lineWidth);
    }
  }

  void _strokePoint(CanvasRenderingContext2D context, Point<num> p, Color color,
      int lineWidth) {
    var b = 3;
    var l = b * 2;

    context.setStrokeColorRgb(
        Color.black.red, Color.black.green, Color.black.blue);
    context.lineWidth = lineWidth;
    context.strokeRect(p.x - b - 1, p.y - b + 1, l, l);

    context.setStrokeColorRgb(
        Color.white.red, Color.white.green, Color.white.blue);
    context.lineWidth = lineWidth;
    context.strokeRect(p.x - b + 1, p.y - b - 1, l, l);

    context.setStrokeColorRgb(color.red, color.green, color.blue);
    context.lineWidth = lineWidth;
    context.strokeRect(p.x - b, p.y - b, l, l);
  }

  HTMLDivElement? _currentHint;

  void hideHint() {
    if (_currentHint != null) {
      _currentHint!.remove();
      _currentHint = null;
    }
  }

  /// Shows a hint with [label] bellow [rect] in canvas.
  void showHintAtRectangle(String label, Rectangle<num> rect) {
    showHint(
        label, Point(rect.left + (rect.width / 2), rect.top + rect.height));
  }

  /// Shows a hint with [label] at [point] in canvas.
  void showHint(String label, Point<num> point) {
    //print('showHint> $label ; $point');

    hideHint();

    var arrowSize = 6;

    num x = point.x * (1 / offsetWidthRatio);
    num y = point.y * (1 / offsetHeightRatio);

    x += canvas.offsetLeft - (8 + arrowSize - 1);
    y += canvas.offsetTop + arrowSize;

    var hint = HTMLDivElement()
      ..style.textAlign = 'center'
      ..style.borderRadius = '6px'
      ..style.padding = '6px 6px'
      ..style.position = 'absolute'
      ..style.zIndex = '999999'
      ..style.left = '${x}px'
      ..style.top = '${y}px'
      ..style.backgroundColor = 'rgba(0,0,0, 0.70)'
      ..style.color = 'rgba(255,255,255, 0.70)'
      ..style.pointerEvents = 'none';

    hint.text = label;

    var arrow = HTMLDivElement()
      ..style.left = '8px'
      ..style.top = '0px'
      ..style.position = 'absolute'
      ..style.transform = 'translate(0%, -100%)'
      ..style.width = '0'
      ..style.height = '0'
      ..style.borderLeft = '${arrowSize - 1}px solid transparent'
      ..style.borderRight = '${arrowSize - 1}px solid transparent'
      ..style.borderBottom = '${arrowSize}px solid rgba(0,0,0, 0.70)';

    hint.append(arrow);

    canvas.parentElement!.appendChild(hint);

    _currentHint = hint;
  }
}

/// Converts [imageSource] to [HTMLCanvasElement].
///
/// [width] Width of the image.
/// [height] Height of the image.
HTMLCanvasElement toCanvasElement(
    CanvasImageSource imageSource, int width, int height) {
  var canvas = HTMLCanvasElement()
    ..width = width
    ..height = height;
  var context = canvas.getContext('2d') as CanvasRenderingContext2D;

  context.drawImage(imageSource, 0, 0);

  return canvas;
}

/// Converts [canvas] to [HTMLImageElement]
///
/// [mimeType] MIME-Type of the image.
/// [quality] Quality of the image.
HTMLImageElement canvasToImageElement(HTMLCanvasElement canvas,
    [String? mimeType, num? quality]) {
  mimeType ??= 'image/png';
  quality ??= 0.99;

  var dataUrl = canvas.toDataUrl(mimeType);
  var img = HTMLImageElement()..src = dataUrl;
  img.width = canvas.width;
  img.height = canvas.height;
  return img;
}

/// Rotates [image] with [angleDegree].
HTMLCanvasElement rotateImageElement(HTMLImageElement image,
    [angleDegree = 90]) {
  var w = image.width;
  var h = image.height;
  return rotateCanvasImageSource(image, w, h, angleDegree);
}

/// Rotates [image] (a [CanvasImageSource]) with [angleDegree].
///
/// [width] Width of the image.
/// [height] Height of the image.
HTMLCanvasElement rotateCanvasImageSource(
    CanvasImageSource image, int width, int height,
    [angleDegree = 90]) {
  angleDegree ??= 90;

  var canvas = HTMLCanvasElement()
    ..width = height
    ..height = width;
  var context = canvas.getContext('2d') as CanvasRenderingContext2D;

  context.translate(canvas.width / 2, canvas.height / 2);
  context.rotate(angleDegree * math.pi / 180);
  context.drawImage(image, -width / 2, -height / 2);

  return canvas;
}
