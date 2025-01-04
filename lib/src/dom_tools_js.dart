import 'dart:async';
import 'dart:js_interop_unsafe';

import 'package:js_interop_utils/js_interop_utils.dart';
import 'package:web/web.dart';

import 'dom_tools_base.dart';

Map<String, Future<bool>> _addedJavaScriptCodes = {};

/// Adds a JavaScript code ([scriptCode]) into DOM.
Future<bool> addJavaScriptCode(String scriptCode) async {
  var prevCall = _addedJavaScriptCodes[scriptCode];
  if (prevCall != null) return prevCall;

  Future<bool> future;

  try {
    var head = document.querySelector('head')!;

    var script = HTMLScriptElement()
      ..type = 'text/javascript'
      ..text = scriptCode;

    head.appendChild(script);

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
    {bool addToBody = false, bool async = false}) async {
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

  print('ADDING <SCRIPT>: $scriptSource > into body: $addToBody');

  Element parent;
  if (addToBody) {
    parent = document.querySelector('body')!;
  } else {
    parent = document.querySelector('head')!;
  }

  var script = HTMLScriptElement()
    ..type = 'text/javascript'
    // ignore: unsafe_html
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

  parent.appendChild(script);

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
  if (name.isEmpty) throw ArgumentError('Empty name');

  var args = parameters.join(' , ');
  var code = '$name = function( $args ) {\n$body\n}';

  return addJavaScriptCode(code);
}

/// Call `eval()` with the content of [scriptCode] and returns the result.
dynamic evalJS(String scriptCode) =>
    globalContext.callMethod('eval'.toJS, scriptCode.toJS).dartify();

typedef MappedFunction = dynamic Function(dynamic o);

/// Maps a JavaScript function to a Dart function.
///
/// [jsFunctionName] Name of the function.
/// [f] Dart function to map.
void mapJSFunction(String jsFunctionName, MappedFunction f) {
  globalContext[jsFunctionName] = (JSAny a) {
    Object? r = f(a.dartify());
    return r.jsify();
  }.toJS;
}

/// Calls JavaScript a [method] in object [o] with [args].
dynamic callJSObjectMethod(JSObject o, String method, [List<Object?>? args]) {
  var argsList = args?.map((e) => e.jsify()).toList() ?? [];
  return o.callMethodVarArgs(method.toJS, argsList).dartify();
}

/// Calls JavaScript a function [method] with [args].
dynamic callJSFunction(String method, [List<Object?>? args]) {
  var argsList = args?.map((e) => e.jsify()).toList();
  return globalContext.callMethodVarArgs(method.toJS, argsList).dartify();
}

/// Returns the keys of [JSObject] [o].
@Deprecated("Use `js_interop_utils` extension `keys`")
List<String> jsObjectKeys(JSObject o) {
  return o.keys.toList();
}

/// Converts [o] to Dart primitives or collections.
///
/// [o] Can be any primitive value, a [JsArray] or a [JSObject]).
@Deprecated("Use `js_interop_utils` extension method `objectDartify`")
Object? jsToDart(Object? o) {
  return o?.objectDartify();
}

/// Converts a [JSArray] [a] to a [List].
/// Also converts values using [jsToDart].
@Deprecated("Use `js_interop_utils` extension method `toList`")
List? jsArrayToList(JSArray? a) {
  return a?.toList();
}

/// Converts a [JSObject] [o] to a [Map].
/// Also converts keys and values using [jsToDart].
@Deprecated("Use `js_interop_utils` extension method `toMap`")
Map? jsObjectToMap(JSObject? o) {
  return o?.toMap();
}

String _jsFunctionBlockScrolling = '__JS__BlockScroll__';

/// Disables scrolling in browser.
void disableScrolling() {
  var scriptCode = '''
  
  if ( window.$_jsFunctionBlockScrolling == null ) {
    $_jsFunctionBlockScrolling = function(event) {
      window.scrollTo( 0, 0 );
      event.preventDefault();
    }  
  }
  
  ''';

  addJavaScriptCode(scriptCode);

  evalJS('''
    window.addEventListener('scroll', $_jsFunctionBlockScrolling, { passive: false });
  ''');
}

/// Enables scrolling in browser.
void enableScrolling() {
  evalJS('''
    if ( window.$_jsFunctionBlockScrolling != null ) {
      window.removeEventListener('scroll', $_jsFunctionBlockScrolling);  
    }
  ''');
}

bool _disableZooming = false;

/// Disables browser zooming.
void disableZooming() {
  if (_disableZooming) return;
  _disableZooming = true;

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

bool _disableDoubleTapZoom = false;

/// Disables browser double clicks/tap.
/// - This calls [Event.preventDefault] for every double click/tap event.
///   - This is useful to prevent double tap zooming.
void disableDoubleClicks() {
  if (_disableDoubleTapZoom) return;
  _disableDoubleTapZoom = true;

  document.addEventListener(
    'dblclick',
    (Event event) {
      event.preventDefault();
    }.toJS,
    true.toJS,
  );
}
