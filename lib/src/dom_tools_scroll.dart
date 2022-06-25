import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'dom_tools_base.dart';

/// Scrolls viewport to the top with a delay.
///
/// [delayMs] Delay in milliseconds.
void scrollToTopDelayed(int delayMs) {
  if (delayMs < 1) {
    scrollToTop();
  } else {
    Future.delayed(Duration(milliseconds: delayMs), scrollToTop);
  }
}

/// Scrolls viewport to the top.
void scrollToTop() {
  window.scrollTo(window.scrollX, 0, {'behavior': 'smooth'});
}

/// Scrolls viewport to the bottom.
void scrollToBottom() {
  window.scrollTo(
      window.scrollX, document.body!.scrollHeight, {'behavior': 'smooth'});
}

/// Scrolls viewport to the left border.
void scrollToLeft() {
  window.scrollTo(0, window.scrollY, {'behavior': 'smooth'});
}

/// Scrolls viewport to the right border.
void scrollToRight() {
  window.scrollTo(
      document.body!.scrollWidth, window.scrollY, {'behavior': 'smooth'});
}

/// Scrolls the viewport to the [element].
///
/// - If `centered` is true, tries to center the element in the viewport.
/// - If `vertical` is true only does a vertical scroll.
/// - If `horizontal` is true only does a horizontal scroll.
/// - If `smooth` is true does a smooth scroll animation .
void scrollToElement(Element element,
    {bool centered = true,
    bool vertical = true,
    bool horizontal = true,
    bool smooth = true}) {
  var pos = getElementDocumentPosition(element);

  var x = pos.a;
  var y = pos.b;

  if (centered) {
    var w = window.innerWidth ?? 0;
    var h = window.innerHeight ?? 0;

    x = max(0, x - (w ~/ 2));
    y = max(0, y - (h ~/ 2));
  }

  window.scrollTo({
    if (horizontal) 'left': x,
    if (vertical) 'top': y,
    if (smooth) 'behavior': 'smooth',
  });
}

/// Blocks a scroll event in the vertical direction that traverses the [element].
void blockVerticalScrollTraverse(Element element) {
  element.onWheel
      .listen((event) => blockVerticalScrollTraverseEvent(element, event));
}

/// Blocks a scroll event in the horizontal direction that traverses the [element].
void blockHorizontalScrollTraverse(Element element) {
  element.onWheel
      .listen((event) => blockHorizontalScrollTraverseEvent(element, event));
}

/// Blocks a scroll event in the vertical and horizontal directions that traverses the [element].
void blockScrollTraverse(Element element) {
  element.onWheel.listen((event) {
    var block = blockVerticalScrollTraverseEvent(element, event);
    if (!block) {
      blockHorizontalScrollTraverseEvent(element, event);
    }
  });
}

/// Blocks a [wheelEvent] in the vertical direction that traverses the [element].
bool blockVerticalScrollTraverseEvent(Element element, WheelEvent wheelEvent) {
  var delta = -wheelEvent.deltaY;
  var up = delta > 0;

  var height = element.offset.height;
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
    Element element, WheelEvent wheelEvent) {
  var delta = -wheelEvent.deltaX;
  var left = delta > 0;

  var width = element.offset.width;
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
