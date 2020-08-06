import 'dart:async';
import 'dart:html';

import 'package:swiss_knife/swiss_knife.dart';

/// Status type of touch device detection.
enum TouchDeviceDetection {
  UNKNOWN,
  NONE,
  MAYBE,
  DETECTED,
}

TouchDeviceDetection _detectTouchDevice;

List<StreamSubscription<TouchEvent>> _detectTouchDeviceListen = [];

/// Will fire a [TouchDeviceDetection] when detection finishes.
final EventStream<TouchDeviceDetection> onDetectTouchDevice = EventStream();

/// Starts touch device detection. Returns the current status.
TouchDeviceDetection detectTouchDevice() {
  if (_detectTouchDevice == null) {
    _detectTouchDevice = TouchDeviceDetection.UNKNOWN;

    try {
      _detectTouchDeviceListen
          .add(document.body.onTouchStart.listen(_onTouchEvent));
      _detectTouchDeviceListen
          .add(document.body.onTouchEnd.listen(_onTouchEvent));
      _detectTouchDeviceListen
          .add(document.body.onTouchMove.listen(_onTouchEvent));

      _detectTouchDevice = TouchDeviceDetection.MAYBE;
    } catch (e) {
      _detectTouchDevice = TouchDeviceDetection.NONE;
      onDetectTouchDevice.add(TouchDeviceDetection.NONE);
    }
  }

  return _detectTouchDevice;
}

void _onTouchEvent(event) {
  for (var listen in _detectTouchDeviceListen) {
    try {
      listen.cancel();
      // ignore: empty_catches
    } catch (e) {}
  }
  _detectTouchDeviceListen = [];

  _detectTouchDeviceListen = null;
  _detectTouchDevice = TouchDeviceDetection.DETECTED;

  onDetectTouchDevice.add(TouchDeviceDetection.DETECTED);
}

/// Converts a [TouchEvent] [event] to a [MouseEvent].
///
/// This helps to use [TouchEvent] as normal [MouseEvent],
/// simplifying UI support for touch events and mouse events.
MouseEvent touchEventToMouseEvent(TouchEvent event) {
  var touches = event.changedTouches;
  if (touches == null || touches.isEmpty) return null;

  var first = touches[0];
  var type = '';

  switch (event.type.toLowerCase()) {
    case 'touchstart':
      type = 'mousedown';
      break;
    case 'touchmove':
      type = 'mousemove';
      break;
    case 'touchend':
      type = 'mouseup';
      break;
    default:
      return null;
  }

  var target = event.target;

  var simulatedEvent = MouseEvent(type,
      canBubble: true,
      cancelable: true,
      view: window,
      detail: 1,
      screenX: first.screen.x,
      screenY: first.screen.y,
      clientX: first.client.x,
      clientY: first.client.y,
      ctrlKey: false,
      altKey: false,
      shiftKey: false,
      metaKey: false,
      button: 0,
      relatedTarget: target);

  return simulatedEvent;
}

/// Redirects [element.onTouchStart] to [element.onMouseDown] as [MouseEvent].
void redirect_onTouchStart_to_MouseEvent(Element element) {
  element.onTouchStart.listen((event) {
    var mouseEvent = touchEventToMouseEvent(event);
    element.dispatchEvent(mouseEvent);
  });
}

/// Redirects [element.onTouchMove] to [element.onMouseMove] as [MouseEvent].
void redirect_onTouchMove_to_MouseEvent(Element element) {
  element.onTouchMove.listen((event) {
    var mouseEvent = touchEventToMouseEvent(event);
    element.dispatchEvent(mouseEvent);
  });
}

/// Redirects [element.onTouchEnd] to [element.onMouseUp] as [MouseEvent].
void redirect_onTouchEnd_to_MouseEvent(Element element) {
  element.onTouchEnd.listen((event) {
    var mouseEvent = touchEventToMouseEvent(event);
    element.dispatchEvent(mouseEvent);
  });
}
