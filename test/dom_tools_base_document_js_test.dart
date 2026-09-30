// ignore_for_file: deprecated_member_use_from_same_package
@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:dom_tools/dom_tools_kit.dart' hide MimeType;
import 'package:swiss_knife/swiss_knife.dart' show DataURLBase64, MimeType;
import 'package:test/test.dart';

/// Integration tests (real DOM) for `dom_tools_base.dart`,
/// `dom_tools_extension.dart`, `dom_tools_document.dart`, `dom_tools_js.dart`,
/// `dom_tools_scroll.dart` and `dom_tools_touch.dart`.

class _Foo {}

var _uid = 0;

String _unique(String prefix) => '$prefix-${_uid++}';

/// Attaches [node] to `document.body`, removing it after the test.
T _attach<T extends Node>(T node, {Node? parent}) {
  (parent ?? document.body!).appendChild(node);
  addTearDown(() {
    final p = node.parentNode;
    if (p != null) p.removeChild(node);
  });
  return node;
}

/// Matches the same JS object as [expected] (JS `===`). With `dart2wasm`,
/// the same JS object can be wrapped by distinct Dart objects.
Matcher _sameJS(JSAny expected) => predicate<Object?>(
  (actual) => (actual as JSAny?).strictEquals(expected).toDart,
  'the same JS object as $expected',
);

const _png1x1 =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

Touch? _touch(EventTarget target, {num x = 10, num y = 20}) {
  try {
    return Touch(
      TouchInit(
        identifier: 1,
        target: target,
        clientX: x,
        clientY: y,
        screenX: x + 1,
        screenY: y + 1,
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Sets `body` margin/padding to `0` (restored after the test), so document
/// positions are deterministic.
void _zeroBodyMargin() {
  final body = document.body!;
  final prevMargin = body.style.margin;
  final prevPadding = body.style.padding;
  body.style.margin = '0';
  body.style.padding = '0';
  addTearDown(() {
    body.style.margin = prevMargin;
    body.style.padding = prevPadding;
  });
}

void _scrollWindowTo(num x, num y) {
  window.scrollTo(ScrollToOptions(left: x, top: y, behavior: 'instant'));
}

/// A large element making the window scrollable (removed after the test).
void _makeWindowScrollable() {
  _attach(
    HTMLDivElement()
      ..style.width = '6000px'
      ..style.height = '6000px',
  );
  _scrollWindowTo(0, 0);
  addTearDown(() => _scrollWindowTo(0, 0));
}

/// A scrollable box (100x100) with a 1000x1000 content.
HTMLDivElement _scrollBox() {
  final box = _attach(
    HTMLDivElement()
      ..style.width = '100px'
      ..style.height = '100px'
      ..style.overflow = 'scroll',
  );
  box.appendChild(
    HTMLDivElement()
      ..style.width = '1000px'
      ..style.height = '1000px',
  );
  return box;
}

/// Captures the next download link click (preventing the real download) and
/// returns its `href` and `download` name.
Future<({String href, String download})> _captureDownload(
  void Function() trigger,
) {
  final completer = Completer<({String href, String download})>();
  final listener = ((Event e) {
    final target = e.target;
    if (target.isA<HTMLAnchorElement>()) {
      final a = target as HTMLAnchorElement;
      if (a.hasAttribute('download')) {
        e.preventDefault();
        if (!completer.isCompleted) {
          completer.complete((href: a.href, download: a.download));
        }
      }
    }
  }).toJS;
  window.addEventListener('click', listener, true.toJS);
  addTearDown(() => window.removeEventListener('click', listener, true.toJS));
  trigger();
  return completer.future.timeout(const Duration(seconds: 5));
}

Future<String> _readURLText(String url) async =>
    utf8.decode(await getURLData(url));

void main() {
  group('isInDOM (Object?.isA<Node>)', () {
    test('null, Dart objects and JS primitives', () {
      expect(isInDOM(null), isFalse);
      expect(isInDOM(_Foo()), isFalse);
      expect(isInDOM('div'), isFalse);
      expect(isInDOM(123), isFalse);
      expect(isInDOM(<String, Object>{}), isFalse);
      expect(isInDOM('div'.toJS), isFalse);
      expect(isInDOM(1.toJS), isFalse);
      expect(isInDOM(JSObject()), isFalse);
    });

    test('attached / detached nodes', () {
      final detached = HTMLDivElement();
      final attached = _attach(HTMLDivElement());
      final text = _attach(Text('t'));

      expect(isInDOM(detached), isFalse);
      expect(isInDOM(attached), isTrue);
      expect(isInDOM(text), isTrue);

      expect(isNodeInDOM(attached), isTrue);
      expect(isNodeInDOM(detached), isFalse);
    });

    test('lists of nodes', () {
      final detached = HTMLDivElement();
      final attached = _attach(HTMLSpanElement());

      expect(isInDOM(<Object?>[]), isFalse);
      expect(isInDOM([detached]), isFalse);
      expect(isInDOM([detached, attached]), isTrue);
      expect(
        isInDOM([
          null,
          'x',
          [detached, attached],
        ]),
        isTrue,
      );
      expect(isInDOM([null, _Foo(), detached]), isFalse);
    });
  });

  group('element values: value / href / src', () {
    test('getElementValue / setElementValue', () {
      final input = HTMLInputElement()..value = 'abc';
      expect(getElementValue(input), equals('abc'));
      input.value = '';
      expect(getElementValue(input, 'def'), equals('def'));
      expect(setElementValue(input, 'x'), isTrue);
      expect(input.value, equals('x'));

      final img = HTMLImageElement();
      expect(setElementValue(img, 'pic.png'), isTrue);
      expect(getElementValue(img), endsWith('/pic.png'));

      final div = HTMLDivElement();
      expect(getElementValue(div), isNull);
      expect(getElementValue(div, 'd'), equals('d'));
      expect(setElementValue(div, 'x'), isFalse);
      expect(setElementValue(null, 'x'), isFalse);
    });

    test('href of link / a / base / area', () {
      final elements = <Element>[
        HTMLLinkElement(),
        HTMLAnchorElement(),
        document.createElement('base'),
        document.createElement('area'),
      ];

      for (final e in elements) {
        expect(isElementWithHREF(e), isTrue, reason: e.tagName);
        expect(setElementHREF(e, 'page.html'), isTrue, reason: e.tagName);
        expect(getElementHREF(e), endsWith('/page.html'), reason: e.tagName);
      }

      final div = HTMLDivElement();
      expect(isElementWithHREF(div), isFalse);
      expect(setElementHREF(div, 'x'), isFalse);
      expect(getElementHREF(div), isNull);
    });

    test('src of img / script / input / media / embed / iframe / source / '
        'track', () {
      final elements = <Element>[
        HTMLImageElement(),
        HTMLScriptElement(),
        HTMLInputElement(),
        HTMLVideoElement(),
        document.createElement('embed'),
        HTMLIFrameElement(),
        document.createElement('source'),
        document.createElement('track'),
      ];

      for (final e in elements) {
        expect(isElementWithSRC(e), isTrue, reason: e.tagName);
        expect(setElementSRC(e, 'file.bin'), isTrue, reason: e.tagName);
        expect(getElementSRC(e), endsWith('/file.bin'), reason: e.tagName);
      }

      final div = HTMLDivElement();
      expect(isElementWithSRC(div), isFalse);
      expect(setElementSRC(div, 'x'), isFalse);
      expect(getElementSRC(div), isNull);
    });

    test(
      'getElementByHREF / getAnchorElementByHREF / getLinkElementByHREF',
      () {
        final href = '${_unique('anchor')}.html';
        final a = _attach(HTMLAnchorElement()..href = href);

        expect(getElementByHREF('a', href), _sameJS(a));
        expect(getAnchorElementByHREF(href), _sameJS(a));
        expect(getAnchorElementByHREF(a.href), _sameJS(a));
        expect(getElementByHREF('a', ''), isNull);
        expect(getAnchorElementByHREF('${_unique('none')}.html'), isNull);

        final linkHref = '${_unique('link')}.xml';
        final link = _attach(
          HTMLLinkElement()
            ..rel = 'alternate'
            ..href = linkHref,
          parent: document.head,
        );

        expect(getLinkElementByHREF(linkHref), _sameJS(link));
        expect(getLinkElementByHREF(linkHref, 'alternate'), _sameJS(link));
        expect(getLinkElementByHREF(linkHref, 'stylesheet'), isNull);
        expect(getLinkElementByHREF(''), isNull);
      },
    );

    test('getElementBySRC / getScriptElementBySRC', () {
      final src = '${_unique('script')}.js';
      final script = _attach(
        HTMLScriptElement()
          ..type = 'text/x-not-executed'
          ..src = src,
      );
      expect(getScriptElementBySRC(src), _sameJS(script));
      expect(getElementBySRC('script', script.src), _sameJS(script));
      expect(getElementBySRC('script', ''), isNull);

      final dataSrc = 'data:text/plain,${_unique('d')}';
      final dataScript = _attach(
        HTMLScriptElement()
          ..type = 'text/x-not-executed'
          ..src = dataSrc,
      );
      expect(getScriptElementBySRC(dataSrc), _sameJS(dataScript));
    });

    test('getElementByValues', () {
      final a = _attach(
        HTMLAnchorElement()
          ..id = _unique('v')
          ..setAttribute('rel', 'r1'),
      );

      String? getId(Element e) => e.id;

      expect(getElementByValues('a', getId, [a.id]), _sameJS(a));
      expect(getElementByValues('', getId, [a.id]), isNull);
      expect(getElementByValues('a', getId, <String>[]), isNull);
      expect(getElementByValues('marquee', getId, [a.id]), isNull);

      String? getRel(Element e) => e.getAttribute('rel');
      expect(
        getElementByValues('a', getId, [a.id], getRel, ['r1']),
        _sameJS(a),
      );
      expect(getElementByValues('a', getId, [a.id], getRel, ['r2']), isNull);
      expect(getElementByValues('a', getId, [a.id], getRel, null), isNull);
    });
  });

  group('element size / load', () {
    test('getElementWidth / getElementHeight', () {
      final attached = _attach(
        HTMLDivElement()
          ..style.width = '100px'
          ..style.height = '40px',
      );
      expect(getElementWidth(attached), equals(100));
      expect(getElementHeight(attached), equals(40));

      // Detached: `offsetWidth` is 0, falls back to `style`:
      final detached = HTMLDivElement()
        ..style.width = '50px'
        ..style.height = '20px';
      expect(getElementWidth(detached), equals(50));
      expect(getElementHeight(detached), equals(20));

      final empty = HTMLDivElement();
      expect(getElementWidth(empty), isNull);
      expect(getElementHeight(empty), isNull);
      expect(getElementWidth(empty, 7), equals(7));
      expect(getElementHeight(empty, 8), equals(8));
    });

    test('elementOnLoad: loaded image', () async {
      final img = HTMLImageElement();
      final loaded = elementOnLoad(img);
      img.src = _png1x1;
      expect(await loaded.timeout(const Duration(seconds: 5)), isTrue);
    });

    // Regression: a failed load fires an `error` event, which `elementOnLoad`
    // didn't listen to, so the future never completed.
    test('elementOnLoad: broken image completes with false', () async {
      final img = HTMLImageElement();
      final loaded = elementOnLoad(img);
      img.src = 'data:image/png;base64,AAAA';
      expect(await loaded.timeout(const Duration(seconds: 5)), isFalse);
    });
  });

  group('element creation / HTML', () {
    test('createDiv / createDivInline / createDivInlineBlock', () {
      expect(createDivInlineBlock().style.display, equals('inline-block'));

      final div = createDiv(html: '<b>x</b>');
      expect(div.style.display, isEmpty);
      expect(div.innerHTML.dartify(), equals('<b>x</b>'));

      final inline = createDiv(inline: true, html: '<i>y</i>', unsafe: true);
      expect(inline.style.display, equals('inline-block'));
      expect(inline.querySelector('i')!.textContent, equals('y'));

      final div2 = createDivInline(html: 'text');
      expect(div2.style.display, equals('inline-block'));
      expect(div2.textContent, equals('text'));

      expect(createDiv().childNodes.length, equals(0));
    });

    test('createSpan / createLabel', () {
      expect(createSpan(html: '<b>s</b>').innerHTML.dartify(), '<b>s</b>');
      expect(createSpan().childNodes.length, equals(0));
      expect(createSpan(html: 'u', unsafe: true).textContent, equals('u'));
      expect(createLabel(html: 'L').textContent, equals('L'));
      expect(createLabel().tagName, equals('LABEL'));
    });

    test('getElementTagName', () {
      expect(getElementTagName(HTMLDivElement()), equals('div'));
      expect(getElementTagName(Text('t')), isNull);
    });

    test('createHTML', () {
      expect(createHTML().tagName, equals('SPAN'));
      expect(createHTML(html: '').tagName, equals('SPAN'));
      expect(createHTML(html: '<b>1</b><i>2</i>').tagName, equals('B'));

      final text = createHTML(html: 'plain text');
      expect(text.tagName, equals('SPAN'));
      expect(text.textContent, equals('plain text'));

      expect(createHTML(html: '<td>c</td>').tagName, equals('TD'));
      expect(createHTML(html: '<th>h</th>').tagName, equals('TH'));
      expect(createHTML(html: '<tr><td>c</td></tr>').tagName, equals('TR'));
      expect(
        createHTML(html: '<tbody><tr><td>c</td></tr></tbody>').tagName,
        equals('TBODY'),
      );
      expect(
        createHTML(html: '<tfoot><tr><td>c</td></tr></tfoot>').tagName,
        equals('TFOOT'),
      );
    });

    // Regression: the dependent-tag regexp matched `thread` instead of
    // `thead`, so a `<thead>` was parsed outside of a table (losing its tags).
    test('createHTML / createElement with <thead>', () {
      final thead = createHTML(html: '<thead><tr><th>h</th></tr></thead>');
      expect(thead.tagName, equals('THEAD'));
      expect(thead.querySelector('th')!.textContent, equals('h'));

      final thead2 = createElement(html: '<thead><tr><th>h</th></tr></thead>');
      expect(thead2.tagName, equals('THEAD'));
    });

    test('createElement', () {
      expect(createElement().tagName, equals('SPAN'));
      expect(createElement(html: '<p>p</p>').tagName, equals('P'));
      expect(createElement(html: 'txt').textContent, equals('txt'));
      expect(createElement(html: '<td>c</td>').tagName, equals('TD'));

      final svg = createElement(html: '<svg></svg>');
      expect(svg.tagName, equals('svg'));
      expect(svg.isA<HTMLElement>(), isFalse);
    });

    test('setElementInnerHTML / appendElementInnerHTML / htmlToText', () {
      final div = HTMLDivElement();
      setElementInnerHTML(div, '<b>1</b>');
      expect(div.innerHTML.dartify(), equals('<b>1</b>'));
      appendElementInnerHTML(div, '<i>2</i>');
      expect(div.innerHTML.dartify(), equals('<b>1</b><i>2</i>'));
      setElementInnerHTML(div, '<u>3</u>', unsafe: true);
      expect(div.innerHTML.dartify(), equals('<u>3</u>'));

      expect(htmlToText('<b>a</b> b <i>c</i>'), equals('a b c'));
    });

    // Regression: attributes were rendered as ` attr='...'` instead of their
    // names.
    test('toHTML', () {
      final div = HTMLDivElement()
        ..id = 'a'
        ..className = 'b'
        ..innerHTML = '<i>x</i>'.toJS;
      expect(toHTML(div), equals("<DIV id='a' class='b'><i>x</i></DIV>"));

      final quoted = HTMLSpanElement()..title = "it's";
      expect(toHTML(quoted), equals('<SPAN title="it\'s"></SPAN>'));

      final select = HTMLSelectElement()
        ..append(
          HTMLOptionElement()
            ..value = 'v1'
            ..label = 'L1',
        )
        ..append(
          HTMLOptionElement()
            ..value = 'v2'
            ..label = 'L2'
            ..selected = true,
        );
      final html = toHTML(select);
      expect(html, startsWith('<SELECT>'));
      expect(html, contains("<option value='v1' >L1</option>"));
      expect(html, contains("<option value='v2'  selected>L2</option>"));
      expect(html, endsWith('</SELECT>'));
    });
  });

  group('position / visibility', () {
    // Regression: the element's own offset was added twice when it had an
    // `offsetParent`.
    test('getElementDocumentPosition', () {
      _zeroBodyMargin();

      final container = _attach(
        HTMLDivElement()
          ..style.position = 'absolute'
          ..style.top = '100px'
          ..style.left = '20px',
      );
      final child = HTMLDivElement()
        ..style.position = 'absolute'
        ..style.top = '50px'
        ..style.left = '10px';
      container.appendChild(child);

      final pos = getElementDocumentPosition(child);
      expect(pos.a, equals(30));
      expect(pos.b, equals(150));

      final rect = child.getBoundingClientRect();
      expect(pos.a, equals(rect.left + window.scrollX));
      expect(pos.b, equals(rect.top + window.scrollY));

      final containerPos = getElementDocumentPosition(container);
      expect(containerPos.a, equals(20));
      expect(containerPos.b, equals(100));
    });

    test('getVisibleNode', () {
      final parent = _attach(HTMLDivElement());
      final hidden = HTMLDivElement()..style.display = 'none';
      final hiddenAttr = HTMLDivElement()..hidden = true.toJS;
      parent
        ..appendChild(hidden)
        ..appendChild(hiddenAttr);

      expect(getVisibleNode(parent), _sameJS(parent));
      expect(getVisibleNode(hidden), _sameJS(parent));
      expect(getVisibleNode(hiddenAttr), _sameJS(parent));
      expect(getVisibleNode(null), isNull);

      final orphan = HTMLDivElement()..style.display = 'none';
      expect(getVisibleNode(orphan), _sameJS(orphan));
    });

    test('isInViewport', () {
      _scrollWindowTo(0, 0);

      final visible = _attach(
        HTMLDivElement()
          ..style.width = '50px'
          ..style.height = '50px',
      );
      expect(isInViewport(visible), isTrue);
      expect(isInViewport(visible, fully: true), isTrue);

      final far = _attach(
        HTMLDivElement()
          ..style.position = 'absolute'
          ..style.top = '20000px'
          ..style.width = '50px'
          ..style.height = '50px',
      );
      expect(isInViewport(far), isFalse);
      expect(isInViewport(far, fully: true), isFalse);

      final partial = _attach(
        HTMLDivElement()
          ..style.position = 'absolute'
          ..style.top = '-25px'
          ..style.width = '50px'
          ..style.height = '50px',
      );
      expect(isInViewport(partial), isTrue);
      expect(isInViewport(partial, fully: true), isFalse);
    });

    // Regression: `window.orientation` is `undefined` in desktop browsers,
    // and reading it as an `int` threw.
    test('orientation', () {
      final landscape = isOrientationInLandscapeMode();
      expect(isOrientationInPortraitMode(), equals(!landscape));
      expect(
        landscape,
        equals(window.screen.orientation.type.startsWith('landscape')),
      );
    });

    test('onOrientationchange', () {
      var count = 0;
      final listener = ((Event e) => count++).toJS;
      expect(onOrientationchange(listener), isTrue);
      addTearDown(
        () => window.removeEventListener('orientationchange', listener),
      );

      window.dispatchEvent(Event('orientationchange'));
      expect(count, equals(1));
    });

    test('device size getters', () {
      expect(deviceWidth, equals(window.innerWidth));
      expect(deviceHeight, equals(window.innerHeight));

      final sizes = [
        isExtraSmallDevice,
        isSmallDevice,
        isMediumDevice,
        isLargeDevice,
        isExtraLargeDevice,
      ];
      expect(sizes.where((s) => s).length, equals(1));

      final w = window.innerWidth;
      expect(isSmallDeviceOrLower, equals(w < 768));
      expect(isSmallDeviceOrHigher, equals(w >= 576));
      expect(isMediumDeviceOrLower, equals(w < 992));
      expect(isMediumDeviceOrLHigher, equals(w >= 768));
      expect(isLargeDeviceOrLower, equals(w < 1200));
      expect(isLargeDeviceOrHigher, equals(w >= 992));
    });

    test('measureText', () {
      final normal = measureText('Hello', fontFamily: 'Arial', fontSize: 20)!;
      expect(normal.width, greaterThan(0));
      expect(normal.height, greaterThan(0));

      final bold = measureText(
        'Hello',
        fontFamily: 'Arial',
        fontSize: 20,
        bold: true,
      )!;
      expect(bold.width, greaterThanOrEqualTo(normal.width));

      final big = measureText('Hello', fontFamily: 'Arial', fontSize: '40px')!;
      expect(big.width, greaterThan(normal.width));
    });
  });

  group('zoom / meta viewport', () {
    test('setZoom / resetZoom', () async {
      final prev = document.body!.style.zoom;
      addTearDown(() => setZoom(prev));

      setZoom('2');
      expect(document.body!.style.zoom, equals('2'));

      resetZoom();
      expect(document.body!.style.zoom, equals('normal'));

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(document.body!.style.zoom, equals('2'));
    });

    test('parseMetaContent / buildMetaContent', () {
      const content = 'width=device-width, initial-scale=1.0, user-scalable';
      final map = parseMetaContent(content);
      expect(
        map,
        equals({
          'width': 'device-width',
          'initial-scale': '1.0',
          'user-scalable': null,
        }),
      );
      expect(buildMetaContent(map), equals(content));
      expect(buildMetaContent({}), isEmpty);
    });

    // Regression: `minimumScale` was only applied when `maximumScale` was also
    // passed, and `maximumScale` alone threw (null check on `minimumScale`).
    test('setMetaViewportScale', () {
      final head = document.head!;
      final noViewport = getMetaTagsWithName('viewport').isEmpty;
      if (noViewport) {
        expect(setMetaViewportScale(minimumScale: '1'), isFalse);
      }

      final meta = HTMLMetaElement()
        ..name = 'viewport'
        ..content = 'width=device-width, initial-scale=1.0';
      head.insertBefore(meta, head.firstChild);
      addTearDown(() => meta.remove());

      expect(setMetaViewportScale(), isFalse);

      expect(setMetaViewportScale(minimumScale: '0.5'), isTrue);
      var params = parseMetaContent(meta.content);
      expect(params['minimum-scale'], equals('0.5'));
      expect(params.containsKey('maximum-scale'), isFalse);

      expect(setMetaViewportScale(maximumScale: '*'), isTrue);
      params = parseMetaContent(meta.content);
      expect(params['maximum-scale'], equals('1.0'));
      expect(params['minimum-scale'], equals('0.5'));

      expect(
        setMetaViewportScale(minimumScale: ' ', maximumScale: '3'),
        isTrue,
      );
      params = parseMetaContent(meta.content);
      expect(params['minimum-scale'], equals('1.0'));
      expect(params['maximum-scale'], equals('3'));
      expect(params['width'], equals('device-width'));
    });

    test('meta tags helpers', () {
      final head = document.head!;
      final name = _unique('x-test-meta');
      final meta = _attach(
        HTMLMetaElement()
          ..name = name
          ..content = 'c1',
        parent: head,
      );

      expect(getMetaTagsWithName(name).single, _sameJS(meta));
      expect(getMetaTagsContentWithName(name), equals(['c1']));
      expect(getMetaTagsContentWithName(_unique('none')), isEmpty);
      expect(
        getElementsWithAttributes('meta', {'name': name, 'content': 'c1'}),
        hasLength(1),
      );
      expect(
        getElementsWithAttributes('meta', {'name': name, 'content': 'c2'}),
        isEmpty,
      );

      expect(isMobileAppStatusBarTranslucent(), isFalse);
      final status = _attach(
        HTMLMetaElement()
          ..name = 'apple-mobile-web-app-status-bar-style'
          ..content = 'black-translucent',
        parent: head,
      );
      expect(isMobileAppStatusBarTranslucent(), isTrue);
      status.content = 'black';
      expect(isMobileAppStatusBarTranslucent(), isFalse);
    });
  });

  group('attributes / CSS', () {
    test('getElementAttribute', () {
      final div = HTMLDivElement()
        ..setAttribute('data-foo-bar', 'x')
        ..setAttribute('title', 't');

      expect(getElementAttribute(div, RegExp(r'^data-foo')), equals('x'));
      expect(getElementAttribute(div, 'TITLE'), equals('t'));
      expect(getElementAttribute(div, null), isNull);
      expect(getElementAttribute(div, RegExp('none')), isNull);
      expect(getElementAttributeStr(div, 'DATA-FOO-BAR'), equals('x'));
      expect(getElementAttributeRegExp(div, RegExp('itl')), equals('t'));
    });

    test('elementMatchesAttribute(s)', () {
      final div = HTMLDivElement()
        ..setAttribute('title', ' abc ')
        ..setAttribute('data-n', '42');

      expect(elementMatchesAttribute(div, 'title', 'abc'), isTrue);
      expect(elementMatchesAttribute(div, 'title', ' abc '), isTrue);
      expect(elementMatchesAttribute(div, 'title', 'x'), isFalse);
      expect(elementMatchesAttribute(div, 'data-n', RegExp(r'^\d+$')), isTrue);
      expect(
        elementMatchesAttribute(div, 'data-n', (String v) => v == '42'),
        isTrue,
      );
      expect(elementMatchesAttribute(div, 'data-n', 42), isFalse);
      expect(elementMatchesAttribute(div, 'missing', null), isTrue);
      expect(elementMatchesAttribute(div, 'missing', 'x'), isFalse);
      expect(elementMatchesAttribute(div, 'title', null), isFalse);

      expect(
        elementMatchesAttributes(div, {'title': 'abc', 'data-n': '42'}),
        isTrue,
      );
      expect(
        elementMatchesAttributes(div, {'title': 'abc', 'data-n': '1'}),
        isFalse,
      );
    });

    test('CSS declarations', () {
      final empty = newCSSStyleDeclaration();
      expect(isCssEmpty(empty), isTrue);
      expect(isCssNotEmpty(empty), isFalse);

      final red = newCSSStyleDeclaration(cssText: 'color: red');
      expect(red.color, equals('red'));
      expect(isCssNotEmpty(red), isTrue);

      expect(defineCSS(null, null, 'color: blue').color, equals('blue'));
      expect(defineCSS(null, null).cssText, isEmpty);
      expect(defineCSS(null, red), _sameJS(red));
      expect(defineCSS(red, null), _sameJS(red));

      final merged = defineCSS(
        red,
        newCSSStyleDeclaration(cssText: 'top: 1px'),
      );
      expect(merged.color, equals('red'));
      expect(merged.top, equals('1px'));
    });

    test('asCssStyleDeclaration', () {
      final css = newCSSStyleDeclaration(cssText: 'color: red');

      expect(asCssStyleDeclaration(null).cssText, isEmpty);
      expect(asCssStyleDeclaration(css), _sameJS(css));
      expect(asCssStyleDeclaration('color: green').color, equals('green'));
      expect(asCssStyleDeclaration('color: blue'.toJS).color, equals('blue'));
      expect(asCssStyleDeclaration(() => 'width: 2px').width, equals('2px'));
      expect(
        asCssStyleDeclaration((() => 'width: 3px'.toJS).toJS).width,
        equals('3px'),
      );
      expect(() => asCssStyleDeclaration(123), throwsStateError);
      expect(() => asCssStyleDeclaration(_Foo()), throwsStateError);
    });

    test('applyCSS', () {
      final div = HTMLDivElement()..style.width = '5px';
      final span = HTMLSpanElement();

      expect(applyCSS(newCSSStyleDeclaration(), div), isFalse);

      final css = newCSSStyleDeclaration(cssText: 'color: red');
      expect(applyCSS(css, div, [span]), isTrue);
      expect(div.style.color, equals('red'));
      expect(div.style.width, equals('5px'));
      expect(span.style.color, equals('red'));

      expect(applyCSS(css, span), isTrue);
    });
  });

  group('DOM tree helpers', () {
    test('nodeTreeContains / nodeTreeContainsAny', () {
      final root = HTMLDivElement();
      final child = HTMLSpanElement();
      root.appendChild(child);
      final other = HTMLDivElement();

      expect(nodeTreeContains(root, child), isTrue);
      expect(nodeTreeContains(root, root), isTrue);
      expect(nodeTreeContains(root, other), isFalse);
      expect(nodeTreeContainsAny(root, []), isFalse);
      expect(nodeTreeContainsAny(root, [other, child]), isTrue);
    });

    // Regression: `insertBefore` arguments were swapped (it tried to insert
    // `n1` before `n2`, which isn't a child), throwing `NotFoundError`.
    test('replaceElement', () {
      final parent = HTMLDivElement();
      final a = HTMLSpanElement()..id = 'a';
      final b = HTMLSpanElement()..id = 'b';
      parent
        ..appendChild(a)
        ..appendChild(b);

      final c = HTMLElement.section()..id = 'c';
      expect(replaceElement(a, c), isTrue);
      expect(parent.children.toList().map((e) => e.id), equals(['c', 'b']));
      expect(a.parentNode, isNull);

      expect(replaceElement(HTMLDivElement(), c), isFalse);
    });

    test('getParentElement', () {
      final div = HTMLDivElement();
      final section = HTMLElement.section();
      final span = HTMLSpanElement();
      div.appendChild(section);
      section.appendChild(span);

      expect(getParentElement(span), _sameJS(section));
      expect(
        getParentElement(span, validator: (p) => p.tagName == 'DIV'),
        _sameJS(div),
      );
      expect(
        getParentElement(
          span,
          validator: (p) => p.tagName == 'DIV',
          maxLevels: 1,
        ),
        isNull,
      );
      expect(getParentElement(span, maxLevels: 0), isNull);
      expect(getParentElement(div), isNull);
      expect(
        getParentElement(span, validator: (p) => p.tagName == 'TABLE'),
        isNull,
      );
    });

    test('DOMTreeReferenceMap', () {
      final root = _attach(HTMLDivElement());
      final span = HTMLSpanElement();
      root.appendChild(span);
      final detached = HTMLDivElement();

      final map = DOMTreeReferenceMap<String>(root);
      map.put(span, 's');
      expect(map.get(span), equals('s'));

      expect(map.isInTree(span), isTrue);
      expect(map.isInTree(root), isTrue);
      expect(map.isInTree(detached), isFalse);
      expect(map.isInTree(null), isFalse);

      expect(map.getParentOf(span), _sameJS(root));
      expect(map.getParentOf(null), isNull);
      expect(map.getChildrenOf(root).length, equals(1));
      expect(map.getChildrenOf(null), isEmpty);

      expect(map.isChildOf(root, span, true), isTrue);
      expect(map.isChildOf(root, span, false), isTrue);
      expect(map.isChildOf(root, root, true), isFalse);
      expect(map.isChildOf(root, root, false), isTrue);
      expect(map.isChildOf(root, detached, false), isFalse);
      expect(map.isChildOf(null, span, false), isFalse);
      expect(map.isChildOf(root, null, false), isFalse);
    });

    test('clearSelections / copyElementToClipboard', () {
      final div = _attach(HTMLDivElement()..textContent = 'copy me');

      final range = document.createRange()..selectNodeContents(div);
      final selection = window.getSelection()!;
      selection
        ..removeAllRanges()
        ..addRange(range);
      expect(selection.rangeCount, equals(1));

      clearSelections();
      expect(window.getSelection()!.rangeCount, equals(0));

      expect(copyElementToClipboard(div), isTrue);
      expect(window.getSelection()!.rangeCount, equals(0));
    });
  });

  group('centered divs', () {
    test('isInlineElement', () {
      expect(isInlineElement(HTMLDivElement()), isFalse);
      expect(
        isInlineElement(HTMLDivElement()..style.display = 'inline-block'),
        isTrue,
      );
      final bootstrap = HTMLDivElement()..className = 'd-inline-flex';
      expect(isInlineElement(bootstrap), isTrue);
      expect(isInlineElement(bootstrap, checkBootstrapClasses: false), isFalse);
    });

    test('setDivCentered', () {
      final div = HTMLDivElement()..className = 'd-block';
      final sub = HTMLDivElement()..className = 'd-flex keep';
      final content = HTMLDivElement();
      final inlineContent = HTMLDivElement()..style.display = 'inline';
      sub
        ..appendChild(content)
        ..appendChild(inlineContent);
      div.appendChild(sub);

      setDivCentered(div);

      expect(div.style.display, equals('table'));
      expect(div.classList.contains('d-block'), isFalse);
      expect(sub.style.display, equals('table-cell'));
      expect(sub.style.textAlign, equals('center'));
      expect(sub.style.verticalAlign, equals('middle'));
      expect(sub.className, equals('keep'));
      expect(content.style.display, equals('inline-block'));
      expect(inlineContent.style.display, equals('inline'));

      final inline = HTMLDivElement()..className = 'd-inline-block';
      final sub2 = HTMLDivElement();
      inline.appendChild(sub2);
      setDivCentered(
        inline,
        centerHorizontally: false,
        centerVertically: false,
      );
      expect(inline.style.display, equals('inline-table'));
      expect(sub2.style.textAlign, isEmpty);
      expect(sub2.style.verticalAlign, isEmpty);
    });

    test('setTreeElementsDivCentered', () {
      final root = HTMLDivElement();
      final target = HTMLDivElement()..className = 'center-me';
      final other = HTMLDivElement()..className = 'other';
      target.appendChild(HTMLDivElement());
      root
        ..appendChild(target)
        ..appendChild(other);

      setTreeElementsDivCentered(root, ' ');
      expect(target.style.display, isEmpty);

      setTreeElementsDivCentered(root, 'center-me');
      expect(target.style.display, equals('table'));
      expect(other.style.display, isEmpty);
    });
  });

  group('prefetchHref', () {
    test('prefetch an existing URL', () async {
      final href =
          '${window.location.href.split('?').first}?prefetch=${_unique('p')}';
      addTearDown(() => getLinkElementByHREF(href, 'prefetch')?.remove());

      final ok = await prefetchHref(href)
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
      expect(ok, isTrue);

      final link = getLinkElementByHREF(href, 'prefetch');
      expect(link, isNotNull);
      expect(link!.parentNode, _sameJS(document.head!));

      // Already in DOM:
      expect(await prefetchHref(href), isTrue);
    });

    // Regression: a failed prefetch fires an `error` event, which wasn't
    // listened to, so the future never completed.
    test('prefetch a missing URL completes with false', () async {
      final href = '/__missing_${_unique('m')}__.txt';
      addTearDown(() => getLinkElementByHREF(href, 'prefetch')?.remove());

      final ok = await prefetchHref(
        href,
        insertIndex: 0,
      ).timeout(const Duration(seconds: 10));
      expect(ok, isFalse);

      final link = getLinkElementByHREF(href, 'prefetch')!;
      expect(document.head!.children.item(0), _sameJS(link));
    });

    test('preLoad uses rel=preload', () async {
      final href =
          '${window.location.href.split('?').first}?preload=${_unique('p')}';
      addTearDown(() => getLinkElementByHREF(href, 'preload')?.remove());

      unawaited(prefetchHref(href, preLoad: true));
      expect(getLinkElementByHREF(href, 'preload'), isNotNull);
      expect(getLinkElementByHREF(href, 'prefetch'), isNull);
    });
  });

  group('DomElementExtension / IterableDomElementExtension', () {
    HTMLDivElement build() => HTMLDivElement()
      ..innerHTML =
          '''
        <a href="link1.html">1</a>
        <a href="link2.html#h2">2</a>
        <a href="link3.html#h3">3</a>
        <input type="text">
        <input type="checkbox">
        <input type="radio">
        <input type="number">
        <input type="email">
        <input type="datetime-local">
        <input type="button">
        <input type="file">
        <input type="password">
        <select></select>
        <textarea></textarea>
        <button>b</button>
        <img src="i.png">
        <div><span>s</span></div>
        <table><tr><td>c</td></tr></table>
      '''
              .toJS;

    test('select* methods', () {
      final div = build();

      expect(div.selectAnchorElements().length, equals(3));
      expect(div.selectAnchorLinks().length, equals(3));
      expect(div.selectAnchorLinks().first, endsWith('/link1.html'));
      expect(div.selectAnchorLinksTargets(), equals(['h2', 'h3']));

      expect(div.selectInputElement().length, equals(9));
      expect(div.selectCheckboxInputElement().length, equals(1));
      expect(div.selectRadioButtonInputElement().length, equals(1));
      expect(div.selectNumberInputElement().length, equals(1));
      expect(div.selectEmailInputElement().length, equals(1));
      expect(div.selectLocalDateTimeInputElement().length, equals(1));
      expect(div.selectButtonInputElement().length, equals(1));
      expect(div.selectFileUploadInputElement().length, equals(1));
      expect(div.selectPasswordInputElement().length, equals(1));
      expect(div.selectSelectElement().length, equals(1));
      expect(div.selectTextAreaElement().length, equals(1));
      expect(div.selectButtonElements().length, equals(1));
      expect(div.selectImageElement().length, equals(1));
      expect(div.selectDivElement().length, equals(1));
      expect(div.selectSpanElement().length, equals(1));
      expect(div.selectTableElement().length, equals(1));
      expect(div.selectTableRowElement().length, equals(1));
      expect(div.selectTableCellElement().length, equals(1));
    });

    test('visibility getters', () {
      final div = HTMLDivElement();
      expect(div.isDisplayNone, isFalse);
      expect(div.isVisibilityHidden, isFalse);
      expect(div.isInvisible, isFalse);

      div.style.display = 'none';
      expect(div.isDisplayNone, isTrue);
      expect(div.isInvisible, isTrue);

      final hidden = HTMLDivElement()..style.visibility = 'hidden';
      expect(hidden.isVisibilityHidden, isTrue);
      expect(hidden.isInvisible, isTrue);

      final hiddenAttr = HTMLDivElement()..hidden = true.toJS;
      expect(hiddenAttr.isInvisible, isTrue);
    });

    test('Iterable<Element> helpers', () {
      final a = HTMLDivElement()
        ..id = 'a'
        ..className = 'x y';
      final b = HTMLDivElement()
        ..id = 'b'
        ..className = 'y';
      final elements = [a, b];

      elements.addClass('z');
      expect(a.classList.contains('z') && b.classList.contains('z'), isTrue);
      elements.removeClass('y');
      expect(a.className, equals('x z'));
      expect(b.className, equals('z'));

      expect(elements.withID('b').single, _sameJS(b));
      expect(elements.withID('none'), isEmpty);
      expect(elements.withClass('x').single, _sameJS(a));
      expect(elements.withClass(' x  z ').single, _sameJS(a));
      expect(elements.withClass('z').length, equals(2));
      expect(elements.withClasses(['x', 'z']).single, _sameJS(a));
      expect(elements.withClasses(['', ' ']), isEmpty);
      expect(elements.withClass('none'), isEmpty);
    });
  });

  group('JavaScript', () {
    test('evalJS', () {
      expect(evalJS('1 + 1'), equals(2));
      expect(evalJS('"s" + 1'), equals('s1'));
      expect(evalJS('null'), isNull);
      expect(
        evalJS('({a: [1, 2], b: {c: true}})'),
        equals({
          'a': [1, 2],
          'b': {'c': true},
        }),
      );
    });

    test('addJavaScriptCode', () async {
      final name = _unique('__dt_code').replaceAll('-', '_');
      final code = 'window.$name = 7;';
      expect(await addJavaScriptCode(code), isTrue);
      expect(evalJS('window.$name'), equals(7));

      evalJS('window.$name = 8;');
      // Same code isn't added again:
      expect(await addJavaScriptCode(code), isTrue);
      expect(evalJS('window.$name'), equals(8));
    });

    // Scripts are loaded from an HTTP fixture: `data:` script URLs break
    // `dart test --coverage` (it fetches `<script URL>.map`).
    int fixtureLoads() =>
        (evalJS('window.__dtFixtureLoads || 0') as num).toInt();

    test('addJavaScriptSource', () async {
      final src = 'dom_tools_script_fixture.js?${_unique('head')}';
      addTearDown(() => getScriptElementBySRC(src)?.remove());

      final loadsBefore = fixtureLoads();
      expect(
        await addJavaScriptSource(src).timeout(const Duration(seconds: 5)),
        isTrue,
      );
      expect(fixtureLoads(), equals(loadsBefore + 1));
      expect(getScriptElementBySRC(src)!.parentNode, _sameJS(document.head!));

      // Already in DOM (not loaded again):
      expect(await addJavaScriptSource(src), isTrue);
      expect(fixtureLoads(), equals(loadsBefore + 1));
    });

    test('addJavaScriptSource into body / async', () async {
      final src = 'dom_tools_script_fixture.js?${_unique('body')}';
      addTearDown(() => getScriptElementBySRC(src)?.remove());

      final loadsBefore = fixtureLoads();
      final loaded = addJavaScriptSource(src, addToBody: true, async: true);
      final script = getScriptElementBySRC(src)!;
      expect(script.parentNode, _sameJS(document.body!));
      expect(script.async, isTrue);

      expect(await loaded.timeout(const Duration(seconds: 5)), isTrue);
      expect(fixtureLoads(), equals(loadsBefore + 1));
    });

    // Regression: a failed script load fires an `error` event, which wasn't
    // listened to, so the future never completed.
    test(
      'addJavaScriptSource of a missing script completes with false',
      () async {
        final src = '/__missing_${_unique('s')}__.js';
        addTearDown(() => getScriptElementBySRC(src)?.remove());

        expect(
          await addJavaScriptSource(src).timeout(const Duration(seconds: 10)),
          isFalse,
        );
      },
    );

    test('addJSFunction / callJSFunction', () async {
      final name = _unique('__dt_sum').replaceAll('-', '_');
      expect(await addJSFunction(name, ['a', 'b'], 'return a + b;'), isTrue);
      expect(callJSFunction(name, [2, 3]), equals(5));
      expect(callJSFunction('parseInt', ['42']), equals(42));
      expect(() => addJSFunction('', [], ''), throwsArgumentError);
    });

    test('mapJSFunction', () {
      final name = _unique('__dt_double').replaceAll('-', '_');
      mapJSFunction(name, (o) => (o as num) * 2);
      expect(evalJS('$name(21)'), equals(42));

      final name2 = _unique('__dt_obj').replaceAll('-', '_');
      mapJSFunction(name2, (o) => {'v': (o as Map)['a']});
      expect(evalJS('$name2({a: "x"}).v'), equals('x'));
    });

    test('callJSObjectMethod', () {
      final JSObject array = [1, 2, 3].toJSDeep;
      expect(callJSObjectMethod(array, 'join', ['-']), equals('1-2-3'));
      expect(callJSObjectMethod(array, 'toString'), equals('1,2,3'));
    });

    test('deprecated conversion helpers', () {
      final obj = {'a': 1, 'b': 'x'}.toJSDeep;
      expect(jsObjectKeys(obj), equals(['a', 'b']));
      expect(jsObjectToMap(obj), equals({'a': 1, 'b': 'x'}));
      expect(jsObjectToMap(null), isNull);
      expect(jsToDart(1.toJS), equals(1));
      expect(jsToDart(null), isNull);
      expect(jsArrayToList([1, 'a'].toJSDeep), equals([1, 'a']));
      expect(jsArrayToList(null), isNull);
    });

    test('disableScrolling / enableScrolling', () async {
      _makeWindowScrollable();

      disableScrolling();
      _scrollWindowTo(0, 300);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(window.scrollY, equals(0));

      enableScrolling();
      _scrollWindowTo(0, 300);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(window.scrollY, equals(300));
    });

    test('disableZooming', () {
      disableZooming();
      disableZooming(); // no-op
      expect(evalJS('typeof UIConsole'), equals('function'));
    });

    test('disableDoubleClicks', () {
      disableDoubleClicks();
      disableDoubleClicks(); // no-op

      final event = MouseEvent(
        'dblclick',
        MouseEventInit(bubbles: true, cancelable: true),
      );
      expect(document.body!.dispatchEvent(event), isFalse);
      expect(event.defaultPrevented, isTrue);
    });
  });

  group('scroll', () {
    test('isSafariIOS', () {
      expect(isSafariIOS(), isFalse);
      expect(isSafariIOS(), isFalse); // cached
    });

    test('scrollTo: window', () async {
      _makeWindowScrollable();

      scrollTo(null, 400, smooth: false);
      expect(window.scrollY, equals(400));
      expect(window.scrollX, equals(0));

      scrollTo(120, null, smooth: false);
      expect(window.scrollX, equals(120));
      expect(window.scrollY, equals(400));

      scrollTo(0, 250, smooth: false, delayMs: 20);
      expect(window.scrollY, equals(400));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(window.scrollY, equals(250));

      // Not a Window/Element: resolves to the window.
      scrollTo(0, 100, smooth: false, scrollable: 'x');
      expect(window.scrollY, equals(100));

      scrollTo(0, 200, smooth: false, scrollable: window);
      expect(window.scrollY, equals(200));
    });

    test('scrollTo: element', () {
      final box = _scrollBox();

      scrollTo(30, 40, smooth: false, scrollable: box);
      expect(box.scrollLeft, equals(30));
      expect(box.scrollTop, equals(40));
    });

    test('scrollToTop / scrollToBottom / scrollToLeft / scrollToRight', () {
      _makeWindowScrollable();

      scrollToBottom(smooth: false);
      expect(window.scrollY, greaterThan(0));

      scrollToRight(smooth: false);
      expect(window.scrollX, greaterThan(0));

      scrollToLeft(smooth: false);
      expect(window.scrollX, equals(0));

      scrollToTop(smooth: false, fixSafariIOS: true);
      expect(window.scrollY, equals(0));

      final box = _scrollBox();
      scrollTo(0, 500, smooth: false, scrollable: box);
      scrollToTop(smooth: false, scrollable: box);
      expect(box.scrollTop, equals(0));
      scrollToBottom(smooth: false, scrollable: box);
      expect(box.scrollTop, greaterThan(0));
    });

    test('scrollToTopDelayed', () async {
      _makeWindowScrollable();
      _scrollWindowTo(0, 300);
      scrollToTopDelayed(10);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(window.scrollY, equals(0));
    });

    test('scrollToElement', () {
      _zeroBodyMargin();
      _makeWindowScrollable();

      final target = _attach(
        HTMLDivElement()
          ..style.position = 'absolute'
          ..style.top = '3000px'
          ..style.left = '0px'
          ..style.width = '10px'
          ..style.height = '10px',
      );

      scrollToElement(target, centered: false, smooth: false);
      expect(window.scrollY, equals(3000));

      _scrollWindowTo(0, 0);
      scrollToElement(
        target,
        centered: false,
        smooth: false,
        translateY: -100,
        translateX: 5,
        horizontal: false,
      );
      expect(window.scrollY, equals(2900));
      expect(window.scrollX, equals(0));

      _scrollWindowTo(0, 0);
      scrollToElement(target, smooth: false);
      expect(window.scrollY, equals(3000 - window.innerHeight ~/ 2));
    });

    test('blockVerticalScrollTraverseEvent', () {
      final box = _scrollBox();

      // At the top, scrolling up would traverse the element:
      final up = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: -50, cancelable: true),
      );
      expect(blockVerticalScrollTraverseEvent(box, up), isTrue);
      expect(up.defaultPrevented, isTrue);
      expect(box.scrollTop, equals(0));

      final down = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: 50, cancelable: true),
      );
      expect(blockVerticalScrollTraverseEvent(box, down), isFalse);
      expect(down.defaultPrevented, isFalse);

      // Past the bottom:
      final farDown = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: 5000, cancelable: true),
      );
      expect(blockVerticalScrollTraverseEvent(box, farDown), isTrue);
      expect(box.scrollTop, greaterThan(0));
    });

    test('blockHorizontalScrollTraverseEvent', () {
      final box = _scrollBox();

      final left = WheelEvent(
        'wheel',
        WheelEventInit(deltaX: -50, cancelable: true),
      );
      expect(blockHorizontalScrollTraverseEvent(box, left), isTrue);
      expect(left.defaultPrevented, isTrue);

      final right = WheelEvent(
        'wheel',
        WheelEventInit(deltaX: 50, cancelable: true),
      );
      expect(blockHorizontalScrollTraverseEvent(box, right), isFalse);

      final farRight = WheelEvent(
        'wheel',
        WheelEventInit(deltaX: 5000, cancelable: true),
      );
      expect(blockHorizontalScrollTraverseEvent(box, farRight), isTrue);
      expect(box.scrollLeft, greaterThan(0));
    });

    test('block*ScrollTraverse listeners', () {
      final vertical = _scrollBox();
      blockVerticalScrollTraverse(vertical);
      final e1 = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: -10, cancelable: true),
      );
      expect(vertical.dispatchEvent(e1), isFalse);

      final horizontal = _scrollBox();
      blockHorizontalScrollTraverse(horizontal);
      final e2 = WheelEvent(
        'wheel',
        WheelEventInit(deltaX: -10, cancelable: true),
      );
      expect(horizontal.dispatchEvent(e2), isFalse);

      final both = _scrollBox();
      blockScrollTraverse(both);
      final e3 = WheelEvent(
        'wheel',
        WheelEventInit(deltaX: -10, cancelable: true),
      );
      expect(both.dispatchEvent(e3), isFalse);
      final e4 = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: -10, cancelable: true),
      );
      expect(both.dispatchEvent(e4), isFalse);
      final e5 = WheelEvent(
        'wheel',
        WheelEventInit(deltaY: 10, cancelable: true),
      );
      expect(both.dispatchEvent(e5), isTrue);
    });
  });

  group('document', () {
    test('normalizeIndent', () {
      expect(normalizeIndent(''), isEmpty);
      expect(normalizeIndent('  a\n  b'), equals('  a\n  b'));
      expect(normalizeIndent('  a\n  b\n  c'), equals('a\nb\nc'));
      expect(normalizeIndent('    a\n    b\n  c'), equals('a\nb\n  c'));
      expect(normalizeIndent('a\nb\nc'), equals('a\nb\nc'));
    });

    test('markdownToHtml', () {
      expect(markdownToHtml(''), isEmpty);
      expect(markdownToHtml('# Title').trim(), equals('<h1>Title</h1>'));

      // Regression: the link attributes were inserted HTML-escaped
      // (`target=&quot;_blank&quot;`), so the anchor target was wrong.
      final link = markdownToHtml(
        '[Go](https://example.com/){:target="_blank"}',
      );
      expect(link, contains('target="_blank"'));
      expect(link, contains('href="https://example.com/"'));
      expect(link, isNot(contains('{:')));
      final anchor =
          createDiv(html: link).querySelector('a') as HTMLAnchorElement;
      expect(anchor.target, equals('_blank'));

      expect(markdownToHtml('*a*', inlineOnly: true), equals('<em>a</em>'));
    });

    // Regression: `markdownToDiv` ignored `normalize` (always normalizing).
    test('markdownToDiv', () {
      expect(markdownToDiv('').childNodes.length, equals(0));

      final div = markdownToDiv('**b**');
      expect(div.style.display, equals('inline-block'));
      expect(div.querySelector('strong')!.textContent, equals('b'));

      const indented = '    line1\n    line2\n    line3';
      expect(markdownToDiv(indented).querySelector('pre'), isNull);
      expect(
        markdownToDiv(indented, normalize: false).querySelector('pre code'),
        isNotNull,
      );
    });

    test('dataURLToBlob / getURLData', () async {
      final dataURL = DataURLBase64(
        base64.encode(utf8.encode('hello')),
        'text/plain',
      );
      final blob = dataURLToBlob(dataURL);
      expect(blob.type, equals('text/plain'));
      expect(blob.size, equals(5));

      final url = URL.createObjectURL(blob);
      addTearDown(() => URL.revokeObjectURL(url));
      expect(await _readURLText(url), equals('hello'));
    });

    test('downloadBlob / downloadContent / downloadDataURL', () async {
      var download = await _captureDownload(
        () => downloadBlob(Blob(<JSAny>['blob!'.toJS].toJS), 'b.txt'),
      );
      expect(download.download, equals('b.txt'));
      expect(await _readURLText(download.href), equals('blob!'));

      download = await _captureDownload(
        () =>
            downloadContent(['a', 'b'], MimeType.parse('text/plain')!, 'c.txt'),
      );
      expect(download.download, equals('c.txt'));
      expect(await _readURLText(download.href), equals('ab'));

      download = await _captureDownload(
        () => downloadDataURL(
          DataURLBase64(base64.encode(utf8.encode('data')), 'text/plain'),
          'd.txt',
        ),
      );
      expect(await _readURLText(download.href), equals('data'));

      // The temporary link is removed after the click:
      await Future<void>.delayed(Duration.zero);
      expect(document.querySelectorAll('a[download]').length, equals(0));
    });

    // Regression: each byte was a separate `Blob` part, stringified as a
    // number (`[65, 66, 67]` downloaded as `"656667"`).
    test('downloadBytes', () async {
      final download = await _captureDownload(
        () => downloadBytes(
          [65, 66, 67],
          MimeType.parse('application/octet-stream')!,
          'bytes.bin',
        ),
      );
      expect(download.download, equals('bytes.bin'));
      expect(await getURLData(download.href), equals([65, 66, 67]));
    });

    test('DataAssets', () async {
      final assets = DataAssets();
      addTearDown(assets.clear);

      expect(assets.isEmpty, isTrue);

      final textURL = assets.putContent(
        'text',
        'hi',
        MimeType.parse('text/plain')!,
      )!;
      final pngURL = assets.putData('png', [
        1,
        2,
        3,
      ], MimeType.parse('image/png')!)!;
      final dataURL = assets.putDataURL(
        'data',
        DataURLBase64(base64.encode(utf8.encode('x')), 'audio/mpeg'),
      )!;
      final blobURL = assets.putBlob(
        'blob',
        Blob(<JSAny>['v'.toJS].toJS, BlobPropertyBag(type: 'video/mp4')),
      )!;

      expect(assets.putContent('', 'x', MimeType.parse('text/plain')!), isNull);
      expect(assets.putData('', [], MimeType.parse('text/plain')!), isNull);
      expect(assets.putBlob('', Blob(<JSAny>[].toJS)), isNull);

      expect(assets.isNotEmpty, isTrue);
      expect(assets.length, equals(4));
      expect(assets.ids, equals(['text', 'png', 'data', 'blob']));
      expect(assets.urls, equals([textURL, pngURL, dataURL, blobURL]));
      expect(assets.entries['png'], equals(pngURL));
      expect(assets.getURL('text'), equals(textURL));
      expect(assets.getIDofURL(pngURL), equals('png'));
      expect(assets.getIDofURL(null), isNull);
      expect(assets.getIDofURL('none'), isNull);
      expect(assets.contains('png'), isTrue);

      expect(assets.getIDsWhereMimeTypeIsImage(), equals(['png']));
      expect(assets.getIDsWhereMimeTypeIsAudio(), equals(['data']));
      expect(assets.getIDsWhereMimeTypeIsVideo(), equals(['blob']));
      expect(
        assets.getIDsWhereMimeTypeIsMedia().toSet(),
        equals({'png', 'data', 'blob'}),
      );
      expect(assets.getURLsWhereMimeTypeIsImage(), equals([pngURL]));
      expect(assets.getURLsWhereMimeTypeIsAudio(), equals([dataURL]));
      expect(assets.getURLsWhereMimeTypeIsVideo(), equals([blobURL]));
      expect(assets.getURLsWhereMimeTypeIsMedia().length, equals(3));
      expect(
        assets.getIDsWhereMimeTypeOf(MimeType.parse('image/jpeg')),
        isEmpty,
      );
      expect(
        assets.getIDsWhereMimeTypeOf(
          MimeType.parse('image/jpeg'),
          matchSubType: false,
        ),
        equals(['png']),
      );
      expect(assets.getIDsWhereMimeTypeOf(null), isEmpty);
      expect(assets.getURLofIDs([]), isEmpty);

      expect(await assets.getData('png'), equals([1, 2, 3]));
      expect(assets.getData('none'), isNull);
      expect(await _readURLText(textURL), equals('hi'));

      expect(assets.rename('text', 'text'), isFalse);
      expect(assets.rename('text', ''), isFalse);
      expect(assets.rename('none', 'x'), isFalse);
      expect(assets.rename('text', 'text2'), isTrue);
      expect(assets.getURL('text2'), equals(textURL));
      expect(assets.contains('text'), isFalse);

      expect(assets.remove(''), isFalse);
      expect(assets.remove('none'), isFalse);
      expect(assets.remove('text2'), isTrue);
      expect(assets.length, equals(3));

      final source = MediaSource();
      final sourceURL = assets.putMediaSource(
        'ms',
        source,
        MimeType.parse('video/webm'),
      );
      expect(sourceURL, startsWith('blob:'));
      expect(assets.putMediaSource('', source), isNull);

      assets.clear();
      expect(assets.isEmpty, isTrue);
    });

    test('reloadAssets', () async {
      expect(await reloadAssets({}), isFalse);
      expect(await reloadAssets({' ': 'img'}), isFalse);
    });

    // Regression: the iframe was removed on its 1st `load` instead of being
    // reloaded, so the 2nd `load` never happened: `false` at the timeout, and
    // no completion without one.
    test('reloadAssets of an image', () async {
      final iframesBefore = document.querySelectorAll('iframe').length;
      final ok = await reloadAssets({
        _png1x1: '?',
      }, timeout: const Duration(seconds: 3));
      expect(ok, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(document.querySelectorAll('iframe').length, equals(iframesBefore));

      // Also completes without a timeout:
      expect(await reloadAssets({_png1x1: 'img'}), isTrue);
    });

    test('reloadIframe', () async {
      final iframe = HTMLIFrameElement()..srcdoc = '<p>x</p>'.toJS;
      final firstLoad = iframe.onLoad.first;
      _attach(iframe);
      await firstLoad.timeout(const Duration(seconds: 5));

      final reload = iframe.onLoad.first;
      expect(await reloadIframe(iframe), isTrue);
      await reload.timeout(const Duration(seconds: 5));
    });
  });

  group('touch', () {
    test('touchEventToMouseEvent', () {
      final div = HTMLDivElement();
      final touch = _touch(div);
      if (touch == null) {
        markTestSkipped('Touch creation not supported');
        return;
      }

      for (final (touchType, mouseType) in [
        ('touchstart', 'mousedown'),
        ('touchmove', 'mousemove'),
      ]) {
        final mouse = touchEventToMouseEvent(
          TouchEvent(
            touchType,
            TouchEventInit(touches: [touch].toJS, altKey: true),
          ),
        )!;
        expect(mouse.type, equals(mouseType));
        expect(mouse.clientX, equals(10));
        expect(mouse.clientY, equals(20));
        expect(mouse.screenX, equals(11));
        expect(mouse.screenY, equals(21));
        expect(mouse.altKey, isTrue);
        expect(mouse.button, equals(0));
      }

      expect(
        touchEventToMouseEvent(
          TouchEvent('touchcancel', TouchEventInit(touches: [touch].toJS)),
        ),
        isNull,
      );
      expect(touchEventToMouseEvent(TouchEvent('touchstart')), isNull);
    });

    // Regression: on `touchend` the lifted touch is only in `changedTouches`
    // (`touches` is empty), so it was never converted.
    test('touchEventToMouseEvent: touchend', () {
      final div = HTMLDivElement();
      final touch = _touch(div, x: 5, y: 6);
      if (touch == null) {
        markTestSkipped('Touch creation not supported');
        return;
      }

      final mouse = touchEventToMouseEvent(
        TouchEvent('touchend', TouchEventInit(changedTouches: [touch].toJS)),
      )!;
      expect(mouse.type, equals('mouseup'));
      expect(mouse.clientX, equals(5));
      expect(mouse.clientY, equals(6));
    });

    test('redirectOnTouch*ToMouseEvent', () {
      final div = HTMLDivElement();
      final touch = _touch(div);
      if (touch == null) {
        markTestSkipped('Touch creation not supported');
        return;
      }

      final types = <String>[];
      for (final type in ['mousedown', 'mousemove', 'mouseup']) {
        div.addEventListener(type, ((Event e) => types.add(e.type)).toJS);
      }

      redirectOnTouchStartToMouseEvent(div);
      redirectOnTouchMoveToMouseEvent(div);
      redirectOnTouchEndToMouseEvent(div);

      div.dispatchEvent(
        TouchEvent('touchstart', TouchEventInit(touches: [touch].toJS)),
      );
      div.dispatchEvent(
        TouchEvent('touchmove', TouchEventInit(touches: [touch].toJS)),
      );
      div.dispatchEvent(
        TouchEvent('touchend', TouchEventInit(changedTouches: [touch].toJS)),
      );
      div.dispatchEvent(TouchEvent('touchstart'));

      expect(types, equals(['mousedown', 'mousemove', 'mouseup']));
    });

    test('detectTouchDevice', () async {
      final detections = <TouchDeviceDetection>[];
      final sub = onDetectTouchDevice.listen(detections.add);
      addTearDown(sub.cancel);

      expect(detectTouchDevice(), equals(TouchDeviceDetection.maybe));
      expect(detectTouchDevice(), equals(TouchDeviceDetection.maybe));

      document.body!.dispatchEvent(TouchEvent('touchstart'));
      await Future<void>.delayed(Duration.zero);

      expect(detectTouchDevice(), equals(TouchDeviceDetection.detected));
      expect(detections, equals([TouchDeviceDetection.detected]));

      // Listeners were cancelled: further touches don't fire again.
      document.body!.dispatchEvent(TouchEvent('touchend'));
      await Future<void>.delayed(Duration.zero);
      expect(detections, hasLength(1));
    });
  });
}
