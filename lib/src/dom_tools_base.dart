

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:swiss_knife/swiss_knife.dart';

////////////////////////////////////////////////////////////////////////////////

typedef ElementValueGetter<T> = T Function(Element element) ;

Element getElementByValues<V>(String tag, ElementValueGetter getter, List<V> values ) {
  if (tag == null || tag.isEmpty) return null ;
  if ( values == null || values.isEmpty ) return null ;
  values.removeWhere( (v) => v == null ) ;
  if ( values.isEmpty ) return null ;

  var allLinks = document.querySelectorAll(tag) ;
  if (allLinks == null || allLinks.isEmpty) return null ;

  var fond = allLinks.firstWhere(
          (l) {
        var elemValue = getter(l) ;
        return values.contains(elemValue) ;
      }
      , orElse: () => null
  ) ;

  return fond ;
}

String getElementHref(Element element) {
  if ( element is LinkElement ) return element.href ;
  if ( element is AnchorElement ) return element.href ;
  if ( element is BaseElement ) return element.href ;
  if ( element is AreaElement ) return element.href ;

  return null ;
}

String getElementSrc(Element element) {
  if ( element is ImageElement ) return element.src ;
  if ( element is ScriptElement ) return element.src ;
  if ( element is InputElement ) return element.src ;

  if ( element is MediaElement ) return element.src ;
  if ( element is EmbedElement ) return element.src ;

  if ( element is IFrameElement ) return element.src ;
  if ( element is SourceElement ) return element.src ;
  if ( element is TrackElement ) return element.src ;

  if ( element is ImageButtonInputElement ) return element.src ;

  return null ;
}

Element getElementByHref(String tag, String href) {
  if ( href == null || href.isEmpty ) return null ;
  var resolvedURL = resolveUri(href).toString() ;
  return getElementByValues(tag, getElementHref, [href, resolvedURL]) ;
}

Element getElementBySrc(String tag, String src) {
  if ( src == null || src.isEmpty ) return null ;

  var values = [src];

  if ( !src.startsWith('data:') ) {
    var resolvedURL = resolveUri(src).toString() ;
    values.add(resolvedURL);
  }

  return getElementByValues(tag, getElementSrc, values) ;
}

AnchorElement getAnchorElementByHref(String href) {
  return getElementByHref('a', href) ;
}

LinkElement getLinkElementByHref(String href) {
  return getElementByHref('link', href) ;
}

ScriptElement getScriptElementBySrc(String src) {
  return getElementBySrc('script', src) ;
}

////////////////////////////////////////////////////////////////////////////////

Future<bool> elementOnLoad(ImageElement img) {
  var completer = Completer<bool>() ;
  img.onLoad.listen( (e) => completer.complete(true) , onError: (e) => completer.complete(false) ) ;
  return completer.future ;
}

DivElement createDivInlineBlock() => DivElement()..style.display = 'inline-block';

DivElement createDiv([bool inline = false, String html]) {
  var div = DivElement() ;

  if (inline) div.style.display = 'inline-block';

  if (html != null) {
    setElementInnerHTML(div, html);
  }

  return div ;
}

DivElement createDivInline([String html]) {
  return createDiv(true, html);
}

SpanElement createSpan([String html]) {
  var span = SpanElement() ;

  if (html != null) {
    setElementInnerHTML(span, html);
  }

  return span ;
}

LabelElement createLabel([String html]) {
  var label = LabelElement() ;

  if (html != null) {
    setElementInnerHTML(label, html);
  }

  return label ;
}

Element createHTML([String html]) {
  var div = createDiv(true, html);
  if ( div.childNodes.isEmpty ) return div ;

  var childNode = div.childNodes.firstWhere( (e) => e is Element , orElse: () => null ) ;

  return childNode ;
}

const _HTML_BASIC_ATTRS = ['style', 'capture', 'type', 'src', 'href', 'target'] ;
const _HTML_CONTROL_ATTRS = ['data-toggle', 'data-target', 'aria-controls', 'aria-expanded', 'aria-label'] ;

const _HTML_EXTENDED_ATTRS = ['field', 'navigate', 'action', 'uilayout', 'oneventkeypress', 'oneventclick'] ;

const _HTML_ELEMENTS_ALLOWED_ATTRS = [ ..._HTML_BASIC_ATTRS , ..._HTML_CONTROL_ATTRS , ..._HTML_EXTENDED_ATTRS ] ;

AnyUriPolicy _anyUriPolicy = AnyUriPolicy() ;


class AnyUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true ;
  }
}

NodeValidatorBuilder _nodeValidatorBuilder = NodeValidatorBuilder()
  ..allowTextElements()
  ..allowHtml5()
  ..allowSvg()
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
  ..allowInlineStyles()
;

void setElementInnerHTML(Element e, String html) {
  e.setInnerHtml(html, validator: _nodeValidatorBuilder) ;
}

void appendElementInnerHTML(Element e, String html) {
  e.appendHtml(html, validator: _nodeValidatorBuilder) ;
}

void scrollToTopAsync(int delayMs) {
  if (delayMs < 1) delayMs = 1 ;
  Future.delayed( Duration(milliseconds: delayMs), scrollToTop) ;
}

void scrollToTop() {
  window.scrollTo(window.scrollX,0, {'behavior': 'smooth'});
}

void scrollToBottom() {
  window.scrollTo(window.scrollX, document.body.scrollHeight, {'behavior': 'smooth'});
}

void scrollToLeft() {
  window.scrollTo(0, window.scrollY, {'behavior': 'smooth'});
}

void scrollToRight() {
  window.scrollTo(document.body.scrollWidth, window.scrollY, {'behavior': 'smooth'});
}

void resetZoom() {
  _resetZoomImpl(0) ;
}

bool _resettingZoom = false ;
bool _resettingViewportScale = false ;

void _resetZoomImpl(int retry) {
  if (_resettingZoom || _resettingViewportScale) {
    if (retry < 100) {
      Future.delayed(Duration(milliseconds: 10), () => _resetZoomImpl(retry++));
    }
    return ;
  }

  if ( !_resettingZoom ) {
    _resettingZoom = true;

    var prev = document.body.style.zoom;
    setZoom('normal');

    Future.delayed(Duration(milliseconds: 10), () {
      setZoom(prev);
      _resettingZoom = false ;
    });
  }

  if ( !_resettingViewportScale ) {
    _resettingViewportScale = true ;

    var metaViewportList = getMetaTagsWithName('viewport') ;

    if ( metaViewportList.isNotEmpty ) {
      var metaViewport =  metaViewportList[0] ;
      var content = metaViewport.getAttribute('content') ;

      setMetaViewportScale( minimumScale: '*' , maximumScale: '*') ;

      Future.delayed( Duration( milliseconds: 10) , () {
        metaViewport.setAttribute('content', content);
        _resettingViewportScale = false ;
      } ) ;
    }
  }
}

void setZoom(String zoom) {
  document.body.style.zoom = zoom ;
}

bool setMetaViewportScale( { String minimumScale, String maximumScale } ) {
  if (minimumScale == null && maximumScale == null) return false ;

  var metaViewportList = getMetaTagsWithName('viewport') ;
  if ( metaViewportList.isEmpty ) return false ;

  var metaViewport =  metaViewportList[0] ;

  var content = metaViewport.getAttribute('content') ;
  var params = parseMetaContent(content) ;

  var defaultScale = params['initial-scale'] ?? '1.0' ;

  var changed = false ;

  if (maximumScale != null) {
    minimumScale = minimumScale.trim() ;
    if (minimumScale.isEmpty || minimumScale == '*') {
      minimumScale = defaultScale;
    }

    params['minimum-scale'] = minimumScale ;
    changed = true ;
  }

  if (maximumScale != null) {
    maximumScale = maximumScale.trim() ;
    if (maximumScale.isEmpty || maximumScale == '*') {
      maximumScale = defaultScale;
    }

    params['maximum-scale'] = maximumScale ;
    changed = true ;
  }

  if (changed) {
    var content2 = buildMetaContent(params);
    metaViewport.setAttribute('content', content2);
    return true ;
  }

  return false ;
}

Map<String,String> parseMetaContent(String content) {
  var parts = content.split(RegExp(r'\s*,\s*')) ;

  // ignore: omit_local_variable_types
  Map<String,String> map = {} ;

  for (var p in parts) {
    var pair = split(p, '=', 2) ;

    if (pair.length == 1) {
      map[ p ] = null ;
    }
    else {
      var key = pair[0].trim() ;
      var val = pair[1].trim() ;
      map[ key ] = val;
    }
  }

  return map ;
}

String buildMetaContent(Map<String,String> map) {
  var content = '' ;

  for (var entry in map.entries) {
    var key = entry.key ;
    var val = entry.value ;

    if (content.isNotEmpty) {
      content += ', ' ;
    }

    if (val == null) {
      content += key ;
    }
    else {
      content += '$key=$val' ;
    }
  }


  return content ;
}

////////////////////////////////////////////////////////////////////////////////

String getElementAttribute(Element element, dynamic key) {
  if (element == null || key == null) return null ;

  if (key is RegExp) {
    return getElementAttributeRegExp(element , key) ;
  }
  else {
    return getElementAttributeStr(element , key.toString()) ;
  }
}

String getElementAttributeRegExp(Element element, RegExp key) {
  if (element == null || key == null) return null ;

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if ( key.hasMatch(k) ) {
      return attrs[k] ;
    }
  }

  return null ;
}

String getElementAttributeStr(Element element, String key) {
  if (element == null || key == null) return null ;

  var val = element.getAttribute(key) ;
  if (val != null) return val;

  key = key.trim();
  key = key.toLowerCase();

  var attrs = element.attributes;

  for (var k in attrs.keys) {
    if (k.toLowerCase() == key) {
      return attrs[k] ;
    }
  }

  return null ;
}



void clearSelections() {
  var selection = window.getSelection() ;

  if (selection != null) {
    selection.removeAllRanges();
  }
}

String toHTML(Element e) {
  return _toHTML_any(e) ;
}

String _toHTML_any(Element e) {
  var html = '';

  html += '<' ;
  html += e.tagName ;

  for (var attr in e.attributes.keys) {
    var val = e.attributes[attr] ;
    if (val != null) {
      if (val.contains("'")) {
        html += ' attr=\"$val\"' ;
      }
      else {
        html += " attr='$val'" ;
      }
    }
    else {
      html += ' attr' ;
    }
  }

  html += '>' ;

  if ( e.innerHtml != null && e.innerHtml.isNotEmpty ) {

    if ( e is SelectElement ) {
      html += _toHTML_innerHtml_Select(e) ;
    }
    else {
      html += e.innerHtml ;
    }

  }

  html += '</${ e.tagName }>' ;

  return html ;
}

String _toHTML_innerHtml_Select(SelectElement e) {
  var html = '' ;

  for (var o in e.options) {
    html += "<option value='${o.value}' ${ o.selected ? ' selected' : ''}>${o.label}</option>";
  }

  return html ;
}



////////////////////////////////////////////////////////////////////////////////

typedef FunctionTest = bool Function() ;

bool isInViewport(Element elem) {
  var rect = elem.getBoundingClientRect();

  var windowWidth = min( window.innerWidth, document.documentElement.clientWidth ) ;
  var windowHeight = min( window.innerHeight, document.documentElement.clientHeight ) ;

  return rect.bottom > 0 && rect.right > 0 && rect.left < windowWidth && rect.top < windowHeight ;
}

bool isOrientationInPortraitMode() {
  return !isOrientationInLandscapeMode() ;
}

bool isOrientationInLandscapeMode() {
  var orientation = window.orientation;
  if (orientation == null) return false ;

  if ( orientation == 90 || orientation == -90 ) {
    return true ;
  }
  else {
    return false ;
  }
}

bool onOrientationchange( EventListener listener ) {
  try {
    window.addEventListener('orientationchange', listener ) ;
    return true ;
  }
  catch(e,s) {
    print(e);
    print(s);
    return false ;
  }
}

bool isNodeInDOM(Node node) {
  return document.body.contains(node) ;
}

bool isInDOM(dynamic element) {
  if (element == null) return false ;

  if (element is Node) {
    return document.body.contains(element);
  }
  else if (element is List) {
    for (var elem in element) {
      var inDom = isInDOM(elem);
      if (inDom) return true ;
    }
    return false ;
  }

  return false ;
}


bool nodeTreeContains( Node node , Node target ) {
  return nodeTreeContainsAny( node , [target] ) ;
}

bool nodeTreeContainsAny( Node node , Iterable<Node> list ) {
  if (list == null || list.isEmpty) return false ;
  return list.firstWhere( (e) => e == node || node.contains(e) , orElse: () => null ) != null ;
}

///////////////////////////

CssStyleDeclaration defineCSS(CssStyleDeclaration currentCSS, CssStyleDeclaration appendCSS, [dynamic defaultCSS]) {
  if (currentCSS == null) {
    return appendCSS ?? asCssStyleDeclaration(defaultCSS) ;
  }
  else if (appendCSS == null) {
    return currentCSS ?? asCssStyleDeclaration(defaultCSS);
  }
  else {
    return CssStyleDeclaration()
      ..cssText = currentCSS.cssText + ' ; ' + appendCSS.cssText;
  }
}

CssStyleDeclaration asCssStyleDeclaration(dynamic css) {
  if (css == null) return CssStyleDeclaration();
  if (css is CssStyleDeclaration) return css;
  if (css is String) return CssStyleDeclaration()..cssText = css;
  if (css is Function) return asCssStyleDeclaration( css() ) ;

  throw StateError("Can't convert to CSS: $css") ;
}

bool hasCSS(CssStyleDeclaration css) {
  if (css == null) return false ;
  var cssText = css.cssText ;
  if (cssText == null || cssText.trim().isEmpty) return false ;
  return true ;
}

bool applyCSS(CssStyleDeclaration css, Element element, [List<Element> extraElements]) {
  if ( !hasCSS(css) ) return false ;
  
  var apply = _applyCSS(css, element) ;

  if (extraElements != null) {
    for (var elem in extraElements) {
      var ok = _applyCSS(css, elem) ;
      apply |= ok ;
    }
  }

  return apply ;
}

bool _applyCSS(CssStyleDeclaration css, Element element) {
  if (element != null) {
    var newCss = element.style.cssText + ' ; ' + css.cssText;
    element.style.cssText = newCss;
    return true ;
  }
  return false ;
}

////////////////////////////////////////////////////////////////////////////////

bool elementMatchesAttributes(Element element, Map<String,dynamic> attributes) {
  for (var entry in attributes.entries) {
    if ( !elementMatchesAttribute(element, entry.key, entry.value) ) {
      return false ;
    }
  }
  return true ;
}

typedef MatchesValue = bool Function(String value) ;

bool elementMatchesAttribute(Element element, String attributeName, dynamic attributeValue) {
  var value = element.getAttribute(attributeName) ;
  if ( value == attributeValue ) return true ;
  if (value == null || attributeValue == null ) return false ;

  if ( attributeValue is String ) {
    return value.trim() == attributeValue.trim() ;
  }
  else if ( attributeValue is RegExp ) {
    return attributeValue.hasMatch(value) ;
  }
  else if ( attributeValue is MatchesValue ) {
    return attributeValue(value) ;
  }

  return false ;
}

List<Element> getElementsWithAttributes(String tag, Map<String,dynamic> matchAttributes) {
  var tags = (document.getElementsByTagName(tag) ?? []).whereType<Element>() ;
  return tags.where( (e) => elementMatchesAttributes(e, matchAttributes) ).toList() ;
}

List<Element> getMetaTagsWithName(String name) {
  return getElementsWithAttributes('meta', {'name': name}) ?? [] ;
}

List<String> getMetaTagsContentWithName(String name) {
  var tags = getMetaTagsWithName(name);
  if (tags == null || tags.isEmpty) return [] ;
  return tags.map( (e) => e.getAttribute('content') ).toList() ;
}

bool isMobileAppStatusBarTranslucent() {
  var metaTagsContents = getMetaTagsContentWithName('apple-mobile-web-app-status-bar-style') ;
  if (metaTagsContents == null || metaTagsContents.isEmpty) return false ;
  var metaStatusContent = metaTagsContents[0] ;
  return metaStatusContent.contains('translucent') ;
}

