import 'dart:async';
import 'dart:js_interop_unsafe';

import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';
import 'dom_tools_extension.dart';

class _ElementTrack<T> {
  final TrackElementValue _trackElementValue;

  final Element _element;

  final ElementValueGetter<T> _elementValueGetter;

  final bool _periodicTracking;

  final OnElementTrackValueEvent<T> _onTrackValueEvent;

  T? _lastCheckValue;

  _ElementTrack(
      this._trackElementValue,
      this._element,
      this._elementValueGetter,
      this._periodicTracking,
      this._onTrackValueEvent);

  T? _initialize() {
    _lastCheckValue = _elementValueGetter(_element);

    _notifyValue(_lastCheckValue);

    return _lastCheckValue;
  }

  void check() {
    var value = _elementValueGetter(_element);

    if (!isEquals(value, _lastCheckValue)) {
      _notifyValue(value);
    }

    _lastCheckValue = value;
  }

  void _notifyValue(T? value) {
    bool keepTracking;
    try {
      keepTracking = _onTrackValueEvent(_element, value);
    } catch (e, s) {
      print(e);
      print(s);
      keepTracking = false;
    }

    var untrack = !keepTracking;

    if (untrack) {
      _trackElementValue.untrack(_element);
    }
  }
}

typedef OnElementTrackValueEvent<T> = bool Function(Element element, T? value);

/// Tracks a DOM [Element] to identify when a value changes.
class TrackElementValue {
  late final Duration _checkInterval;

  TrackElementValue([Duration? checkInterval]) {
    _checkInterval = checkInterval ?? Duration(milliseconds: 250);
  }

  final Map<Element, _ElementTrack> _elements = {};

  /// Tracks [element] using [elementValueGetter] to catch the value.
  ///
  /// [element] The element to track.
  /// [elementValueGetter] The value getter.
  /// [onTrackValueEvent] Callback to call when value changes.
  /// [periodicTracking] If [true] this tracking will continue after first event.
  T? track<T>(Element? element, ElementValueGetter<T>? elementValueGetter,
      OnElementTrackValueEvent<T>? onTrackValueEvent,
      {bool periodicTracking = false}) {
    if (element == null ||
        elementValueGetter == null ||
        onTrackValueEvent == null) {
      return null;
    }

    if (_elements.containsKey(element)) return null;

    var elementTrack = _ElementTrack(
        this, element, elementValueGetter, periodicTracking, onTrackValueEvent);
    _elements[element] = elementTrack;

    var initialValue = elementTrack._initialize();

    _scheduleCheck();

    return initialValue;
  }

  /// Untracks [element].
  T? untrack<T>(Element element) {
    var removed = _elements.remove(element);

    _elementsProperties.remove(element);

    if (_elements.isEmpty) {
      _cancelTimer();
    }

    return removed?._lastCheckValue;
  }

  /// Checks tracked elements for values changes.
  void checkElements() {
    if (_elements.isEmpty) return;

    var values = _elements.values.toList(growable: false);

    for (var e in values) {
      e.check();

      if (!e._periodicTracking) {
        _elements.remove(e._element);
      }
    }
  }

  Timer? _timer;

  void _scheduleCheck() {
    _timer ??= Timer.periodic(_checkInterval, _checkFromTimer);
  }

  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
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

  Object? setProperty(Element element, String key, Object? value) {
    var elemProps = _elementsProperties[element];
    if (elemProps == null) {
      _elementsProperties[element] = elemProps = {};
    }
    var prev = elemProps[key];
    elemProps[key] = value;
    return prev;
  }

  Object? getProperty(Element element, String key) {
    var elemProps = _elementsProperties[element];
    return elemProps != null ? elemProps[key] : null;
  }
}

typedef OnElementEvent = void Function(Element element);

/// Tracks a DOM [Element] to identify when its visible in viewport.
class TrackElementInViewport {
  late TrackElementValue _trackElementValue;

  TrackElementInViewport([Duration? checkInterval]) {
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
      {OnElementEvent? onEnterViewport,
      OnElementEvent? onLeaveViewport,
      bool periodicTracking = false}) {
    if ((onEnterViewport == null && onLeaveViewport == null)) {
      return false;
    }

    var initValue = _trackElementValue
        .track<bool>(element, (elem) => isInViewport(elem), (elem, show) {
      if (show!) {
        _trackElementValue.setProperty(element, 'viewport', true);
        if (onEnterViewport != null) onEnterViewport(element);
        return periodicTracking || onLeaveViewport != null;
      } else {
        var alreadyViewed =
            _trackElementValue.getProperty(element, 'viewport') ?? false;
        if (onLeaveViewport != null) onLeaveViewport(element);
        return !(alreadyViewed as bool) || periodicTracking;
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
  TrackElementValue? _trackElementValueInstance;

  TrackElementValue? get _trackElementValue {
    if (_trackElementValueInstance == null) {
      _trackElementValueInstance = TrackElementValue();

      window.addEventListener(
          'onresize',
          (Event e) {
            _onResizeWindow();
          }.toJS);
    }

    return _trackElementValueInstance;
  }

  ResizeObserver? _resizeObserverInstance;

  bool _resizeObserverInstanceError = false;

  ResizeObserver? get _resizeObserver {
    if (_resizeObserverInstanceError) return null;

    if (_resizeObserverInstance == null) {
      try {
        ResizeObserver? observer;
        observer = ResizeObserver((JSArray? ar) {
          var l = ar?.toList() ?? [];
          _onResizeObserver(l, observer!);
        }.toJS);
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
      _trackResizeObserver(resizeObserver, element, onResize);
      return;
    }

    var trackElementValue = _trackElementValue;

    if (trackElementValue != null) {
      _trackResizeFallbackByElementValue(trackElementValue, element, onResize);
      return;
    }

    throw UnsupportedError("Can't track element resize");
  }

  /// Untracks [element].
  void untrack(Element element) {
    var resizeObserver = _resizeObserver;

    if (resizeObserver != null) {
      _untrackResizeObserver(resizeObserver, element);
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

  void _trackResizeObserver(
      ResizeObserver resizeObserver, Element element, OnElementEvent onResize) {
    _resizeObserverListeners[element] = onResize;
    resizeObserver.observe(element);
  }

  void _untrackResizeObserver(ResizeObserver resizeObserver, Element element) {
    resizeObserver.unobserve(element);
    _resizeObserverListeners.remove(element);
  }

  void _onResizeObserver(List entries, ResizeObserver observer) {
    var targets = _getEntriesTargets(entries);

    for (var elem in targets) {
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

  List<Element> _getEntriesTargets(List entries) {
    var targets = <Element>[];

    for (var entry in entries) {
      if (entry is ResizeObserverEntry) {
        var target = entry.target;
        targets.add(target);
      } else if (entry is JSObject) {
        var target = entry['target'];
        if (target is Element) {
          targets.add(target);
        }
      }
    }

    return targets;
  }

  void _trackResizeFallbackByElementValue(TrackElementValue trackElementValue,
      Element element, OnElementEvent onResize) {
    trackElementValue.track<Object>(element, (e) {
      var element = e.asHTMLElement;
      return (element?.offsetWidth, element?.offsetHeight);
    }, (e, v) {
      onResize(e);
      return true;
    }, periodicTracking: true);
  }

  void _onResizeWindow() {
    _trackElementValueInstance?.checkElements();
  }
}
