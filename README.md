# dom_tools

DOM rich elements and tools

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
