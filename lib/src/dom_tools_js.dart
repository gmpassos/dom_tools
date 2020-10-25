import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:js_util';

import 'dom_tools_base.dart';

Map<String, Future<bool>> _addedJavaScriptCodes = {};

/// Adds a JavaScript code ([scriptCode]) into DOM.
Future<bool> addJavaScriptCode(String scriptCode) async {
  var prevCall = _addedJavaScriptCodes[scriptCode];
  if (prevCall != null) return prevCall;

  Future<bool> future;

  try {
    HeadElement head = querySelector('head');

    var script = ScriptElement()
      ..type = 'text/javascript'
      ..text = scriptCode;

    head.children.add(script);

    future = Future.value(true);
  } catch (e, s) {
    print(e);
    print(s);
    future = Future.value(false);
  }

  _addedJavaScriptCodes[scriptCode] = future;

  return future;
}

Map<String, Future<bool>> _addedJavaScriptsSources = {};

/// Adds a JavaScript path ([scriptSource]] into DOM.
///
/// [addToBody] If [true] adds into `body` node instead of `head` node.
/// [async] If true, the script will be executed asynchronously as soon as it is available,
/// and not when the page has finished parsing.
Future<bool> addJavaScriptSource(String scriptSource,
    {bool addToBody, bool async}) async {
  var scriptInDom = getScriptElementBySRC(scriptSource);

  var prevCall = _addedJavaScriptsSources[scriptSource];

  if (prevCall != null) {
    if (scriptInDom != null) {
      return prevCall;
    } else {
      var removed = _addedJavaScriptsSources.remove(scriptSource);
      assert(removed != null);
    }
  }

  if (scriptInDom != null) {
    return true;
  }

  addToBody ??= false;
  async ??= false;

  print('ADDING <SCRIPT>: $scriptSource > into body: $addToBody');

  Element parent;
  if (addToBody) {
    parent = querySelector('body');
  } else {
    parent = querySelector('head');
  }

  var script = ScriptElement()
    ..type = 'text/javascript'
    ..src = scriptSource;

  if (async) {
    script.async = true;
  }

  var completer = Completer<bool>();

  script.onLoad.listen((e) {
    completer.complete(true);
  }, onError: (e) {
    completer.complete(false);
  });

  parent.children.add(script);

  var call = completer.future;
  _addedJavaScriptsSources[scriptSource] = call;

  return call;
}

/// Adds a JavaScript function into DOM.
///
/// [name] Name of the function.
/// [parameters] Parameters names of the function.
/// [body] Content of the function.
Future<bool> addJSFunction(String name, List<String> parameters, String body) {
  if (name == null || name.isEmpty) throw ArgumentError('Empty name');
  parameters ??= [];
  body ??= '';

  var args = parameters.join(' , ');
  var code = '$name = function( $args ) {\n$body\n}';

  return addJavaScriptCode(code);
}

/// Call `eval()` with the content of [scriptCode] and returns the result.
dynamic evalJS(String scriptCode) {
  var res = context.callMethod('eval', [scriptCode]);
  return res;
}

typedef MappedFunction = dynamic Function(dynamic o);

/// Maps a JavaScript function to a Dart function.
///
/// [jsFunctionName] Name of the functin.
/// [f] Dart function to map.
void mapJSFunction(String jsFunctionName, MappedFunction f) {
  context[jsFunctionName] = f;
}

/// Calls JavaScript a [method] in object [o] with [args].
dynamic callJSObjectMethod(dynamic o, String method, [List args]) {
  return callMethod(o, method, args);
}

/// Calls JavaScript a function [method] with [args].
dynamic callJSFunction(String method, [List args]) {
  return context.callMethod(method, args);
}

/// Returns the keys of [JsObject] [o].
List<String> jsObjectKeys(JsObject o) {
  var keys = context['Object'].callMethod('keys', [o]);
  return jsArrayToList(keys).map((e) => '$e').toList();
}

/// Converts [o] to Dart primitives or collections.
///
/// [o] Can be any primitive value, a [JsArray] or a [JsObject]).
dynamic jsToDart(dynamic o) {
  if (o == null) return null;

  if (o is String) return o;
  if (o is num) return o;
  if (o is bool) return o;

  if (o is JsArray) return jsArrayToList(o);
  if (o is JsObject) return jsObjectToMap(o);

  if (o is List) return o.map(jsToDart).toList();
  if (o is Map) {
    return o.map((key, value) => MapEntry(jsToDart(key), jsToDart(value)));
  }

  return o;
}

/// Converts a [JsArray] [a] to a [List].
/// Also converts values using [jsToDart].
List jsArrayToList(JsArray a) {
  if (a == null) return null;
  return a.map(jsToDart).toList();
}

/// Converts a [JsObject] [o] to a [Map].
/// Also converts keys and values using [jsToDart].
Map jsObjectToMap(JsObject o) {
  if (o == null) return null;

  var keys = jsObjectKeys(o);
  if (keys == null || keys.isEmpty) return {};

  return Map.fromEntries(keys.map((k) {
    var v = o[k];
    return MapEntry(k, jsToDart(v));
  }));
}

String _JS_FUNCTION_BLOCK_SCROLLING = '__JS__BlockScroll__';

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

  addJavaScriptCode(scriptCode);

  evalJS('''
    window.addEventListener('scroll', $_JS_FUNCTION_BLOCK_SCROLLING, { passive: false });
  ''');
}

/// Enables scrolling in browser.
void enableScrolling() {
  evalJS('''
    if ( window.$_JS_FUNCTION_BLOCK_SCROLLING != null ) {
      window.removeEventListener('scroll', $_JS_FUNCTION_BLOCK_SCROLLING);  
    }
  ''');
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

  addJavaScriptCode(scriptCode);
}
