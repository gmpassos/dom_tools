# dom_tools

[![pub package](https://img.shields.io/pub/v/dom_tools.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/dom_tools)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/dom_tools/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/dom_tools/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/dom_tools?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/dom_tools/latest?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/dom_tools?logo=git&logoColor=white)](https://github.com/gmpassos/dom_tools/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/dom_tools?logo=github&logoColor=white)](https://github.com/gmpassos/dom_tools/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/dom_tools?logo=github&logoColor=white)](https://github.com/gmpassos/dom_tools)
[![License](https://img.shields.io/github/license/gmpassos/dom_tools?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/dom_tools/blob/master/LICENSE)
[![Funding](https://img.shields.io/badge/Donate-yellow?labelColor=666666&style=plastic&logo=liberapay)](https://liberapay.com/gmpassos/donate)
[![Funding](https://img.shields.io/liberapay/patrons/gmpassos.svg?logo=liberapay)](https://liberapay.com/gmpassos/donate)


DOM rich elements and tools for CSS, JavaScript, Element Tracking, DOM Manipulation, Storage, Dialog and more. 

## Usage

A simple usage example:

```dart
import 'package:dom_tools/dom_tools.dart';

main() {

  // Example of an image that only loads when visualized in viewport: 

  TrackElementInViewport tracker = TrackElementInViewport() ;
  var imageElement = ImageElement() ;
  
  tracker.track(imageElement, onEnterViewport: (elem) {
    imageElement.src = 'http://api.host/path/to/image' ;
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
