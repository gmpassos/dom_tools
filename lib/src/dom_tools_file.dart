import 'dart:async';
import 'dart:convert' as data_convert;
import 'dart:html';
import 'dart:typed_data';

import 'package:dom_tools/dom_tools.dart';
import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';

/// Reads selected file of [input] as [Uint8List].
Future<Uint8List/*?*/>/*!*/ readFileInputElementAsArrayBuffer(
    FileUploadInputElement/*?*/ input,
    [bool removeExifFromImage = false]) async {
  if (input == null || input.files == null || input.files.isEmpty) return null;

  var file = input.files.first;

  Uint8List data;
  if (removeExifFromImage ?? false) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parsePayloadAsArrayBuffer(dataURL);
    }
  }
  data ??= await readFileDataAsArrayBuffer(file);

  return data;
}

/// Reads selected file of [input] as [String].
Future<String/*?*/> readFileInputElementAsString(FileUploadInputElement/*?*/ input,
    [bool removeExifFromImage = false]) async {
  if (input == null || input.files == null || input.files.isEmpty) return null;

  var file = input.files.first;

  String data;
  if (removeExifFromImage ?? false) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parseMimeTypeAsString(dataURL);
    }
  }
  data ??= await readFileDataAsText(file);

  return data;
}

/// Reads selected file of [input] as Base64.
Future<String/*?*/> readFileInputElementAsBase64(FileUploadInputElement/*?*/ input,
    [bool removeExifFromImage = false]) async {
  if (input == null || input.files == null || input.files.isEmpty) return null;

  var file = input.files.first;

  String data;
  if (removeExifFromImage ?? false) {
    var dataURL = await removeExifFromImageFile(file);
    if (dataURL != null) {
      data = DataURLBase64.parsePayloadAsBase64(dataURL);
    }
  }
  data ??= await readFileDataAsBase64(file);

  return data;
}

/// Reads selected file of [input] as DATA URL Base64.
Future<String/*?*/> readFileInputElementAsDataURLBase64(FileUploadInputElement/*?*/ input,
    [bool removeExifFromImage = false]) async {
  if (input == null || input.files == null || input.files.isEmpty) return null;

  var file = input.files.first;

  String data;
  if (removeExifFromImage ?? false) {
    var dataURL = await removeExifFromImageFile(file);
    data = dataURL;
  }
  data ??= await readFileDataAsDataURLBase64(file);

  return data;
}

/// Removes Exif from JPEG [file].
///
/// Returns null if no operation was performed.
Future<String/*?*/>/*!*/ removeExifFromImageFile(File file) async {
  var mimeType = getFileMimeType(file);

  if (mimeType != null && mimeType.isImageJPEG) {
    var fileDataURL = await readFileDataAsDataURLBase64(file);

    if (fileDataURL != null) {
      var img = ImageElement(src: fileDataURL);
      await elementOnLoad(img);

      var canvas = toCanvasElement(img, img.naturalWidth, img.naturalHeight);
      img = canvasToImageElement(canvas, mimeType.toString());

      return img.src;
    }
  }

  return null;
}

/// Returns the [file] [MimeType].
///
/// [accept] the accept attribute when file was selected.
MimeType getFileMimeType(File file, [String/*!*/ accept = '']) {
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

/// Reads [file] as DATA URL Base64 [String].
Future<String/*?*/> readFileDataAsDataURLBase64(File file, [String/*!*/ accept = '']) async {
  var base64 = await readFileDataAsBase64(file);
  if (base64 == null) return null ;
  var mediaType = getFileMimeType(file, accept);
  return toDataURLBase64(MimeType.asString(mediaType, ''), base64);
}

/// Reads [file] as Base64 [String].
Future<String/*?*/> readFileDataAsBase64(File file) async {
  var data = await readFileDataAsArrayBuffer(file);
  return data != null ? data_convert.base64.encode(data) : null ;
}

/// Reads [file] as [Uint8List].
Future<Uint8List/*?*/> readFileDataAsArrayBuffer(File file) async {
  final reader = FileReader();
  reader.readAsArrayBuffer(file);
  await Future.any([reader.onLoad.first, reader.onError.first, reader.onAbort.first]);
  var fileData = reader.result as Uint8List ;
  return fileData;
}

/// Reads [file] as text.
Future<String/*?*/> readFileDataAsText(File file) async {
  final reader = FileReader();
  reader.readAsText(file);
  await Future.any([reader.onLoad.first, reader.onError.first, reader.onAbort.first]);
  var fileData = reader.result as String ;
  return fileData;
}

/// Builds a DATA URL string.
String toDataURLBase64(String mediaType, String base64) {
  return 'data:$mediaType;base64,$base64';
}
