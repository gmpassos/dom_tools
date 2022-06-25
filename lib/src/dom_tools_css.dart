import 'dart:async';
import 'dart:html';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:dom_tools/dom_tools.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:swiss_knife/swiss_knife.dart';

final RegExp _patternCssLengthUnit =
    RegExp(r'(px|%|vw|vh|vmin|vmax|em|ex|ch|rem|cm|mm|in|pc|pt)$');

/// Parses a CSS length, using optional [unit].
///
/// [def] Default value if parse fails or [cssValue] [isEmptyString].
/// [allowPXWithoutSuffix]
num? parseCSSLength(String cssValue,
    {String? unit, int? def, bool allowPXWithoutSuffix = false}) {
  if (isEmptyString(cssValue)) return def;
  cssValue = cssValue.toLowerCase().trim();
  if (isEmptyString(cssValue)) return def;

  if (unit != null) {
    unit = unit.toLowerCase().trim();
  }

  if (isNotEmptyString(unit)) {
    if (cssValue.endsWith(unit!)) {
      var s = cssValue.substring(0, cssValue.length - unit.length).trim();
      return parseNum(s, def);
    } else if (allowPXWithoutSuffix && unit == 'px' && isNum(cssValue)) {
      return parseNum(cssValue, def);
    }
  } else {
    var match = _patternCssLengthUnit.firstMatch(cssValue);
    if (match != null) {
      var unit = match.group(1)!;
      var s = cssValue.substring(0, cssValue.length - unit.length).trim();
      return parseNum(s, def);
    }
  }

  return def;
}

Map<String, Future<bool>> _addedCSSCodes = {};

/// Adds a CSS code ([cssCode]) into DOM.
Future<bool> addCSSCode(String cssCode) async {
  var prevCall = _addedCSSCodes[cssCode];
  if (prevCall != null) return prevCall;

  Future<bool> future;

  try {
    var head = querySelector('head') as HeadElement;

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
Future<bool> addCssSource(String cssSource, {int? insertIndex}) async {
  var linkInDom = getLinkElementByHREF(cssSource, 'stylesheet');

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

  var head = querySelector('head') as HeadElement?;

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
    insertIndex = Math.min(insertIndex, head!.children.length);
    head.children.insert(insertIndex, script);
  } else {
    head!.children.add(script);
  }

  var call = completer.future;
  _addedCssSources[cssSource] = call;

  return call;
}

/// Returns a [CssStyleDeclaration] from an element.
CssStyleDeclaration getComputedStyle(
    {Element? parent,
    Element? element,
    String? classes,
    String? style,
    bool? hidden}) {
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

  parent!.children.add(element);

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
  final int? color;

  final String? colorHex;

  final String? colorRGBa;

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
      return colorHex!.startsWith('#') ? colorHex! : '#$colorHex';
    } else if (colorRGBa != null) {
      return colorRGBa!.startsWith('rgba(') ? colorRGBa! : 'rgba($colorRGBa)';
    } else {
      return '#${color!.toRadixString(16).substring(2)}';
    }
  }
}

/// Specifies a CSS text style.
class TextStyle implements CSSValueBase {
  final StyleColor? color;

  final StyleColor? backgroundColor;

  final FontStyle? fontStyle;

  final FontWeight? fontWeight;

  final StyleColor? borderColor;

  final String? borderRadius;

  final String? padding;

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
      str += 'font-style: ${EnumToString.convertToString(fontStyle)} ;';
    }
    if (fontWeight != null) {
      str += 'font-weight: ${EnumToString.convertToString(fontWeight)} ;';
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
void loadCSS(String cssClassPrefix, Map<String, CSSValueBase>? css) {
  var loadedThemes = _loadedThemesByPrefix[cssClassPrefix];

  if (loadedThemes == null) {
    _loadedThemesByPrefix[cssClassPrefix] = loadedThemes = {};
  }

  if (loadedThemes[css] != null) return;
  loadedThemes[css] = true;

  var id = '__dom_tools__dynamic_css__$cssClassPrefix';

  var styleElement = StyleElement()..id = id;

  var prev = document.head!.querySelector('#$id');
  if (prev != null) {
    prev.remove();
  }

  document.head!.append(styleElement);

  var sheet = styleElement.sheet as CssStyleSheet?;

  for (var key in css!.keys) {
    var val = css[key]!;
    var rule = '.$cssClassPrefix$key { ${val.cssValue()} }\n';
    sheet!.insertRule(rule, 0);
    print(rule);
  }
}

/// A Theme set, with multiples themes.
class CSSThemeSet {
  final String cssPrefix;

  final List<Map<String, CSSValueBase>> _themes;

  final int defaultThemeIndex;

  CSSThemeSet(this.cssPrefix, this._themes, [this.defaultThemeIndex = 0]);

  Map<String, CSSValueBase>? getCSSTheme(int themeIndex) {
    if (_themes.isEmpty) return null;
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
  void loadCSSTheme(Map<String, CSSValueBase>? css) {
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

abstract class CSSAnimationConfig {
  /// Returns [true] if this configuration is valid;
  bool get isValid;

  /// Returns [false] if this configuration is NOT valid;
  bool get isNotValid => !isValid;

  /// Plays CSS animation.
  ///
  /// - [initialDelay] An initial delay, before start transitions.
  /// - [callback] Callback to be called after transition and set of [_finalProperties].
  ///
  /// *NOTE:* Should return null if [isNotValid].
  Future<void>? play({Duration? initialDelay, AnimationCallback? callback});
}

/// CSS animation configuration for a group of [CSSAnimationConfig].
class CSSAnimationConfigGroup extends CSSAnimationConfig {
  final List<CSSAnimationConfig> _configs;

  CSSAnimationConfigGroup(this._configs);

  /// Group of [CSSAnimationConfig].
  List<CSSAnimationConfig> get configs =>
      List<CSSAnimationConfig>.unmodifiable(_configs);

  @override
  bool get isValid =>
      _configs.isNotEmpty && _configs.where((c) => c.isNotValid).isEmpty;

  @override
  Future<void> play({Duration? initialDelay, AnimationCallback? callback}) {
    var plays = _configs
        .map((c) => c.play(initialDelay: initialDelay, callback: callback))
        .whereType<Future<void>>()
        .toList();
    return Future.wait(plays);
  }
}

/// CSS animation configuration for a [List<Element>].
class CSSAnimationConfigElements extends CSSAnimationConfig {
  /// Elements to animate.
  final List<Element> _elements;

  /// CSS properties to animate.
  final Map<String, String> _transitionProperties;

  /// Time duration of the animation/transition of properties. Default: 1s.
  final Duration duration;

  /// Type of speed curve function (linear, ease, ease-in, ease-out, ease-in-out, step-start, step-end). Default: `ease`.
  final String timingFunction;

  /// The initial properties to set before transition.
  final Map<String, String> _initialProperties;

  /// Classes to set before transitions. Will remove classes starting with '!'.
  final Set<String> _initialClasses;

  /// Properties to rollback, to values before start of transition.
  final Set<String> _rollbackProperties;

  /// The pre-final properties, to set before [finalizeInterval].
  final Map<String, String> _preFinalProperties;

  /// The final properties to set after transition.
  final Map<String, String> _finalProperties;

  /// Classes to set after transitions. Will remove classes starting with '!'.
  final Set<String> _finalClasses;

  /// Time after CSS transition to set [_finalProperties]. Default: 100ms
  final Duration? finalizeInterval;

  CSSAnimationConfigElements(Iterable<Element> elements, this.duration,
      {String timingFunction = 'ease',
      Map<String, String>? initialProperties,
      Iterable<String>? initialClasses,
      Iterable<String>? rollbackProperties,
      Map<String, String>? transitionProperties,
      Map<String, String>? preFinalProperties,
      Map<String, String>? finalProperties,
      Iterable<String>? finalClasses,
      this.finalizeInterval})
      : _elements = _parseElements(elements),
        timingFunction = _parseTimingFunction(timingFunction),
        _initialProperties = initialProperties ?? {},
        _initialClasses = _parseSet(initialClasses),
        _rollbackProperties = _parseSet(rollbackProperties),
        _transitionProperties = transitionProperties ?? {},
        _preFinalProperties = preFinalProperties ?? {},
        _finalProperties = finalProperties ?? {},
        _finalClasses = _parseSet(finalClasses);

  static String _parseTimingFunction(String timingFunction) {
    return isNotEmptyString(timingFunction, trim: true)
        ? timingFunction.trim()
        : 'ease';
  }

  static List<Element> _parseElements(Iterable<Element> elements) =>
      elements.toList();

  static Set<String> _parseSet(Iterable<String>? it) => Set.from((it ?? [])
      .where((c) => isNotEmptyString(c, trim: true))
      .map((c) => c.trim()));

  List<Element> get elements => List<Element>.unmodifiable(_elements);

  Map<String, String> get transitionProperties =>
      Map<String, String>.unmodifiable(_transitionProperties);

  Map<String, String> get initialProperties =>
      Map<String, String>.unmodifiable(_initialProperties);

  Set<String> get initialClasses => Set<String>.from(_initialClasses);

  Set<String> get rollbackProperties => Set<String>.from(_rollbackProperties);

  Map<String, String> get preFinalProperties =>
      Map<String, String>.unmodifiable(_preFinalProperties);

  Map<String, String> get finalProperties =>
      Map<String, String>.unmodifiable(_finalProperties);

  Set<String> get finalClasses => Set<String>.from(_finalClasses);

  @override
  bool get isValid {
    if (_elements.isEmpty) return false;
    if (_transitionProperties.isEmpty) return false;

    return true;
  }

  @override
  Future<void>? play({Duration? initialDelay, AnimationCallback? callback}) {
    return _animateInit(initialDelay: initialDelay, callback: callback);
  }

  Future<void>? _animateInit(
      {Duration? initialDelay, AnimationCallback? callback}) {
    if (isNotValid) return null;

    _rollbackProperties
        .removeWhere((p) => !_transitionProperties.containsKey(p));

    if (initialDelay != null && initialDelay.inMilliseconds > 0) {
      return Future.delayed(initialDelay, () {
        return _animate(callback);
      });
    } else {
      return _animate(callback);
    }
  }

  Future<void> _animate(AnimationCallback? callback) {
    var prevTransitions =
        Map.fromEntries(_elements.map((e) => MapEntry(e, e.style.transition)));

    var prevValues = <Element, Map<String, String>>{};

    for (var entry in _transitionProperties.entries) {
      var key = entry.key;

      for (var element in _elements) {
        var prevVal = element.style.getPropertyValue(key);

        if (_rollbackProperties.contains(key)) {
          prevValues[element] ??= {};
          prevValues[element]![key] = prevVal;
        }
      }
    }

    if (_initialProperties.isNotEmpty || _initialClasses.isNotEmpty) {
      for (var entry in _initialProperties.entries) {
        var key = entry.key;

        for (var element in _elements) {
          element.style.setProperty(key, entry.value);
        }
      }

      addElementsClasses(_elements, _initialClasses);

      return Future.delayed(Duration(milliseconds: 16), () {
        return _animateTransitions(prevValues, prevTransitions, callback);
      });
    } else {
      return _animateTransitions(prevValues, prevTransitions, callback);
    }
  }

  Future<void> _animateTransitions(Map<Element, Map<String, String>> prevValues,
      Map<Element, String> prevTransitions, AnimationCallback? callback) async {
    var durationMs = duration.inMilliseconds;

    for (var e in _elements) {
      e.style.transition = 'all ${durationMs}ms $timingFunction';
    }

    var setValues = <Element, Map<String, String>>{};

    for (var entry in _transitionProperties.entries) {
      var key = entry.key;

      for (var element in _elements) {
        element.style.setProperty(key, entry.value);

        if (_rollbackProperties.contains(key)) {
          setValues[element] ??= {};
          setValues[element]![key] = element.style.getPropertyValue(key);
        }
      }
    }

    var interval =
        finalizeInterval != null ? finalizeInterval!.inMilliseconds : 100;

    if (_preFinalProperties.isNotEmpty) {
      await Future.delayed(Duration(milliseconds: durationMs));

      for (var entry in _preFinalProperties.entries) {
        var key = entry.key;
        for (var element in _elements) {
          element.style.setProperty(key, entry.value);
        }
      }

      await Future.delayed(Duration(milliseconds: interval));
    } else {
      await Future.delayed(Duration(milliseconds: durationMs + interval));
    }

    for (var key in _rollbackProperties) {
      for (var element in _elements) {
        var setVal = element.style.getPropertyValue(key);
        if (setVal == setValues[element]![key]) {
          var prevValue = prevValues[element]![key];
          element.style.setProperty(key, prevValue);
        }
      }
    }

    for (var element in _elements) {
      for (var entry in _finalProperties.entries) {
        element.style.setProperty(entry.key, entry.value);
      }

      addElementsClasses(_elements, _finalClasses);

      var prevTransition = prevTransitions[element]!;
      element.style.transition = prevTransition;
    }

    if (callback != null) {
      try {
        callback();
      } catch (e, s) {
        print(e);
        print(s);
      }
    }
  }

  @override
  String toString() {
    return 'CSSAnimationConfig{elements: $_elements, transitionProperties: $_transitionProperties, duration: $duration, timingFunction: $timingFunction, initialProperties: $_initialProperties, initialClasses: $_initialClasses, rollbackProperties: $_rollbackProperties, preFinalProperties: $_preFinalProperties, finalProperties: $_finalProperties, finalClasses: $_finalClasses, finalizeInterval: $finalizeInterval}';
  }
}

/// Sames [animateCSS] but runs [animationsConfig] in sequence;
Future<void>? animateCSSSequence(Iterable<CSSAnimationConfig> animationsConfig,
    {Duration? initialDelay, int? repeat, bool? repeatInfinity}) {
  var animationsList = animationsConfig.where((e) => e.isValid).toList();
  if (animationsList.isEmpty) return null;

  if (animationsList.length == 1) {
    return animationsList[0].play(initialDelay: initialDelay);
  }

  repeat ??= 0;
  repeatInfinity ??= false;

  if (initialDelay != null && initialDelay.inMilliseconds > 0) {
    return Future.delayed(initialDelay, () {
      return _animateCSSSequenceRepeat(animationsList, repeat!, repeatInfinity);
    });
  } else {
    return _animateCSSSequenceRepeat(animationsList, repeat, repeatInfinity);
  }
}

Future<void>? _animateCSSSequenceRepeat(List<CSSAnimationConfig> animationsList,
    int repeat, bool? repeatInfinity) async {
  var future = _animateCSSSequence(animationsList);

  while (repeat > 0 || repeatInfinity!) {
    await future;

    if (document.visibilityState == 'hidden') {
      print('ANIMATION_SEQUENCE: PAGE HIDDEN!');
      ListenerWrapper(document.onVisibilityChange, (dynamic event) {
        print(
            'ANIMATION_SEQUENCE: PAGE SHOW! continue sequence: repeat $repeat ; repeatInfinity: $repeatInfinity');
        _animateCSSSequenceRepeat(animationsList, repeat - 1, repeatInfinity);
      }, oneShot: true)
          .listen();
      break;
    }

    future = _animateCSSSequence(animationsList);
    --repeat;
  }

  return future;
}

Future<void>? _animateCSSSequence(List<CSSAnimationConfig> animationsList) {
  animationsList = animationsList.where((c) => c.isValid).toList();
  if (animationsList.isEmpty) return null;

  var futures = <Future<void>>[];

  var playIdx = 0;
  for (; playIdx < animationsList.length; ++playIdx) {
    var play = animationsList[playIdx].play();
    if (play != null) {
      futures.add(play);
      ++playIdx;
      break;
    }
  }

  for (; playIdx < animationsList.length; ++playIdx) {
    var prevFuture = futures.last;
    var animation = animationsList[playIdx];

    var future = prevFuture.then((_) {
      var play = animation.play();
      return play ?? Future.value();
    });

    futures.add(future);
  }

  return futures.last;
}

/// Add to [elements] a set of [classes]. Will remove classes starting with '!'.
bool addElementsClasses(Iterable<Element> elements, Iterable<String> classes) {
  if (isEmptyObject(classes)) return false;

  var initialClasses =
      Set<String>.from(classes.where((c) => isNotEmptyString(c)));
  if (initialClasses.isEmpty) return false;

  var changedAny = false;

  for (var className in initialClasses) {
    className = className.trim();
    var remove = className.startsWith('!');
    if (remove) className = className.substring(1);

    for (var element in elements) {
      bool changed;
      if (remove) {
        changed = element.classes.remove(className);
      } else {
        changed = element.classes.add(className);
      }

      if (changed) changedAny = true;
    }
  }

  return changedAny;
}

/// Sets [element] scroll colors, using standard CSS property `scrollbar-color`
/// and webkit pseudo element `::-webkit-scrollbar-thumb` and `::-webkit-scrollbar-track`
String? setElementScrollColors(
    Element element, int scrollWidth, String scrollButtonColor,
    [String? scrollBgColor]) {
  scrollBgColor ??= '';

  scrollButtonColor = scrollButtonColor.trim();
  scrollBgColor = scrollBgColor.trim();

  if (scrollButtonColor.isEmpty && scrollBgColor.isEmpty) return null;

  if (scrollWidth < 0) scrollWidth = 0;

  removeElementScrollColors(element);

  element.style.setProperty('scrollbar-width', '${scrollWidth}px');
  element.style.setProperty(
      'scrollbar-color', '$scrollButtonColor $scrollBgColor'.trim());

  var regExpNonWord = RegExp(r'\W+');

  var buttonColorID = scrollButtonColor.replaceAll(regExpNonWord, '_');
  var bgColorID = scrollButtonColor.replaceAll(regExpNonWord, '_');

  var scrollColorClassID =
      '__scroll_color__${scrollWidth}__${buttonColorID}__$bgColorID';

  var webkitScrollColorsCSS =
      '.$scrollColorClassID::-webkit-scrollbar { width: ${scrollWidth}px;}\n';

  if (scrollButtonColor.isNotEmpty) {
    var radius = scrollWidth * 2;
    var border = scrollWidth > 1 ? Math.max(1, scrollWidth ~/ 4) : 0;

    webkitScrollColorsCSS +=
        '.$scrollColorClassID::-webkit-scrollbar-thumb { background-color: $scrollButtonColor ; border-radius: ${radius}px; border: ${border}px solid $scrollBgColor;}\n';
  }

  if (scrollBgColor.isNotEmpty) {
    webkitScrollColorsCSS +=
        '.$scrollColorClassID::-webkit-scrollbar-track { background: $scrollBgColor ;}\n';
    webkitScrollColorsCSS +=
        '.$scrollColorClassID::-webkit-scrollbar-track-piece { background: $scrollBgColor ;}\n';
  }

  addCSSCode(webkitScrollColorsCSS);

  if (!element.classes.contains(scrollColorClassID)) {
    element.classes.add(scrollColorClassID);
  }

  return scrollColorClassID;
}

/// Removes [element] scroll colors CSS properties set by [setElementScrollColors].
List<String>? removeElementScrollColors(Element element) {
  element.style.removeProperty('scrollbar-width');
  element.style.removeProperty('scrollbar-color');

  var scrollClassIDs =
      element.classes.where((c) => c.startsWith('__scroll_color__')).toList();

  if (isNotEmptyObject(scrollClassIDs)) {
    element.classes.removeAll(scrollClassIDs);
    return scrollClassIDs;
  } else {
    return null;
  }
}

void setTreeElementsBackgroundBlur(Element element, String className) {
  if (isEmptyString(className, trim: true)) return;

  className = className.trim();

  var levels = [1, 2, 3, 4];

  if (element.classes.contains(className)) {
    setElementBackgroundBlur(element, 3);
  } else {
    for (var level in levels) {
      if (element.classes.contains('$className-$level')) {
        setElementBackgroundBlur(element, level * 3);
      }
    }
  }

  var elements = element.querySelectorAll('.$className');
  for (var e in elements) {
    setElementBackgroundBlur(e, 3);
  }

  for (var level in levels) {
    var elements = element.querySelectorAll('.$className-$level');
    for (var e in elements) {
      setElementBackgroundBlur(e, level * 3);
    }
  }
}

/// Sets [element] background as a blur effect of size [blurSize].
/// Uses CSS property `backdrop-filter`.
void setElementBackgroundBlur(Element element, [int? blurSize]) {
  blurSize ??= 3;
  var filter = blurSize > 0 ? 'blur(${blurSize}px)' : 'none';
  element.style.setProperty('backdrop-filter', filter);
}

/// Removes [element] background blur effect, set by [setElementBackgroundBlur].
void removeElementBackgroundBlur(Element element, [int? blurSize]) {
  var val = element.style.getPropertyValue('backdrop-filter');
  if (val.contains('blur')) {
    element.style.removeProperty('backdrop-filter');
  }
}

const int cssMaxZIndex = 2147483647;

/// Returns the [element] `z-index` or [element.parent] `z-index` recursively.
String? getElementZIndex(Element? element, [String? def]) {
  while (element != null) {
    var zIndex = element.style.zIndex;
    if (isNotEmptyObject(zIndex) && isInt(zIndex)) {
      return zIndex;
    }
    element = element.parent;
  }
  return def;
}

/// Returns a [CssStyleDeclaration] of the pre-computed CSS properties of [element].
CssStyleDeclaration getElementPreComputedStyle(Element element) {
  var list = getElementAllCssProperties(element);
  var allCss = list.join('; ');
  return CssStyleDeclaration.css(allCss);
}

/// Returns a list of CSS properties associated with [element]
List<String> getElementAllCssProperties(Element element) {
  var rules = getElementAllCssRule(element);

  var cssTexts = rules
      .map((r) => r.cssText ?? '')
      .map(parseCssRuleTextProperties)
      .where((p) => p.isNotEmpty)
      .toList();

  var elemCssText = element.style.cssText;
  if (elemCssText != null && elemCssText.isNotEmpty) {
    cssTexts.add(elemCssText);
  }

  return cssTexts;
}

/// Returns a list of [CssRule] associated with [element].
List<CssRule> getElementAllCssRule(Element element) {
  var tag = element.tagName.toLowerCase();

  var patterns = [tag, ...element.classes.map((c) => r'\.' + c)];

  var regExp = RegExp(r'^(?:' + patterns.join('|') + r')$',
      multiLine: false, caseSensitive: false);

  var rules = selectCssRuleWithSelector(regExp);

  return rules;
}

/// Transforms all [CssMediaRule] to [targetClass] rule applied for [viewportWidth] and [viewportHeight].
List<String> getAllViewportMediaCssRuleAsClassRule(
    int viewportWidth, viewportHeight, String targetClass) {
  var rules = getAllViewportMediaCssRule(viewportWidth, viewportHeight);

  var rulesFixed = <String, List<String>>{};

  for (var mediaRule in rules) {
    var cssRules = mediaRule.cssRules;
    if (cssRules == null) continue;
    for (var rule in cssRules.whereType<CssStyleRule>()) {
      var block = rule.style.cssText;
      if (block == null || block.isEmpty) continue;

      var selectors = parseCssRuleSelectors(rule);
      var selectorsFixed = selectors.map((s) => '.$targetClass $s');
      var selectors2 = selectorsFixed.join(' , ');

      var blocks = rulesFixed.putIfAbsent(selectors2, () => <String>[]);
      blocks.add(block);
    }
  }

  var rules2 = rulesFixed
      .map((sel, blocks) {
        var css = blocks.join(' ; ');
        if (blocks.length > 1) {
          var css2 = CssStyleDeclaration.css(css).cssText;
          if (css2 != null) {
            css = css2;
          }
        }
        return MapEntry(sel, '$sel { $css }');
      })
      .values
      .toList();

  return rules2;
}

/// Transforms all [CssMediaRule] to [targetClass] rule not applied for [viewportWidth] and [viewportHeight].
List<String> getAllOutOfViewportMediaCssRuleAsClassRule(
    int viewportWidth, viewportHeight, String targetClass) {
  var rules = getAllOutOfViewportMediaCssRule(viewportWidth, viewportHeight);

  var rulesFixed = <String, List<String>>{};

  for (var mediaRule in rules) {
    for (var rule in mediaRule.cssRules!.whereType<CssStyleRule>()) {
      var selectors = parseCssRuleSelectors(rule);
      var selectorsFixed = selectors.map((s) => '.$targetClass $s');

      var block = rule.style.cssText!;
      var blockUnset =
          block.replaceAll(RegExp(r':.*?;'), ': initial !important;');

      var selectors2 = selectorsFixed.join(' , ');
      var blocks = rulesFixed.putIfAbsent(selectors2, () => <String>[]);
      blocks.add(blockUnset);
    }
  }

  var rules2 = rulesFixed
      .map((key, value) {
        String? css = value.join(' ; ');
        if (value.length > 1) {
          css = CssStyleDeclaration.css(css).cssText;
        }
        return MapEntry(key, '$key { $css }');
      })
      .values
      .toList();

  return rules2;
}

/// Returns all [CssMediaRule] not applied for [viewportWidth] and [viewportHeight].
List<CssMediaRule> getAllOutOfViewportMediaCssRule(
    int viewportWidth, viewportHeight) {
  var rules = getAllMediaCssRule(r'(?:min|max)-(?:width|height):\s*.*?');

  var viewportRules = <CssMediaRule>[];

  for (var rule in rules) {
    var conditionText =
        rule.conditionText!.trim().replaceAll(RegExp(r'^\(|\)$'), '');

    var parts = split(conditionText, ':', 2);
    if (parts.length != 2) continue;

    var type = parts[0].trim().toLowerCase();
    var value = parts[1].trim().toLowerCase();

    value = value.replaceFirst(RegExp(r'px$'), '');

    if (isNum(value)) {
      var n = parseNum(value);

      if (type == 'min-width') {
        if (viewportWidth < n!) {
          viewportRules.add(rule);
        }
      } else if (type == 'min-height') {
        if (viewportHeight < n) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-width') {
        if (viewportWidth > n!) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-height') {
        if (viewportHeight > n) {
          viewportRules.add(rule);
        }
      }
    }
  }

  return viewportRules;
}

/// Returns all [CssMediaRule] applied for [viewportWidth] [viewportHeight].
List<CssMediaRule> getAllViewportMediaCssRule(
    int viewportWidth, viewportHeight) {
  var rules = getAllMediaCssRule(r'(?:min|max)-(?:width|height):\s*.*?');

  var viewportRules = <CssMediaRule>[];

  for (var rule in rules) {
    var conditionText =
        rule.conditionText!.trim().replaceAll(RegExp(r'^\(|\)$'), '');

    var parts = split(conditionText, ':', 2);
    if (parts.length != 2) continue;

    var type = parts[0].trim().toLowerCase();
    var value = parts[1].trim().toLowerCase();

    value = value.replaceFirst(RegExp(r'px$'), '');
    if (isNum(value)) {
      var n = parseNum(value);

      if (type == 'min-width') {
        if (viewportWidth >= n!) {
          viewportRules.add(rule);
        }
      } else if (type == 'min-height') {
        if (viewportHeight >= n) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-width') {
        if (viewportWidth <= n!) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-height') {
        if (viewportHeight <= n) {
          viewportRules.add(rule);
        }
      }
    }
  }

  return viewportRules;
}

/// Returns a list of @media [CssRule] with [mediaCondition].
List<CssMediaRule> getAllMediaCssRule(String mediaCondition) {
  mediaCondition = mediaCondition.trim();

  RegExp regExp;

  if (mediaCondition.isNotEmpty) {
    regExp = RegExp(r'^@media.*?\(\s*' + mediaCondition + r'\s*\)$',
        multiLine: false, caseSensitive: false);
  } else {
    regExp =
        RegExp(r'^@media.*?\(.*?\)', multiLine: false, caseSensitive: false);
  }

  var rules =
      selectCssRuleWithSelector(regExp).whereType<CssMediaRule>().toList();

  return rules;
}

/// Returns a list of [CssRule] with [targetSelector] patterns.
List<CssRule> selectCssRuleWithSelector(Pattern targetSelector) {
  var sheets = getAllCssStyleSheet();

  var rules = sheets
      .map((s) => getAllCssRuleBySelector(targetSelector, s))
      .expand((e) => e)
      .toList();

  return rules;
}

/// Returns all current [CssStyleSheet].
List<CssStyleSheet> getAllCssStyleSheet() {
  var styles = querySelectorAll('style').cast<StyleElement>();
  var links = querySelectorAll('link').cast<LinkElement>();

  var sheets = [
    ...styles.map((s) => s.sheet).whereType<CssStyleSheet>(),
    ...links.map((s) => s.sheet).whereType<CssStyleSheet>(),
  ];

  return sheets;
}

/// Returns a [List<CssRule>] for [targetSelector].
List<CssRule> getAllCssRuleBySelector(
    Pattern targetSelector, CssStyleSheet? sheet) {
  if (sheet == null) return [];

  if (targetSelector is String) {
    var s = targetSelector.trim().toLowerCase();
    if (s.isEmpty) return [];
    return _getAllCssRuleBySelectorString(s, sheet);
  } else if (targetSelector is RegExp) {
    return _getAllCssRuleBySelectorRegExp(targetSelector, sheet);
  } else {
    throw StateError('Invalid targetSelector: $targetSelector');
  }
}

List<CssRule> _getAllCssRuleBySelectorString(
    String targetSelector, CssStyleSheet sheet) {
  var rules = <CssRule>[];

  for (var rule in sheet.rules!) {
    var selectors = parseCssRuleSelectors(rule).map((s) => s.toLowerCase());

    var firstMatch = selectors.firstWhereOrNull((s) => s == targetSelector);

    if (firstMatch != null) {
      rules.add(rule);
    }
  }

  return rules;
}

List<CssRule> _getAllCssRuleBySelectorRegExp(
    RegExp targetSelector, CssStyleSheet sheet) {
  var rules = <CssRule>[];

  for (var rule in sheet.rules!) {
    var selectors = parseCssRuleSelectors(rule).map((s) => s.toLowerCase());

    var firstMatch =
        selectors.firstWhereOrNull((s) => targetSelector.hasMatch(s));

    if (firstMatch != null) {
      rules.add(rule);
    }
  }

  return rules;
}

/// Parses the selectors of [cssRule].
List<String> parseCssRuleSelectors(CssRule cssRule) {
  if (cssRule is CssStyleRule) {
    var selectorText = cssRule.selectorText.trim();
    var list = parseStringFromInlineList(selectorText, RegExp(r'\s*,\s*'));
    return list ?? <String>[];
  } else {
    return parseCssRuleTextSelectors(cssRule.cssText);
  }
}

/// Returns a list of selectors of the [CssRule] text.
List<String> parseCssRuleTextSelectors(String? cssRuleText) {
  if (cssRuleText == null || cssRuleText.isEmpty) return [];
  var idx = cssRuleText.indexOf('{');
  if (idx < 0) return [];
  var selectorText = cssRuleText.substring(0, idx).trim();
  var list = parseStringFromInlineList(selectorText, RegExp(r'\s*,\s*'));
  return list ?? [];
}

/// Returns a list of properties of the [CssRule] text.
String parseCssRuleTextProperties(String? cssRuleText) {
  if (cssRuleText == null || cssRuleText.isEmpty) return '';
  var idx1 = cssRuleText.indexOf('{');
  if (idx1 < 0) return '';
  var idx2 = cssRuleText.lastIndexOf('}');
  var properties = cssRuleText.substring(idx1 + 1, idx2).trim();
  return properties;
}
