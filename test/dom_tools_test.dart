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

    test('DataStorage[session]', () async {
      var dataStorage = DataStorage('t1', DataStorageType.session);

      var state1 = dataStorage.createState("s1");

      expect(state1.isLoaded, isTrue);

      expect(state1.get("a"), isNull);
      expect(await state1.getAsync("a"), isNull);

      state1.set('a', 123);

      expect(await state1.getAsync("a"), equals(123));
      expect(state1.get("a"), equals(123));

      print('state1.a: ${state1.get("a")}');

      state1.set('b', {'x': 10, 'y': 'Y'});

      expect(await state1.getAsync("b"), equals({'x': 10, 'y': 'Y'}));
      expect(state1.get("b"), equals({'x': 10, 'y': 'Y'}));
    });

    test('DataStorage[persistent]', () async {
      var dataStorage = DataStorage('t1', DataStorageType.persistent);

      var state1 = dataStorage.createState("s1");

      expect(state1.isLoaded, isFalse);

      await state1.waitLoaded();

      expect(state1.isLoaded, isTrue);

      expect(state1.get("a"), isNull);
      expect(await state1.getAsync("a"), isNull);

      state1.set('a', 123);

      expect(await state1.getAsync("a"), equals(123));
      expect(state1.get("a"), equals(123));

      print('state1.a: ${state1.get("a")}');

      state1.set('b', {'x': 10, 'y': 'Y'});

      expect(await state1.getAsync("b"), equals({'x': 10, 'y': 'Y'}));
      expect(state1.get("b"), equals({'x': 10, 'y': 'Y'}));
    });
  });
}
