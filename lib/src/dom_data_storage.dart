
import 'dart:async';
import 'dart:html';
import 'dart:indexed_db';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:json_object_mapper/json_object_mapper.dart';

////////////////////////////////////

abstract class _SimpleStorage {

  bool isLoaded() ;

  Future<List<String>> listKeys(String prefix) ;

  Future<String> get(String key) ;
  Future<bool> set(String key, String value) ;
  Future<bool> remove(String key) ;

  Future<List<String>> listStorageKeys(String prefix) async {
    var keys1 = await listKeys(prefix);
    var keys2 = keys1.where((k) => k.endsWith('/time')).map((k) => k.substring(0,k.length-5));
    // ignore: omit_local_variable_types
    List<String> list = List.from(keys2).cast() ;
    return Future.value(list) ;
  }

  Future<bool> setStorageValue(String key, StorageValue value) {
    set('$key/time', value.storeTime.toString()) ;
    set('$key/value', value.value) ;
    return Future.value(true) ;
  }

  Future<StorageValue> getStorageValue(String key) async {
    var timeStr = await get('$key/time') ;
    if (timeStr == null) return null ;

    var value = await get('$key/value') ;

    var time = int.parse(timeStr) ;

    var storageValue = StorageValue.stored(time , value) ;
    return storageValue ;
  }

  Future<bool> removeStorageValue(String key) {
    remove('$key/time') ;
    remove('$key/value') ;
    return Future.value(true) ;
  }

}

class _SessionSimpleStorage extends _SimpleStorage {

  @override
  bool isLoaded() {
    return true ;
  }

  @override
  Future<String> get(String key) {
    var value = window.sessionStorage[key];
    return Future.value(value) ;
  }

  @override
  Future<List<String>> listKeys(String prefix) {
    // ignore: omit_local_variable_types
    List<String> keys = [] ;

    for (var key in window.sessionStorage.keys) {
      if (key.startsWith(prefix)) {
        keys.add(key);
      }
    }

    return Future.value(keys) ;
  }

  @override
  Future<bool> remove(String key) {
    window.sessionStorage.remove(key) ;
    return Future.value(true) ;
  }

  @override
  Future<bool> set(String key, String value) {
    window.sessionStorage[key] = value ;
    return Future.value(true) ;
  }

}

class _PersistentSimpleStorage extends _SimpleStorage {

  _SimpleStorage _storage ;

  _PersistentSimpleStorage() {
    _loadStorage() ;
  }

  Future<_SimpleStorage> _storageLoader ;

  Future<_SimpleStorage> _loadStorage() {
    if ( _DBSimpleStorage.isSupported ) {
      var completer = Completer<_SimpleStorage>() ;

      _storageLoader = completer.future ;

      var db = _DBSimpleStorage();

      db.onLoad.listen( (ok) {
        if (ok) {
          print('Loaded _DBSimpleStorage: $db') ;
          _onLoadStorage(db);
          completer.complete(db) ;
        }
        else {
          var localStorage = _LocalSimpleStorage() ;
          print('Error loading _DBSimpleStorage: $db > Using _LocalSimpleStorage: $localStorage') ;
          _onLoadStorage(localStorage);
          completer.complete(localStorage) ;
        }
      } );

      return completer.future ;
    }
    else {
      var localStorage = _LocalSimpleStorage() ;
      _onLoadStorage(localStorage);
      return Future.value( localStorage ) ;
    }
  }

  final EventStream<bool> onLoad = EventStream() ;

  void _onLoadStorage(_SimpleStorage storage) {
    _storage = storage ;
    onLoad.add(true);
  }

  Future<_SimpleStorage> _getStorage() {
    if (_storage != null) return Future.value(_storage) ;
    return _storageLoader ;
  }

  @override
  bool isLoaded() {
    return _storage != null && _storage.isLoaded() ;
  }

  @override
  Future<String> get(String key) async {
    var storage = await _getStorage() ;
    return storage.get(key);
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    var storage = await _getStorage() ;
    return storage.listKeys(prefix);
  }

  @override
  Future<bool> remove(String key) async {
    var storage = await _getStorage() ;
    return storage.remove(key);
  }

  @override
  Future<bool> set(String key, String value) async {
    var storage = await _getStorage() ;
    return storage.set(key, value);
  }

}

class _LocalSimpleStorage extends _SimpleStorage {

  @override
  bool isLoaded() {
    return true ;
  }

  @override
  Future<String> get(String key) {
    var value = window.localStorage[key];
    return Future.value(value) ;
  }

  @override
  Future<List<String>> listKeys(String prefix) {
    // ignore: omit_local_variable_types
    List<String> keys = [] ;

    for (var key in window.localStorage.keys) {
      if (key.startsWith(prefix)) {
        keys.add(key);
      }
    }

    return Future.value(keys) ;
  }

  @override
  Future<bool> remove(String key) {
    window.localStorage.remove(key) ;
    return Future.value(true) ;
  }

  @override
  Future<bool> set(String key, String value) {
    window.localStorage[key] = value ;
    return Future.value(true) ;
  }

}

class _DBSimpleStorage extends _SimpleStorage {

  static final String INDEXED_DB_NAME = 'dom_tools__simple_storage' ;

  static bool get isSupported {
    return IdbFactory.supported ;
  }

  Future<Database> _open ;
  Database _db ;

  _DBSimpleStorage() {
    _openVersioned();
  }

  void _openVersioned() {
    _open = window.indexedDB.open(INDEXED_DB_NAME, version: 1, onUpgradeNeeded: _initializeDatabase) ;
    _open.then( _setDB ).catchError( _onOpenVersionedError ) ;
  }

  bool _loadError = false ;

  bool get loadError => _loadError;

  final EventStream<bool> onLoad = EventStream() ;

  void _onOpenVersionedError(dynamic error) {
    print('indexedDB open versioned error: $error > $isSupported') ;
    _loadError = true ;
    onLoad.add(false) ;
  }

  @override
  bool isLoaded() {
    return _db != null ;
  }

  void _setDB(Database db) {
    _db = db ;
    onLoad.add(true) ;
  }

  Future<Database> _getDB() {
    if (_db != null) return Future.value(_db) ;
    return _open ;
  }

  static final String OBJ_STORE = 'objs' ;

  void _initializeDatabase(VersionChangeEvent e) {
    Database db = e.target.result;
    db.createObjectStore(OBJ_STORE, keyPath: 'k', autoIncrement: false);
  }

  @override
  Future<String> get(String key) async {
    var db = await _getDB();
    var transaction = db.transaction(OBJ_STORE, 'readonly') ;
    var objectStore = transaction.objectStore(OBJ_STORE);
    Map obj = await objectStore.getObject(key);
    if (obj == null) return null ;
    String value = obj['v'] ;
    return value ;
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    var db = await _getDB();
    var transaction = db.transaction(OBJ_STORE, 'readonly') ;
    var objectStore = transaction.objectStore(OBJ_STORE);

    // ignore: omit_local_variable_types
    List<String> keys = [] ;

    var cursors = objectStore.openCursor(autoAdvance: true).asBroadcastStream();
    cursors.listen((cursor) {
      String k = cursor.key;
      if ( k.startsWith(prefix) ) {
        keys.add( k ) ;
      }
    });

    return cursors.length.then((_) {
      return keys ;
    });
  }

  @override
  Future<bool> remove(String key) async {
    var db = await _getDB();
    var transaction = db.transaction(OBJ_STORE, 'readwrite') ;
    var objectStore = transaction.objectStore(OBJ_STORE);
    return objectStore.delete(key).then((_) {
      return true ;
    });
  }

  @override
  Future<bool> set(String key, String value) async {
    var db = await _getDB();
    var transaction = db.transaction(OBJ_STORE, 'readwrite') ;
    var objectStore = transaction.objectStore(OBJ_STORE);

    // ignore: omit_local_variable_types
    Map<String,String> obj = {
      'k': key,
      'v': value
    } ;

    return objectStore.put(obj).then( (dbKey) {
      return dbKey != null ;
    } ) ;
  }


}

////////////////////////////////////

enum DataStorageType {
  PERSISTENT,
  SESSION
}

class DataStorage {

  static final _SimpleStorage _sessionStorage = _SessionSimpleStorage() ;
  static final _SimpleStorage _persistentStorage = _PersistentSimpleStorage() ;

  static bool isValidKeyName(String key) {
    if (key.contains('/')) return false ;
    if (key.contains(RegExp('\\s'))) return false ;
    return true ;
  }

  final String id ;
  final DataStorageType storageType ;

  _SimpleStorage _simpleStorage ;

  DataStorage(this.id, [this.storageType = DataStorageType.SESSION]) {
    if ( !isValidKeyName(id) ) {
      throw ArgumentError('Invalid DataStorage id: $id') ;
    }

    _simpleStorage = storageType == DataStorageType.PERSISTENT ? _persistentStorage : _sessionStorage ;
  }

  final Map<String, State> _states = {} ;

  List<State> getStates() {
    return List.from(_states.values) ;
  }

  List<State> getStatesNames() {
    return List.from(_states.keys) ;
  }

  bool registerState(State state) {
    if ( _states.containsKey(state.name) ) return false ;
    _states[ state.name ] = state ;
    return true ;
  }

  State unregisterState(String name) {
    var prev = _states.remove(name);
    return prev ;
  }

  State createState(String stateName) {
    var state = getState(stateName);
    state ??= State(this, stateName);
    return state ;
  }

  State getState(String name) {
    return _states[name];
  }

  bool containsState(String name) {
    return _states[name] != null ;
  }

  Future<StorageValue> _getStorageValue(String fullKey) async {
    try {
      var storageValue = await _simpleStorage.getStorageValue(fullKey) ;
      return storageValue ;
    }
    catch (e,s) {
      window.console.error('DataStorage[$id]> Error loading key: $fullKey >> $e') ;
      window.console.error(s) ;
      return null ;
    }
  }

  Future<bool> _loadState(State state) async {
    var storageRootKey = state.storageRootKey ;

    var keys = await _simpleStorage.listStorageKeys(storageRootKey) ;

    for (var storageKey in keys) {
      var storageValue = await _getStorageValue(storageKey);
      if (storageValue == null) continue ;

      var key = storageKey.substring(storageRootKey.length) ;
      state._setStorageValue(key, storageValue, false);
    }

    return true ;
  }

  void _onStateChange(State state, String key, dynamic value) {
    var storageKey = state.getStorageKey(key);

    if (value == null) {
      _simpleStorage.removeStorageValue(storageKey) ;
    }
    else {
      var storageValue = StorageValue(value) ;
      _simpleStorage.setStorageValue(storageKey, storageValue) ;
    }
  }

}

class StorageValue extends JSONObject {

  int storeTime ;
  String value ;

  @override
  List<String> getObjectFields() {
    return ['storeTime', 'value'] ;
  }

  StorageValue(this.value) {
    storeTime = DateTime.now().millisecondsSinceEpoch ;
  }

  StorageValue.stored(this.storeTime, this.value) ;

  @override
  String toString() {
    return 'StorageValue{storeTime: $storeTime, value: $value}';
  }

}

enum StateOperation {
  LOAD,
  SET,
  ALL,
}

typedef StateEventListener = void Function(StateOperation op, State state, String key, dynamic value);
typedef StateKeyListener = void Function(dynamic value);

class State {

  final DataStorage storage;
  final String name ;

  State(this.storage, this.name) {
    if ( !DataStorage.isValidKeyName(name) ) {
      throw ArgumentError('Invalid State name: $name') ;
    }

    if ( !storage.registerState(this) ) {
      throw StateError('DataStorage[${ storage.id }] already have a registered State[$name]!') ;
    }

    _load() ;
  }

  bool _loaded = false ;

  bool get isLoaded => _loaded ;

  final EventStream<bool> onLoad = EventStream() ;

  void _load() {
    storage._loadState(this).then((loaded) {
      _loaded = loaded ;

      try {
        onLoad.add(loaded);
      } catch (e) {
        print(e);
      }
    }) ;
  }

  State fireLoadedKeysEvents() {
    for (var key in _properties.keys) {
      var value = _properties[key];
      _notifyChange(StateOperation.LOAD, key, value);
    }
    return this ;
  }

  String get storageRootKey => storage.id +'/'+ name +'/' ;

  String getStorageKey(String key) {
    return storageRootKey + key ;
  }

  final Map<String,dynamic> _properties = {} ;

  List<String> get keys => List.from(_properties.keys) ;

  Future<List<String>> getKeysAsync() async {
    if (isLoaded) return keys ;

    return onLoad.listenAsFuture().then((_){
      return keys ;
    });
  }

  void _setStorageValue(String key, StorageValue storageValue, bool overwrite) {
    if (!overwrite && _properties.containsKey(key)) return ;
    _properties[key] = storageValue.value ;
  }

  dynamic remove(String key) {
    return set(key, null);
  }

  dynamic set(String key, dynamic value) {
    var prev = _properties[key] ;
    _properties[key] = value ;

    _notifyChange(StateOperation.SET, key, value);

    return prev ;
  }

  bool setIfAbsent(String key, dynamic value) {
    if ( !_properties.containsKey(key) ) {
      _properties[key] = value ;
      _notifyChange(StateOperation.SET, key, value);
      return true ;
    }
    else {
      return false ;
    }
  }

  Future getAsync(String key) async {
    if (isLoaded) return get(key) ;
    return onLoad.listen((_){
      get(key) ;
    });
  }

  Future getOrDefaultAsync(String key, dynamic defaultValue) async {
    if (isLoaded) return getOrDefault(key, defaultValue) ;
    return onLoad.listen((_){
      getOrDefault(key, defaultValue) ;
    });
  }

  Future getOrSetDefaultAsync(String key, dynamic defaultValue) async {
    if (isLoaded) return getOrSetDefault(key, defaultValue) ;
    return onLoad.listen((_){
      getOrSetDefault(key, defaultValue) ;
    });
  }

  dynamic get(String key) {
    return _properties[key] ;
  }

  dynamic getOrDefault(String key, dynamic defaultValue) {
    if ( !_properties.containsKey(key) ) {
      return defaultValue ;
    }
    else {
      return _properties[key] ;
    }
  }

  dynamic getOrSetDefault(String key, dynamic defaultValue) {
    if ( !_properties.containsKey(key) ) {
      _properties[key] = defaultValue ;
      _notifyChange(StateOperation.SET, key, defaultValue);
      return defaultValue ;
    }
    else {
      return _properties[key] ;
    }
  }

  void _notifyChange(StateOperation op, String key, dynamic value) {
    if (op == StateOperation.SET) {
      try {
        storage._onStateChange(this, key, value);
      }
      catch (exception, stackTrace) {
        print(exception);
        print(stackTrace);
      }
    }

    try {
      _fireEvent(op, this, key, value) ;
    }
    catch (exception, stackTrace) {
      print(exception);
      print(stackTrace);
    }
  }

  ///////////////////////////////////////////////////

  State listen(StateOperation op, StateEventListener listener) {
    _registerEventListener(op, listener);
    return this ;
  }

  State listenAll(StateEventListener listener) {
    _registerEventListener(StateOperation.ALL, listener);
    return this ;
  }

  State listenKey(String key, StateKeyListener listener) {
    _registerKeyListener(key, listener);
    return this ;
  }

  ///////////////////////////////////////////////////

  final Map<String, List<StateKeyListener>> _keyListeners = {} ;

  void _registerKeyListener(String key, StateKeyListener listener) {
    var listeners = _keyListeners[key] ;
    if (listeners == null) _keyListeners[key] = listeners = [] ;
    listeners.add(listener) ;
  }

  final Map<StateOperation, List<StateEventListener>> _eventListeners = {} ;

  void _registerEventListener(StateOperation op, StateEventListener listener) {
    var listeners = _eventListeners[op] ;
    if (listeners == null) _eventListeners[op] = listeners = [] ;
    listeners.add(listener) ;
  }

  void _fireEvent(StateOperation op, State state, String key, dynamic value) {
    var eventListeners = _eventListeners[op] ;
    var eventListenersAll = _eventListeners[StateOperation.ALL] ;

    if (eventListenersAll != null) {
      eventListeners ??= [];
      eventListeners.addAll(eventListenersAll) ;
    }

    if (eventListeners != null && eventListeners.isNotEmpty) {
      for (var listener in eventListeners) {
        try {
          listener(op, state, key, value);
        }
        catch (exception, stackTrace) {
          print(exception);
          print(stackTrace);
        }
      }
    }

    var keyListeners = _keyListeners[key] ;

    if (keyListeners != null && keyListeners.isNotEmpty) {
      for (var listener in keyListeners) {
        try {
          listener(value);
        }
        catch (exception, stackTrace) {
          print(exception);
          print(stackTrace);
        }
      }
    }

  }

}



