import 'dart:async';
import 'dart:js_interop_unsafe';
import 'dart:math';

import 'package:dom_tools/dom_tools.dart';
import 'package:web/web.dart';

bool? _safariIOS;

bool isSafariIOS() {
  var safariIOS = _safariIOS;
  if (safariIOS != null) return safariIOS;

  var userAgent = window.navigator.userAgent.toLowerCase();

  safariIOS = userAgent.contains('safari') &&
      RegExp(r'ip(?:ad|od|hone)').hasMatch(userAgent);

  _safariIOS = safariIOS;

  return safariIOS;
}

void _callAsync(int delayMs, void Function() f) {
  if (delayMs < 1) {
    f();
  } else {
    Future.delayed(Duration(milliseconds: delayMs), f);
  }
}

/// Scrolls viewport to [x],[y].
/// - If [smooth] is `true` will animate the scroll.
/// - If [delayMs] >= 1 it will scroll after a [Future.delayed]. (value in milliseconds)
/// - [scrollable] is the element to scroll. If `null` it will be the [window] or the [body],
///   identifying which one is scrolled.
void scrollTo(num? x, num? y,
    {bool smooth = true, int? delayMs, Object? scrollable}) {
  if (delayMs != null && delayMs > 0) {
    _callAsync(
        delayMs, () => scrollTo(x, y, smooth: smooth, scrollable: scrollable));
    return;
  }

  var scrollableResolved = _resolveScrollable(scrollable);

  var params = JSObject();
  if (x != null) params.setProperty('left'.toJS, x.toInt().toJS);
  if (y != null) params.setProperty('top'.toJS, y.toInt().toJS);
  if (smooth) params.setProperty('behavior'.toJS, 'smooth'.toJS);

  if (scrollableResolved.isA<Window>()) {
    (scrollableResolved as Window).scrollTo(params);
  } else if (scrollableResolved.isA<Element>()) {
    (scrollableResolved as Element).scrollTo(params);
  } else {
    window.scrollTo(params);
  }
}

JSObject? _resolveScrollable(Object? scrollable) {
  var jsAny = scrollable.asJSAny;

  if (!jsAny.isA<Window>() && !jsAny.isA<Element>()) {
    jsAny = null;
  }

  if (jsAny.isA<JSObject>()) {
    return jsAny as JSObject;
  } else {
    final body = document.body!;

    final windowScrolled = window.scrollY != 0 || window.scrollX != 0;
    final bodyScrolled = body.scrollTop != 0 || body.scrollLeft != 0;

    if (bodyScrolled && !windowScrolled) {
      return body;
    } else {
      return window;
    }
  }
}

/// Use [scrollToTop] instead.
@Deprecated("Use `scrollToTop` with parameter `delayMs`.")
void scrollToTopDelayed(int delayMs) {
  scrollToTop(delayMs: delayMs);
}

/// Scrolls viewport to the top.
///
/// - If [fixSafariIOS] is `true` it will detect Safari on iOS ([isSafariIOS])
///   and will use [y] as `1` (not `0`) to avoid a bug with direct scroll to `0`,
///   where `smooth` is ignored and the viewport position is vertically shifted
///   even at `scrollX == 0`. Bug still present on iOS 16.4 (latest version on current date).
/// - See [scrollTo].
void scrollToTop(
    {bool smooth = true, int y = 0, bool fixSafariIOS = false, int? delayMs}) {
  if (fixSafariIOS && y == 0 && isSafariIOS()) {
    y = 1;
  }

  scrollTo(window.scrollX, y, smooth: smooth, delayMs: delayMs);
}

/// Scrolls viewport to the bottom.
///
/// - See [scrollTo].
void scrollToBottom({bool smooth = true, int? delayMs}) =>
    scrollTo(window.scrollX, document.body!.scrollHeight,
        smooth: smooth, delayMs: delayMs);

/// Scrolls viewport to the left border.
///
/// - See [scrollTo].
void scrollToLeft({bool smooth = true, int? delayMs}) =>
    scrollTo(0, window.scrollY, smooth: smooth, delayMs: delayMs);

/// Scrolls viewport to the right border.
///
/// - See [scrollTo].
void scrollToRight({bool smooth = true, int? delayMs}) =>
    scrollTo(document.body!.scrollWidth, window.scrollY,
        smooth: smooth, delayMs: delayMs);

/// Scrolls the viewport to the [element].
///
/// - If `centered` is true, tries to center the element in the viewport.
/// - If `vertical` is true only does a vertical scroll.
/// - If `horizontal` is true only does a horizontal scroll.
/// - If `smooth` is true does a smooth scroll animation.
/// - [scrollable] is the element to scroll. If `null` it will be the [window] or the [body],
///   identifying which one is scrolled.
void scrollToElement(
  HTMLElement element, {
  bool centered = true,
  bool vertical = true,
  bool horizontal = true,
  bool smooth = true,
  int? translateX,
  int? translateY,
  Object? scrollable,
}) {
  var pos = getElementDocumentPosition(element);

  var x = pos.a;
  var y = pos.b;

  if (translateX != null) {
    x += translateX;
  }

  if (translateY != null) {
    y += translateY;
  }

  if (centered) {
    var w = window.innerWidth;
    var h = window.innerHeight;

    x = max(0, x - (w ~/ 2));
    y = max(0, y - (h ~/ 2));
  }

  scrollTo(
    horizontal ? x : null,
    vertical ? y : null,
    smooth: smooth,
    scrollable: scrollable,
  );
}

/// Blocks a scroll event in the vertical direction that traverses the [element].
void blockVerticalScrollTraverse(HTMLElement element) {
  element.onWheel
      .listen((event) => blockVerticalScrollTraverseEvent(element, event));
}

/// Blocks a scroll event in the horizontal direction that traverses the [element].
void blockHorizontalScrollTraverse(HTMLElement element) {
  element.onWheel
      .listen((event) => blockHorizontalScrollTraverseEvent(element, event));
}

/// Blocks a scroll event in the vertical and horizontal directions that traverses the [element].
void blockScrollTraverse(HTMLElement element) {
  element.onWheel.listen((event) {
    var block = blockVerticalScrollTraverseEvent(element, event);
    if (!block) {
      blockHorizontalScrollTraverseEvent(element, event);
    }
  });
}

/// Blocks a [wheelEvent] in the vertical direction that traverses the [element].
bool blockVerticalScrollTraverseEvent(
    HTMLElement element, WheelEvent wheelEvent) {
  var delta = -wheelEvent.deltaY;
  var up = delta > 0;

  var height = element.offsetHeight;
  var scrollTop = element.scrollTop;
  var scrollHeight = element.scrollHeight;

  var block = false;
  if (!up && -delta > scrollHeight - height - scrollTop) {
    //Scrolling down, but this will take us past the bottom.
    element.scrollTop = scrollHeight;
    block = true;
  } else if (up && delta > scrollTop) {
    //Scrolling up, but this will take us past the top.
    element.scrollTop = 0;
    block = true;
  }

  if (block) {
    wheelEvent.stopPropagation();
    wheelEvent.preventDefault();
  }

  return block;
}

/// Blocks a [wheelEvent] in the horizontal direction that traverses the [element].
bool blockHorizontalScrollTraverseEvent(
    HTMLElement element, WheelEvent wheelEvent) {
  var delta = -wheelEvent.deltaX;
  var left = delta > 0;

  var width = element.offsetWidth;
  var scrollLeft = element.scrollLeft;
  var scrollWidth = element.scrollWidth;

  var block = false;
  if (!left && -delta > scrollWidth - width - scrollLeft) {
    //Scrolling right, but this will take us past the right limit.
    element.scrollLeft = scrollWidth;
    block = true;
  } else if (left && delta > scrollLeft) {
    //Scrolling left, but this will take us past the left limit.
    element.scrollLeft = 0;
    block = true;
  }

  if (block) {
    wheelEvent.stopPropagation();
    wheelEvent.preventDefault();
  }

  return block;
}
