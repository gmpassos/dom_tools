import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as dart_svg;

import 'package:swiss_knife/swiss_knife.dart';

/// Gets the [element] value depending of identified type.
///
/// If the resolved value is null or empty, and def is not null,
/// it will return [def].
String getElementValue(Element element, [String def]) {
  if (element == null) return def;

  String value;

  if (element is InputElement) {
    value = element.value;
  } else if (element is CanvasImageSource) {
    value = getElementSRC(element);
  } else if (element is CheckboxInputElement) {
    value = element.checked ? 'true' : 'false';
  } else if (element is TextAreaElement) {
    value = element.value;
  } else if (isElementWithSRC(element)) {
    value = getElementSRC(element);
  } else if (isElementWithHREF(element)) {
    value = getElementHREF(element);
  } else {
    value = element.text;
  }

  return def != null && isEmptyObject(value) ? def : value;
}

/// Sets the [element] [value] depending of the identified type.
bool setElementValue(Element element, String value) {
  if (element == null) return false;

  if (element is InputElement) {
    element.value = value;
    return true;
  } else if (element is CanvasImageSource) {
    return setElementSRC(element, value);
  } else if (element is CheckboxInputElement) {
    element.checked = parseBool(value);
    return true;
  } else if (element is TextAreaElement) {
    element.value = value;
    return true;
  } else if (isElementWithSRC(element)) {
    return setElementSRC(element, value);
  } else if (isElementWithHREF(element)) {
    return setElementHREF(element, value);
  } else {
    element.text = value;
    return true;
  }
}

/// Returns a value from an [Element].
typedef ElementValueGetter<T> = T Function(Element element);

/// selects in DOM an [Element] with [tag] and one of [values] provided by [getter].
Element getElementByValues<V>(
    String tag, ElementValueGetter getter, List<V> values) {
  if (tag == null || tag.isEmpty) return null;
  if (values == null || values.isEmpty) return null;
  values.removeWhere((v) => v == null);
  if (values.isEmpty) return null;

  var allLinks = document.querySelectorAll(tag);
  if (allLinks == null || allLinks.isEmpty) return null;

  var fond = allLinks.firstWhere((l) {
    var elemValue = getter(l);
    return values.contains(elemValue);
  }, orElse: () => null);

  return fond;
}

/// Returns `href` value for different [Element] types.
String getElementHREF(Element element) {
  if (element is LinkElement) return element.href;
  if (element is AnchorElement) return element.href;
  if (element is BaseElement) return element.href;
  if (element is AreaElement) return element.href;

  return null;
}

/// Sets [element] [href] depending of the identified type.
bool setElementHREF(Element element, String href) {
  if (element is LinkElement) {
    element.href = href;
    return true;
  } else if (element is AnchorElement) {
    element.href = href;
    return true;
  } else if (element is BaseElement) {
    element.href = href;
    return true;
  } else if (element is AreaElement) {
    element.href = href;
    return true;
  }

  return false;
}

/// Returns [true] if [element] type can have `href` attribute.
bool isElementWithHREF(Element element) {
  if (element is LinkElement) return true;
  if (element is AnchorElement) return true;
  if (element is BaseElement) return true;
  if (element is AreaElement) return true;

  return false;
}

/// Returns `src` value for different [Element] types.
String getElementSRC(Element element) {
  if (element is ImageElement) return element.src;
  if (element is ScriptElement) return element.src;
  if (element is InputElement) return element.src;

  if (element is MediaElement) return element.src;
  if (element is EmbedElement) return element.src;

  if (element is IFrameElement) return element.src;
  if (element is SourceElement) return element.src;
  if (element is TrackElement) return element.src;

  if (element is ImageButtonInputElement) return element.src;

  return null;
}

/// Sets the [element] [src] depending of the identified type.
bool setElementSRC(Element element, String src) {
  if (element == null) return false;

  if (element is ImageElement) {
    element.src = src;
    return true;
  } else if (element is ScriptElement) {
    element.src = src;
    return true;
  } else if (element is InputElement) {
    element.src = src;
    return true;
  } else if (element is MediaElement) {
    element.src = src;
    return true;
  } else if (element is EmbedElement) {
    element.src = src;
    return true;
  } else if (element is IFrameElement) {
    element.src = src;
    return true;
  } else if (element is SourceElement) {
    element.src = src;
    return true;
  } else if (element is TrackElement) {
    element.src = src;
    return true;
  } else if (element is ImageButtonInputElement) {
    element.src = src;
    return true;
  } else {
    return false;
  }
}

/// Returns [true] if [element] type can have `src` attribute.
bool isElementWithSRC(Element element) {
  if (element is ImageElement) return true;
  if (element is ScriptElement) return true;
  if (element is InputElement) return true;

  if (element is MediaElement) return true;
  if (element is EmbedElement) return true;

  if (element is IFrameElement) return true;
  if (element is SourceElement) return true;
  if (element is TrackElement) return true;

  if (element is ImageButtonInputElement) return true;

  return false;
}

/// Selects an [Element] in DOM with [tag] and [href].
Element getElementByHREF(String tag, String href) {
  if (href == null || href.isEmpty) return null;
  var resolvedURL = resolveUri(href).toString();
  return getElementByValues(tag, getElementHREF, [href, resolvedURL]);
}

/// Selects an [Element] in DOM with [tag] and [src].
Element getElementBySRC(String tag, String src) {
  if (src == null || src.isEmpty) return null;

  var values = [src];

  if (!src.startsWith('data:')) {
    var resolvedURL = resolveUri(src).toString();
    values.add(resolvedURL);
  }

  return getElementByValues(tag, getElementSRC, values);
}

/// Selects an [AnchorElement] in DOM with [href].
AnchorElement getAnchorElementByHREF(String href) {
  return getElementByHREF('a', href);
}

/// Selects an [LinkElement] in DOM with [href].
LinkElement getLinkElementByHREF(String href) {
  return getElementByHREF('link', href);
}

/// Selects an [ScriptElement] in DOM with [src].
ScriptElement getScriptElementBySRC(String src) {
  return getElementBySRC('script', src);
}

/// Returns a [Future<bool>] for when [img] loads.
Future<bool> elementOnLoad(ImageElement img) {
  var completer = Completer<bool>();
  img.onLoad.listen((e) => completer.complete(true),
      onError: (e) => completer.complete(false));
  return completer.future;
}

/// Creates a `div` with `display: inline-block`.
DivElement createDivInlineBlock() =>
    DivElement()..style.display = 'inline-block';

/// Creates a `div`.
/// [inline] If [true] sets `display: inline-block`.
/// [html] The HTML to parse as content.
DivElement createDiv(
    [bool inline = false, String html, NodeValidator validator]) {
  var div = DivElement();

  if (inline) div.style.display = 'inline-block';

  if (html != null) {
    setElementInnerHTML(div, html, validator: validator);
  }

  return div;
}

/// Creates a `div` with `display: inline-block`.
///
/// [html] The HTML to parse as content.
DivElement createDivInline([String html]) {
  return createDiv(true, html);
}

/// Creates a `span` element.
///
/// [html] The HTML to parse as content.
SpanElement createSpan([String html, NodeValidator validator]) {
  var span = SpanElement();

  if (html != null) {
    setElementInnerHTML(span, html, validator: validator);
  }

  return span;
}

/// Creates a `label` element.
///
/// [html] The HTML to parse as content.
LabelElement createLabel([String html, NodeValidator validator]) {
  var label = LabelElement();

  if (html != null) {
    setElementInnerHTML(label, html, validator: validator);
  }

  return label;
}

/// Returns the [node] tag name.
/// Returns null if [node] is not an [Element].
String getElementTagName(Node node) =>
    node != null && node is Element ? node.tagName.toLowerCase() : null;

final RegExp _REGEXP_DEPENDENT_TAG =
    RegExp(r'^\s*<(tbody|thread|tfoot|tr|td|th)\W', multiLine: false);

/// Creates a HTML [Element]. Returns 1st node form parsed HTML.
Element createHTML([String html, NodeValidator validator]) {
  var dependentTagMatch = _REGEXP_DEPENDENT_TAG.firstMatch(html);

  if (dependentTagMatch != null) {
    var dependentTagName = dependentTagMatch.group(1).toLowerCase();

    DivElement div;
    if (dependentTagName == 'td' || dependentTagName == 'th') {
      div = createDiv(true, '<table><tbody><tr>\n$html\n</tr></tbody></table>');
    } else if (dependentTagName == 'tr') {
      div = createDiv(true, '<table><tbody>\n$html\n</tbody></table>');
    } else if (dependentTagName == 'tbody' ||
        dependentTagName == 'thead' ||
        dependentTagName == 'tfoot') {
      div = createDiv(true, '<table>\n$html\n</table>');
    } else {
      throw StateError("Can't handle dependent tag: $dependentTagName");
    }

    var childNode = div.querySelector(dependentTagName);
    return childNode;
  } else {
    var div = createDiv(true, html, validator);
    if (div.nodes.isEmpty) return div;

    var childNode =
        div.nodes.firstWhere((e) => e is Element, orElse: () => null);

    if (childNode != null) {
      return childNode;
    }

    var span = SpanElement();
    span.nodes.addAll(div.nodes);
    return span;
  }
}

const _HTML_BASIC_ATTRS = [
  'style',
  'capture',
  'type',
  'src',
  'href',
  'target',
  'contenteditable',
  'xmlns'
];

const _HTML_CONTROL_ATTRS = [
  'data-toggle',
  'data-target',
  'data-dismiss',
  'data-source',
  'aria-controls',
  'aria-expanded',
  'aria-label',
  'aria-current',
  'aria-hidden',
  'role',
];

const _HTML_EXTENDED_ATTRS = [
  'field',
  'field_value',
  'element_value',
  'src-original',
  'href-original',
  'navigate',
  'action',
  'uilayout',
  'oneventkeypress',
  'oneventclick'
];

const _HTML_ELEMENTS_ALLOWED_ATTRS = [
  ..._HTML_BASIC_ATTRS,
  ..._HTML_CONTROL_ATTRS,
  ..._HTML_EXTENDED_ATTRS
];

AnyUriPolicy _anyUriPolicy = AnyUriPolicy();

/// Allows anu [Uri] policy.
class AnyUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true;
  }
}

class _FullSvgNodeValidator implements NodeValidator {
  @override
  bool allowsElement(Element element) {
    if (element is dart_svg.ScriptElement) {
      return false;
    }
    if (element is dart_svg.SvgElement) {
      return true;
    }
    return false;
  }

  @override
  bool allowsAttribute(Element element, String attributeName, String value) {
    if (attributeName == 'is' || attributeName.startsWith('on')) {
      return false;
    }
    return allowsElement(element);
  }
}

NodeValidatorBuilder createStandardNodeValidator(
    {bool svg = true, bool allowSvgForeignObject = false}) {
  var validator = NodeValidatorBuilder()
    ..allowTextElements()
    ..allowHtml5()
    ..allowElement('a', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('nav', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('div', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('li', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('ul', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('ol', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('span', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('img', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('textarea', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('input', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('label', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('button', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('iframe', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowElement('svg', attributes: _HTML_ELEMENTS_ALLOWED_ATTRS)
    ..allowImages(_anyUriPolicy)
    ..allowNavigation(_anyUriPolicy)
    ..allowInlineStyles();

  if (svg ?? true) {
    if (allowSvgForeignObject ?? false) {
      validator.add(_FullSvgNodeValidator());
    } else {
      validator.allowSvg();
    }
  }

  return validator;
}

NodeValidatorBuilder _defaultNodeValidator = createStandardNodeValidator();

/// Sets the inner HTML of [element] with parsed result of [html].
void setElementInnerHTML(Element element, String html,
    {NodeValidator validator}) {
  validator ??= _defaultNodeValidator;
  element.setInnerHtml(html, validator: validator);
}

/// Appends to the inner HTML of [element] with parsed result of [html].
void appendElementInnerHTML(Element element, String html,
    {NodeValidator validator}) {
  validator ??= _defaultNodeValidator;
  element.appendHtml(html, validator: validator);
}

/// Transform [html] to plain text.
String htmlToText(String html, [NodeValidator validator]) {
  var elem = createHTML('<div>$html</div>', validator);
  return elem.text;
}

/// Scrolls viewport to the top with a delay.
///
/// [delayMs] Delay in milliseconds.
void scrollToTopDelayed(int delayMs) {
  if (delayMs < 1) {
    scrollToTop();
  } else {
    Future.delayed(Duration(milliseconds: delayMs), scrollToTop);
  }
}

/// Scrolls viewport to the top.
void scrollToTop() {
  window.scrollTo(window.scrollX, 0, {'behavior': 'smooth'});
}

/// Scrolls viewport to the bottom.
void scrollToBottom() {
  window.scrollTo(
      window.scrollX, document.body.scrollHeight, {'behavior': 'smooth'});
}

/// Scrolls viewport to the left border.
void scrollToLeft() {
  window.scrollTo(0, window.scrollY, {'behavior': 'smooth'});
}

/// Scrolls viewport to the right border.
void scrollToRight() {
  window.scrollTo(
      document.body.scrollWidth, window.scrollY, {'behavior': 'smooth'});
}

/// Resets viewport zoom.
void resetZoom() {
  _resetZoomImpl(0);
}

bool _resettingZoom = false;

bool _resettingViewportScale = false;

void _resetZoomImpl(int retry) {
  if (_resettingZoom || _resettingViewportScale) {
    if (retry < 100) {
      Future.delayed(Duration(milliseconds: 10), () => _resetZoomImpl(retry++));
    }
    return;
  }

  if (!_resettingZoom) {
    _resettingZoom = true;

    var prev = document.body.style.zoom;
    setZoom('normal');

    Future.delayed(Duration(milliseconds: 10), () {
      setZoom(prev);
      _resettingZoom = false;
    });
  }

  if (!_resettingViewportScale) {
    _resettingViewportScale = true;

    var metaViewportList = getMetaTagsWithName('viewport');

    if (metaViewportList.isNotEmpty) {
      var metaViewport = metaViewportList[0];
      var content = metaViewport.getAttribute('content');

      setMetaViewportScale(minimumScale: '*', maximumScale: '*');

      Future.delayed(Duration(milliseconds: 10), () {
        metaViewport.setAttribute('content', content);
        _resettingViewportScale = false;
      });
    }
  }
}

/// Sets the viewport [zoom].
void setZoom(String zoom) {
  document.body.style.zoom = zoom;
}

/// Sets the `meta` viewport with [minimumScale] and [maximumScale].
bool setMetaViewportScale({String minimumScale, String maximumScale}) {
  if (minimumScale == null && maximumScale == null) return false;

  var metaViewportList = getMetaTagsWithName('viewport');
  if (metaViewportList.isEmpty) return false;

  var metaViewport = metaViewportList[0];

  var content = metaViewport.getAttribute('content');
  var params = parseMetaContent(content);

  var defaultScale = params['initial-scale'] ?? '1.0';

  var changed = false;

  if (maximumScale != null) {
    minimumScale = minimumScale.trim();
    if (minimumScale.isEmpty || minimumScale == '*') {
      minimumScale = defaultScale;
    }

    params['minimum-scale'] = minimumScale;
    changed = true;
  }

  if (maximumScale != null) {
    maximumScale = maximumScale.trim();
    if (maximumScale.isEmpty || maximumScale == '*') {
      maximumScale = defaultScale;
    }

    params['maximum-scale'] = maximumScale;
    changed = true;
  }

  if (changed) {
    var content2 = buildMetaContent(params);
    metaViewport.setAttribute('content', content2);
    return true;
  }

  return false;
}

/// Parses a `meta` content to [Map<String,String>].
Map<String, String> parseMetaContent(String content) {
  var parts = content.split(RegExp(r'\s*,\s*'));

  // ignore: omit_local_variable_types
  Map<String, String> map = {};

  for (var p in parts) {
    var pair = split(p, '=', 2);

    if (pair.length == 1) {
      map[p] = null;
    } else {
      var key = pair[0].trim();
      var val = pair[1].trim();
      map[key] = val;
    }
  }

  return map;
}

/// Builds a `meta` content from [map].
String buildMetaContent(Map<String, String> map) {
  var content = '';

  for (var entry in map.entries) {
    var key = entry.key;
    var val = entry.value;

    if (content.isNotEmpty) {
      content += ', ';
    }

    if (val == null) {
      content += key;
    } else {
      content += '$key=$val';
    }
  }

  return content;
}

/// Returns [element] attribute with [key].
///
/// [key] Can be a [RegExp] or a [String].
String getElementAttribute(Element element, dynamic key) {
  if (element == null || key == null) return null;

  if (key is RegExp) {
    return getElementAttributeRegExp(element, key);
  } else {
    return getElementAttributeStr(element, key.toString());
  }
}

/// Returns [element] attribute with [RegExp] [key].
String getElementAttributeRegExp(Element element, RegExp key) {
  if (element == null || key == null) return null;

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if (key.hasMatch(k)) {
      return attrs[k];
    }
  }

  return null;
}

/// Returns [element] attribute with [String] [key].
String getElementAttributeStr(Element element, String key) {
  if (element == null || key == null) return null;

  var val = element.getAttribute(key);
  if (val != null) return val;

  key = key.trim();
  key = key.toLowerCase();

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if (k.toLowerCase() == key) {
      return attrs[k];
    }
  }

  return null;
}

/// Clears selected text in vieport.
void clearSelections() {
  var selection = window.getSelection();

  if (selection != null) {
    selection.removeAllRanges();
  }
}

/// Converts [element] to HTML.
String toHTML(Element element) {
  return _toHTML_any(element);
}

String _toHTML_any(Element e) {
  var html = '';

  html += '<';
  html += e.tagName;

  for (var attr in e.attributes.keys) {
    var val = e.attributes[attr];
    if (val != null) {
      if (val.contains("'")) {
        html += ' attr=\"$val\"';
      } else {
        html += " attr='$val'";
      }
    } else {
      html += ' attr';
    }
  }

  html += '>';

  if (e.innerHtml != null && e.innerHtml.isNotEmpty) {
    if (e is SelectElement) {
      html += _toHTML_innerHtml_Select(e);
    } else {
      html += e.innerHtml;
    }
  }

  html += '</${e.tagName}>';

  return html;
}

String _toHTML_innerHtml_Select(SelectElement e) {
  var html = '';

  for (var o in e.options) {
    html +=
        "<option value='${o.value}' ${o.selected ? ' selected' : ''}>${o.label}</option>";
  }

  return html;
}

typedef FunctionTest = bool Function();

/// Returns [true] if [element] is visible in viewport.
bool isInViewport(Element element) {
  var rect = element.getBoundingClientRect();

  var windowWidth =
      min(window.innerWidth, document.documentElement.clientWidth);
  var windowHeight =
      min(window.innerHeight, document.documentElement.clientHeight);

  return rect.bottom > 0 &&
      rect.right > 0 &&
      rect.left < windowWidth &&
      rect.top < windowHeight;
}

/// Returns [true] if device orientation is in Portrait mode.
bool isOrientationInPortraitMode() {
  return !isOrientationInLandscapeMode();
}

/// Returns [true] if device orientation is in Landscape mode.
bool isOrientationInLandscapeMode() {
  var orientation = window.orientation;
  if (orientation == null) return false;

  if (orientation == 90 || orientation == -90) {
    return true;
  } else {
    return false;
  }
}

/// Attaches [listener] to `orientationchange` event.
bool onOrientationchange(EventListener listener) {
  try {
    window.addEventListener('orientationchange', listener);
    return true;
  } catch (e, s) {
    print(e);
    print(s);
    return false;
  }
}

/// Returns [true] if [node] is in DOM tree.
bool isNodeInDOM(Node node) {
  return document.body.contains(node);
}

/// Returns [true] if [element] is in DOM tree.
///
/// [element] Can be a [Node] or a [List] of [Node].
bool isInDOM(dynamic element) {
  if (element == null) return false;

  if (element is Node) {
    return document.body.contains(element);
  } else if (element is List) {
    for (var elem in element) {
      var inDom = isInDOM(elem);
      if (inDom) return true;
    }
    return false;
  }

  return false;
}

/// Returns [true] if [rootNode] contains [target].
bool nodeTreeContains(Node rootNode, Node target) {
  return nodeTreeContainsAny(rootNode, [target]);
}

/// Returns [true] if [rootNode] contains any [Node] in [list].
bool nodeTreeContainsAny(Node rootNode, Iterable<Node> list) {
  if (list == null || list.isEmpty) return false;
  return list.firstWhere((e) => e == rootNode || rootNode.contains(e),
          orElse: () => null) !=
      null;
}

/// Defines a new [CssStyleDeclaration] merging [currentCSS] and [appendCSS].
///
/// [defaultCSS] if [currentCSS] and [appendCSS] are [null].
CssStyleDeclaration defineCSS(
    CssStyleDeclaration currentCSS, CssStyleDeclaration appendCSS,
    [dynamic defaultCSS]) {
  if (currentCSS == null) {
    return appendCSS ?? asCssStyleDeclaration(defaultCSS);
  } else if (appendCSS == null) {
    return currentCSS ?? asCssStyleDeclaration(defaultCSS);
  } else {
    return CssStyleDeclaration()
      ..cssText = currentCSS.cssText + ' ; ' + appendCSS.cssText;
  }
}

/// Parses dynamic [css] as [CssStyleDeclaration].
CssStyleDeclaration asCssStyleDeclaration(dynamic css) {
  if (css == null) return CssStyleDeclaration();
  if (css is CssStyleDeclaration) return css;
  if (css is String) return CssStyleDeclaration()..cssText = css;
  if (css is Function) return asCssStyleDeclaration(css());

  throw StateError("Can't convert to CSS: $css");
}

/// Returns [true] if [CssStyleDeclaration] is empty.
bool isCssEmpty(CssStyleDeclaration css) {
  if (css == null) return true;
  var cssText = css.cssText;
  return cssText == null || cssText.trim().isEmpty;
}

/// Returns [true] if [CssStyleDeclaration] is not empty.
bool isCssNotEmpty(CssStyleDeclaration css) {
  return !isCssEmpty(css);
}

/// Applies [css] to [element] and [extraElements] list if present.
bool applyCSS(CssStyleDeclaration css, Element element,
    [List<Element> extraElements]) {
  if (!isCssNotEmpty(css)) return false;

  var apply = _applyCSS(css, element);

  if (extraElements != null) {
    for (var elem in extraElements) {
      var ok = _applyCSS(css, elem);
      apply |= ok;
    }
  }

  return apply;
}

bool _applyCSS(CssStyleDeclaration css, Element element) {
  if (element != null) {
    var newCss = element.style.cssText + ' ; ' + css.cssText;
    element.style.cssText = newCss;
    return true;
  }
  return false;
}

/// Returns [true] if [element] matches [attributes].
bool elementMatchesAttributes(
    Element element, Map<String, dynamic> attributes) {
  for (var entry in attributes.entries) {
    if (!elementMatchesAttribute(element, entry.key, entry.value)) {
      return false;
    }
  }
  return true;
}

typedef MatchesValue = bool Function(String value);

/// Returns [true] if [element] matches [attributeName] and [attributeValue].
bool elementMatchesAttribute(
    Element element, String attributeName, dynamic attributeValue) {
  var value = element.getAttribute(attributeName);
  if (value == attributeValue) return true;
  if (value == null || attributeValue == null) return false;

  if (attributeValue is String) {
    return value.trim() == attributeValue.trim();
  } else if (attributeValue is RegExp) {
    return attributeValue.hasMatch(value);
  } else if (attributeValue is MatchesValue) {
    return attributeValue(value);
  }

  return false;
}

/// Selects elements from DOM with [tag] and matches attribute.
///
/// [tag] Type of tag for selection.
/// [matchAttributes] Attributes to match in selection.
List<Element> getElementsWithAttributes(
    String tag, Map<String, dynamic> matchAttributes) {
  var tags = (document.getElementsByTagName(tag) ?? []).whereType<Element>();
  return tags
      .where((e) => elementMatchesAttributes(e, matchAttributes))
      .toList();
}

/// Returns a list of `meta` [Element] with [name].
List<Element> getMetaTagsWithName(String name) {
  return getElementsWithAttributes('meta', {'name': name}) ?? [];
}

/// Returns a list of `meta` contet with [name].
List<String> getMetaTagsContentWithName(String name) {
  var tags = getMetaTagsWithName(name);
  if (tags == null || tags.isEmpty) return [];
  return tags.map((e) => e.getAttribute('content')).toList();
}

/// Returns [true] if `meta` tag of name `apple-mobile-web-app-status-bar-style`
/// is `translucent`.
bool isMobileAppStatusBarTranslucent() {
  var metaTagsContents =
      getMetaTagsContentWithName('apple-mobile-web-app-status-bar-style');
  if (metaTagsContents == null || metaTagsContents.isEmpty) return false;
  var metaStatusContent = metaTagsContents[0];
  return metaStatusContent.contains('translucent');
}
