import 'dart:convert';
import 'dart:html';
import 'dart:indexed_db';

import 'package:async_extension/async_extension.dart';
import 'package:json_object_mapper/json_object_mapper.dart';
import 'package:swiss_knife/swiss_knife.dart';

void _consoleLog(Object? error) {
  window.console.error(error);
}

void _consoleError(Object? error) {
  window.console.error(error);
}

abstract class _SimpleStorage {
  bool get isLoaded;

  FutureOr<List<String>> listKeys(String prefix);

  FutureOr<Object?> get(String key);

  FutureOr<bool> set(String key, Object? value);

  FutureOr<bool> remove(String key);

  FutureOr<List<String>> listStorageKeys(String prefix) =>
      listKeys(prefix).resolveMapped((allKeys) {
        var keys = allKeys
            .where((k) => k.endsWith('/time'))
            .map((k) => k.substring(0, k.length - 5))
            .toList();
        return keys;
      });

  FutureOr<bool> setStorageValue(String key, StorageValue value) {
    var r1 = set('$key/time', value.storeTime);
    var r2 = set('$key/value', value.value);
    return r1.resolveBoth(r2, (ok1, ok2) => ok1 && ok2);
  }

  FutureOr<StorageValue?> getStorageValue(String key) {
    var timeValue = get('$key/time');
    if (timeValue == null) return null;

    var value = get('$key/value');

    return timeValue.resolveBoth(value, (timeValue, value) {
      if (timeValue == null) return null;

      var time = timeValue is int ? timeValue : int.parse('$timeValue'.trim());

      var storageValue = StorageValue.stored(time, value);
      return storageValue;
    });
  }

  FutureOr<bool> removeStorageValue(String key) {
    var r1 = remove('$key/time');
    var r2 = remove('$key/value');
    return r1.resolveBoth(r2, (ok1, ok2) => ok1 || ok2);
  }
}

class _SessionSimpleStorage extends _SimpleStorage {
  @override
  bool get isLoaded => true;

  @override
  Object? get(String key) {
    var valueJson = window.sessionStorage[key];
    var value = valueJson == null ? null : json.decode(valueJson);
    return value;
  }

  @override
  List<String> listKeys(String prefix) {
    var keys =
        window.sessionStorage.keys.where((k) => k.startsWith(prefix)).toList();
    return keys;
  }

  @override
  bool remove(String key) {
    var prev = window.sessionStorage.remove(key);
    return prev != null;
  }

  @override
  bool set(String key, Object? value) {
    window.sessionStorage[key] = json.encode(value);
    return true;
  }
}

class _PersistentSimpleStorage extends _SimpleStorage {
  _SimpleStorage? _storage;

  _PersistentSimpleStorage() {
    _loadStorage();
  }

  Future<_SimpleStorage>? _storageLoader;

  Future<_SimpleStorage> _loadStorage() {
    if (_DBSimpleStorage.isSupported) {
      var completer = Completer<_SimpleStorage>();

      _storageLoader = completer.future;

      var db = _DBSimpleStorage();

      db.onLoad.listen((ok) {
        if (ok) {
          _consoleLog('-- Loaded _DBSimpleStorage: $db');
          _onLoadStorage(db);
          completer.complete(db);
        } else {
          var localStorage = _LocalSimpleStorage();
          _consoleLog(
              '[WARN] Error loading _DBSimpleStorage: $db > Using _LocalSimpleStorage: $localStorage');
          _onLoadStorage(localStorage);
          completer.complete(localStorage);
        }
      });

      return completer.future;
    } else {
      var localStorage = _LocalSimpleStorage();
      _onLoadStorage(localStorage);
      return Future.value(localStorage);
    }
  }

  final EventStream<bool> onLoad = EventStream();

  void _onLoadStorage(_SimpleStorage storage) {
    _storage = storage;
    onLoad.add(true);
  }

  FutureOr<_SimpleStorage> _getStorage() {
    var storage = _storage;
    if (storage != null) return storage;
    return _storageLoader!;
  }

  @override
  bool get isLoaded {
    var storage = _storage;
    return storage != null && storage.isLoaded;
  }

  @override
  FutureOr<Object?> get(String key) =>
      _getStorage().resolveMapped((storage) => storage.get(key));

  @override
  FutureOr<List<String>> listKeys(String prefix) =>
      _getStorage().resolveMapped((storage) => storage.listKeys(prefix));

  @override
  FutureOr<bool> remove(String key) =>
      _getStorage().resolveMapped((storage) => storage.remove(key));

  @override
  FutureOr<bool> set(String key, Object? value) =>
      _getStorage().resolveMapped((storage) => storage.set(key, value));
}

class _LocalSimpleStorage extends _SimpleStorage {
  @override
  bool get isLoaded => true;

  @override
  Future<String> get(String key) {
    var valueJson = window.localStorage[key];
    var value = valueJson == null ? null : json.decode(valueJson);
    return Future.value(value);
  }

  @override
  Future<List<String>> listKeys(String prefix) {
    // ignore: omit_local_variable_types
    List<String> keys = [];

    for (var key in window.localStorage.keys) {
      if (key.startsWith(prefix)) {
        keys.add(key);
      }
    }

    return Future.value(keys);
  }

  @override
  Future<bool> remove(String key) {
    window.localStorage.remove(key);
    return Future.value(true);
  }

  @override
  Future<bool> set(String key, Object? value) {
    window.localStorage[key] = json.encode(value);
    return Future.value(true);
  }
}

class _DBSimpleStorage extends _SimpleStorage {
  static const String indexedDbName = 'dom_tools__simple_storage';

  static bool get isSupported {
    return IdbFactory.supported;
  }

  late final Future<Database> _open;

  Database? _db;

  _DBSimpleStorage() {
    _openVersioned();
  }

  void _openVersioned() {
    _open = window.indexedDB!
        .open(indexedDbName, version: 1, onUpgradeNeeded: _initializeDatabase);
    _open.then(_setDB).catchError(_onOpenVersionedError);
  }

  bool _loadError = false;

  bool get loadError => _loadError;

  final EventStream<bool> onLoad = EventStream();

  void _onOpenVersionedError(dynamic error) {
    _consoleError(
        '-- indexedDB open versioned error: $error (isSupported: $isSupported)');
    _loadError = true;
    onLoad.add(false);
  }

  @override
  bool get isLoaded => _db != null;

  void _setDB(Database db) {
    _db = db;
    onLoad.add(true);
  }

  FutureOr<Database> _getDB() {
    var db = _db;
    if (db != null) return db;
    return _open;
  }

  static const String objStore = 'objs';

  void _initializeDatabase(VersionChangeEvent e) {
    Database db = e.target.result;
    db.createObjectStore(objStore, keyPath: 'k', autoIncrement: false);
  }

  @override
  FutureOr<Object?> get(String key) async {
    var db = await _getDB();
    var transaction = db.transaction(objStore, 'readonly');
    var objectStore = transaction.objectStore(objStore);

    var obj = await (objectStore
        .getObject(key)
        .then((value) => value as Map<String, dynamic>?));
    if (obj == null) return null;

    var value = obj['v'];
    return value;
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    var db = await _getDB();
    var transaction = db.transaction(objStore, 'readonly');
    var objectStore = transaction.objectStore(objStore);

    var cursors = objectStore.openCursor(autoAdvance: true);

    var keys = await cursors
        .where((cursor) {
          var k = cursor.key as String;
          return k.startsWith(prefix);
        })
        .map((cursor) => cursor.key as String)
        .toList();

    return keys;
  }

  @override
  Future<bool> remove(String key) async {
    var db = await _getDB();
    var transaction = db.transaction(objStore, 'readwrite');
    var objectStore = transaction.objectStore(objStore);
    return objectStore.delete(key).then((_) => true);
  }

  @override
  Future<bool> set(String key, Object? value) async {
    var db = await _getDB();
    var transaction = db.transaction(objStore, 'readwrite');
    var objectStore = transaction.objectStore(objStore);

    var obj = <String, Object?>{'k': key, 'v': value};

    return objectStore.put(obj).then((dbKey) => dbKey != null);
  }
}

/// Type of [DataStorage].
enum DataStorageType {
  /// Data is persistent between sessions.
  persistent,

  /// Data is available ony in the current browser session.
  session
}

/// Represents a persistent storage in the browser.
///
/// It uses the available storage for implementation.
class DataStorage {
  static final _SimpleStorage _sessionStorage = _SessionSimpleStorage();

  static final _SimpleStorage _persistentStorage = _PersistentSimpleStorage();

  static bool isValidKeyName(String key) {
    if (key.contains('/')) return false;
    if (key.contains(RegExp('\\s'))) return false;
    return true;
  }

  /// ID of this storage.
  final String id;

  /// Type of this storage.
  final DataStorageType storageType;

  late _SimpleStorage _simpleStorage;

  DataStorage(this.id, [this.storageType = DataStorageType.session]) {
    if (!isValidKeyName(id)) {
      throw ArgumentError('Invalid DataStorage id: $id');
    }

    _simpleStorage = storageType == DataStorageType.persistent
        ? _persistentStorage
        : _sessionStorage;
  }

  final Map<String, State> _states = {};

  /// Returns a [List<State>] stored in this storage.
  List<State> getStates() {
    return List.from(_states.values);
  }

  /// Returns a [List<String>] of stored [State] names.
  List<String> getStatesNames() {
    return List.from(_states.keys);
  }

  /// Registers a [state].
  bool registerState(State state) {
    if (_states.containsKey(state.name)) return false;
    _states[state.name] = state;
    return true;
  }

  /// Unregister a [State] by [name].
  State? unregisterState(String name) {
    var prev = _states.remove(name);
    return prev;
  }

  /// Creates a [State] with [stateName].
  State createState(String stateName) {
    var state = getState(stateName);
    state ??= State(this, stateName);
    return state;
  }

  /// Gets a stored [State] with [name].
  State? getState(String name) {
    return _states[name];
  }

  /// Returns [true] if this storage contains a [State] with [name].
  bool containsState(String name) {
    return _states[name] != null;
  }

  FutureOr<StorageValue?> _getStorageValue(String fullKey) async {
    try {
      var storageValue = _simpleStorage.getStorageValue(fullKey);
      return storageValue;
    } catch (e, s) {
      _consoleError('DataStorage[$id]> Error loading key: $fullKey >> $e');
      _consoleError(s);
      return null;
    }
  }

  FutureOr<bool> _loadState(State state) {
    var storageRootKey = state.storageRootKey;

    return _simpleStorage.listStorageKeys(storageRootKey).resolveMapped((keys) {
      var keysAndValuesAsync = keys
          .map((k) => MapEntry(k, _getStorageValue(k)))
          .toMapFromEntries()
          .resolveAllValues();

      return keysAndValuesAsync.resolveMapped((keysAndValues) {
        for (var e in keysAndValues.entries) {
          var value = e.value;
          if (value != null) {
            var key = e.key.substring(storageRootKey.length);
            state._setStorageValue(key, value, false);
          }
        }
        return true;
      });
    });
  }

  void _onStateChange(State state, String key, dynamic value) {
    var storageKey = state.getStorageKey(key);

    if (value == null) {
      _simpleStorage.removeStorageValue(storageKey);
    } else {
      var storageValue = StorageValue(value);
      _simpleStorage.setStorageValue(storageKey, storageValue);
    }
  }
}

/// Represents a value stored in [State].
class StorageValue extends JSONObject {
  /// Time of storage.
  final int storeTime;

  /// The stored value.
  Object? value;

  @override
  List<String> getObjectFields() {
    return ['storeTime', 'value'];
  }

  StorageValue(this.value) : storeTime = DateTime.now().millisecondsSinceEpoch;

  StorageValue.stored(this.storeTime, this.value);

  @override
  String toString() {
    return 'StorageValue{storeTime: $storeTime, value: $value}';
  }
}

/// State operation.
enum StateOperation {
  load,
  set,
  all,
}

typedef StateEventListener = void Function(
    StateOperation op, State state, String key, dynamic value);
typedef StateKeyListener = void Function(dynamic value);

/// A state stored in [DataStorage].
class State {
  /// The storage of this state.
  final DataStorage storage;

  /// Name of this state.
  final String name;

  State(this.storage, this.name) {
    if (!DataStorage.isValidKeyName(name)) {
      throw ArgumentError('Invalid State name: $name');
    }

    if (!storage.registerState(this)) {
      throw StateError(
          'DataStorage[${storage.id}] already have a registered State[$name]!');
    }

    _load();
  }

  bool _loaded = false;

  /// Returns [true] if this state is already loaded.
  /// See [onLoad] and [waitLoaded].
  bool get isLoaded => _loaded;

  Future<bool>? _waitingLoad;

  /// Waits for this [State] load.
  /// See [onLoad] and [isLoaded].
  FutureOr<bool> waitLoaded() {
    if (isLoaded) return true;

    var waitingLoad = _waitingLoad ??= onLoad.first.then((ok) {
      _waitingLoad = null;
      return ok;
    });

    return waitingLoad;
  }

  /// Fired when this [State] is loaded.
  /// See [waitLoaded] and [isLoaded].
  final EventStream<bool> onLoad = EventStream();

  void _load() {
    storage._loadState(this).resolveMapped((loaded) {
      _loaded = loaded;

      try {
        onLoad.add(loaded);
      } catch (e) {
        _consoleError(e);
      }
    });
  }

  State fireLoadedKeysEvents() {
    for (var key in _properties.keys) {
      var value = _properties[key];
      _notifyChange(StateOperation.load, key, value);
    }
    return this;
  }

  FutureOr<R> _callLoaded<R>(FutureOr<R> Function() call) {
    if (isLoaded) {
      return call();
    } else {
      return waitLoaded().resolveMapped((val) => call());
    }
  }

  String get storageRootKey => '${storage.id}/$name/';

  /// Returns the internal storage key for [key].
  String getStorageKey(String key) {
    return storageRootKey + key;
  }

  final Map<String, Object?> _properties = {};

  /// Returns the storage keys in this state.
  List<String> get keys => List.from(_properties.keys);

  /// Same as [keys], but async.
  Future<List<String>> getKeysAsync() async {
    if (isLoaded) return keys;

    return onLoad.listenAsFuture().then((_) {
      return keys;
    });
  }

  void _setStorageValue(String key, StorageValue storageValue, bool overwrite) {
    if (!overwrite && _properties.containsKey(key)) return;
    _properties[key] = storageValue.value;
  }

  /// Remove [key].
  dynamic remove(String key) {
    return set(key, null);
  }

  /// Sets [key] to [value].
  V? set<V>(String key, V? value) {
    var prev = _properties[key];
    _properties[key] = value;

    _notifyChange(StateOperation.set, key, value);

    return prev as V?;
  }

  /// Sets [key] to [value] if not stored yet.
  bool setIfAbsent<V>(String key, V? value) {
    if (!_properties.containsKey(key)) {
      _properties[key] = value;
      _notifyChange(StateOperation.set, key, value);
      return true;
    } else {
      return false;
    }
  }

  /// Gets the value of [key] in async mode.
  Future<V?> getAsync<V>(String key) async {
    if (isLoaded) return get<V>(key);
    return _callLoaded<V?>(() => get<V>(key));
  }

  /// Gets [key] value. If absent returns [defaultValue].
  Future<V?> getOrDefaultAsync<V>(String key, dynamic defaultValue) async {
    if (isLoaded) return getOrDefault<V>(key, defaultValue);
    return _callLoaded<V?>(() => getOrDefault<V>(key, defaultValue));
  }

  /// Gets [key] value. If absent sets the key to [defaultValue] and returns it.
  Future<V?> getOrSetDefaultAsync<V>(String key, dynamic defaultValue) async {
    if (isLoaded) return getOrSetDefault<V>(key, defaultValue);
    return _callLoaded<V?>(() => getOrSetDefault<V>(key, defaultValue));
  }

  /// Gets [key] value.
  ///
  /// Note, this [State] should be already loaded [isLoaded].
  V? get<V>(String key) {
    return _properties[key] as V?;
  }

  /// Gets [key] value or returns [defaultValue].
  ///
  /// Note, this [State] should be already loaded [isLoaded].
  V? getOrDefault<V>(String key, V? defaultValue) {
    if (!_properties.containsKey(key)) {
      return defaultValue;
    } else {
      return _properties[key] as V?;
    }
  }

  /// Gets [key] value. If absent sets the key value to [defaultValue] and returns it.
  ///
  /// Note, this [State] should be already loaded [isLoaded].
  V? getOrSetDefault<V>(String key, V? defaultValue) {
    if (!_properties.containsKey(key)) {
      _properties[key] = defaultValue;
      _notifyChange(StateOperation.set, key, defaultValue);
      return defaultValue;
    } else {
      return _properties[key] as V?;
    }
  }

  void _notifyChange(StateOperation op, String key, dynamic value) {
    if (op == StateOperation.set) {
      try {
        storage._onStateChange(this, key, value);
      } catch (e, s) {
        _consoleError(e);
        _consoleError(s);
      }
    }

    try {
      _fireEvent(op, this, key, value);
    } catch (e, s) {
      _consoleError(e);
      _consoleError(s);
    }
  }

  /// Listen for [op] events.
  ///
  /// [op] The [StateOperation] to listen.
  /// [listener] The listener callback.
  State listen(StateOperation op, StateEventListener listener) {
    _registerEventListener(op, listener);
    return this;
  }

  /// Listen all events.
  ///
  /// [listener] The listener callback.
  State listenAll(StateEventListener listener) {
    _registerEventListener(StateOperation.all, listener);
    return this;
  }

  /// Listen for a specific [key] events.
  ///
  /// [listener] The listener callback.
  State listenKey(String key, StateKeyListener listener) {
    _registerKeyListener(key, listener);
    return this;
  }

  final Map<String, List<StateKeyListener>> _keyListeners = {};

  void _registerKeyListener(String key, StateKeyListener listener) {
    var listeners = _keyListeners[key];
    if (listeners == null) _keyListeners[key] = listeners = [];
    listeners.add(listener);
  }

  final Map<StateOperation, List<StateEventListener>> _eventListeners = {};

  void _registerEventListener(StateOperation op, StateEventListener listener) {
    var listeners = _eventListeners[op];
    if (listeners == null) _eventListeners[op] = listeners = [];
    listeners.add(listener);
  }

  void _fireEvent(StateOperation op, State state, String key, dynamic value) {
    var eventListeners = _eventListeners[op];
    var eventListenersAll = _eventListeners[StateOperation.all];

    if (eventListenersAll != null) {
      eventListeners ??= [];
      eventListeners.addAll(eventListenersAll);
    }

    if (eventListeners != null && eventListeners.isNotEmpty) {
      for (var listener in eventListeners) {
        try {
          listener(op, state, key, value);
        } catch (e, s) {
          _consoleError(e);
          _consoleError(s);
        }
      }
    }

    var keyListeners = _keyListeners[key];

    if (keyListeners != null && keyListeners.isNotEmpty) {
      for (var listener in keyListeners) {
        try {
          listener(value);
        } catch (e, s) {
          _consoleError(e);
          _consoleError(s);
        }
      }
    }
  }
}

extension IterableMapEntryExtension<K, V> on Iterable<MapEntry<K, V>> {
  /// Converts this [Iterable] of [MapEntry] to a [Map].
  Map<K, V> toMapFromEntries() => Map<K, V>.fromEntries(this);
}
