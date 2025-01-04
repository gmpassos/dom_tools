import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_css.dart';
import 'dom_tools_extension.dart';

/// Gets the [element] value depending of identified type.
///
/// If the resolved value is null or empty, and def is not null,
/// it will return [def].
String? getElementValue(Element element, [String? def]) {
  String? value;

  if (element.isA<HTMLInputElement>()) {
    value = (element as HTMLInputElement).value;
  } else {
    value = getElementSRC(element);
  }

  return def != null && isEmptyObject(value) ? def : value;
}

/// Sets the [element] [value] depending of the identified type.
bool setElementValue(Element? element, String value) {
  if (element == null) return false;

  if (element.isA<HTMLInputElement>()) {
    (element as HTMLInputElement).value = value;
    return true;
  } else {
    return setElementSRC(element, value);
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

    var fond = allLinks.whereElement().firstWhereOrNull((l) {
      var elemValue = getter(l);
      var ok = values.contains(elemValue);
      if (!ok) return false;
      var elemValue2 = getter2(l);
      var ok2 = values2.contains(elemValue2);
      return ok2;
    });
    return fond;
  } else {
    var fond = allLinks.whereElement().firstWhereOrNull((l) {
      var elemValue = getter(l);
      return values.contains(elemValue);
    });

    return fond;
  }
}

/// Returns `href` value for different [Element] types.
String? getElementHREF(Element element) {
  if (element.isA<HTMLLinkElement>()) return (element as HTMLLinkElement).href;
  if (element.isA<HTMLAnchorElement>()) {
    return (element as HTMLAnchorElement).href;
  }
  if (element.isA<HTMLBaseElement>()) return (element as HTMLBaseElement).href;
  if (element.isA<HTMLAreaElement>()) return (element as HTMLAreaElement).href;

  return null;
}

/// Sets [element] [href] depending of the identified type.
bool setElementHREF(Element element, String href) {
  if (element.isA<HTMLLinkElement>()) {
    (element as HTMLLinkElement).href = href;
    return true;
  } else if (element.isA<HTMLAnchorElement>()) {
    // ignore: unsafe_html
    (element as HTMLAnchorElement).href = href;
    return true;
  } else if (element.isA<HTMLBaseElement>()) {
    (element as HTMLBaseElement).href = href;
    return true;
  } else if (element.isA<HTMLAreaElement>()) {
    (element as HTMLAreaElement).href = href;
    return true;
  }

  return false;
}

/// Returns [true] if [element] type can have `href` attribute.
bool isElementWithHREF(Element element) {
  if (element.isA<HTMLLinkElement>()) return true;
  if (element.isA<HTMLAnchorElement>()) return true;
  if (element.isA<HTMLBaseElement>()) return true;
  if (element.isA<HTMLAreaElement>()) return true;

  return false;
}

/// Returns `src` value for different [Element] types.
String? getElementSRC(Element element) {
  if (element.isA<HTMLImageElement>()) return (element as HTMLImageElement).src;
  if (element.isA<HTMLScriptElement>()) {
    return (element as HTMLScriptElement).src;
  }
  if (element.isA<HTMLInputElement>()) return (element as HTMLInputElement).src;

  if (element.isA<HTMLMediaElement>()) return (element as HTMLMediaElement).src;
  if (element.isA<HTMLEmbedElement>()) return (element as HTMLEmbedElement).src;

  if (element.isA<HTMLIFrameElement>()) {
    return (element as HTMLIFrameElement).src;
  }
  if (element.isA<HTMLSourceElement>()) {
    return (element as HTMLSourceElement).src;
  }
  if (element.isA<HTMLTrackElement>()) return (element as HTMLTrackElement).src;

  return null;
}

/// Sets the [element] [src] depending of the identified type.
bool setElementSRC(Element element, String src) {
  if (element.isA<HTMLImageElement>()) {
    (element as HTMLImageElement).src = src;
    return true;
  } else if (element.isA<HTMLScriptElement>()) {
    (element as HTMLScriptElement).src = src;
    return true;
  } else if (element.isA<HTMLInputElement>()) {
    (element as HTMLInputElement).src = src;
    return true;
  } else if (element.isA<HTMLMediaElement>()) {
    (element as HTMLMediaElement).src = src;
    return true;
  } else if (element.isA<HTMLEmbedElement>()) {
    (element as HTMLEmbedElement).src = src;
    return true;
  } else if (element.isA<HTMLIFrameElement>()) {
    (element as HTMLIFrameElement).src = src;
    return true;
  } else if (element.isA<HTMLSourceElement>()) {
    (element as HTMLSourceElement).src = src;
    return true;
  } else if (element.isA<HTMLTrackElement>()) {
    (element as HTMLTrackElement).src = src;
    return true;
  } else {
    return false;
  }
}

/// Returns [true] if [element] type can have `src` attribute.
bool isElementWithSRC(Element element) {
  if (element.isA<HTMLImageElement>()) return true;
  if (element.isA<HTMLScriptElement>()) return true;
  if (element.isA<HTMLInputElement>()) return true;

  if (element.isA<HTMLMediaElement>()) return true;
  if (element.isA<HTMLEmbedElement>()) return true;

  if (element.isA<HTMLIFrameElement>()) return true;
  if (element.isA<HTMLSourceElement>()) return true;
  if (element.isA<HTMLTrackElement>()) return true;

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
HTMLAnchorElement? getAnchorElementByHREF(String href) {
  return getElementByHREF('a', href) as HTMLAnchorElement?;
}

/// Selects an [LinkElement] in DOM with [href].
HTMLLinkElement? getLinkElementByHREF(String href, [String? rel]) {
  if (href.isEmpty) return null;

  if (isNotEmptyString(rel)) {
    var resolvedURL = resolveUri(href).toString();
    return getElementByValues('link', getElementHREF, [href, resolvedURL],
        (e) => e.getAttribute('rel'), [rel]) as HTMLLinkElement?;
  } else {
    return getElementByHREF('link', href) as HTMLLinkElement?;
  }
}

/// Selects an [ScriptElement] in DOM with [src].
HTMLScriptElement? getScriptElementBySRC(String src) {
  return getElementBySRC('script', src) as HTMLScriptElement?;
}

/// Returns [element] width. Tries to use 'offsetWidth' or 'style.width' values.
///
/// [def] default value if width is `null` or `0`.
int? getElementWidth(HTMLElement element, [int? def]) {
  var w = element.offsetWidth;
  if (w <= 0) {
    w = parseCSSLength(element.style.width, unit: 'px', def: def ?? 0) as int;
  }
  return w <= 0 ? def : w;
}

/// Returns [element] height. Tries to use 'offsetHeight' or 'style.height' values.
///
/// [def] default value if width is `null` or `0`.
int? getElementHeight(HTMLElement element, [int? def]) {
  var h = element.offsetHeight;
  if (h <= 0) {
    h = parseCSSLength(element.style.height, unit: 'px', def: def ?? 0) as int;
  }
  return h <= 0 ? def : h;
}

/// Returns a [Future<bool>] for when [img] loads.
Future<bool> elementOnLoad(HTMLImageElement img) {
  var completer = Completer<bool>();
  img.onLoad.listen((e) => completer.complete(true),
      onError: (e) => completer.complete(false));
  return completer.future;
}

/// Creates a `div` with `display: inline-block`.
HTMLDivElement createDivInlineBlock() =>
    HTMLDivElement()..style.display = 'inline-block';

/// Creates a `div`.
/// [inline] If [true] sets `display: inline-block`.
/// [html] The HTML to parse as content.
HTMLDivElement createDiv(
    {bool inline = false,
    String? html,
    @Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  var div = HTMLDivElement();

  if (inline) div.style.display = 'inline-block';

  if (html != null) {
    setElementInnerHTML(div, html, unsafe: unsafe);
  }

  return div;
}

/// Creates a `div` with `display: inline-block`.
///
/// [html] The HTML to parse as content.
HTMLDivElement createDivInline({String? html, bool unsafe = false}) {
  return createDiv(inline: true, html: html, unsafe: unsafe);
}

/// Creates a `span` element.
///
/// [html] The HTML to parse as content.
HTMLSpanElement createSpan(
    {String? html,
    @Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  var span = HTMLSpanElement();

  if (html != null) {
    setElementInnerHTML(span, html, unsafe: unsafe);
  }

  return span;
}

/// Creates a `label` element.
///
/// [html] The HTML to parse as content.
HTMLLabelElement createLabel(
    {String? html,
    @Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  var label = HTMLLabelElement();

  if (html != null) {
    setElementInnerHTML(label, html, unsafe: unsafe);
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
HTMLElement createHTML(
    {String? html,
    @Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  if (html == null || html.isEmpty) return HTMLSpanElement();

  var dependentTagMatch = _regexpDependentTag.firstMatch(html);

  if (dependentTagMatch != null) {
    var dependentTagName = dependentTagMatch.group(1)!.toLowerCase();

    HTMLDivElement div;
    if (dependentTagName == 'td' || dependentTagName == 'th') {
      div = createDiv(
          inline: true,
          html: '<table><tbody><tr>\n$html\n</tr></tbody></table>',
          unsafe: unsafe);
    } else if (dependentTagName == 'tr') {
      div = createDiv(
          inline: true,
          html: '<table><tbody>\n$html\n</tbody></table>',
          unsafe: unsafe);
    } else if (dependentTagName == 'tbody' ||
        dependentTagName == 'thead' ||
        dependentTagName == 'tfoot') {
      div = createDiv(
          inline: true, html: '<table>\n$html\n</table>', unsafe: unsafe);
    } else {
      throw StateError("Can't handle dependent tag: $dependentTagName");
    }

    var childNode = div.querySelector(dependentTagName);
    return childNode?.asHTMLElement ??
        (throw StateError("Can't create HTML:\n$html"));
  } else {
    var div = createDiv(inline: true, html: html, unsafe: unsafe);

    var childNodes = div.childNodes;
    if (childNodes.isEmpty) return div;

    var childNode = childNodes.whereElement().firstOrNull;

    if (childNode is HTMLElement) {
      return childNode;
    }

    var span = HTMLSpanElement();
    span.appendNodes(div.childNodes.toIterable());
    return span;
  }
}

/// Sets the inner HTML of [element] with parsed result of [html].
void setElementInnerHTML(HTMLElement element, String html,
    {@Deprecated(
        "`NodeValidator` not implemented on package `web`. See parameter `unsafe`.")
    Object? validator,
    bool unsafe = false}) {
  if (unsafe) {
    element.setHTMLUnsafe(html.toJS);
  } else {
    element.innerHTML = html.toJS;
  }
}

/// Appends to the inner HTML of [element] with parsed result of [html].
void appendElementInnerHTML(HTMLElement element, String html,
    {@Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  element.insertAdjacentHTML("beforeend", html.toJS);
}

/// Transform [html] to plain text.
String? htmlToText(String html,
    [@Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator]) {
  var elem = createHTML(html: '<div>$html</div>');
  return elem.textContent;
}

/// Returns the X and Y position of [Element] int the [Document].
Pair<num> getElementDocumentPosition(HTMLElement element) {
  var obj = getVisibleNode(element);

  num top = obj!.offsetTop;
  num left = obj.offsetLeft;

  if (obj.offsetParent != null) {
    do {
      top += obj!.offsetTop;
      left += obj.offsetLeft;
    } while ((obj = obj.offsetParent?.asHTMLElement) != null);
  }

  return Pair<num>(left, top);
}

/// Get the first visible element in the hierarchy.
HTMLElement? getVisibleNode(HTMLElement? element) {
  while (element != null &&
      (element.hidden?.dartify() == true || element.style.display == 'none')) {
    var parent = element.parentElement;
    if (parent != null && parent.isA<HTMLElement>()) {
      element = parent as HTMLElement;
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
String? getElementAttribute(HTMLElement element, Object? key) {
  if (key == null) return null;

  if (key is RegExp) {
    return getElementAttributeRegExp(element, key);
  } else {
    return getElementAttributeStr(element, key.toString());
  }
}

/// Returns [element] attribute with [RegExp] [key].
String? getElementAttributeRegExp(HTMLElement element, RegExp key) {
  for (var k in element.getAttributeNames().toList()) {
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

  for (var k in element.getAttributeNames().toList()) {
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
String toHTML(HTMLElement element) {
  return _toHTMLAny(element);
}

String _toHTMLAny(HTMLElement e) {
  var html = '';

  html += '<';
  html += e.tagName;

  for (var attr in e.getAttributeNames().toList()) {
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

  var innerHTML = e.innerHTML.dartify()?.toString();

  if (innerHTML != null && innerHTML.isNotEmpty) {
    if (e is HTMLSelectElement) {
      html += _toHTMLInnerHtmlSelect(e);
    } else {
      html += innerHTML;
    }
  }

  html += '</${e.tagName}>';

  return html;
}

String _toHTMLInnerHtmlSelect(HTMLSelectElement e) {
  var html = '';

  for (var o in e.options.toIterable()) {
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
      min(window.innerWidth, document.documentElement!.clientWidth);
  var windowHeight =
      min(window.innerHeight, document.documentElement!.clientHeight);

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

/// Defines a new [CSSStyleDeclaration] merging [currentCSS] and [appendCSS].
///
/// [defaultCSS] if [currentCSS] and [appendCSS] are [null].
CSSStyleDeclaration defineCSS(
    CSSStyleDeclaration? currentCSS, CSSStyleDeclaration? appendCSS,
    [dynamic defaultCSS]) {
  if (currentCSS == null) {
    return appendCSS ?? asCssStyleDeclaration(defaultCSS);
  } else if (appendCSS == null) {
    return currentCSS;
  } else {
    var css = HTMLTemplateElement().style;
    css.cssText = '${currentCSS.cssText} ; ${appendCSS.cssText}';
    return css;
  }
}

CSSStyleDeclaration newCSSStyleDeclaration({String? cssText}) {
  var style = HTMLTemplateElement().style;
  if (cssText != null && cssText.isNotEmpty) {
    style.cssText = cssText;
  }
  return style;
}

/// Parses dynamic [css] as [CSSStyleDeclaration].
CSSStyleDeclaration asCssStyleDeclaration(dynamic css) {
  if (css == null) return newCSSStyleDeclaration();
  if (css is CSSStyleDeclaration) return css;
  if (css is String) return newCSSStyleDeclaration(cssText: css);
  if (css is Function) return asCssStyleDeclaration(css());

  throw StateError("Can't convert to CSS: $css");
}

/// Returns [true] if [CSSStyleDeclaration] is empty.
bool isCssEmpty(CSSStyleDeclaration css) {
  var cssText = css.cssText;
  return cssText.trim().isEmpty;
}

/// Returns [true] if [CSSStyleDeclaration] is not empty.
bool isCssNotEmpty(CSSStyleDeclaration css) {
  return !isCssEmpty(css);
}

/// Applies [css] to [element] and [extraElements] list if present.
bool applyCSS(CSSStyleDeclaration css, Element element,
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

bool _applyCSS(CSSStyleDeclaration css, Element element) {
  var newCss = '${element.style?.cssText ?? ''} ; ${css.cssText}';
  element.style?.cssText = newCss;
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
void setTreeElementsDivCentered(HTMLElement element, String className,
    {bool centerVertically = true, bool centerHorizontally = true}) {
  if (isEmptyString(className, trim: true)) return;

  var elements = element.querySelectorAll('div.$className').toIterable();

  for (var e in elements) {
    if (e is HTMLDivElement) {
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
void setDivCentered(HTMLDivElement div,
    {bool centerVertically = true,
    bool centerHorizontally = true,
    bool checkBootstrapClasses = true}) {
  div.style.display =
      isInlineElement(div, checkBootstrapClasses: checkBootstrapClasses)
          ? 'inline-table'
          : 'table';

  div.classList.removeAll(_divCenteredBootstrapConflictingClasses);

  var subDivs = div.querySelectorAll(':scope > div').whereHTMLElement();

  for (var subDiv in subDivs) {
    print(subDiv.outerHTML);

    subDiv.classList.removeAll(_divCenteredBootstrapConflictingClasses);
    subDiv.style.display = 'table-cell';

    if (centerHorizontally) {
      subDiv.style.textAlign = 'center';
    }

    if (centerVertically) {
      subDiv.style.verticalAlign = 'middle';
    }

    var contentDivs =
        subDiv.querySelectorAll(':scope > div').whereHTMLElement();

    for (var contentDiv in contentDivs) {
      if (!isInlineElement(contentDiv as HTMLDivElement,
          checkBootstrapClasses: checkBootstrapClasses)) {
        contentDiv.style.display = 'inline-block';
      }
    }
  }
}

/// Returns [true] if [element] `display` property is inline.
bool isInlineElement(HTMLDivElement element,
    {bool checkBootstrapClasses = true}) {
  if (element.style.display.toLowerCase().contains('inline')) return true;

  if (checkBootstrapClasses) {
    final classList = element.classList;

    return classList.contains('d-inline') ||
        classList.contains('d-inline-block') ||
        classList.contains('d-inline-flex');
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

  var head = document.querySelector('head') as HTMLHeadElement?;

  var script = HTMLLinkElement()
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

    head.insertChild(insertIndex, script);
  } else {
    head!.appendChild(script);
  }

  var call = completer.future;
  _prefetchedHref[href] = call;

  return call;
}

/// Replaces [n1] with [n2] in [n1] parent.
///
/// Returns [true] if replace was performed.
bool replaceElement(Node n1, Node n2) {
  var parent = n1.parentElement;

  if (parent != null) {
    var idx = parent.childNodes.indexOf(n1);
    if (idx >= 0) {
      parent.insertBefore(n1, n2);
      parent.removeChild(n1);
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
    var parent = element.parentElement;
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
  Node? getParentOf(Node? key) => key?.parentNode;

  @override
  Iterable<Node> getChildrenOf(Node? key) => key?.childNodes.toIterable() ?? [];

  @override
  bool isChildOf(Node? parent, Node? child, bool deep) {
    if (parent == null || child == null) return false;

    var parentConn = parent.isConnected;
    var childConn = child.isConnected;

    if (parentConn != childConn) return false;

    if (deep) {
      return !identical(parent, child) && parent.contains(child);
    } else {
      return parent.contains(child);
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

HTMLCanvasElement? _measureTextCanvas;

Dimension? measureText(String text,
    {required String fontFamily, required Object fontSize, bool bold = false}) {
  final canvas = _measureTextCanvas ??= HTMLCanvasElement()
    ..width = 10
    ..height = 10;

  final ctx = canvas.context2D;

  var fontSizeStr = fontSize is num ? '${fontSize}px' : fontSize.toString();

  var font = '${bold ? 'bold ' : ''}$fontSizeStr $fontFamily';
  ctx.font = font;

  final m = ctx.measureText(text);

  var actualBoundingBoxAscent =
      m.tryActualBoundingBoxAscent ?? m.tryFontBoundingBoxAscent ?? 1;
  var actualBoundingBoxDescent =
      m.tryActualBoundingBoxDescent ?? m.tryFontBoundingBoxDescent ?? 1;

  var fontBoundingBoxDescent =
      m.tryFontBoundingBoxDescent ?? m.tryActualBoundingBoxDescent ?? 1;

  var width = m.width;

  var height = m.tryEmHeightAscent;
  if (height != null) {
    height += fontBoundingBoxDescent;
  } else {
    height = actualBoundingBoxAscent + actualBoundingBoxDescent;
  }

  var d = Dimension(width.round(), height.round());
  return d;
}
