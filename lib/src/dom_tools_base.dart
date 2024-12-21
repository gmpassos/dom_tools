import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:svg' as dart_svg;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:dom_tools/src/dom_tools_css.dart';
import 'package:swiss_knife/swiss_knife.dart';

/// Gets the [element] value depending of identified type.
///
/// If the resolved value is null or empty, and def is not null,
/// it will return [def].
String? getElementValue(Element element, [String? def]) {
  String? value;

  if (element is InputElement) {
    value = element.value;
  } else if (element is CanvasImageSource) {
    value = getElementSRC(element);
  } else if (element is CheckboxInputElement) {
    value = element.checked! ? 'true' : 'false';
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
bool setElementValue(Element? element, String value) {
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
typedef ElementValueGetter<T> = T? Function(Element element);

/// selects in DOM an [Element] with [tag] and one of [values] provided by [getter].
Element? getElementByValues<V>(
    String tag, ElementValueGetter getter, List<V> values,
    [ElementValueGetter? getter2, List<V>? values2]) {
  if (tag.isEmpty) return null;
  if (values.isEmpty) return null;

  var allLinks = document.querySelectorAll(tag);
  if (allLinks.isEmpty) return null;

  if (getter2 != null) {
    if (values2 == null || values2.isEmpty) return null;

    var fond = allLinks.firstWhereOrNull((l) {
      var elemValue = getter(l);
      var ok = values.contains(elemValue);
      if (!ok) return false;
      var elemValue2 = getter2(l);
      var ok2 = values2.contains(elemValue2);
      return ok2;
    });
    return fond;
  } else {
    var fond = allLinks.firstWhereOrNull((l) {
      var elemValue = getter(l);
      return values.contains(elemValue);
    });

    return fond;
  }
}

/// Returns `href` value for different [Element] types.
String? getElementHREF(Element element) {
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
    // ignore: unsafe_html
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
String? getElementSRC(Element element) {
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
  if (element is ImageElement) {
    // ignore: unsafe_html
    element.src = src;
    return true;
  } else if (element is ScriptElement) {
    // ignore: unsafe_html
    element.src = src;
    return true;
  } else if (element is InputElement) {
    element.src = src;
    return true;
  } else if (element is MediaElement) {
    element.src = src;
    return true;
  } else if (element is EmbedElement) {
    // ignore: unsafe_html
    element.src = src;
    return true;
  } else if (element is IFrameElement) {
    // ignore: unsafe_html
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
Element? getElementByHREF(String tag, String href) {
  if (href.isEmpty) return null;
  var resolvedURL = resolveUri(href).toString();
  return getElementByValues(tag, getElementHREF, [href, resolvedURL]);
}

/// Selects an [Element] in DOM with [tag] and [src].
Element? getElementBySRC(String tag, String src) {
  if (src.isEmpty) return null;

  var values = [src];

  if (!src.startsWith('data:')) {
    var resolvedURL = resolveUri(src).toString();
    values.add(resolvedURL);
  }

  return getElementByValues(tag, getElementSRC, values);
}

/// Selects an [AnchorElement] in DOM with [href].
AnchorElement? getAnchorElementByHREF(String href) {
  return getElementByHREF('a', href) as AnchorElement?;
}

/// Selects an [LinkElement] in DOM with [href].
LinkElement? getLinkElementByHREF(String href, [String? rel]) {
  if (href.isEmpty) return null;

  if (isNotEmptyString(rel)) {
    var resolvedURL = resolveUri(href).toString();
    return getElementByValues('link', getElementHREF, [href, resolvedURL],
        (e) => e.getAttribute('rel'), [rel]) as LinkElement?;
  } else {
    return getElementByHREF('link', href) as LinkElement?;
  }
}

/// Selects an [ScriptElement] in DOM with [src].
ScriptElement? getScriptElementBySRC(String src) {
  return getElementBySRC('script', src) as ScriptElement?;
}

/// Returns [element] width. Tries to use 'offsetWidth' or 'style.width' values.
///
/// [def] default value if width is `null` or `0`.
int? getElementWidth(Element element, [int? def]) {
  var w = element.offsetWidth;
  if (w <= 0) {
    w = parseCSSLength(element.style.width, unit: 'px', def: def ?? 0) as int;
  }
  return w <= 0 ? def : w;
}

/// Returns [element] height. Tries to use 'offsetHeight' or 'style.height' values.
///
/// [def] default value if width is `null` or `0`.
int? getElementHeight(Element element, [int? def]) {
  var h = element.offsetHeight;
  if (h <= 0) {
    h = parseCSSLength(element.style.height, unit: 'px', def: def ?? 0) as int;
  }
  return h <= 0 ? def : h;
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
    [bool inline = false, String? html, NodeValidator? validator]) {
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
DivElement createDivInline([String? html]) {
  return createDiv(true, html);
}

/// Creates a `span` element.
///
/// [html] The HTML to parse as content.
SpanElement createSpan([String? html, NodeValidator? validator]) {
  var span = SpanElement();

  if (html != null) {
    setElementInnerHTML(span, html, validator: validator);
  }

  return span;
}

/// Creates a `label` element.
///
/// [html] The HTML to parse as content.
LabelElement createLabel([String? html, NodeValidator? validator]) {
  var label = LabelElement();

  if (html != null) {
    setElementInnerHTML(label, html, validator: validator);
  }

  return label;
}

/// Returns the [node] tag name.
/// Returns null if [node] is not an [Element].
String? getElementTagName(Node node) =>
    node is Element ? node.tagName.toLowerCase() : null;

final RegExp _regexpDependentTag =
    RegExp(r'^\s*<(tbody|thread|tfoot|tr|td|th)\W', multiLine: false);

/// Creates a HTML [Element]. Returns 1st node form parsed HTML.
Element createHTML([String? html, NodeValidator? validator]) {
  if (html == null || html.isEmpty) return SpanElement();

  var dependentTagMatch = _regexpDependentTag.firstMatch(html);

  if (dependentTagMatch != null) {
    var dependentTagName = dependentTagMatch.group(1)!.toLowerCase();

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
    return childNode!;
  } else {
    var div = createDiv(true, html, validator);
    if (div.nodes.isEmpty) return div;

    var childNode = div.nodes.firstWhereOrNull((e) => e is Element);

    if (childNode is Element) {
      return childNode;
    }

    var span = SpanElement();
    span.nodes.addAll(div.nodes);
    return span;
  }
}

const _htmlBasicAttrs = [
  'style',
  'capture',
  'type',
  'src',
  'href',
  'target',
  'contenteditable',
  'xmlns'
];

const _htmlControlAttrs = [
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

const _htmlExtendedAttrs = [
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

const _htmlElementsAllowedAttrs = [
  ..._htmlBasicAttrs,
  ..._htmlControlAttrs,
  ..._htmlExtendedAttrs
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
    ..allowElement('a', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('nav', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('div', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('li', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('ul', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('ol', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('span', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('img', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('textarea', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('input', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('label', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('button', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('iframe', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('svg', attributes: _htmlElementsAllowedAttrs)
    ..allowElement('video', attributes: [
      ..._htmlElementsAllowedAttrs,
      'autoplay',
      'controls',
      'muted'
    ])
    ..allowElement('source', attributes: [..._htmlElementsAllowedAttrs, 'type'])
    ..allowImages(_anyUriPolicy)
    ..allowNavigation(_anyUriPolicy)
    ..allowInlineStyles();

  if (svg) {
    if (allowSvgForeignObject) {
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
    {NodeValidator? validator}) {
  validator ??= _defaultNodeValidator;
  // ignore: unsafe_html
  element.setInnerHtml(html, validator: validator);
}

/// Appends to the inner HTML of [element] with parsed result of [html].
void appendElementInnerHTML(Element element, String html,
    {NodeValidator? validator}) {
  validator ??= _defaultNodeValidator;
  element.appendHtml(html, validator: validator);
}

/// Transform [html] to plain text.
String? htmlToText(String html, [NodeValidator? validator]) {
  var elem = createHTML('<div>$html</div>', validator);
  return elem.text;
}

/// Returns the X and Y position of [Element] int the [Document].
Pair<num> getElementDocumentPosition(Element element) {
  var obj = getVisibleNode(element);

  num top = obj!.offsetTop;
  num left = obj.offsetLeft;

  if (obj.offsetParent != null) {
    do {
      top += obj!.offsetTop;
      left += obj.offsetLeft;
    } while ((obj = obj.offsetParent) != null);
  }

  return Pair<num>(left, top);
}

/// Get the first visible element in the hierarchy.
Element? getVisibleNode(Element? element) {
  while (element!.hidden || element.style.display == 'none') {
    var parent = element.parent;
    if (parent != null) {
      element = parent;
    } else {
      break;
    }
  }
  return element;
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

    var prev = document.body!.style.zoom;
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
        metaViewport.setAttribute('content', content!);
        _resettingViewportScale = false;
      });
    }
  }
}

/// Sets the viewport [zoom].
void setZoom(String zoom) {
  document.body!.style.zoom = zoom;
}

/// Sets the `meta` viewport with [minimumScale] and [maximumScale].
bool setMetaViewportScale({String? minimumScale, String? maximumScale}) {
  if (minimumScale == null && maximumScale == null) return false;

  var metaViewportList = getMetaTagsWithName('viewport');
  if (metaViewportList.isEmpty) return false;

  var metaViewport = metaViewportList[0];

  var content = metaViewport.getAttribute('content')!;
  var params = parseMetaContent(content);

  var defaultScale = params['initial-scale'] ?? '1.0';

  var changed = false;

  if (maximumScale != null) {
    minimumScale = minimumScale!.trim();
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
Map<String, String?> parseMetaContent(String content) {
  var parts = content.split(RegExp(r'\s*,\s*'));

  // ignore: omit_local_variable_types
  Map<String, String?> map = {};

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
String buildMetaContent(Map<String, String?> map) {
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
String? getElementAttribute(Element element, Object? key) {
  if (key == null) return null;

  if (key is RegExp) {
    return getElementAttributeRegExp(element, key);
  } else {
    return getElementAttributeStr(element, key.toString());
  }
}

/// Returns [element] attribute with [RegExp] [key].
String? getElementAttributeRegExp(Element element, RegExp key) {
  for (var k in element.getAttributeNames()) {
    if (key.hasMatch(k)) {
      return element.getAttribute(k);
    }
  }

  return null;
}

/// Returns [element] attribute with [String] [key].
String? getElementAttributeStr(Element element, String key) {
  var val = element.getAttribute(key);
  if (val != null) return val;

  key = key.trim().toLowerCase();

  for (var k in element.getAttributeNames()) {
    if (k.toLowerCase() == key) {
      return element.getAttribute(k);
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
  return _toHTMLAny(element);
}

String _toHTMLAny(Element e) {
  var html = '';

  html += '<';
  html += e.tagName;

  for (var attr in e.getAttributeNames()) {
    var val = e.getAttribute(attr);
    if (val != null) {
      if (val.contains("'")) {
        html += ' attr="$val"';
      } else {
        html += " attr='$val'";
      }
    } else {
      html += ' attr';
    }
  }

  html += '>';

  if (e.innerHtml != null && e.innerHtml!.isNotEmpty) {
    if (e is SelectElement) {
      html += _toHTMLInnerHtmlSelect(e);
    } else {
      html += e.innerHtml!;
    }
  }

  html += '</${e.tagName}>';

  return html;
}

String _toHTMLInnerHtmlSelect(SelectElement e) {
  var html = '';

  for (var o in e.options) {
    html +=
        "<option value='${o.value}' ${o.selected ? ' selected' : ''}>${o.label}</option>";
  }

  return html;
}

typedef FunctionTest = bool Function();

/// Returns [true] if [element] is visible in viewport.
bool isInViewport(Element element, {bool fully = false}) {
  var rect = element.getBoundingClientRect();

  var windowWidth =
      min(window.innerWidth!, document.documentElement!.clientWidth);
  var windowHeight =
      min(window.innerHeight!, document.documentElement!.clientHeight);

  if (fully) {
    return rect.left >= 0 &&
        rect.top >= 0 &&
        rect.right < windowWidth &&
        rect.bottom < windowHeight;
  } else {
    return rect.bottom > 0 &&
        rect.right > 0 &&
        rect.left < windowWidth &&
        rect.top < windowHeight;
  }
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
  return document.body!.contains(node);
}

/// Returns [true] if [element] is in DOM tree.
///
/// [element] Can be a [Node] or a [List] of [Node].
bool isInDOM(dynamic element) {
  if (element == null) return false;

  if (element is Node) {
    return document.body!.contains(element);
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
  if (list.isEmpty) return false;
  return list.firstWhereOrNull((e) => e == rootNode || rootNode.contains(e)) !=
      null;
}

/// Defines a new [CssStyleDeclaration] merging [currentCSS] and [appendCSS].
///
/// [defaultCSS] if [currentCSS] and [appendCSS] are [null].
CssStyleDeclaration defineCSS(
    CssStyleDeclaration? currentCSS, CssStyleDeclaration? appendCSS,
    [dynamic defaultCSS]) {
  if (currentCSS == null) {
    return appendCSS ?? asCssStyleDeclaration(defaultCSS);
  } else if (appendCSS == null) {
    return currentCSS;
  } else {
    return CssStyleDeclaration()
      ..cssText = '${currentCSS.cssText!} ; ${appendCSS.cssText!}';
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
  var cssText = css.cssText;
  return cssText == null || cssText.trim().isEmpty;
}

/// Returns [true] if [CssStyleDeclaration] is not empty.
bool isCssNotEmpty(CssStyleDeclaration css) {
  return !isCssEmpty(css);
}

/// Applies [css] to [element] and [extraElements] list if present.
bool applyCSS(CssStyleDeclaration css, Element element,
    [List<Element>? extraElements]) {
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
  var newCss = '${element.style.cssText!} ; ${css.cssText!}';
  element.style.cssText = newCss;
  return true;
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
  var tags = (document.getElementsByTagName(tag)).whereType<Element>();
  return tags
      .where((e) => elementMatchesAttributes(e, matchAttributes))
      .toList();
}

/// Returns a list of `meta` [Element] with [name].
List<Element> getMetaTagsWithName(String name) {
  return getElementsWithAttributes('meta', {'name': name});
}

/// Returns a list of `meta` contet with [name].
List<String?> getMetaTagsContentWithName(String name) {
  var tags = getMetaTagsWithName(name);
  if (tags.isEmpty) return [];
  return tags.map((e) => e.getAttribute('content')).toList();
}

/// Returns [true] if `meta` tag of name `apple-mobile-web-app-status-bar-style`
/// is `translucent`.
bool isMobileAppStatusBarTranslucent() {
  var metaTagsContents =
      getMetaTagsContentWithName('apple-mobile-web-app-status-bar-style');
  if (metaTagsContents.isEmpty) return false;
  var metaStatusContent = metaTagsContents[0]!;
  return metaStatusContent.contains('translucent');
}

/// Copies [element] text to Clipboard.
bool copyElementToClipboard(Element element) {
  var selection = window.getSelection();
  // Selection not supported or blocked:
  if (selection == null) return false;

  var range = document.createRange();
  range.selectNodeContents(element);

  selection.removeAllRanges();
  selection.addRange(range);

  document.execCommand('copy');

  window.getSelection()?.removeAllRanges();
  return true;
}

/// Set all [element] sub div with [className] to centered content.
void setTreeElementsDivCentered(Element element, String className,
    {bool centerVertically = true, bool centerHorizontally = true}) {
  if (isEmptyString(className, trim: true)) return;

  var elements = element.querySelectorAll('div.$className');

  for (var e in elements) {
    if (e is DivElement) {
      setDivCentered(e,
          centerVertically: centerVertically,
          centerHorizontally: centerHorizontally);
    }
  }
}

const _divCenteredBootstrapConflictingClasses = <String>{
  'd-none',
  'd-inline',
  'd-inline-block',
  'd-block',
  'd-table',
  'd-table-cell',
  'd-table-row',
  'd-flex',
  'd-inline-flex',
};

/// Sets [div] as centered content, using `display` property as `table` and sub
/// div elements `display` property as `table-cell`.
void setDivCentered(DivElement div,
    {bool centerVertically = true,
    bool centerHorizontally = true,
    bool checkBootstrapClasses = true}) {
  div.style.display =
      isInlineElement(div, checkBootstrapClasses: checkBootstrapClasses)
          ? 'inline-table'
          : 'table';

  div.classes.removeAll(_divCenteredBootstrapConflictingClasses);

  var subDivs = div.querySelectorAll(':scope > div');

  for (var subDiv in subDivs) {
    print(subDiv.outerHtml);

    subDiv.classes.removeAll(_divCenteredBootstrapConflictingClasses);
    subDiv.style.display = 'table-cell';

    if (centerHorizontally) {
      subDiv.style.textAlign = 'center';
    }

    if (centerVertically) {
      subDiv.style.verticalAlign = 'middle';
    }

    var contentDivs = subDiv.querySelectorAll(':scope > div');

    for (var contentDiv in contentDivs) {
      if (!isInlineElement(contentDiv as DivElement,
          checkBootstrapClasses: checkBootstrapClasses)) {
        contentDiv.style.display = 'inline-block';
      }
    }
  }
}

/// Returns [true] if [element] `display` property is inline.
bool isInlineElement(DivElement element, {bool checkBootstrapClasses = true}) {
  if (element.style.display.toLowerCase().contains('inline')) return true;

  if (checkBootstrapClasses) {
    return element.classes.contains('d-inline') ||
        element.classes.contains('d-inline-block') ||
        element.classes.contains('d-inline-flex');
  }

  return false;
}

Map<String, Future<bool>> _prefetchedHref = {};

/// Prefetch a HREF using a `link` element into `head` DOM node.
///
/// [href] The path to the CSS source file.
/// [insertIndex] optional index of insertion inside `head` node.
Future<bool> prefetchHref(String href,
    {int? insertIndex, bool? preLoad}) async {
  var rel = 'prefetch';

  if (preLoad ?? false) {
    rel = 'preload';
  }

  var linkInDom = getLinkElementByHREF(href, rel);

  var prevCall = _prefetchedHref[href];

  if (prevCall != null) {
    if (linkInDom != null) {
      return prevCall;
    } else {
      var removed = _prefetchedHref.remove(href);
      assert(removed != null);
    }
  }

  if (linkInDom != null) {
    return true;
  }

  var head = querySelector('head') as HeadElement?;

  var script = LinkElement()
    ..rel = rel
    ..href = href;

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
  _prefetchedHref[href] = call;

  return call;
}

/// Replaces [n1] with [n2] in [n1] parent.
///
/// Returns [true] if replace was performed.
bool replaceElement(Node n1, Node n2) {
  var parent = n1.parent;

  if (parent != null) {
    var idx = parent.nodes.indexOf(n1);
    if (idx >= 0) {
      parent.nodes.removeAt(idx);
      parent.nodes.insert(idx, n2);
      return true;
    }
  }

  return false;
}

/// Returns the parent of [element] applying [validator] and [maxLevels].
Element? getParentElement(Element element,
    {bool Function(Element parent)? validator, int maxLevels = 1000}) {
  if (maxLevels < 1) return null;

  for (var level = 1; level <= maxLevels; ++level) {
    var parent = element.parent;
    if (parent != null) {
      if (validator != null) {
        if (validator(parent)) {
          return parent;
        }
      } else {
        return parent;
      }

      element = parent;
    } else {
      break;
    }
  }

  return null;
}

/// A [TreeReferenceMap] for DOM Nodes.
class DOMTreeReferenceMap<V> extends TreeReferenceMap<Node, V> {
  DOMTreeReferenceMap(super.root,
      {super.autoPurge,
      super.keepPurgedKeys,
      super.purgedEntriesTimeout,
      super.maxPurgedEntries});

  @override
  bool isInTree(Node? key) {
    if (key == null) return false;
    var rootConn = root.isConnected;
    var keyConn = key.isConnected;
    // Optimization: If `rootConn` and `keyConn` differ,
    // `root` and `key` cannot be in the same DOM tree:
    if (rootConn != keyConn) {
      return false;
    } else {
      return root.contains(key);
    }
  }

  @override
  Node? getParentOf(Node? key) => key?.parent;

  @override
  Iterable<Node> getChildrenOf(Node? key) => key?.nodes ?? [];

  @override
  bool isChildOf(Node? parent, Node? child, bool deep) {
    if (parent == null || child == null) return false;

    var parentConn = parent.isConnected;
    var childConn = child.isConnected;

    if (parentConn != childConn) return false;

    if (deep) {
      return !identical(parent, child) && parent.contains(child);
    } else {
      return parent.nodes.contains(child);
    }
  }
}

int? get deviceWidth => window.innerWidth;

int? get deviceHeight => window.innerHeight;

bool get isExtraSmallDevice => deviceWidth! < 576;

bool get isSmallDevice {
  var w = deviceWidth!;
  return w >= 576 && w < 768;
}

bool get isSmallDeviceOrLower {
  return deviceWidth! < 768;
}

bool get isSmallDeviceOrHigher {
  return deviceWidth! >= 576;
}

bool get isMediumDevice {
  var w = deviceWidth!;
  return w >= 768 && w < 992;
}

bool get isMediumDeviceOrLower {
  return deviceWidth! < 992;
}

bool get isMediumDeviceOrLHigher {
  return deviceWidth! >= 768;
}

bool get isLargeDevice {
  var w = deviceWidth!;
  return w >= 992 && w < 1200;
}

bool get isLargeDeviceOrLower {
  return deviceWidth! < 1200;
}

bool get isLargeDeviceOrHigher {
  return deviceWidth! >= 992;
}

bool get isExtraLargeDevice => deviceWidth! >= 1200;

CanvasElement? _measureTextCanvas;

Dimension? measureText(String text,
    {required String fontFamily, required Object fontSize, bool bold = false}) {
  final canvas = _measureTextCanvas ??= CanvasElement(width: 10, height: 10);
  final ctx = canvas.context2D;

  var fontSizeStr = fontSize is num ? '${fontSize}px' : fontSize.toString();

  var font = '${bold ? 'bold ' : ''}$fontSizeStr $fontFamily';
  ctx.font = font;

  final m = ctx.measureText(text);

  var actualBoundingBoxAscent =
      m.actualBoundingBoxAscent ?? m.fontBoundingBoxAscent ?? 1;
  var actualBoundingBoxDescent =
      m.actualBoundingBoxDescent ?? m.fontBoundingBoxDescent ?? 1;

  var fontBoundingBoxDescent =
      m.fontBoundingBoxDescent ?? m.actualBoundingBoxDescent ?? 1;

  var width = m.width ?? 1;

  var height = m.emHeightAscent;
  if (height != null) {
    height += fontBoundingBoxDescent;
  } else {
    height = actualBoundingBoxAscent + actualBoundingBoxDescent;
  }

  var d = Dimension(width.round(), height.round());
  return d;
}
