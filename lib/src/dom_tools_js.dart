
import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'dart:js_util';

import 'dom_tools_base.dart';

////////////////////////////////////////////////////////////////////////////////

Map<String, Future<bool> > _addedJavaScriptCodes = {} ;

Future<bool> addJavaScriptCode(String scriptCode) async {
  var prevCall = _addedJavaScriptCodes[scriptCode] ;
  if ( prevCall != null ) return prevCall ;

  Future<bool> future ;

  try {
    HeadElement head = querySelector('head') ;

    var script = ScriptElement()
      ..type = 'text/javascript'
      ..text = scriptCode
    ;

    head.children.add(script);

    future = Future.value(true) ;
  }
  catch (e,s) {
    print(e);
    print(s);
    future = Future.value(false) ;
  }

  _addedJavaScriptsSources[scriptCode] = future ;

  return future ;
}

////////////////////////////////////////////////////////////////////////////////


Map<String, Future<bool> > _addedJavaScriptsSources = {} ;

Future<bool> addJavaScriptSource(String scriptSource, [bool addToBody]) async {
  var scriptInDom = getScriptElementBySrc(scriptSource);

  var prevCall = _addedJavaScriptsSources[scriptSource] ;

  if ( prevCall != null ) {
    if (scriptInDom != null) {
      return prevCall ;
    }
    else {
      var removed = _addedJavaScriptsSources.remove(scriptSource) ;
      assert(removed != null) ;
    }
  }

  if (scriptInDom != null) {
    return true ;
  }

  addToBody ??= false ;

  print('ADDING <SCRIPT>: $scriptSource > into body: $addToBody') ;

  Element parent ;
  if ( addToBody ) {
    parent = querySelector('body') ;
  }
  else {
    parent = querySelector('head') ;
  }

  var script = ScriptElement()
    ..type = 'text/javascript'
    ..src = scriptSource
  ;

  var completer = Completer<bool>() ;

  script.onLoad.listen( (e) {
    completer.complete(true) ;
  } , onError: (e) {
    completer.complete(false) ;
  } ) ;

  parent.children.add(script);

  var call = completer.future ;
  _addedJavaScriptsSources[scriptSource] = call ;

  return call ;
}


////////////////////////////////////////////////////////////////////////////////

Future<bool> addJSFunction(String name, List<String> parameters, String body) {
  if (name == null || name.isEmpty) throw ArgumentError('Empty name') ;
  parameters ??= [] ;
  body ??= '' ;

  var args = parameters.join(' , ') ;
  var code = '$name = function( $args ) {\n$body\n}' ;

  return addJavaScriptCode(code) ;
}

////////////////////////////////////////////////////////////////////////////////


dynamic evalJS(String scriptCode) {
  context.callMethod('eval', [scriptCode]);
}

typedef MappedFunction = void Function(dynamic o) ;

void mapJSFunction(String jsFunctionName, MappedFunction f) {

  var setterName = '__mapJSFunction__set_$jsFunctionName' ;

  var scriptCode = '''
  
    $jsFunctionName = function(o) {};
  
    function $setterName(f) {
      console.log('mapJSFunction: $jsFunctionName(o)');
      $jsFunctionName = f ;
    }
    
  ''';

  addJavaScriptCode(scriptCode) ;

  var setter = context[setterName] as JsFunction ;

  setter.apply([ (dynamic o) => f(o) ]) ;

}

dynamic callObjectMethod(dynamic o, String method, [List args]) {
  return callMethod(o, method, args);
}

dynamic callFunction(String method, [List args]) {
  return context.callMethod(method, args);
}

////////////////////////////////////////////////////////////////////////////////

void disableScrolling() {
  var scriptCode = '''
  
  if ( window.UI__BlcokScroll__ == null ) {
    UI__BlcokScroll__ = function(event) {
      window.scrollTo( 0, 0 );
      event.preventDefault();
    }  
  }
  
  ''';

  addJavaScriptCode(scriptCode) ;

  evalJS('''
    window.addEventListener('scroll', UI__BlcokScroll__, { passive: false });
  ''') ;


}

void enableScrolling() {
  evalJS('''
    if ( window.UI__BlcokScroll__ != null ) {
      window.removeEventListener('scroll', UI__BlcokScroll__);  
    }
  ''') ;
}

void disableZooming() {

  var scriptCode = '''
  
  if ( window.UIConsole == null ) {
    UIConsole = function(o) {
      console.log(o);
    }  
  }
  
  var _blockZoom_lastTime = new Date() ;
  
  var blockZoom = function(event) {
    var s = event.scale ;
    
    if (s > 1 || s < 1) {
      var now = new Date() ;
      var elapsedTime = now.getTime() - _blockZoom_lastTime.getTime() ;
      
      if (elapsedTime > 1000) {
        UIConsole('Block event['+ event.type +'].scale:'+ s) ;
      }
      
      _blockZoom_lastTime = now ;
      event.preventDefault();
    }
  }
  
  var block = function(types) {
    UIConsole('Block scale event of types: '+types) ;
    
    for (var i = 0; i < types.length; i++) {
      var t = types[i];
      window.addEventListener(t, blockZoom, { passive: false } );
    }
  }
  
  block( ["gesturestart", "gestureupdate", "gestureend", "touchenter", "touchstart", "touchmove", "touchend", "touchleave"]);
  
  ''';

  addJavaScriptCode(scriptCode) ;

}
