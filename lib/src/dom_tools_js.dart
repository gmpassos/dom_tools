
import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'dart:js_util';

import 'dom_tools_base.dart';

Map<String, Future<bool> > _addedJavaScriptCodes = {} ;

/// Adds a JavaScript code ([scriptCode]) into DOM.
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


Map<String, Future<bool> > _addedJavaScriptsSources = {} ;

/// Adds a JavaScript path ([scriptSource]] into DOM.
///
/// [addToBody] If [true] adds into `body` node instead of `head` node.
Future<bool> addJavaScriptSource(String scriptSource, [bool addToBody]) async {
  var scriptInDom = getScriptElementBySRC(scriptSource);

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

/// Adds a JavaScript function into DOM.
///
/// [name] Name of the function.
/// [parameters] Parameters names of the function.
/// [body] Content of the function.
Future<bool> addJSFunction(String name, List<String> parameters, String body) {
  if (name == null || name.isEmpty) throw ArgumentError('Empty name') ;
  parameters ??= [] ;
  body ??= '' ;

  var args = parameters.join(' , ') ;
  var code = '$name = function( $args ) {\n$body\n}' ;

  return addJavaScriptCode(code) ;
}

/// Call `eval()` with the content of [scriptCode] and returns the result.
dynamic evalJS(String scriptCode) {
  context.callMethod('eval', [scriptCode]);
}

typedef MappedFunction = void Function(dynamic o) ;

/// Maps a JavaScript function to a Dart function.
///
/// [jsFunctionName] Name of the functin.
/// [f] Dart function to map.
void mapJSFunction(String jsFunctionName, MappedFunction f) {
  context[jsFunctionName] = f ;
}

/// Calls JavaScript a [method] in object [o] with [args].
dynamic callObjectMethod(dynamic o, String method, [List args]) {
  return callMethod(o, method, args);
}

/// Calls JavaScript a function [method] with [args].
dynamic callFunction(String method, [List args]) {
  return context.callMethod(method, args);
}

String _JS_FUNCTION_BLOCK_SCROLLING = 'UI__BlockScroll__' ;

/// Disables scrolling in browser.
void disableScrolling() {
  var scriptCode = '''
  
  if ( window.$_JS_FUNCTION_BLOCK_SCROLLING == null ) {
    $_JS_FUNCTION_BLOCK_SCROLLING = function(event) {
      window.scrollTo( 0, 0 );
      event.preventDefault();
    }  
  }
  
  ''';

  addJavaScriptCode(scriptCode) ;

  evalJS('''
    window.addEventListener('scroll', $_JS_FUNCTION_BLOCK_SCROLLING, { passive: false });
  ''') ;

}



/// Enables scrolling in browser.
void enableScrolling() {
  evalJS('''
    if ( window.$_JS_FUNCTION_BLOCK_SCROLLING != null ) {
      window.removeEventListener('scroll', $_JS_FUNCTION_BLOCK_SCROLLING);  
    }
  ''') ;
}

/// Disables zooming in browser.
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
