import 'dart:async';
import 'dart:html';

import 'package:dom_tools/dom_tools.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:swiss_knife/swiss_knife.dart';

Map<String, Future<bool>> _addedCSSCodes = {};

/// Adds a CSS code ([cssCode]) into DOM.
Future<bool> addCSSCode(String cssCode) async {
  var prevCall = _addedCSSCodes[cssCode];
  if (prevCall != null) return prevCall;

  Future<bool> future;

  try {
    HeadElement head = querySelector('head');

    var styleElement = StyleElement();
    styleElement.innerHtml = cssCode;

    head.append(styleElement);

    future = Future.value(true);
  } catch (e, s) {
    print(e);
    print(s);
    future = Future.value(false);
  }

  _addedCSSCodes[cssCode] = future;

  return future;
}

Map<String, Future<bool>> _addedCssSources = {};

/// Add a CSS path using a `link` element into `head` DOM node.
///
/// [cssSource] The path to the CSS source file.
/// [insertIndex] optional index of insertion inside `head` node.
Future<bool> addCssSource(String cssSource, {int insertIndex}) async {
  var linkInDom = getLinkElementByHREF(cssSource);

  var prevCall = _addedCssSources[cssSource];

  if (prevCall != null) {
    if (linkInDom != null) {
      return prevCall;
    } else {
      var removed = _addedCssSources.remove(cssSource);
      assert(removed != null);
    }
  }

  if (linkInDom != null) {
    return true;
  }

  print('ADDING <LINK>: $cssSource');

  HeadElement head = querySelector('head');

  var script = LinkElement()
    ..rel = 'stylesheet'
    ..href = cssSource;

  var completer = Completer<bool>();

  script.onLoad.listen((e) {
    completer.complete(true);
  }, onError: (e) {
    completer.complete(false);
  });

  if (insertIndex != null) {
    insertIndex = Math.min(insertIndex, head.children.length);
    head.children.insert(insertIndex, script);
  } else {
    head.children.add(script);
  }

  var call = completer.future;
  _addedCssSources[cssSource] = call;

  return call;
}

/// Returns a [CssStyleDeclaration] from an element.
CssStyleDeclaration getComputedStyle(
    {Element parent,
    Element element,
    String classes,
    String style,
    bool hidden}) {
  parent ??= document.body;
  hidden ??= true;

  element ??= DivElement();

  var prevHidden = element.hidden;

  element.hidden = hidden;

  if (classes != null && classes.isNotEmpty) {
    var allClasses =
        classes.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    for (var c in allClasses) {
      element.classes.add(c);
    }
  }

  if (style != null && style.isNotEmpty) {
    element.style.cssText = style;
  }

  parent.children.add(element);

  var computedStyle = element.getComputedStyle();
  var cssText = computedStyle.cssText;

  var computedStyle2 = CssStyleDeclaration();
  computedStyle2.cssText = cssText;

  element.remove();

  element.hidden = prevHidden;

  return computedStyle2;
}

/// Specifies a CSS font style.
enum FontStyle {
  normal,
  italic,
  oblique,
}

/// Specifies a CSS font weight.
enum FontWeight { normal, bold, bolder, lighter }

/// Specifies a CSS color.
class StyleColor {
  final int color;

  final String colorHex;

  final String colorRGBa;

  const StyleColor(this.color)
      : colorHex = null,
        colorRGBa = null;

  const StyleColor.fromHex(this.colorHex)
      : color = null,
        colorRGBa = null;

  const StyleColor.fromRGBa(this.colorRGBa)
      : color = null,
        colorHex = null;

  @override
  String toString() {
    if (colorHex != null) {
      return colorHex.startsWith('#') ? colorHex : '#$colorHex';
    } else if (colorRGBa != null) {
      return colorRGBa.startsWith('rgba(') ? colorRGBa : 'rgba($colorRGBa)';
    } else {
      return '#${color.toRadixString(16).substring(2)}';
    }
  }
}

/// Specifies a CSS text style.
class TextStyle implements CSSValueBase {
  final StyleColor color;

  final StyleColor backgroundColor;

  final FontStyle fontStyle;

  final FontWeight fontWeight;

  final StyleColor borderColor;

  final String borderRadius;

  final String padding;

  const TextStyle(
      {this.color,
      this.backgroundColor,
      this.fontStyle,
      this.fontWeight,
      this.borderColor,
      this.borderRadius,
      this.padding});

  @override
  String cssValue() {
    var str = '';

    if (color != null) str += 'color: $color ;';
    if (backgroundColor != null) str += 'background-color: $backgroundColor ;';

    if (fontStyle != null) {
      str += 'font-style: ${EnumToString.parse(fontStyle)} ;';
    }
    if (fontWeight != null) {
      str += 'font-weight: ${EnumToString.parse(fontWeight)} ;';
    }

    if (borderColor != null) str += 'border-color: $borderColor ;';
    if (borderRadius != null) str += 'border-radius: $borderRadius;';

    if (padding != null) str += 'padding: $padding;';

    return str;
  }
}

abstract class CSSValueBase {
  String cssValue();
}

Map<String, Map<dynamic, bool>> _loadedThemesByPrefix = {};

/// Loads [css] dynamically.
///
/// [cssClassPrefix] Prefix for each class in [css] Map.
/// [css] Map of CSS classes.
void loadCSS(String cssClassPrefix, Map<String, CSSValueBase> css) {
  cssClassPrefix ??= '';

  var _loadedThemes = _loadedThemesByPrefix[cssClassPrefix];

  if (_loadedThemes == null) {
    _loadedThemesByPrefix[cssClassPrefix] = _loadedThemes = {};
  }

  if (_loadedThemes[css] != null) return;
  _loadedThemes[css] = true;

  var id = '__dom_tools__dynamic_css__$cssClassPrefix';

  var styleElement = StyleElement()..id = id;
  ;

  var prev = document.head.querySelector('#$id');
  if (prev != null) {
    prev.remove();
  }

  document.head.append(styleElement);

  CssStyleSheet sheet = styleElement.sheet;

  for (var key in css.keys) {
    var val = css[key];
    var rule = '.$cssClassPrefix$key { ${val.cssValue()} }\n';
    sheet.insertRule(rule, 0);
    print(rule);
  }
}

/// A Theme set, with multiples themes.
class CSSThemeSet {
  final String cssPrefix;

  final List<Map<String, CSSValueBase>> _themes;

  final int defaultThemeIndex;

  CSSThemeSet(this.cssPrefix, this._themes, [this.defaultThemeIndex = 0]);

  Map<String, CSSValueBase> getCSSTheme(int themeIndex) {
    if (_themes == null || _themes.isEmpty) return null;
    return themeIndex >= 0 && themeIndex < _themes.length
        ? _themes[themeIndex]
        : null;
  }

  /// Loads theme at [themeIndex].
  int loadTheme(int themeIndex) {
    var cssTheme = getCSSTheme(themeIndex);

    if (cssTheme != null) {
      loadCSSTheme(cssTheme);
      return themeIndex;
    } else {
      cssTheme = getCSSTheme(defaultThemeIndex);
      loadCSSTheme(cssTheme);
      return defaultThemeIndex;
    }
  }

  bool _loadedTheme = false;

  bool get loadedTheme => _loadedTheme;

  /// Loads [css] into DOM.
  void loadCSSTheme(Map<String, CSSValueBase> css) {
    loadCSS(cssPrefix, css);
    _loadedTheme = true;
  }

  /// Ensures that the [defaultThemeIndex] is loaded into DOM.
  void ensureThemeLoaded() {
    if (!_loadedTheme) {
      loadTheme(defaultThemeIndex);
    }
  }
}

typedef AnimationCallback = void Function();

/// Changes CSS properties ([cssProperties]) of [elements] using
/// animation (CSS transition).
///
/// [duration] Time duration of the animation/transition. Default: 1s.
/// [timingFunction] Type of speed curve function (linear, ease, ease-in, ease-out, ease-in-out, step-start, step-end). Default: `ease`.
/// [finalizeInterval] Time after CSS transition to set [finalProperties]. Default: 100ms
/// [rollbackProperties] Properties to rollback, to values before start of transition.
/// [finalProperties] The final properties to set after transition.
/// [callback] Callback to be called after transition and set of [finalProperties].
void animateCSS(Iterable<Element> elements, Map<String, String> cssProperties,
    Duration duration,
    {String timingFunction,
    Duration finalizeInterval,
    Set<String> rollbackProperties,
    Map<String, String> finalProperties,
    AnimationCallback callback}) {
  if (elements == null || cssProperties == null) return;

  elements = List.from(elements.where((e) => e != null));

  if (elements.isEmpty || cssProperties.isEmpty) return;

  duration ??= Duration(seconds: 1);
  timingFunction ??= 'ease';
  rollbackProperties ??= {};
  finalProperties ??= {};

  rollbackProperties.removeWhere((p) => !cssProperties.containsKey(p));

  var durationMs = duration.inMilliseconds;

  var prevTransitions =
      Map.fromEntries(elements.map((e) => MapEntry(e, e.style.transition)));

  elements.forEach(
      (e) => e.style.transition = 'all ${durationMs}ms $timingFunction');

  var prevValues = <Element, Map<String, String>>{};
  var setValues = <Element, Map<String, String>>{};

  for (var entry in cssProperties.entries) {
    var key = entry.key;

    for (var element in elements) {
      var prevVal = element.style.getPropertyValue(key);
      element.style.setProperty(key, entry.value);

      if (rollbackProperties.contains(key)) {
        prevValues[element] ??= {};
        prevValues[element][key] = prevVal;

        setValues[element] ??= {};
        setValues[element][key] = element.style.getPropertyValue(key);
      }
    }
  }

  var interval =
      finalizeInterval != null ? finalizeInterval.inMilliseconds : 100;

  Future.delayed(Duration(milliseconds: durationMs + interval), () {
    for (var key in rollbackProperties) {
      for (var element in elements) {
        var setVal = element.style.getPropertyValue(key);
        if (setVal == setValues[element][key]) {
          var prevValue = prevValues[element][key];
          element.style.setProperty(key, prevValue);
        }
      }
    }

    for (var element in elements) {
      for (var entry in finalProperties.entries) {
        element.style.setProperty(entry.key, entry.value);
      }
      var prevTransition = prevTransitions[element];
      element.style.transition = prevTransition;

      print(element.outerHtml);
    }

    try {
      callback();
    } catch (e, s) {
      print(e);
      print(s);
    }
  });
}
