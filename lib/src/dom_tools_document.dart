import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:dom_tools/dom_tools.dart';
import 'package:markdown/markdown.dart' as mk;
import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';
import 'dom_tools_css.dart';

const CODE_THEME_0 = {
  'comment': TextStyle(color: StyleColor(0xffd4d0ab)),
  'quote': TextStyle(color: StyleColor(0xffd4d0ab)),
  'variable': TextStyle(color: StyleColor(0xffffa07a)),
  'template-variable': TextStyle(color: StyleColor(0xffffa07a)),
  'tag': TextStyle(color: StyleColor(0xffffa07a)),
  'name': TextStyle(color: StyleColor(0xffffa07a)),
  'selector-id': TextStyle(color: StyleColor(0xffffa07a)),
  'selector-class': TextStyle(color: StyleColor(0xffffa07a)),
  'regexp': TextStyle(color: StyleColor(0xffffa07a)),
  'deletion': TextStyle(color: StyleColor(0xffffa07a)),
  'number': TextStyle(color: StyleColor(0xfff5ab35)),
  'built_in': TextStyle(color: StyleColor(0xfff5ab35)),
  'builtin-name': TextStyle(color: StyleColor(0xfff5ab35)),
  'literal': TextStyle(color: StyleColor(0xfff5ab35)),
  'type': TextStyle(color: StyleColor(0xfff5ab35)),
  'params': TextStyle(color: StyleColor(0xfff5ab35)),
  'meta': TextStyle(color: StyleColor(0xfff5ab35)),
  'link': TextStyle(color: StyleColor(0xfff5ab35)),
  'attribute': TextStyle(color: StyleColor(0xffffd700)),
  'string': TextStyle(color: StyleColor(0xffabe338)),
  'symbol': TextStyle(color: StyleColor(0xffabe338)),
  'bullet': TextStyle(color: StyleColor(0xffabe338)),
  'addition': TextStyle(color: StyleColor(0xffabe338)),
  'title': TextStyle(color: StyleColor(0xff00e0e0)),
  'section': TextStyle(color: StyleColor(0xff00e0e0)),
  'keyword': TextStyle(color: StyleColor(0xffdcc6e0)),
  'selector-tag': TextStyle(color: StyleColor(0xffdcc6e0)),
  'root': TextStyle(
      backgroundColor: StyleColor(0xff2b2b2b), color: StyleColor(0xfff8f8f2)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

const CODE_THEME_1 = {
  'root': TextStyle(
      color: StyleColor(0xff000000), backgroundColor: StyleColor(0xffffffff)),
  'subst':
      TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff000000)),
  'title':
      TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff000000)),
  'comment':
      TextStyle(color: StyleColor(0xff808080), fontStyle: FontStyle.italic),
  'quote':
      TextStyle(color: StyleColor(0xff808080), fontStyle: FontStyle.italic),
  'meta': TextStyle(color: StyleColor(0xff808000)),
  'tag': TextStyle(backgroundColor: StyleColor(0xffefefef)),
  'section':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'name': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'literal':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'keyword':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-tag':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'type': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-id':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-class':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'attribute':
      TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff0000ff)),
  'number':
      TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'regexp':
      TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'link':
      TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'string':
      TextStyle(color: StyleColor(0xff008000), fontWeight: FontWeight.bold),
  'symbol': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'bullet': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'formula': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'variable': TextStyle(color: StyleColor(0xff660e7a)),
  'template-variable': TextStyle(color: StyleColor(0xff660e7a)),
  'addition': TextStyle(backgroundColor: StyleColor(0xffbaeeba)),
  'deletion': TextStyle(backgroundColor: StyleColor(0xffffc8bd)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

const CODE_THEME_2 = {
  'comment': TextStyle(color: StyleColor(0xff7e7887)),
  'quote': TextStyle(color: StyleColor(0xff7e7887)),
  'variable': TextStyle(color: StyleColor(0xffbe4678)),
  'template-variable': TextStyle(color: StyleColor(0xffbe4678)),
  'attribute': TextStyle(color: StyleColor(0xffbe4678)),
  'regexp': TextStyle(color: StyleColor(0xffbe4678)),
  'link': TextStyle(color: StyleColor(0xffbe4678)),
  'tag': TextStyle(color: StyleColor(0xffbe4678)),
  'name': TextStyle(color: StyleColor(0xffbe4678)),
  'selector-id': TextStyle(color: StyleColor(0xffbe4678)),
  'selector-class': TextStyle(color: StyleColor(0xffbe4678)),
  'number': TextStyle(color: StyleColor(0xffaa573c)),
  'meta': TextStyle(color: StyleColor(0xffaa573c)),
  'built_in': TextStyle(color: StyleColor(0xffaa573c)),
  'builtin-name': TextStyle(color: StyleColor(0xffaa573c)),
  'literal': TextStyle(color: StyleColor(0xffaa573c)),
  'type': TextStyle(color: StyleColor(0xffaa573c)),
  'params': TextStyle(color: StyleColor(0xffaa573c)),
  'string': TextStyle(color: StyleColor(0xff2a9292)),
  'symbol': TextStyle(color: StyleColor(0xff2a9292)),
  'bullet': TextStyle(color: StyleColor(0xff2a9292)),
  'title': TextStyle(color: StyleColor(0xff576ddb)),
  'section': TextStyle(color: StyleColor(0xff576ddb)),
  'keyword': TextStyle(color: StyleColor(0xff955ae7)),
  'selector-tag': TextStyle(color: StyleColor(0xff955ae7)),
  'deletion': TextStyle(
      color: StyleColor(0xff19171c), backgroundColor: StyleColor(0xffbe4678)),
  'addition': TextStyle(
      color: StyleColor(0xff19171c), backgroundColor: StyleColor(0xff2a9292)),
  'root': TextStyle(
      backgroundColor: StyleColor(0xff19171c), color: StyleColor(0xff8b8792)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

final CSSThemeSet CODE_THEME =
    CSSThemeSet('hljs-', [CODE_THEME_0, CODE_THEME_1, CODE_THEME_2], 2);

/// Normalizes a indent, removing the common/global indent of the code.
///
/// Useful to remove indent caused due declaration inside a multiline String
/// with it's own indentation.
String normalizeIndent(String text) {
  if (text.isEmpty) return text;

  var lines = text.split(RegExp(r'[\r\n]'));

  if (lines.length <= 2) return text;

  // ignore: omit_local_variable_types
  Map<String, int> indentCount = {};

  for (var line in lines) {
    var indent = line.split(RegExp(r'\S'))[0];
    var count = indentCount[indent] ?? 0;
    indentCount[indent] = count + 1;
  }

  if (indentCount.isEmpty) return text;

  var identList = List.from(indentCount.keys)
    ..sort((a, b) => indentCount[b]!.compareTo(indentCount[a]!));

  String mainIdent = identList[0];

  if (mainIdent.isEmpty) return text;

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.startsWith(mainIdent)) {
      var line2 = line.substring(mainIdent.length);
      lines[i] = line2;
    }
  }

  var textNorm = lines.join('\n');

  return textNorm;
}

/// Converts a [markdown] document into a HTML in a div node.
///
/// Links are extended to accept attributes:
///
/// ```markdown
///   [Go to Google](https://www.google.com/){:target="_blank"}
/// ```
///
/// [markdown] The markdown document.
/// [normalize] If [true] normalizes indent.
DivElement markdownToDiv(String markdown,
    {bool normalize = true,
    Iterable<mk.BlockSyntax>? blockSyntaxes,
    Iterable<mk.InlineSyntax>? inlineSyntaxes,
    mk.ExtensionSet? extensionSet,
    mk.Resolver? linkResolver,
    mk.Resolver? imageLinkResolver,
    bool inlineOnly = false}) {
  if (markdown.isEmpty) return createDivInline();
  var html = markdownToHtml(markdown,
      blockSyntaxes: blockSyntaxes,
      inlineSyntaxes: inlineSyntaxes,
      extensionSet: extensionSet,
      linkResolver: linkResolver,
      imageLinkResolver: imageLinkResolver,
      inlineOnly: inlineOnly);
  return createDivInline(html);
}

/// Converts a [markdown] document into a HTML string.
///
/// [markdown] The markdown document.
/// [normalize] If [true] normalizes indent.
String markdownToHtml(String markdown,
    {bool normalize = true,
    Iterable<mk.BlockSyntax>? blockSyntaxes,
    Iterable<mk.InlineSyntax>? inlineSyntaxes,
    mk.ExtensionSet? extensionSet,
    mk.Resolver? linkResolver,
    mk.Resolver? imageLinkResolver,
    bool inlineOnly = false}) {
  if (markdown.isEmpty) return '';
  if (normalize) markdown = normalizeIndent(markdown);

  var markdownHtml = mk.markdownToHtml(markdown,
      blockSyntaxes: blockSyntaxes ?? [],
      inlineSyntaxes: inlineSyntaxes ?? [],
      extensionSet: extensionSet,
      linkResolver: linkResolver,
      imageLinkResolver: imageLinkResolver,
      inlineOnly: inlineOnly);

  // allow attributes for url. For example:
  // [GitHub](https://github.com/){:target="_blank"}
  markdownHtml = regExpReplaceAll(
      RegExp(r'(<a.*?)(>.*?</a>){:(.*?)}',
          multiLine: false, caseSensitive: false),
      markdownHtml,
      r'$1 $3$2');

  return markdownHtml;
}

/// Converts a [dataURL] to a [Blob].
Blob dataURLToBlob(DataURLBase64 dataURL) {
  var mimeType = dataURL.mimeTypeAsString;
  var buffer = dataURL.payloadArrayBuffer;
  return Blob([buffer], mimeType);
}

/// Makes a HTTP request and returns [url] content as [Uint8List].
Future<Uint8List> getURLData(String url,
    {String? user, String? password, bool withCredentials = true}) {
  var httpRequest = HttpRequest();

  httpRequest.withCredentials = withCredentials;

  httpRequest.responseType = 'arraybuffer';

  var completer = Completer<Uint8List>();

  httpRequest.onLoad.listen((event) {
    var status = httpRequest.status;
    if (status == 200) {
      var response = httpRequest.response;
      var data = Uint8List.view(response);
      completer.complete(data);
    } else {
      completer.completeError('Invalid response status: $status');
    }
  }, onError: (error) {
    completer.completeError(error);
  });

  httpRequest.onError.listen((event) {
    completer.completeError(event);
  });

  httpRequest.open('GET', url, async: true, user: user, password: password);

  httpRequest.send();

  return completer.future;
}

/// Downloads [dataURL], saving a file with [fileName].
void downloadDataURL(DataURLBase64 dataURL, String fileName) {
  var blob = dataURLToBlob(dataURL);
  downloadBlob(blob, fileName);
}

/// Downloads [content] of type [mimeType], saving a file with [fileName].
void downloadContent(List<String> content, MimeType mimeType, String fileName) {
  var blob = Blob(content, mimeType.toString());
  downloadBlob(blob, fileName);
}

/// Downloads [bytes] of type [mimeType], saving a file with [fileName].
void downloadBytes(List<int> bytes, MimeType mimeType, String fileName) {
  var blob = Blob([bytes], mimeType.toString());
  downloadBlob(blob, fileName);
}

/// Downloads [blob] of type [mimeType], saving a file with [fileName].
void downloadBlob(Blob blob, String fileName) {
  var fileLink = AnchorElement();
  fileLink.style.display = 'none';

  if (isNotEmptyObject(fileName)) fileLink.download = fileName;
  // ignore: unsafe_html
  fileLink.href = Url.createObjectUrlFromBlob(blob);

  fileLink.onClick.listen((event) {
    fileLink.remove();
  });

  document.body!.append(fileLink);

  fileLink.click();
}

class _AssetObjectURL {
  final String objectURL;

  final MimeType? mimeType;

  _AssetObjectURL(this.objectURL, [this.mimeType]);
}

/// A collections of assets (DataURL, Blob, MediaSource) that can be accessed
/// by an `ObjectURL`, avoiding usage and encoding to data URL (base64).
class DataAssets {
  final Map<String, _AssetObjectURL> _assets = {};

  /// Clears all assets and revoke all ObjectURL.
  void clear() {
    for (var id in List.from(_assets.keys)) {
      remove(id);
    }
    _assets.clear();
  }

  bool get isEmpty => _assets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get length => _assets.length;

  /// Returns a List of all IDs.
  List<String> get ids => List<String>.from(_assets.keys);

  /// Returns a List of all URLs.
  List<String> get urls => _assets.values.map((e) => e.objectURL).toList();

  /// Returns a [Map] of ID and ObjectURL pairs.
  Map<String, String> get entries => Map.fromEntries(
      _assets.entries.map((e) => MapEntry(e.key, e.value.objectURL)));

  /// Returns a list of IDs of [mimeType].
  ///
  /// [matchSubType] If [true] also matches the [mimeType.subType].
  List<String> getIDsWhereMimeTypeOf(MimeType? mimeType,
      {bool matchSubType = true}) {
    if (mimeType == null) return [];

    var ids = _assets.entries
        .where((e) {
          var entryMimeType = e.value.mimeType;
          if (entryMimeType == null) return false;

          if (entryMimeType.type == mimeType.type) {
            if (!matchSubType) return true;
            entryMimeType.subType == mimeType.subType;
          }
          return false;
        })
        .map((e) => e.key)
        .toList();

    return ids;
  }

  /// Returns a list of IDs of type 'image/*'.
  List<String> getIDsWhereMimeTypeIsImage() =>
      getIDsWhereMimeTypeOf(MimeType('image', '*'), matchSubType: false);

  /// Returns a list of IDs of type 'video/*'.
  List<String> getIDsWhereMimeTypeIsVideo() =>
      getIDsWhereMimeTypeOf(MimeType('video', '*'), matchSubType: false);

  /// Returns a list of IDs of type 'audio/*'.
  List<String> getIDsWhereMimeTypeIsAudio() =>
      getIDsWhereMimeTypeOf(MimeType('audio', '*'), matchSubType: false);

  /// Returns a list of IDs of type 'image/*', 'video/*' or 'audio/*'.
  List<String> getIDsWhereMimeTypeIsMedia() => <String>{
        ...getIDsWhereMimeTypeIsImage(),
        ...getIDsWhereMimeTypeIsVideo(),
        ...getIDsWhereMimeTypeIsAudio(),
      }.toList();

  /// Returns a list of ObjectURL of type 'image/*'.
  List<String> getURLsWhereMimeTypeIsImage() =>
      getURLofIDs(getIDsWhereMimeTypeIsImage()).whereType<String>().toList();

  /// Returns a list of ObjectURL of type 'video/*'.
  List<String> getURLsWhereMimeTypeIsVideo() =>
      getURLofIDs(getIDsWhereMimeTypeIsVideo()).whereType<String>().toList();

  /// Returns a list of ObjectURL of type 'audio/*'.
  List<String> getURLsWhereMimeTypeIsAudio() =>
      getURLofIDs(getIDsWhereMimeTypeIsAudio()).whereType<String>().toList();

  /// Returns a list of ObjectURL of type 'image/*', 'video/*' or 'audio/*'.
  List<String> getURLsWhereMimeTypeIsMedia() =>
      getURLofIDs(getIDsWhereMimeTypeIsMedia()).whereType<String>().toList();

  /// Returns a list of ObjectURL for [ids].
  List<String?> getURLofIDs(List<String> ids) {
    if (ids.isEmpty) return [];
    return ids.map((id) => getURL(id)).toList();
  }

  /// Returns the ObjectURL of [id].
  String? getURL(String id) => _assets[id]?.objectURL;

  /// Returns the ID of [url].
  String? getIDofURL(String? url) {
    if (url == null) return null;
    for (var entry in _assets.entries) {
      if (entry.value.objectURL == url) {
        return entry.key;
      }
    }
    return null;
  }

  Future<Uint8List>? getData(String id) {
    var url = getURL(id);
    return url != null ? getURLData(url) : null;
  }

  /// Returns [true] if contains [id].
  bool contains(String id) => _assets.containsKey(id);

  /// Changes [id] to [id2].
  bool rename(String id, String id2) {
    if (id == id2) return false;

    if (isEmptyString(id) || isEmptyString(id2)) return false;

    var prev = _assets.remove(id);
    if (prev != null) {
      _assets[id2] = prev;
      return true;
    }
    return false;
  }

  /// Removes asset [id] and revoke ObjectURL.
  bool remove(String id) {
    if (isEmptyString(id)) return false;

    var prev = _assets.remove(id);
    if (prev != null) {
      try {
        Url.revokeObjectUrl(prev.objectURL);
      } catch (e, s) {
        print(e);
        print(s);
      }
      return true;
    }
    return false;
  }

  /// Put an asset [id] of value [content] and [mimeType].
  String? putContent(String id, String content, MimeType mimeType) {
    if (isEmptyString(id)) return null;
    var blob = Blob([content], mimeType.toString());
    return putBlob(id, blob);
  }

  /// Put an asset [id] of value [data].
  String? putData(String id, List<int> data, MimeType mimeType) {
    if (id.isEmpty) return null;
    var blob = Blob([data], mimeType.toString());
    return putBlob(id, blob);
  }

  /// Put an asset [id] of value [dataURL].
  String? putDataURL(String id, DataURLBase64 dataURL) {
    if (id.isEmpty) return null;
    var blob = dataURLToBlob(dataURL);
    return putBlob(id, blob);
  }

  /// Put an asset [id] of value [blob].
  String? putBlob(String id, Blob blob) {
    if (id.isEmpty) return null;
    var objURL = Url.createObjectUrlFromBlob(blob);
    _assets[id] = _AssetObjectURL(objURL, MimeType.parse(blob.type));
    return objURL;
  }

  /// Put an asset [id] of value [source].
  String? putMediaSource(String id, MediaSource source, [MimeType? mimeType]) {
    if (id.isEmpty) return null;
    var objURL = Url.createObjectUrlFromSource(source);
    _assets[id] = _AssetObjectURL(objURL, mimeType);
    return objURL;
  }

  /// Put an asset [id] of value [stream].
  String? putMediaStream(String id, MediaStream stream, [MimeType? mimeType]) {
    if (id.isEmpty) return null;
    var objURL = Url.createObjectUrlFromStream(stream);
    _assets[id] = _AssetObjectURL(objURL, mimeType);
    return objURL;
  }
}

/// Reloads an asset (img, audi or video), forcing reload of asset URL.
///
/// [assetsURLAndTag] A [Map] of URL as key and tag as value. Accepts '?' as tag (will be defined by URL extension).
Future<bool> reloadAssets(Map<String, String> assetsURLAndTag,
    {Duration? timeout}) async {
  if (assetsURLAndTag.isEmpty) return false;

  var doc = '<html><body>';

  var docAssetsCount = 0;
  for (var e in assetsURLAndTag.entries) {
    var url = e.key;
    if (isEmptyString(url, trim: true)) continue;

    var tag = e.value;

    if (isEmptyString(tag, trim: true) || tag == '?') {
      var mimeType = MimeType.byExtension(url);
      tag = mimeType?.htmlTag ?? 'img';
    }

    doc += '<$tag src="$url">';
    docAssetsCount++;
  }

  doc += '</body></html>';

  if (docAssetsCount == 0) return false;

  var iFrame = IFrameElement()
    ..width = '10'
    ..height = '10'
    ..style.display = 'none';

  iFrame.setAttribute('loading', 'eager');

  var completer = Completer<bool>();
  StreamSubscription<Event>? listen;

  var reloadCounter = 0;

  listen = iFrame.onLoad.listen((event) {
    if (reloadCounter == 0) {
      reloadCounter++;
      Future.microtask(() => iFrame.remove());
    } else if (reloadCounter == 1) {
      listen?.cancel();
      completer.complete(true);
      Future.microtask(() => iFrame.remove());
    }
  });

  // ignore: unsafe_html
  iFrame.srcdoc = doc;
  document.body!.append(iFrame);

  if (timeout != null) {
    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        listen?.cancel();
        completer.complete(false);
        Future.microtask(() => iFrame.remove());
      }
    });
  }

  return completer.future;
}

/// Reloads an IFrame document.
Future<bool> reloadIframe(IFrameElement iFrame, [bool? forceGet]) async {
  var loaded = await addJavaScriptCode('''
    window.__dom_tools_reloadIFrame = function(iframe,forceGet) {
      iframe.contentWindow.location.reload(forceGet);
    }
  ''');

  if (!loaded) return false;

  forceGet ??= false;
  callJSFunction('__dom_tools_reloadIFrame', [iFrame, forceGet]);
  return true;
}
