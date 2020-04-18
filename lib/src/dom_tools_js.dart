
import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'dart:js_util';


Map<String,bool> _addedJScripts = {} ;

bool addJScript(String scriptCode) {
  if ( _addedJScripts.containsKey(scriptCode) ) return false ;
  _addedJScripts[scriptCode] = true ;

  /*
  print("addJScript: <<<");
  print(scriptCode) ;
  print(">>>") ;
  */

  HeadElement head = querySelector('head') ;

  var script = ScriptElement()
    ..type = 'text/javascript'
    ..text = scriptCode
  ;

  head.children.add(script);

  return true ;
}

Map<String, Future<bool> > _addedJScriptsSources = {} ;

Future<bool> addJScriptSource(String scriptSource) async {
  var prevCall = _addedJScriptsSources[scriptSource] ;
  if ( prevCall != null ) return prevCall ;

  /*
  print("addJScriptSource: <<<");
  print(scriptCode) ;
  print(">>>") ;
  */

  HeadElement head = querySelector('head') ;

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

  head.children.add(script);

  var call = completer.future ;
  _addedJScriptsSources[scriptSource] = call ;

  return call ;
}

void evalJS(String scriptCode) {
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

  addJScript(scriptCode) ;

  var setter = context[setterName] as JsFunction ;

  setter.apply([ (dynamic o) => f(o) ]) ;

}

dynamic callObjectMethod(dynamic o, String method, [List args]) {
  return callMethod(o, method, args);
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

  addJScript(scriptCode) ;

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

  addJScript(scriptCode) ;

}
