
import 'dart:html';

import 'package:enum_to_string/enum_to_string.dart';

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
