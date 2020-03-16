

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:swiss_knife/swiss_knife.dart';

////////////////////////////////////////////////////////////////////////////////

DivElement createDivInlineBlock() => DivElement()..style.display = 'inline-block';

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

