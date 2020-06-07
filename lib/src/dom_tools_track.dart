import 'dart:async';
import 'dart:html';

import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';

class _ElementTrack<T> {
  final TrackElementValue _trackElementValue;

  final Element _element;

  final ElementValueGetter<T> _elementValueGetter;

  final bool _periodicTracking;

  final OnElementTrackValueEvent<T> _onTrackValueEvent;

  T _lastCheck_value;

  _ElementTrack(
      this._trackElementValue,
      this._element,
      this._elementValueGetter,
      this._periodicTracking,
      this._onTrackValueEvent);

  T _initialize() {
    _lastCheck_value = _elementValueGetter(_element);

    _notifyValue(_lastCheck_value);

    return _lastCheck_value;
  }

  void check() {
    var value = _elementValueGetter(_element);

    if (!isEquals(value, _lastCheck_value)) {
      _notifyValue(value);
    }

    _lastCheck_value = value;
  }

  void _notifyValue(T value) {
    var keepTracking;
    try {
      keepTracking = _onTrackValueEvent(_element, value);
    } catch (e, s) {
      print(e);
      print(s);
      keepTracking = false;
    }

    var untrack;

    if (keepTracking != null) {
      untrack = !keepTracking;
    } else {
      untrack = !_periodicTracking;
    }

    if (untrack) {
      _trackElementValue.untrack(_element);
    }
  }
}

typedef OnElementTrackValueEvent<T> = bool Function(Element element, T value);

/// Tracks a DOM [Element] to identify when a value changes.
class TrackElementValue {
  Duration _checkInterval;

  TrackElementValue([Duration checkInterval]) {
    _checkInterval = checkInterval ?? Duration(milliseconds: 250);
  }

  final Map<Element, _ElementTrack> _elements = {};

  /// Tracks [element] using [elementValueGetter] to catch the value.
  ///
  /// [element] The element to track.
  /// [elementValueGetter] The value getter.
  /// [onTrackValueEvent] Callback to call when value changes.
  /// [periodicTracking] If [true] this tracking will continue after first event.
  T track<T>(Element element, ElementValueGetter<T> elementValueGetter,
      OnElementTrackValueEvent<T> onTrackValueEvent,
      [bool periodicTracking]) {
    if (element == null ||
        elementValueGetter == null ||
        onTrackValueEvent == null) return null;

    if (_elements.containsKey(element)) return null;

    periodicTracking ??= false;

    var elementTrack = _ElementTrack(
        this, element, elementValueGetter, periodicTracking, onTrackValueEvent);
    _elements[element] = elementTrack;

    var initialValue = elementTrack._initialize();

    _scheduleCheck();

    return initialValue;
  }

  /// Untracks [element].
  T untrack<T>(Element element) {
    var removed = _elements.remove(element);

    _elementsProperties.remove(element);

    if (_elements.isEmpty) {
      _cancelTimer();
    }

    return removed != null ? removed._lastCheck_value : null;
  }

  /// Checks tracked elements for values changes.
  void checkElements() {
    if (_elements.isEmpty) return;

    // ignore: omit_local_variable_types
    List<_ElementTrack> values = List.from(_elements.values);

    for (var elem in values) {
      elem.check();
    }
  }

  Timer _timer;

  void _scheduleCheck() {
    _timer ??= Timer.periodic(_checkInterval, _checkFromTimer);
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  void _checkFromTimer(Timer timer) {
    if (_elements.isEmpty) {
      _cancelTimer();
    } else {
      checkElements();
    }
  }

  final Map<Element, Map<String, dynamic>> _elementsProperties = {};

  dynamic setProperty(Element element, String key, dynamic value) {
    var elemProps = _elementsProperties[element];
    if (elemProps == null) {
      _elementsProperties[element] = elemProps = {};
    }
    var prev = elemProps[key];
    elemProps[key] = value;
    return prev;
  }

  dynamic getProperty(Element element, String key) {
    var elemProps = _elementsProperties[element];
    return elemProps != null ? elemProps[key] : null;
  }
}

typedef OnElementEvent = void Function(Element element);

/// Tracks a DOM [Element] to identify when its visible in viewport.
class TrackElementInViewport {
  TrackElementValue _trackElementValue;

  TrackElementInViewport([Duration checkInterval]) {
    _trackElementValue = TrackElementValue(checkInterval);
  }

  /// Tracks [element] if it's visible in viewport.
  ///
  /// Useful to track when an element is visible for the 1st time,
  /// usually due scrolling.
  ///
  /// [element] The element to track
  /// [onEnterViewport] Callback to call when element shows up in viewport.
  /// [onLeaveViewport] Callback to call when element leaves viewport.
  /// [periodicTracking] If [true] this tracking will continue after first event.
  bool track(Element element,
      {OnElementEvent onEnterViewport,
      OnElementEvent onLeaveViewport,
      bool periodicTracking}) {
    if (element == null ||
        (onEnterViewport == null && onLeaveViewport == null)) {
      return null;
    }

    periodicTracking ??= false;

    var initValue = _trackElementValue
        .track(element, (elem) => isInViewport(elem), (elem, show) {
      if (show) {
        _trackElementValue.setProperty(element, 'viewport', true);
        if (onEnterViewport != null) onEnterViewport(element);
        return periodicTracking || onLeaveViewport != null;
      } else {
        var alreadyViewed =
            _trackElementValue.getProperty(element, 'viewport') ?? false;
        if (onLeaveViewport != null) onLeaveViewport(element);
        return !alreadyViewed || periodicTracking;
      }
    });

    return initValue == true;
  }

  /// Untracks [element].
  void untrack(Element element) {
    _trackElementValue.untrack(element);
  }
}

/// Tracks a DOM [Element] to identify when its size changes.
class TrackElementResize {
  TrackElementValue _trackElementValueInstance;

  TrackElementValue get _trackElementValue {
    if (_trackElementValueInstance == null) {
      _trackElementValueInstance = TrackElementValue();
      window.onResize.listen((e) => _onResizeWindow());
    }

    return _trackElementValueInstance;
  }

  ResizeObserver _resizeObserverInstance;

  bool _resizeObserverInstanceError = false;

  ResizeObserver get _resizeObserver {
    if (_resizeObserverInstanceError) return null;

    if (_resizeObserverInstance == null) {
      try {
        var observer = ResizeObserver(_onResizeObserver);
        _resizeObserverInstance = observer;
      } catch (e, s) {
        _resizeObserverInstanceError = true;

        print(e);
        print(s);
      }
    }

    return _resizeObserverInstance;
  }

  /// Tracks [element] resize events.
  ///
  /// [element] Element to track.
  /// [onResize] Callback to call when size changes.
  void track(Element element, OnElementEvent onResize) {
    var resizeObserver = _resizeObserver;

    if (resizeObserver != null) {
      _track_ResizeObserver(resizeObserver, element, onResize);
      return;
    }

    var trackElementValue = _trackElementValue;

    if (trackElementValue != null) {
      _track_elementValue(trackElementValue, element, onResize);
      return;
    }

    throw UnsupportedError("Can't track element resize");
  }

  /// Untracks [element].
  void untrack(Element element) {
    var resizeObserver = _resizeObserver;

    if (resizeObserver != null) {
      _untrack_ResizeObserver(resizeObserver, element);
      return;
    }

    var trackElementValue = _trackElementValue;

    if (trackElementValue != null) {
      trackElementValue.untrack(element);
      return;
    }

    throw UnsupportedError("Can't track element resize");
  }

  final Map<Element, OnElementEvent> _resizeObserverListeners = {};

  void _track_ResizeObserver(
      ResizeObserver resizeObserver, Element element, OnElementEvent onResize) {
    _resizeObserverListeners[element] = onResize;
    resizeObserver.observe(element);
  }

  void _untrack_ResizeObserver(ResizeObserver resizeObserver, Element element) {
    resizeObserver.unobserve(element);
    _resizeObserverListeners.remove(element);
  }

  void _onResizeObserver(
      List<ResizeObserverEntry> entries, ResizeObserver observer) {
    for (var entry in entries) {
      var elem = entry.target;
      var listener = _resizeObserverListeners[elem];
      if (listener != null) {
        try {
          listener(elem);
        } catch (e, s) {
          print(e);
          print(s);
        }
      }
    }
  }

  void _track_elementValue(TrackElementValue trackElementValue, Element element,
      OnElementEvent onResize) {
    trackElementValue.track(element, (e) => e.offset, (e, v) {
      onResize(e);
      return true;
    }, true);
  }

  void _onResizeWindow() {
    _trackElementValueInstance.checkElements();
  }
}
