import 'dart:async';
import 'dart:convert' as data_convert;
import 'dart:typed_data';

import 'package:swiss_knife/swiss_knife.dart';
import 'package:web_utils/web_utils.dart' hide MimeType;

import 'dom_tools_base.dart';
import 'dom_tools_paint.dart';

/// Reads selected file of [input] as [Uint8List].
Future<Uint8List?> readFileInputElementAsArrayBuffer(HTMLInputElement? input,
    [bool removeExifFromImage = false]) async {
  if (input == null) return null;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  var file = files.item(0)!;

  Uint8List? data;
  if (removeExifFromImage) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parsePayloadAsArrayBuffer(dataURL);
    }
  }

  data ??= await readFileDataAsArrayBuffer(file);

  return data;
}

/// Reads selected file of [input] as [String].
Future<String?> readFileInputElementAsString(HTMLInputElement? input,
    [bool removeExifFromImage = false]) async {
  if (input == null) return null;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  var file = files.item(0)!;

  String? data;
  if (removeExifFromImage) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parseMimeTypeAsString(dataURL);
    }
  }

  data ??= await readFileDataAsText(file);

  return data;
}

/// Reads selected file of [input] as Base64.
Future<String?> readFileInputElementAsBase64(HTMLInputElement? input,
    [bool removeExifFromImage = false]) async {
  if (input == null) return null;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  var file = files.item(0)!;

  String? data;
  if (removeExifFromImage) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parsePayloadAsBase64(dataURL);
    }
  }

  data ??= await readFileDataAsBase64(file);

  return data;
}

/// Reads selected file of [input] as DATA URL Base64.
Future<String?> readFileInputElementAsDataURLBase64(HTMLInputElement? input,
    [bool removeExifFromImage = false]) async {
  if (input == null) return null;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  var file = files.item(0)!;

  String? data;
  if (removeExifFromImage) {
    data = await removeExifFromImageFile(file);
  }

  data ??= await readFileDataAsDataURLBase64(file);

  return data;
}

/// Reads selected file of [input] and return a [Blob] URL.
Future<String?> readFileInputElementAsBlobUrl(HTMLInputElement? input,
    [bool removeExifFromImage = false]) async {
  if (input == null) return null;

  final files = input.files;
  if (files == null || files.isEmpty) return null;

  var file = files.item(0)!;

  String? data;
  if (removeExifFromImage) {
    data = await removeExifFromImageFile(file);
  }

  if (data == null) {
    data = await readFileDataAsBlobURL(file);
  } else if (data.startsWith('data:')) {
    var dataUrlBase64 = DataURLBase64.parse(data);
    if (dataUrlBase64 != null) {
      data = createBlobURL(
          dataUrlBase64.payloadArrayBuffer, dataUrlBase64.mimeTypeAsString);
    }
  }

  return data;
}

/// Removes Exif from JPEG [file].
///
/// Returns null if no operation was performed.
Future<String?> removeExifFromImageFile(File file) async {
  var mimeType = getFileMimeType(file);

  if (mimeType != null && mimeType.isImageJPEG) {
    var fileURL = await readFileDataAsBlobURL(file);

    if (fileURL != null) {
      var img = HTMLImageElement()..src = fileURL;

      await _yeld();

      await elementOnLoad(img);

      await _yeld();

      var canvas = toCanvasElement(img, img.naturalWidth, img.naturalHeight);

      await _yeld();

      revokeBlobURL(fileURL);

      await _yeld();

      var dataUrl = canvas.toDataUrl('image/png', 0.99);

      await _yeld();

      return dataUrl;
    }
  }

  return null;
}

/// Returns the [file] [MimeType].
///
/// [accept] the accept attribute when file was selected.
MimeType? getFileMimeType(File file, [String accept = '']) {
  var mimeType = MimeType.byExtension(file.name, defaultAsApplication: false);
  if (mimeType != null) return mimeType;

  var fileExtension = getPathExtension(file.name) ?? '';
  fileExtension = fileExtension.toLowerCase().trim();

  if (fileExtension == 'jpg') fileExtension = 'jpeg';

  accept = accept.toLowerCase();

  var mediaType = '';

  if (accept.contains('image')) {
    mediaType = 'image/$fileExtension';
  } else if (accept.contains('video')) {
    mediaType = 'video/$fileExtension';
  } else if (accept.contains('audio')) {
    mediaType = 'audio/$fileExtension';
  } else if (accept.contains('json')) {
    mediaType = 'application/json';
  } else {
    mediaType = fileExtension;
  }

  return MimeType.parse(mediaType);
}

/// Reads [file] as [Blob] URL.
Future<String?> readFileDataAsBlobURL(File file, [String accept = '']) async {
  var bs = await readFileDataAsArrayBuffer(file);
  if (bs == null) return null;

  var mimeType = getFileMimeType(file, accept);
  var mimeTypeStr = mimeType?.toString() ?? MimeType.applicationOctetStream;

  await _yeld();

  var blobURL = createBlobURL(bs, mimeTypeStr);

  await _yeld();

  return blobURL;
}

/// Reads [file] as DATA URL Base64 [String].
Future<String?> readFileDataAsDataURLBase64(File file,
    [String accept = '']) async {
  var base64 = await readFileDataAsBase64(file);
  if (base64 == null) return null;
  var mediaType = getFileMimeType(file, accept);
  return toDataURLBase64(MimeType.asString(mediaType, ''), base64);
}

/// Reads [file] as Base64 [String].
Future<String?> readFileDataAsBase64(File file) async {
  var data = await readFileDataAsArrayBuffer(file);
  return data != null ? data_convert.base64.encode(data) : null;
}

/// Reads [file] as [Uint8List].
Future<Uint8List?> readFileDataAsArrayBuffer(File file) async {
  final reader = FileReader();
  reader.readAsArrayBuffer(file);

  await reader.onLoadEnd.first;

  if (reader.error != null) {
    return null;
  }

  var result = reader.result;

  if (result.isA<JSArrayBuffer>()) {
    var arrayBuffer = result as JSArrayBuffer;
    var byteBuffer = arrayBuffer.toDart;
    return Uint8List.view(byteBuffer);
  } else if (result.isA<JSUint8Array>()) {
    var fileData = result as JSUint8Array?;
    return fileData?.toDart;
  } else {
    return null;
  }
}

/// Reads [file] as text.
Future<String?> readFileDataAsText(File file) async {
  final reader = FileReader();
  reader.readAsText(file);

  await reader.onLoadEnd.first;

  if (reader.error != null) {
    return null;
  }

  var fileData = reader.result as JSString?;
  return fileData?.toDart;
}

/// Builds a DATA URL string.
String toDataURLBase64(String? mediaType, String base64) {
  return 'data:$mediaType;base64,$base64';
}

String createBlobURL(Uint8List data, String mimeType) {
  var blob = Blob(
    [data.toJS].toJS,
    BlobPropertyBag(type: mimeType),
  );

  var blobUrl = URL.createObjectURL(blob);
  return blobUrl;
}

void revokeBlobURL(String blobUrl) {
  URL.revokeObjectURL(blobUrl);
}

Future<void> _yeld({int ms = 1}) => Future.delayed(Duration(milliseconds: ms));
