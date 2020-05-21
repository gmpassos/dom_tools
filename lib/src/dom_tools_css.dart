
import 'dart:async';
import 'dart:html';

import 'package:dom_tools/dom_tools.dart';
import 'package:enum_to_string/enum_to_string.dart';


////////////////////////////////////////////////////////////////////////////////

Map<String, Future<bool>> _addedCssSources = {} ;

Future<bool> addCssSource(String cssSource) async {
  var linkInDom = getLinkElementByHref(cssSource);

  var prevCall = _addedCssSources[cssSource] ;

  if ( prevCall != null ) {
    if (linkInDom != null) {
      return prevCall ;
    }
    else {
      var removed = _addedCssSources.remove(cssSource) ;
      assert(removed != null) ;
    }
  }

  if (linkInDom != null) {
    return true ;
  }

  print('ADDING <LINK>: $cssSource') ;

  HeadElement head = querySelector('head') ;

  var script = LinkElement()
    ..rel = 'stylesheet'
    ..href = cssSource
  ;

  var completer = Completer<bool>() ;

  script.onLoad.listen( (e) {
    completer.complete(true) ;
  } , onError: (e) {
    completer.complete(false) ;
  } ) ;

  head.children.add(script);

  var call = completer.future ;
  _addedCssSources[cssSource] = call ;

  return call ;
}

CssStyleDeclaration getComputedStyle( { Element parent, Element element, String classes , String style , bool hidden } ) {
  parent ??= document.body ;
  hidden ??= true ;

  element ??= DivElement() ;

  element.hidden = hidden ;

  if (classes != null && classes.isNotEmpty) {
    var allClasses = classes.split(RegExp(r'\s+')).where( (s) => s.isNotEmpty ).toList() ;
    for (var c in allClasses) {
      element.classes.add(c) ;
    }
  }

  if (style != null && style.isNotEmpty) {
    element.style.cssText = style ;
  }

  parent.children.add(element) ;

  var computedStyle = element.getComputedStyle() ;
  var cssText = computedStyle.cssText;

  var computedStyle2 = CssStyleDeclaration() ;
  computedStyle2.cssText = cssText ;

  element.remove() ;

  return computedStyle2 ;
}

////////////////////////////////////////////////////////////////////////////////

enum FontStyle {
  normal,
  italic,
  oblique,
}

enum FontWeight {
  normal,
  bold,
  bolder,
  lighter
}

class StyleColor {
  final int color ;
  final String colorHex ;
  final String colorRGBa ;

  const StyleColor(this.color) : colorHex = null , colorRGBa = null ;
  const StyleColor.fromHex(this.colorHex) : color = null ,colorRGBa = null ;
  const StyleColor.fromRGBa(this.colorRGBa) : color = null , colorHex = null ;

  @override
  String toString() {
    if (colorHex != null) {
      return colorHex.startsWith('#') ? colorHex : '#$colorHex' ;
    }
    else if (colorRGBa != null) {
      return colorRGBa.startsWith('rgba(') ? colorRGBa : 'rgba($colorRGBa)' ;
    }
    else {
      return '#${ color.toRadixString(16).substring(2) }' ;
    }

  }
}

class TextStyle implements CSSValue {
  final StyleColor color ;
  final StyleColor backgroundColor ;
  final FontStyle fontStyle ;
  final FontWeight fontWeight ;
  final StyleColor borderColor ;
  final String borderRadius ;
  final String padding ;

  const TextStyle( {this.color, this.backgroundColor, this.fontStyle, this.fontWeight, this.borderColor, this.borderRadius , this.padding } );

  @override
  String cssValue() {
    var str = '' ;

    if (color != null) str += 'color: $color ;' ;
    if (backgroundColor != null) str += 'background-color: $backgroundColor ;' ;

    if (fontStyle != null) str += 'font-style: ${ EnumToString.parse(fontStyle) } ;' ;
    if (fontWeight != null) str += 'font-weight: ${ EnumToString.parse(fontWeight) } ;' ;

    if (borderColor != null) str += 'border-color: $borderColor ;' ;
    if (borderRadius != null) str += 'border-radius: $borderRadius;' ;

    if (padding != null) str += 'padding: $padding;' ;

    return str ;
  }
}

abstract class CSSValue {
  String cssValue() ;
}


Map<String,Map<dynamic,bool>> _loadedThemesByPrefix = {} ;

void loadCSS(String cssPrefix, Map<String, CSSValue> css) {
  cssPrefix ??= '';

  var _loadedThemes = _loadedThemesByPrefix[cssPrefix] ;

  if (_loadedThemes == null) {
    _loadedThemesByPrefix[cssPrefix] = _loadedThemes = {} ;
  }

  if ( _loadedThemes[css] != null ) return ;
  _loadedThemes[css] = true ;

  var id = '__dom_tools__dynamic_css__$cssPrefix';

  var styleElement = StyleElement()
    ..id = id ;
  ;

  var prev = document.head.querySelector('#$id') ;
  if (prev != null) {
    prev.remove();
  }

  document.head.append(styleElement);

  CssStyleSheet sheet = styleElement.sheet;

  for (var key in css.keys) {
    var val = css[key] ;
    var rule = '.$cssPrefix$key { ${ val.cssValue() } }\n' ;
    sheet.insertRule(rule, 0) ;
    print(rule);
  }

}


class CSSThemeSet {

  final String cssPrefix ;
  final List< Map<String, CSSValue> > _themes ;
  final int defaultThemeID ;

  CSSThemeSet(this.cssPrefix, this._themes, [this.defaultThemeID = 0]) ;

  Map<String, CSSValue> getCSSTheme(int themeID) {
    if (_themes == null || _themes.isEmpty) return null ;
    return themeID >= 0 && themeID < _themes.length ?  _themes[themeID] : null ;
  }

  int loadTheme(int themeID) {
    var cssTheme = getCSSTheme(themeID) ;

    if (cssTheme != null) {
      loadCSSTheme(cssTheme) ;
      return themeID ;
    }
    else {
      cssTheme = getCSSTheme(defaultThemeID) ;
      loadCSSTheme(cssTheme) ;
      return defaultThemeID ;
    }
  }

  bool _loadedTheme = false ;

  bool get loadedTheme => _loadedTheme;

  void loadCSSTheme(Map<String, CSSValue> css) {
    loadCSS(cssPrefix, css);
    _loadedTheme = true ;
  }

  void ensureThemeLoaded() {
    if (!_loadedTheme) {
      loadTheme( defaultThemeID );
    }
  }

}
