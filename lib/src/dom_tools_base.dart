

import 'dart:async';
import 'dart:html';
import 'dart:math';

////////////////////////////////////////////////////////////////////////////////

DivElement createDivInlineBlock() => DivElement()..style.display = 'inline-block';

bool isInViewport(Element elem) {
  var rect = elem.getBoundingClientRect();

  var windowWidth = min( window.innerWidth, document.documentElement.clientWidth ) ;
  var windowHeight = min( window.innerHeight, document.documentElement.clientHeight ) ;

  return rect.bottom > 0 && rect.right > 0 && rect.left < windowWidth && rect.top < windowHeight ;
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

class _ElementTrack {

  final TrackElementInViewport _trackElementInViewport ;

  final Element _element ;
  final bool _periodicTracking ;
  final OnElementEvent _onEnterViewport ;
  final OnElementEvent _onLeaveViewPort;

  bool _lastCheck_viewing ;

  _ElementTrack(this._trackElementInViewport, this._element, this._periodicTracking, this._onEnterViewport, this._onLeaveViewPort) ;

  bool _initialize() {
    _lastCheck_viewing = isInViewport(_element) ;

    if (_lastCheck_viewing) {
      _notifyEnter();
    }

    return _lastCheck_viewing ;
  }

  void check() {
    var viewing = isInViewport(_element) ;

    if (viewing) {
      print(_element) ;
    }

    if ( !_lastCheck_viewing ) {
      if (viewing) {
        _notifyEnter();
      }
    }
    else {
      if (!viewing) {
        _notifyLeave() ;
      }
    }

    _lastCheck_viewing = viewing;
  }

  void _notifyEnter() {
    try {
      if (_onEnterViewport != null) _onEnterViewport(_element) ;
    }
    catch (e,s) {
      print(e);
      print(s);
    }

    if ( !_periodicTracking && _onLeaveViewPort == null ) _trackElementInViewport.untrack(_element) ;
  }

  void _notifyLeave() {
    try {
      if (_onLeaveViewPort != null) _onLeaveViewPort(_element) ;
    }
    catch (e,s) {
      print(e);
      print(s);
    }

    if ( !_periodicTracking ) _trackElementInViewport.untrack(_element) ;
  }

}

typedef OnElementEvent = void Function(Element element) ;

class TrackElementInViewport {

  Duration _checkInterval ;

  TrackElementInViewport( [Duration checkInterval] ) {
    _checkInterval = checkInterval ?? Duration(milliseconds: 250) ;
  }

  final Map<Element,_ElementTrack> _elements = {} ;

  bool track( Element element , { bool periodicTracking, OnElementEvent onEnterViewport , OnElementEvent onLeaveViewPort }) {
    if (element == null) return null ;
    if ( _elements.containsKey(element) ) return null ;

    if (onEnterViewport == null && onLeaveViewPort == null ) return null ;
    periodicTracking ??= false ;

    var elementTrack = _ElementTrack(this, element, periodicTracking, onEnterViewport, onLeaveViewPort);
    _elements[element] = elementTrack ;

    var viewing = elementTrack._initialize() ;

    _scheduleCheck() ;

    return viewing ;
  }

  bool untrack( Element elem ) {
    var removed = _elements.remove(elem) ;

    if (_elements.isEmpty) {
      _timer.cancel();
      _timer = null ;
    }

    return removed != null ? removed._lastCheck_viewing : null ;
  }

  void checkElements() {
    if ( _elements.isEmpty ) return ;

    for ( var elem in List.from(_elements.values) ) {
      elem.check() ;
    }
  }

  Timer _timer ;

  void _scheduleCheck() {
    _timer ??= Timer.periodic( _checkInterval, _checkFromTimer );
  }

  void _checkFromTimer(Timer timer) {
    if (_elements.isEmpty) {
      _timer.cancel();
      _timer = null ;
    }
    else {
      checkElements();
    }
  }

}
