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

    if (callback != null) {
      try {
        callback();
      } catch (e, s) {
        print(e);
        print(s);
      }
    }
  });
}

/// Sets [element] scroll colors, using standard CSS property `scrollbar-color`
/// and webkit pseudo element `::-webkit-scrollbar-thumb` and `::-webkit-scrollbar-track`
String setElementScrollColors(
    Element element, int scrollWidth, String scrollButtonColor,
    [String scrollBgColor]) {
  if (element == null) return null;

  scrollWidth ??= 6;
  scrollButtonColor ??= '';
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
      '__scroll_color__${scrollWidth}__${buttonColorID}__${bgColorID}';

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
List<String> removeElementScrollColors(Element element) {
  if (element == null) return null;

  element.style.removeProperty('scrollbar-width');
  element.style.removeProperty('scrollbar-color');

  var scrollClassIDs =
      element.classes.where((c) => c.startsWith('__scroll_color__'));

  if (isNotEmptyObject(scrollClassIDs)) {
    element.classes.removeAll(scrollClassIDs);
    return scrollClassIDs;
  } else {
    return null;
  }
}

/// Sets [element] background as a blur effect of size [blurSize].
/// Uses CSS property `backdrop-filter`.
void setElementBackgroundBlur(Element element, [int blurSize]) {
  if (element == null) return;

  blurSize ??= 3;
  var filter = blurSize > 0 ? 'blur(${blurSize}px)' : 'none';
  element.style.setProperty('backdrop-filter', filter);
}

/// Removes [element] background blur effect, set by [setElementBackgroundBlur].
void removeElementBackgroundBlur(Element element, [int blurSize]) {
  if (element == null) return;

  var val = element.style.getPropertyValue('backdrop-filter');
  if (val != null && val.contains('blur')) {
    element.style.removeProperty('backdrop-filter');
  }
}

const int CSS_MAX_Z_INDEX = 2147483647;

/// Returns the [element] `z-index` or [element.parent] `z-index` recursively.
String getElementZIndex(Element element, [String def]) {
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

  var cssTexts =
      rules.map((r) => r.cssText).map(parseCssRuleTextProperties).toList();
  cssTexts.removeWhere((e) => e.isEmpty);

  cssTexts.add(element.style.cssText);

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
    for (var rule in mediaRule.cssRules.whereType<CssStyleRule>()) {
      var selectors = parseCssRuleSelectors(rule);
      var selectorsFixed = selectors.map((s) => '.$targetClass $s');
      var block = rule.style.cssText;

      var selectors2 = selectorsFixed.join(' , ');
      var blocks = rulesFixed.putIfAbsent(selectors2, () => <String>[]);
      blocks.add(block);
    }
  }

  var rules2 = rulesFixed
      .map((key, value) {
        var css = value.join(' ; ');
        if (value.length > 1) {
          css = CssStyleDeclaration.css(css).cssText;
        }
        return MapEntry(key, '$key { $css }');
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
    for (var rule in mediaRule.cssRules.whereType<CssStyleRule>()) {
      var selectors = parseCssRuleSelectors(rule);
      var selectorsFixed = selectors.map((s) => '.$targetClass $s');

      var block = rule.style.cssText;
      var blockUnset =
          block.replaceAll(RegExp(r':.*?;'), ': initial !important;');

      var selectors2 = selectorsFixed.join(' , ');
      var blocks = rulesFixed.putIfAbsent(selectors2, () => <String>[]);
      blocks.add(blockUnset);
    }
  }

  var rules2 = rulesFixed
      .map((key, value) {
        var css = value.join(' ; ');
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
  var rules = getAllMediaCssRule('(?:min|max)-(?:width|height):\s*.*?');

  var viewportRules = <CssMediaRule>[];

  for (var rule in rules) {
    var conditionText =
        rule.conditionText.trim().replaceAll(RegExp(r'(?:^\(|\)$)'), '');

    var parts = split(conditionText, ':', 2);
    if (parts.length != 2) continue;

    var type = parts[0].trim().toLowerCase();
    var value = parts[1].trim().toLowerCase();

    value = value.replaceFirst(RegExp(r'px$'), '');

    if (isNum(value)) {
      var n = parseNum(value);

      if (type == 'min-width') {
        if (viewportWidth < n) {
          viewportRules.add(rule);
        }
      } else if (type == 'min-height') {
        if (viewportHeight < n) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-width') {
        if (viewportWidth > n) {
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
  var rules = getAllMediaCssRule('(?:min|max)-(?:width|height):\s*.*?');

  var viewportRules = <CssMediaRule>[];

  for (var rule in rules) {
    var conditionText =
        rule.conditionText.trim().replaceAll(RegExp(r'(?:^\(|\)$)'), '');

    var parts = split(conditionText, ':', 2);
    if (parts.length != 2) continue;

    var type = parts[0].trim().toLowerCase();
    var value = parts[1].trim().toLowerCase();

    value = value.replaceFirst(RegExp(r'px$'), '');
    if (isNum(value)) {
      var n = parseNum(value);

      if (type == 'min-width') {
        if (viewportWidth >= n) {
          viewportRules.add(rule);
        }
      } else if (type == 'min-height') {
        if (viewportHeight >= n) {
          viewportRules.add(rule);
        }
      } else if (type == 'max-width') {
        if (viewportWidth <= n) {
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
  mediaCondition ??= '';
  mediaCondition = mediaCondition.trim();

  RegExp regExp;

  if (mediaCondition != null && mediaCondition.isNotEmpty) {
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
    ...styles.map((s) => s.sheet as CssStyleSheet),
    ...links.map((s) => s.sheet as CssStyleSheet),
  ];
  return sheets;
}

List<CssRule> getAllCssRuleBySelector(
    Pattern targetSelector, CssStyleSheet sheet) {
  if (sheet == null || targetSelector == null) return [];

  if (targetSelector is String) {
    var s = targetSelector.trim().toLowerCase();
    if (s.isEmpty) return [];
    return _getAllCssRuleBySelector_String(s, sheet);
  } else if (targetSelector is RegExp) {
    return _getAllCssRuleBySelector_RegExp(targetSelector, sheet);
  } else {
    throw StateError('Invalid targetSelector: $targetSelector');
  }
}

List<CssRule> _getAllCssRuleBySelector_String(
    String targetSelector, CssStyleSheet sheet) {
  var rules = <CssRule>[];

  for (var rule in sheet.rules) {
    var selectors = parseCssRuleSelectors(rule).map((s) => s.toLowerCase());

    var firstMatch =
        selectors.firstWhere((s) => s == targetSelector, orElse: () => null);

    if (firstMatch != null) {
      rules.add(rule);
    }
  }

  return rules;
}

List<CssRule> _getAllCssRuleBySelector_RegExp(
    RegExp targetSelector, CssStyleSheet sheet) {
  var rules = <CssRule>[];

  for (var rule in sheet.rules) {
    var selectors = parseCssRuleSelectors(rule).map((s) => s.toLowerCase());

    var firstMatch = selectors.firstWhere((s) => targetSelector.hasMatch(s),
        orElse: () => null);

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
    return list;
  } else {
    return parseCssRuleTextSelectors(cssRule.cssText);
  }
}

/// Returns a list of selectors of the [CssRule] text.
List<String> parseCssRuleTextSelectors(String cssRuleText) {
  var idx = cssRuleText.indexOf('{');
  if (idx < 0) return [];
  var selectorText = cssRuleText.substring(0, idx).trim();
  var list = parseStringFromInlineList(selectorText, RegExp(r'\s*,\s*'));
  return list;
}

/// Returns a list of properties of the [CssRule] text.
String parseCssRuleTextProperties(String cssRuleText) {
  var idx1 = cssRuleText.indexOf('{');
  if (idx1 < 0) return '';
  var idx2 = cssRuleText.lastIndexOf('}');
  var properties = cssRuleText.substring(idx1 + 1, idx2).trim();
  return properties;
}
