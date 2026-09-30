@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dom_tools/dom_tools_kit.dart';
import 'package:test/test.dart';

/// Integration tests (real browser) for `dom_data_storage.dart`,
/// `dom_tools_css.dart`, `dom_tools_file.dart` and `dom_tools_dialog.dart`.

var _seq = 0;

/// A unique id, valid as a [DataStorage]/[State] key name.
String _uid(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

/// Polls [check] until it returns `true`, or fails after [timeout].
Future<void> _until(
  FutureOr<bool> Function() check, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (!await check()) {
    if (DateTime.now().isAfter(end)) {
      fail('Timeout waiting for condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void _removeSessionKeys(String prefix) {
  for (final k in window.sessionStorage.keys.toList()) {
    if (k.startsWith(prefix)) window.sessionStorage.removeItem(k);
  }
}

/// Appends [css] in a new `style` element, removed after the test.
HTMLStyleElement _addStyle(String css) {
  final style = HTMLStyleElement()..textContent = css;
  document.head!.appendChild(style);
  addTearDown(() => style.remove());
  return style;
}

HTMLDivElement _attached() {
  final div = HTMLDivElement();
  document.body!.appendChild(div);
  addTearDown(() => div.remove());
  return div;
}

/// A [w]x[h] canvas filled with a color.
HTMLCanvasElement _canvas(int w, int h) {
  final canvas = HTMLCanvasElement()
    ..width = w
    ..height = h;
  final ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
  ctx.fillStyle = 'rgb(200, 10, 10)'.toJS;
  ctx.fillRect(0, 0, w, h);
  return canvas;
}

File _file(List<int> bytes, String name, [String type = '']) => File(
  <JSAny>[Uint8List.fromList(bytes).toJS].toJS,
  name,
  FilePropertyBag(type: type),
);

/// A real JPEG [File] (encoded by the browser).
File _jpegFile(String name) {
  final dataUrl = _canvas(4, 2).toDataURL('image/jpeg');
  final bytes = base64.decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
  return _file(bytes, name, 'image/jpeg');
}

HTMLInputElement _fileInput(List<File> files) {
  final transfer = DataTransfer();
  for (final f in files) {
    transfer.items.add(f);
  }
  return HTMLInputElement()
    ..type = 'file'
    ..files = transfer.files;
}

@JS('Object.prototype.toString.call')
external JSString _jsToString(JSAny? o);

void main() {
  group('DataStorage (session)', () {
    late String id;

    setUp(() {
      id = _uid('ds');
      addTearDown(() => _removeSessionKeys('$id/'));
    });

    test('State set/get/remove persists to sessionStorage', () {
      final storage = DataStorage(id);
      expect(storage.storageType, equals(DataStorageType.session));

      final state = State(storage, 'st');
      expect(state.isLoaded, isTrue);
      expect(state.storageRootKey, equals('$id/st/'));
      expect(state.getStorageKey('k'), equals('$id/st/k'));

      expect(state.set('k', 'v1'), isNull);
      expect(state.set('k', 'v2'), equals('v1'));
      expect(state.get<String>('k'), equals('v2'));
      expect(state.keys, equals(['k']));

      expect(window.sessionStorage.getItem('$id/st/k/value'), equals('"v2"'));
      expect(window.sessionStorage.getItem('$id/st/k/time'), isNotNull);

      expect(state.remove('k'), equals('v2'));
      expect(state.get<String>('k'), isNull);
      expect(window.sessionStorage.getItem('$id/st/k/value'), isNull);
      expect(window.sessionStorage.getItem('$id/st/k/time'), isNull);
    });

    test('values are loaded by a new State with the same storage id', () async {
      final state1 = State(DataStorage(id), 'st');
      state1.set('a', 1);
      state1.set('b', {'x': true});
      state1.set('c', [1, 2]);

      final state2 = State(DataStorage(id), 'st');
      expect(await state2.waitLoaded(), isTrue);
      expect(state2.get<int>('a'), equals(1));
      expect(state2.get<Map>('b'), equals({'x': true}));
      // Regression: `get<List<int>>` threw a `TypeError` (`parseListOf`
      // returns a `List<int?>`).
      expect(state2.get<List<int>>('c'), equals([1, 2]));
      expect((await state2.getKeysAsync()).toSet(), equals({'a', 'b', 'c'}));
    });

    // The code changed in this upgrade: `DataStorage._getStorageValue` awaits
    // inside `try`, so a failed read is logged and yields `null`.
    test(
      'a value that fails to load is skipped (no unhandled error)',
      () async {
        final now = DateTime.now().millisecondsSinceEpoch;
        window.sessionStorage
          ..setItem('$id/st/good/time', '$now')
          ..setItem('$id/st/good/value', '"ok"')
          ..setItem('$id/st/bad/time', '$now')
          ..setItem('$id/st/bad/value', '{not json');

        final state = State(DataStorage(id), 'st');
        expect(await state.waitLoaded(), isTrue);
        expect(state.get<String>('good'), equals('ok'));
        expect(state.keys, isNot(contains('bad')));
        expect(await state.getAsync<String>('bad'), isNull);
      },
    );

    test('typed getters cast stored values', () async {
      final state = State(DataStorage(id), 'st');
      state.set('i', '42');
      state.set('d', '1.5');
      state.set('n', '7');
      state.set('b', 'true');
      state.set('s', 10);
      state.set('li', ['1', '2']);
      state.set('ld', ['1.5', '2']);
      state.set('ln', ['1', '2.5']);

      expect(await state.getAsync<int>('i'), equals(42));
      expect(await state.getAsync<double>('d'), equals(1.5));
      expect(await state.getAsync<num>('n'), equals(7));
      expect(await state.getAsync<bool>('b'), isTrue);
      expect(await state.getAsync<String>('s'), equals('10'));
      expect(state.get<List<int>>('li'), equals([1, 2]));
      expect(state.get<List<double>>('ld'), equals([1.5, 2.0]));
      expect(state.get<List<num>>('ln'), equals([1, 2.5]));
      // Not castable:
      expect(state.get<Uint8List>('i'), isNull);
    });

    test('defaults', () async {
      final state = State(DataStorage(id), 'st');

      expect(state.getOrDefault<int>('x', 5), equals(5));
      expect(state.keys, isEmpty);
      expect(await state.getOrDefaultAsync<int>('x', 6), equals(6));

      expect(state.getOrSetDefault<int>('x', 7), equals(7));
      expect(state.getOrSetDefault<int>('x', 8), equals(7));
      expect(await state.getOrSetDefaultAsync<int>('y', 9), equals(9));
      expect(window.sessionStorage.getItem('$id/st/y/value'), equals('9'));

      expect(state.setIfAbsent('z', 1), isTrue);
      expect(state.setIfAbsent('z', 2), isFalse);
      expect(state.get<int>('z'), equals(1));
      expect(state.getOrDefault<int>('z', 99), equals(1));
    });

    test('listen / listenAll / listenKey', () {
      final state = State(DataStorage(id), 'st');
      final ops = <String>[];
      final all = <String>[];
      final keyValues = <Object?>[];

      state
          .listen(StateOperation.set, (op, s, k, v) => ops.add('$k=$v'))
          .listenAll((op, s, k, v) => all.add('${op.name}:$k'))
          .listenKey('a', keyValues.add);

      state.set('a', 1);
      state.set('b', 2);
      state.set('a', 3);

      expect(ops, equals(['a=1', 'b=2', 'a=3']));
      // Regression: `_fireEvent` added the `all` listeners into the registered
      // `set` listeners list on every event, so they were called more and more
      // times (1, 2, 3, ...).
      expect(all, equals(['set:a', 'set:b', 'set:a']));
      expect(keyValues, equals([1, 3]));

      // Listener errors are caught:
      state.listenKey('b', (_) => throw StateError('listener'));
      state.set('b', 4);
      expect(ops.last, equals('b=4'));
    });

    test('fireLoadedKeysEvents fires `load` events', () async {
      State(DataStorage(id), 'st').set('a', 1);

      final state = State(DataStorage(id), 'st');
      await state.waitLoaded();
      final loaded = <String>[];
      state.listen(StateOperation.load, (op, s, k, v) => loaded.add('$k=$v'));
      expect(state.fireLoadedKeysEvents(), same(state));
      expect(loaded, equals(['a=1']));
    });

    test('states registry', () {
      final storage = DataStorage(id);
      final s1 = storage.createState('one');
      expect(storage.createState('one'), same(s1));
      expect(storage.getState('one'), same(s1));
      expect(storage.containsState('one'), isTrue);
      expect(storage.containsState('two'), isFalse);
      expect(storage.getStatesNames(), equals(['one']));
      expect(storage.getStates(), equals([s1]));

      expect(() => State(storage, 'one'), throwsStateError);
      expect(storage.registerState(s1), isFalse);

      expect(storage.unregisterState('one'), same(s1));
      expect(storage.unregisterState('one'), isNull);
      expect(storage.getStates(), isEmpty);
    });

    test('invalid names', () {
      expect(DataStorage.isValidKeyName('ok_name'), isTrue);
      expect(DataStorage.isValidKeyName('a/b'), isFalse);
      expect(DataStorage.isValidKeyName('a b'), isFalse);
      expect(() => DataStorage('a/b'), throwsArgumentError);
      expect(() => State(DataStorage(id), 'x y'), throwsArgumentError);
    });

    test('StorageValue', () {
      final v = StorageValue('x');
      expect(v.value, equals('x'));
      expect(v.storeTime, closeTo(DateTime.now().millisecondsSinceEpoch, 5000));
      final s = StorageValue.stored(123, [1]);
      expect(
        s.toJson(),
        equals({
          'storeTime': 123,
          'value': [1],
        }),
      );
      expect(s.toString(), equals('StorageValue{storeTime: 123, value: [1]}'));
    });
  });

  group('DataStorage (persistent)', () {
    test('set, reload and remove (IndexedDB or localStorage)', () async {
      final id = _uid('dp');
      final state = State(DataStorage(id, DataStorageType.persistent), 'st');
      expect(await state.waitLoaded(), isTrue);

      state.set('k', {'n': 1});
      state.set('s', 'text');

      // Writes are asynchronous: poll a fresh State until it sees them.
      await _until(() async {
        final s = State(DataStorage(id, DataStorageType.persistent), 'st');
        await s.waitLoaded();
        return s.get<Map>('k') != null && s.get<String>('s') == 'text';
      });

      state.remove('k');
      state.remove('s');

      await _until(() async {
        final s = State(DataStorage(id, DataStorageType.persistent), 'st');
        await s.waitLoaded();
        return s.keys.isEmpty;
      });
    });
  });

  group('IDBRequest.toFuture', () {
    test('success and error', () async {
      final name = _uid('idb');

      final open = window.indexedDB.open(name, 2);
      final db = await open.toFuture() as IDBDatabase;
      expect(db.version, equals(2));
      db.close();

      // Lower version than the existing one: `error` event.
      await expectLater(
        window.indexedDB.open(name, 1).toFuture(),
        throwsA(anything),
      );

      await window.indexedDB.deleteDatabase(name).toFuture();
    });
  });

  group('CSS', () {
    test('parseCSSLength', () {
      expect(parseCSSLength('10px'), equals(10));
      expect(parseCSSLength('1.5em'), equals(1.5));
      expect(parseCSSLength(' 50% '), equals(50));
      expect(parseCSSLength('10PX', unit: 'px'), equals(10));
      expect(parseCSSLength('10em', unit: 'px'), isNull);
      expect(parseCSSLength('10em', unit: 'px', def: 3), equals(3));
      expect(parseCSSLength('12', unit: 'px'), isNull);
      expect(
        parseCSSLength('12', unit: 'px', allowPXWithoutSuffix: true),
        equals(12),
      );
      expect(parseCSSLength('abc'), isNull);
      expect(parseCSSLength('', def: 1), equals(1));
      expect(parseCSSLength('   ', def: 2), equals(2));
    });

    test('addCSSCode adds once', () async {
      final cls = _uid('css_code');
      final code = '.$cls { color: rgb(1, 2, 3); }';

      expect(await addCSSCode(code), isTrue);
      expect(await addCSSCode(code), isTrue);

      final styles = document.head!
          .querySelectorAll('style')
          .toElements()
          .where((e) => e.textContent == code)
          .toList();
      expect(styles.length, equals(1));
      addTearDown(() => styles.first.remove());

      final div = _attached()..className = cls;
      expect(window.getComputedStyle(div).color, equals('rgb(1, 2, 3)'));
    });

    test('addCssSource loads a stylesheet link', () async {
      final cls = _uid('css_src');
      final href = 'data:text/css,.$cls%7Bcolor:rgb(4,5,6)%7D';

      expect(await addCssSource(href), isTrue);
      final link = getLinkElementByHREF(href, 'stylesheet');
      expect(link, isNotNull);
      addTearDown(() => link!.remove());

      // Already in DOM:
      expect(await addCssSource(href), isTrue);
      expect(
        document.head!
            .querySelectorAll('link')
            .toElements()
            .where((e) => e.getAttribute('href') == href),
        hasLength(1),
      );

      final div = _attached()..className = cls;
      expect(window.getComputedStyle(div).color, equals('rgb(4, 5, 6)'));
    });

    test('addCssSource with insertIndex', () async {
      final href = 'data:text/css,.${_uid('css_idx')}%7B%7D';
      expect(await addCssSource(href, insertIndex: 0), isTrue);
      final link = getLinkElementByHREF(href, 'stylesheet')!;
      addTearDown(() => link.remove());
      expect(document.head!.children.indexOf(link), equals(0));
    });

    // Regression: a failed load fires an `error` event, which was never
    // listened to, so the returned future never completed.
    test('addCssSource completes with false when the link fails', () async {
      final href = '/__missing_${_uid('css')}.css';
      final ok = await addCssSource(href).timeout(const Duration(seconds: 10));
      expect(ok, isFalse);
      getLinkElementByHREF(href, 'stylesheet')?.remove();
    });

    // Regression: the result copied the computed style's `cssText`, which is
    // empty in Chromium, so it had no properties at all.
    test('getComputedStyle', () {
      final cls = _uid('cs');
      _addStyle('.$cls { font-size: 17px; }');
      final parent = _attached();

      final style = getComputedStyle(
        parent: parent,
        classes: ' $cls  other ',
        style: 'color: rgb(7, 8, 9)',
      );
      expect(style.color, equals('rgb(7, 8, 9)'));
      expect(style.fontSize, equals('17px'));
      expect(style.display, equals('none'), reason: 'hidden by default');
      expect(parent.childElementCount, equals(0), reason: 'element removed');

      final element = HTMLDivElement()..hidden = false.toJS;
      final visible = getComputedStyle(element: element, hidden: false);
      expect(visible.display, equals('block'));
      expect(element.isConnected, isFalse);
      expect(element.hidden.dartify(), isFalse);
    });

    test('StyleColor', () {
      expect(const StyleColor(0xFF112233).toString(), equals('#112233'));
      // Regression: a color with alpha < 0x10 (or no alpha) lost digits,
      // e.g. `#2233`.
      expect(const StyleColor(0x00112233).toString(), equals('#112233'));
      expect(const StyleColor(0x0A000001).toString(), equals('#000001'));
      expect(const StyleColor.fromHex('abc').toString(), equals('#abc'));
      expect(const StyleColor.fromHex('#abc').toString(), equals('#abc'));
      expect(
        const StyleColor.fromRGBa('1,2,3,0.5').toString(),
        equals('rgba(1,2,3,0.5)'),
      );
      expect(
        const StyleColor.fromRGBa('rgba(1,2,3,1)').toString(),
        equals('rgba(1,2,3,1)'),
      );
    });

    test('TextStyle.cssValue', () {
      expect(const TextStyle().cssValue(), isEmpty);
      final css = const TextStyle(
        color: StyleColor.fromHex('fff'),
        backgroundColor: StyleColor.fromHex('000'),
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        borderColor: StyleColor.fromHex('f00'),
        borderRadius: '4px',
        padding: '2px',
      ).cssValue();
      expect(
        css,
        equals(
          'color: #fff ;background-color: #000 ;font-style: italic ;'
          'font-weight: bold ;border-color: #f00 ;border-radius: 4px;'
          'padding: 2px;',
        ),
      );
    });

    test('loadCSS / CSSThemeSet', () {
      final prefix = _uid('theme');
      addTearDown(
        () => document.head!
            .querySelector('#__dom_tools__dynamic_css__$prefix')
            ?.remove(),
      );

      final theme0 = <String, CSSValueBase>{
        'a': const TextStyle(color: StyleColor.fromHex('010203')),
      };
      final theme1 = <String, CSSValueBase>{
        'a': const TextStyle(color: StyleColor.fromHex('040506')),
      };
      final set = CSSThemeSet(prefix, [theme0, theme1]);
      expect(set.loadedTheme, isFalse);
      expect(set.getCSSTheme(1), same(theme1));
      expect(set.getCSSTheme(5), isNull);

      set.ensureThemeLoaded();
      expect(set.loadedTheme, isTrue);

      final div = _attached()..className = '${prefix}a';
      expect(window.getComputedStyle(div).color, equals('rgb(1, 2, 3)'));

      expect(set.loadTheme(1), equals(1));
      expect(window.getComputedStyle(div).color, equals('rgb(4, 5, 6)'));
      expect(
        document.head!
            .querySelectorAll('#__dom_tools__dynamic_css__$prefix')
            .length,
        equals(1),
      );

      expect(set.loadTheme(9), equals(0), reason: 'falls back to default');
    });

    // Regression: `loadCSS(prefix, null)` threw on `css!` (e.g. a
    // `CSSThemeSet` without themes).
    test('loadCSS with no CSS / CSSThemeSet without themes', () {
      final prefix = _uid('empty');
      loadCSS(prefix, null);
      final set = CSSThemeSet(prefix, []);
      expect(set.getCSSTheme(0), isNull);
      expect(set.loadTheme(0), equals(0));
      expect(set.loadedTheme, isTrue);
    });

    test('addElementsClasses', () {
      final a = HTMLDivElement()..className = 'x';
      final b = HTMLDivElement();
      expect(addElementsClasses([a, b], []), isFalse);
      // Regression: a whitespace-only class passed the (untrimmed) emptiness
      // check and `classList.add('')` threw a `SyntaxError`.
      expect(addElementsClasses([a, b], ['', ' ']), isFalse);
      expect(addElementsClasses([a, b], ['y', '!x']), isTrue);
      expect(a.className, equals('y'));
      expect(b.className, equals('y'));
      expect(addElementsClasses([a, b], ['y']), isFalse);
    });

    group('CSSAnimationConfigElements', () {
      test('validity and getters', () {
        final e = HTMLDivElement();
        final empty = CSSAnimationConfigElements([], Duration.zero);
        expect(empty.isValid, isFalse);
        expect(empty.play(), isNull);

        final config = CSSAnimationConfigElements(
          [e],
          const Duration(milliseconds: 10),
          timingFunction: '  ',
          initialProperties: {'opacity': '0'},
          initialClasses: ['a', ' '],
          rollbackProperties: ['width', 'unknown'],
          transitionProperties: {'opacity': '1', 'width': '10px'},
          preFinalProperties: {'color': 'red'},
          finalProperties: {'height': '5px'},
          finalClasses: [' b '],
          finalizeInterval: const Duration(milliseconds: 5),
        );
        expect(config.isValid, isTrue);
        expect(config.isNotValid, isFalse);
        expect(config.timingFunction, equals('ease'));
        expect(config.elements, hasLength(1));
        expect(config.initialProperties, equals({'opacity': '0'}));
        expect(config.initialClasses, equals({'a'}));
        expect(config.rollbackProperties, equals({'width', 'unknown'}));
        expect(config.transitionProperties.keys, equals(['opacity', 'width']));
        expect(config.preFinalProperties, equals({'color': 'red'}));
        expect(config.finalProperties, equals({'height': '5px'}));
        expect(config.finalClasses, equals({'b'}));
        expect(config.toString(), contains('CSSAnimationConfig{'));
      });

      test('play applies properties, classes, rollback and callback', () async {
        final e = _attached()..style.transition = 'none';
        e.style.width = '3px';

        var called = false;
        final config = CSSAnimationConfigElements(
          [e],
          const Duration(milliseconds: 20),
          initialProperties: {'opacity': '0.5'},
          initialClasses: ['init'],
          rollbackProperties: ['width'],
          transitionProperties: {'opacity': '1', 'width': '10px'},
          preFinalProperties: {'color': 'red'},
          finalProperties: {'height': '5px'},
          finalClasses: ['done', '!init'],
          finalizeInterval: const Duration(milliseconds: 10),
        );

        final play = config.play(
          initialDelay: const Duration(milliseconds: 5),
          callback: () => called = true,
        );
        expect(play, isNotNull);
        await play;

        expect(called, isTrue);
        expect(e.style.opacity, equals('1'));
        expect(e.style.width, equals('3px'), reason: 'rolled back');
        expect(e.style.color, equals('red'));
        expect(e.style.height, equals('5px'));
        expect(e.classList.contains('done'), isTrue);
        expect(e.classList.contains('init'), isFalse);
        expect(e.style.transition, equals('none'), reason: 'restored');
      });

      test('group and sequence', () async {
        final order = <String>[];
        CSSAnimationConfigElements anim(String name, Element e) =>
            _CallbackAnimation(
              CSSAnimationConfigElements(
                [e],
                const Duration(milliseconds: 5),
                transitionProperties: {'opacity': '0.9'},
                finalizeInterval: Duration.zero,
              ),
              () => order.add(name),
            );

        final a = HTMLDivElement();
        final b = HTMLDivElement();

        final group = CSSAnimationConfigGroup([anim('a', a), anim('b', b)]);
        expect(group.isValid, isTrue);
        expect(group.configs, hasLength(2));
        await group.play();
        expect(order.toSet(), equals({'a', 'b'}));
        expect(CSSAnimationConfigGroup([]).isValid, isFalse);

        order.clear();
        await animateCSSSequence([
          anim('1', a),
          CSSAnimationConfigElements([], Duration.zero), // invalid: skipped
          anim('2', b),
          anim('3', a),
        ]);
        expect(order, equals(['1', '2', '3']));

        order.clear();
        await animateCSSSequence(
          [anim('x', a), anim('y', b)],
          initialDelay: const Duration(milliseconds: 5),
          repeat: 1,
        );
        expect(order, equals(['x', 'y', 'x', 'y']));

        order.clear();
        await animateCSSSequence([anim('only', a)]);
        expect(order, equals(['only']));

        expect(animateCSSSequence([]), isNull);
      });
    });

    test('scroll colors', () {
      final a = HTMLDivElement();
      final b = HTMLDivElement();

      expect(setElementScrollColors(a, 4, ' ', ' '), isNull);

      final idA = setElementScrollColors(a, 8, 'red', 'blue')!;
      final idB = setElementScrollColors(b, 8, 'red', 'green')!;
      expect(a.classList.contains(idA), isTrue);
      expect(a.style.scrollbarColor, equals('red blue'));
      // Regression: the class ID used the button color twice, so elements
      // with different background colors shared the class (and CSS).
      expect(idA, isNot(equals(idB)));
      expect(idA, contains('blue'));

      final idNeg = setElementScrollColors(a, -1, 'red')!;
      expect(idNeg, startsWith('__scroll_color__0__'));
      expect(a.classList.contains(idA), isFalse, reason: 'previous removed');

      expect(removeElementScrollColors(a), equals([idNeg]));
      expect(removeElementScrollColors(a), isNull);
      expect(a.style.scrollbarColor, isEmpty);
    });

    test('backdrop filter / background blur', () {
      final e = HTMLDivElement();
      expect(getElementBackdropFilter(e), isNull);

      setElementBackdropFilter(e, 'blur(2px)');
      expect(getElementBackdropFilter(e), equals('blur(2px)'));

      removeElementBackdropFilter(e);
      expect(getElementBackdropFilter(e), isNull);

      setElementBackgroundBlur(e);
      expect(getElementBackdropFilter(e), equals('blur(3px)'));
      removeElementBackgroundBlur(e);
      expect(getElementBackdropFilter(e), isNull);

      setElementBackgroundBlur(e, 0);
      expect(getElementBackdropFilter(e), equals('none'));
      removeElementBackgroundBlur(e);
      expect(getElementBackdropFilter(e), equals('none'), reason: 'not blur');
    });

    test('setTreeElementsBackgroundBlur', () {
      final root = HTMLDivElement()
        ..className = 'bb'
        ..innerHTML = '<p class="bb"></p><i class="bb-2"></i><b></b>'.toJS;
      setTreeElementsBackgroundBlur(root, ' ');
      expect(getElementBackdropFilter(root), isNull);

      setTreeElementsBackgroundBlur(root, ' bb ');
      expect(getElementBackdropFilter(root), equals('blur(3px)'));
      expect(getElementBackdropFilter(root.querySelector('p')!), 'blur(3px)');
      expect(getElementBackdropFilter(root.querySelector('i')!), 'blur(6px)');
      expect(getElementBackdropFilter(root.querySelector('b')!), isNull);

      final lvl = HTMLDivElement()..className = 'bb-4';
      setTreeElementsBackgroundBlur(lvl, 'bb');
      expect(getElementBackdropFilter(lvl), equals('blur(12px)'));
    });

    test('getElementZIndex', () {
      final parent = HTMLDivElement()..style.zIndex = '7';
      final child = HTMLSpanElement();
      parent.appendChild(child);
      expect(getElementZIndex(child), equals('7'));
      expect(getElementZIndex(HTMLDivElement(), '1'), equals('1'));
      expect(getElementZIndex(null), isNull);
      expect(cssMaxZIndex, equals(2147483647));
    });

    test('element CSS rules and pre-computed style', () {
      final cls = _uid('pre');
      _addStyle('.$cls { color: rgb(9, 9, 9); } section { margin: 1px; }');

      final e = HTMLElement.section()
        ..className = cls
        ..style.padding = '2px';

      final rules = getElementAllCssRule(e);
      expect(rules.map((r) => r.cssText).join(), contains('.$cls'));

      final props = getElementAllCssProperties(e);
      expect(props, contains('color: rgb(9, 9, 9);'));
      expect(props, contains('padding: 2px;'));

      final pre = getElementPreComputedStyle(e);
      expect(pre.color, equals('rgb(9, 9, 9)'));
      expect(pre.padding, equals('2px'));
    });

    test('select CSS rules', () {
      final cls = _uid('sel');
      final style = _addStyle('.$cls, .$cls-b { color: red; }');
      final sheet = style.sheet as CSSStyleSheet;

      expect(selectCssRuleWithSelector('.$cls'), hasLength(1));
      expect(selectCssRuleWithSelector(RegExp('^\\.$cls-b\$')), hasLength(1));
      expect(getAllCssRuleBySelector('.$cls-b', sheet), hasLength(1));
      expect(getAllCssRuleBySelector('  ', sheet), isEmpty);
      expect(getAllCssRuleBySelector('.x', null), isEmpty);
      expect(
        () => getAllCssRuleBySelector(_OtherPattern(), sheet),
        throwsStateError,
      );
      expect(getAllCssStyleSheet(), contains(sheet));

      final rule = sheet.cssRules.item(0)!;
      expect(parseCssRuleSelectors(rule), equals(['.$cls', '.$cls-b']));
    });

    test('CSS rule text parsing', () {
      expect(parseCssRuleTextSelectors('a, .b { x: y }'), equals(['a', '.b']));
      expect(parseCssRuleTextSelectors(null), isEmpty);
      expect(parseCssRuleTextSelectors('no-brace'), isEmpty);
      expect(parseCssRuleTextProperties('a { x: y; z: w }'), 'x: y; z: w');
      expect(parseCssRuleTextProperties(''), isEmpty);
      expect(parseCssRuleTextProperties('a'), isEmpty);
    });

    test('viewport @media rules', () {
      final id = _uid('vp');
      _addStyle(
        '@media (max-width: 5000px) { .${id}A { color: red; } '
        '@supports (display: grid) { .${id}B { color: blue; } } } '
        '@media (min-width: 9000px) { .${id}C { color: green; } } '
        '@media (max-height: 10px) { .${id}D { color: black; } }',
      );

      bool has(List<CSSMediaRule> rules, String cls) =>
          rules.any((r) => r.cssText.contains('.$id$cls'));

      final media = getAllMediaCssRule('');
      expect(has(media, 'A') && has(media, 'C') && has(media, 'D'), isTrue);
      expect(getAllMediaCssRule(r'min-width:\s*9000px'), hasLength(1));

      final inViewport = getAllViewportMediaCssRule(1000, 800);
      expect(has(inViewport, 'A'), isTrue);
      expect(has(inViewport, 'C'), isFalse);
      expect(has(inViewport, 'D'), isFalse);

      final outViewport = getAllOutOfViewportMediaCssRule(1000, 800);
      expect(has(outViewport, 'C'), isTrue);
      expect(has(outViewport, 'D'), isTrue);
      expect(has(outViewport, 'A'), isFalse);

      final asClass = getAllViewportMediaCssRuleAsClassRule(
        1000,
        800,
        'tgt',
      ).where((r) => r.contains(id)).toList();
      expect(asClass, equals(['.tgt .${id}A { color: red; }']));

      final outAsClass = getAllOutOfViewportMediaCssRuleAsClassRule(
        1000,
        800,
        'tgt',
      ).where((r) => r.contains(id)).toList();
      expect(
        outAsClass,
        containsAll([
          '.tgt .${id}C { color: initial !important; }',
          '.tgt .${id}D { color: initial !important; }',
        ]),
      );

      // Regression: nested non-style rules (here `@supports`) passed the
      // `whereType<CSSStyleRule>()` filter (JS interop types can't be checked
      // with `is`) and produced invalid rules like `.tgt @supports ... { }`.
      expect(
        getAllViewportMediaCssRuleAsClassRule(
          1000,
          800,
          'tgt',
        ).any((r) => r.contains('@supports')),
        isFalse,
      );
    });

    test('viewport @media rules merge blocks of the same selector', () {
      final id = _uid('vpm');
      _addStyle(
        '@media (max-width: 5000px) { .${id}A { color: red; } } '
        '@media (min-width: 10px) { .${id}A { margin: 1px; } }',
      );
      final rules = getAllViewportMediaCssRuleAsClassRule(
        1000,
        800,
        't',
      ).where((r) => r.contains(id)).toList();
      expect(rules, hasLength(1));
      expect(rules.single, contains('color: red'));
      expect(rules.single, contains('margin: 1px'));
    });
  });

  group('Files', () {
    test('getFileMimeType', () {
      expect(getFileMimeType(_file([1], 'a.png')).toString(), 'image/png');
      expect(
        getFileMimeType(_file([1], 'a.json')).toString(),
        contains('json'),
      );
      expect(
        getFileMimeType(_file([1], 'a.zzz'), 'image/*').toString(),
        equals('image/zzz'),
      );
      expect(
        getFileMimeType(_file([1], 'a.zzz'), 'video/*').toString(),
        equals('video/zzz'),
      );
      expect(
        getFileMimeType(_file([1], 'a.zzz'), 'audio/*').toString(),
        equals('audio/zzz'),
      );
      expect(
        getFileMimeType(_file([1], 'a.zzz'), 'application/json').toString(),
        equals('application/json'),
      );
    });

    test('read file data', () async {
      final file = _file(utf8.encode('hello é'), 'a.txt', 'text/plain');

      expect(await readFileDataAsText(file), equals('hello é'));
      expect(
        await readFileDataAsArrayBuffer(file),
        equals(utf8.encode('hello é')),
      );
      expect(
        await readFileDataAsBase64(file),
        equals(base64.encode(utf8.encode('hello é'))),
      );
      expect(
        await readFileDataAsDataURLBase64(file),
        equals(
          'data:text/plain;base64,${base64.encode(utf8.encode('hello é'))}',
        ),
      );

      final blobUrl = (await readFileDataAsBlobURL(file))!;
      expect(blobUrl, startsWith('blob:'));
      revokeBlobURL(blobUrl);
    });

    test('toDataURLBase64 / createBlobURL', () async {
      expect(
        toDataURLBase64('text/plain', 'YQ=='),
        'data:text/plain;base64,YQ==',
      );

      final url = createBlobURL(Uint8List.fromList([1, 2, 3]), 'app/x');
      expect(url, startsWith('blob:'));

      // The blob holds the bytes (a typed array, not "1,2,3"):
      final xhr = XMLHttpRequest()
        ..open('GET', url)
        ..responseType = 'arraybuffer';
      final load = xhr.onLoad.first;
      xhr.send();
      await load;
      expect(
        (xhr.response as JSArrayBuffer).toDart.asUint8List(),
        equals([1, 2, 3]),
      );
      revokeBlobURL(url);
    });

    test('read file inputs', () async {
      final input = _fileInput([_file(utf8.encode('abc'), 'a.txt')]);

      expect(await readFileInputElementAsString(input), equals('abc'));
      expect(
        await readFileInputElementAsArrayBuffer(input),
        equals([97, 98, 99]),
      );
      expect(await readFileInputElementAsBase64(input), equals('YWJj'));
      expect(
        await readFileInputElementAsDataURLBase64(input),
        endsWith(';base64,YWJj'),
      );
      final blobUrl = (await readFileInputElementAsBlobUrl(input))!;
      expect(blobUrl, startsWith('blob:'));
      revokeBlobURL(blobUrl);

      final empty = _fileInput([]);
      expect(await readFileInputElementAsString(empty), isNull);
      expect(await readFileInputElementAsArrayBuffer(empty), isNull);
      expect(await readFileInputElementAsBase64(empty), isNull);
      expect(await readFileInputElementAsDataURLBase64(empty), isNull);
      expect(await readFileInputElementAsBlobUrl(empty), isNull);

      expect(await readFileInputElementAsString(null), isNull);
      expect(await readFileInputElementAsArrayBuffer(null), isNull);
      expect(await readFileInputElementAsBase64(null), isNull);
      expect(await readFileInputElementAsDataURLBase64(null), isNull);
      expect(await readFileInputElementAsBlobUrl(null), isNull);
    });

    // Regression: the image `load` listener was attached after setting `src`
    // (and a delay), so a fast load was missed and this never completed.
    test('removeExifFromImageFile', () async {
      expect(await removeExifFromImageFile(_file([1], 'a.txt')), isNull);

      final dataUrl = await removeExifFromImageFile(_jpegFile('photo.jpg'));
      expect(dataUrl, startsWith('data:image/png;base64,'));
    });

    test('read file inputs removing Exif (JPEG)', () async {
      final input = _fileInput([_jpegFile('photo.jpg')]);

      final bytes = (await readFileInputElementAsArrayBuffer(input, true))!;
      expect(bytes.sublist(1, 4), equals(ascii.encode('PNG')));

      final b64 = (await readFileInputElementAsBase64(input, true))!;
      expect(base64.decode(b64).sublist(1, 4), equals(ascii.encode('PNG')));

      final dataUrl = await readFileInputElementAsDataURLBase64(input, true);
      expect(dataUrl, startsWith('data:image/png;base64,'));

      final blobUrl = (await readFileInputElementAsBlobUrl(input, true))!;
      expect(blobUrl, startsWith('blob:'));
      revokeBlobURL(blobUrl);

      // Regression: returned the data URL MIME type ("image/png") instead of
      // the (Latin-1 decoded) payload.
      final str = (await readFileInputElementAsString(input, true))!;
      expect(str.substring(1, 4), equals('PNG'));
    });
  });

  group('Dialogs', () {
    List<HTMLDivElement> dialogs() => document.body!.children
        .toList()
        .where((e) => e.getAttribute('style')?.contains('999999999') ?? false)
        .cast<HTMLDivElement>()
        .toList();

    setUp(() {
      addTearDown(() {
        for (final d in dialogs()) {
          d.remove();
        }
      });
    });

    test('showDialogText', () {
      expect(showDialogText(null), isNull);
      expect(showDialogText(''), isNull);

      final dialog = showDialogText(
        'Hello',
        transparency: 0.5,
        padding: '1px',
      )!;
      expect(dialog.isConnected, isTrue);
      expect(dialog.querySelector('span:last-child')!.textContent, 'Hello');
      expect(dialog.style.backgroundColor, equals('rgba(0, 0, 0, 0.5)'));
      expect(dialog.style.padding, equals('1px'));
      expect(dialog.style.position, equals('fixed'));
      expect(getElementBackdropFilter(dialog), equals('blur(6px)'));
    });

    test('close button removes the dialog', () {
      final dialog = showDialogText('x')!;
      expect(dialog.style.backgroundColor, equals('rgba(0, 0, 0, 0.9)'));
      final close = dialog.firstElementChild as HTMLElement;
      expect(close.textContent, equals('×'));
      close.click();
      expect(dialog.isConnected, isFalse);
      expect(dialog.style.display, equals('none'));
    });

    test('showDialogHTML', () {
      expect(showDialogHTML(null), isNull);
      expect(showDialogHTML(''), isNull);

      final dialog = showDialogHTML('<b id="dlg-b">bold</b>')!;
      expect(dialog.querySelector('#dlg-b')!.textContent, equals('bold'));

      final unsafe = showDialogHTML('<i id="dlg-i">i</i>', unsafe: true)!;
      expect(unsafe.querySelector('#dlg-i'), isNotNull);
    });

    test('showDialogImage adds download and rotate controls', () {
      final src = _canvas(4, 2).toDataURL('image/png');
      showDialogImage(src);

      final dialog = dialogs().last;
      final download = dialog.querySelector('a') as HTMLAnchorElement;
      expect(download.href, equals(src));
      expect(download.download, endsWith('.png'));
      expect(download.title, equals('Download'));
      expect(
        dialog
            .querySelectorAll('span')
            .toElements()
            .map((e) => e.getAttribute('title')),
        contains('Rotate Right'),
      );
      expect((dialog.querySelector('img') as HTMLImageElement).src, src);
    });

    test('download file names', () {
      final titled = HTMLImageElement()
        ..src = _canvas(1, 1).toDataURL('image/png')
        ..title = 'photo';
      final d1 = showDialogElement(titled);
      expect(
        (d1.querySelector('a') as HTMLAnchorElement).download,
        equals('image-photo.png'),
      );

      final url = HTMLImageElement()..src = '/images/pic.gif';
      final d2 = showDialogElement(url);
      expect((d2.querySelector('a') as HTMLAnchorElement).download, 'pic.gif');

      final video = HTMLVideoElement()..src = '/v/clip.mp4';
      final d3 = showDialogElement(video);
      expect((d3.querySelector('a') as HTMLAnchorElement).download, 'clip.mp4');
      expect(
        d3
            .querySelectorAll('span')
            .toElements()
            .map((e) => e.getAttribute('title')),
        isNot(contains('Rotate Right')),
      );

      final plain = showDialogElement(HTMLDivElement());
      expect(plain.querySelector('a'), isNull);
    });

    // Regression: rotate picked the first child matching
    // `isA<CanvasImageSource>()` (a `JSObject` typedef): the close button. It
    // then failed with a `LateInitializationError` instead of rotating.
    test('rotate replaces the image with a rotated one', () async {
      final img = HTMLImageElement();
      final loaded = elementOnLoad(img);
      img.src = _canvas(4, 2).toDataURL('image/png');
      expect(await loaded, isTrue);

      final dialog = showDialogElement(img);
      final rotate =
          dialog
                  .querySelectorAll('span')
                  .toElements()
                  .firstWhere((e) => e.getAttribute('title') == 'Rotate Right')
              as HTMLElement;
      rotate.click();

      final rotated = dialog.querySelector('img') as HTMLImageElement;
      expect(rotated.src, isNot(equals(img.src)));
      expect(rotated.width, equals(2));
      expect(rotated.height, equals(4));
      expect(rotated.style.maxWidth, equals('98vw'));
      expect(
        (dialog.querySelector('a') as HTMLAnchorElement).href,
        equals(rotated.src),
      );
      expect(_jsToString(rotated).toDart, equals('[object HTMLImageElement]'));
    });
  });
}

/// Wraps a [CSSAnimationConfigElements], calling [onPlay] when it ends.
class _CallbackAnimation extends CSSAnimationConfigElements {
  final CSSAnimationConfigElements _config;
  final void Function() _onPlay;

  _CallbackAnimation(this._config, this._onPlay)
    : super(
        _config.elements,
        _config.duration,
        transitionProperties: _config.transitionProperties,
        finalizeInterval: _config.finalizeInterval,
      );

  @override
  Future<void>? play({Duration? initialDelay, AnimationCallback? callback}) =>
      _config.play(
        initialDelay: initialDelay,
        callback: () {
          _onPlay();
          callback?.call();
        },
      );
}

/// A [Pattern] that is neither a [String] nor a [RegExp].
class _OtherPattern implements Pattern {
  @override
  Iterable<Match> allMatches(String string, [int start = 0]) => const [];

  @override
  Match? matchAsPrefix(String string, [int start = 0]) => null;
}
