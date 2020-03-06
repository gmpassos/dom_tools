
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
  const StyleColor(this.color);

  @override
  String toString() {
    return '#${ color.toRadixString(16).substring(2) }' ;
  }
}

class TextStyle implements CSSValue {
  final StyleColor color ;
  final StyleColor backgroundColor ;
  final FontStyle fontStyle ;
  final FontWeight fontWeight ;

  const TextStyle( {this.color, this.backgroundColor, this.fontStyle, this.fontWeight} );

  @override
  String cssValue() {
    var str = '' ;
    if (color != null) str += 'color: $color ;' ;
    if (backgroundColor != null) str += 'background-color: $backgroundColor ;' ;
    if (fontStyle != null) str += 'font-style: ${ EnumToString.parse(fontStyle) } ;' ;
    if (fontWeight != null) str += 'font-weight: ${ EnumToString.parse(fontWeight) } ;' ;
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

  CssStyleSheet sheet = styleElement.sheet;

  for (var key in css.keys) {
    var val = css[key] ;
    var rule = '.$cssPrefix$key { ${ val.cssValue() } }\n' ;
    sheet.insertRule(rule, 0) ;
    //print(rule);
  }

  var prev = document.head.querySelector('#$id') ;

  if (prev != null) {
    prev.remove();
  }

  document.head.append(styleElement);

}
