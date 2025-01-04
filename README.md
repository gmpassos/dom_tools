# dom_tools

[![pub package](https://img.shields.io/pub/v/dom_tools.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/dom_tools)
[![Dart CI](https://github.com/gmpassos/dom_tools/actions/workflows/dart.yml/badge.svg?branch=master)](https://github.com/gmpassos/dom_tools/actions/workflows/dart.yml)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/dom_tools?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/dom_tools/latest?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/dom_tools?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/dom_tools?logo=github&logoColor=white)](https://github.com/gmpassos/dom_tools/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/dom_tools?logo=github&logoColor=white)](https://github.com/gmpassos/dom_tools)
[![License](https://img.shields.io/github/license/gmpassos/dom_tools?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/dom_tools/blob/master/LICENSE)

DOM rich elements and tools for CSS, JavaScript, Element Tracking, DOM Manipulation, Storage, Dialog and more. 

### Package `web`

Starting with version `3.0.0`, the `dom_tools` package relies on the [web](https://pub.dev/packages/web) package,
replacing the deprecated `dart:html` library (deprecated as of Dart `3.7.0+`).

## Usage

A simple usage example:

```dart
import 'dart:html';
import 'package:dom_tools/dom_tools.dart';

void main() {

  var imgSrc = 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png' ;

  // Example of an image that only loads when visualized in viewport:

  var tracker = TrackElementInViewport() ;
  var imageElement = ImageElement() ;

  tracker.track(imageElement, onEnterViewport: (elem) {
    imageElement.src = imgSrc ;
  });

  document.body.children.add( imageElement ) ;

  Future.delayed( Duration(seconds: 10) , (){
    var img = getElementBySRC('img', imgSrc) ;
    if (img == null) {
      window.alert('After 10s the image is not visible in viewport yet') ;
    }
    else {
      window.alert('After 10s the image was visible in viewport.') ;
    }
  });
  
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/dom_tools/issues

## Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

Dart free & open-source [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).
