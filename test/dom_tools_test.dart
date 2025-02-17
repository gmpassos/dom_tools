@TestOn('browser')
library;

import 'package:dom_tools/dom_tools_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Browser tests', () {
    setUp(() {});

    test('evalJS', () {
      var c = evalJS(' var a = 2 ; var b = 3 ; var c = a * b ; c ');
      expect(c, equals(6));
    });

    test('touchEventToMouseEvent', () {
      var div = HTMLDivElement();

      Touch? touch;

      try {
        touch = Touch(TouchInit(
          identifier: 123,
          target: div,
          screenX: 200,
          screenY: 100,
          clientX: 100,
          clientY: 50,
        ));
      } catch (e) {
        print(e);
      }

      if (touch == null) {
        print('** Touch creation not supported. Aborting test!');
        return;
      }

      var touchEvent = TouchEvent(
          'touchstart',
          TouchEventInit(
            touches: [touch].toJS,
            ctrlKey: false,
            shiftKey: true,
            altKey: false,
            metaKey: false,
          ));

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

    test('extensions', () {
      var div = HTMLDivElement()
        ..innerHTML = '''
      
        <a id="lnk1" href="link1.html">link 1</a>
        <a id="lnk2" href="link2.html#h2" class="hash hash2">link 2</a>
        <a id="lnk3" href="link3.html#h3" class="hash">link 3</a>
        
        <input id="chk1" type="checkbox" value="a" checked>
        <input id="chk2" type="checkbox" value="b" class="chkb">
        
        <input id="rad1" type="radio" value="c" checked>
        <input id="rad2" type="radio" value="d">
        
        <img id="img1" src='foo.png'>
        
      '''
            .toJS;

      var innerElements = _elementsToTag(div.children.toList());

      expect(
          innerElements,
          equals([
            '<a id=lnk1 href=link1.html>',
            '<a id=lnk2 href=link2.html#h2 class=hash+hash2>',
            '<a id=lnk3 href=link3.html#h3 class=hash>',
            '<input id=chk1 type=checkbox value=a checked>',
            '<input id=chk2 type=checkbox value=b class=chkb>',
            '<input id=rad1 type=radio value=c checked>',
            '<input id=rad2 type=radio value=d>',
            '<img id=img1 src=foo.png>',
          ]));

      {
        expect(
            _elementsToTag(div.children.toIterable().withClass('hash')),
            equals([
              '<a id=lnk2 href=link2.html#h2 class=hash+hash2>',
              '<a id=lnk3 href=link3.html#h3 class=hash>',
            ]));

        expect(_elementsToTag(div.children.toIterable().withClass('hash2')),
            equals(['<a id=lnk2 href=link2.html#h2 class=hash+hash2>']));

        expect(_elementsToTag(div.children.toIterable().withClass('chkb')),
            equals(['<input id=chk2 type=checkbox value=b class=chkb>']));

        expect(
            _elementsToTag(
                div.children.toIterable().withClasses(['hash', 'hash2'])),
            equals([
              '<a id=lnk2 href=link2.html#h2 class=hash+hash2>',
            ]));
      }

      {
        expect(_elementsToTag(div.children.toIterable().withID('lnk2')),
            equals(['<a id=lnk2 href=link2.html#h2 class=hash+hash2>']));

        expect(_elementsToTag(div.children.toIterable().withID('img1')),
            equals(['<img id=img1 src=foo.png>']));
      }

      {
        var sel = div.selectAnchorElements();

        print(_elementsToTag(sel));

        expect(sel.length, equals(3));

        expect(
            _elementsToTag(sel),
            equals([
              '<a id=lnk1 href=link1.html>',
              '<a id=lnk2 href=link2.html#h2 class=hash+hash2>',
              '<a id=lnk3 href=link3.html#h3 class=hash>'
            ]));

        var selLinks = div.selectAnchorLinks();

        expect(selLinks.map((e) => e.split('/').last),
            equals(['link1.html', 'link2.html#h2', 'link3.html#h3']));

        var selLinksTargets = div.selectAnchorLinksTargets();

        expect(selLinksTargets, equals(['h2', 'h3']));
      }

      {
        var sel = div.selectCheckboxInputElement();

        print(_elementsToTag(sel));

        expect(sel.length, equals(2));

        expect(
            _elementsToTag(sel),
            equals([
              '<input id=chk1 type=checkbox value=a checked>',
              '<input id=chk2 type=checkbox value=b class=chkb>'
            ]));

        expect(sel[0].id, equals('chk1'));
        expect(sel[0].value, equals('a'));
        expect(sel[0].checked, isTrue);

        expect(sel[1].id, equals('chk2'));
        expect(sel[1].value, equals('b'));
        expect(sel[1].checked, isFalse);
      }

      {
        var sel = div.selectRadioButtonInputElement();

        print(_elementsToTag(sel));

        expect(sel.length, equals(2));

        expect(
            _elementsToTag(sel),
            equals([
              '<input id=rad1 type=radio value=c checked>',
              '<input id=rad2 type=radio value=d>'
            ]));

        expect(sel[0].id, equals('rad1'));
        expect(sel[0].value, equals('c'));
        expect(sel[0].checked, isTrue);

        expect(sel[1].id, equals('rad2'));
        expect(sel[1].value, equals('d'));
        expect(sel[1].checked, isFalse);
      }

      {
        var sel = div.selectImageElement();

        print(_elementsToTag(sel));

        expect(sel.length, equals(1));

        expect(_elementsToTag(sel), equals(['<img id=img1 src=foo.png>']));

        expect(sel[0].id, equals('img1'));
        expect(sel[0].src, endsWith('foo.png'));
      }
    });

    test('measureText', () {
      var text = 'Hello World';

      var m1 = measureText(text, fontFamily: 'Arial', fontSize: 16)!;

      var m2 = measureText(text, fontFamily: 'Arial', fontSize: 12)!;

      expect(m1.width > m2.width, isTrue);
      expect(m1.height > m2.height, isTrue,
          reason: "m1.height: ${m1.height} ; m2.height: ${m2.height}");
    });
  });
}

List<String> _elementsToTag(Iterable<Element> children) {
  return children
      .map((e) =>
          '<${e.tagName.toLowerCase()} ${e.attributes.toIterable().map((e) {
            var key = e.name;
            var value = e.value.replaceAll(' ', '+');
            return value.isNotEmpty ? '$key=$value' : key;
          }).join(' ')}>')
      .toList();
}
