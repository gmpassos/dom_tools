@TestOn('browser')
import 'dart:html';

import 'package:dom_tools/dom_tools.dart';
import 'package:test/test.dart';

void main() {
  group('Browser tests', () {
    setUp(() {});

    test('evalJS', () {
      var c = evalJS(' var a = 2 ; var b = 3 ; var c = a * b ; c ');
      expect(c, equals(6));
    });

    test('touchEventToMouseEvent', () {
      var div = DivElement();

      Touch? touch;

      try {
        touch = Touch({
          'identifier': 123,
          'target': div,
          'screenX': 200,
          'screenY': 100,
          'clientX': 100,
          'clientY': 50,
        });
      } catch (e) {
        print(e);
      }

      if (touch == null) {
        print('** Touch creation not supported. Aborting test!');
        return;
      }

      var touchEvent = TouchEvent('touchstart', {
        'touches': [touch],
        'ctrlKey': false,
        'shiftKey': true,
        'altKey': false,
        'metaKey': false,
      });

      var mouseEvent = touchEventToMouseEvent(touchEvent)!;
      expect(mouseEvent, isNotNull);
      expect(mouseEvent.ctrlKey, isFalse);
      expect(mouseEvent.shiftKey, isTrue);
      expect(mouseEvent.altKey, isFalse);
      expect(mouseEvent.metaKey, isFalse);
    });
  });
}
