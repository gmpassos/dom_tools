import 'dart:html';

import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';
import 'dom_tools_paint.dart';

/// Shows a text dialog.
///
/// [text] The text to show.
/// [transparency] The transparency of the dialog as double.
/// [padding] The padding of the dialog.
DivElement? showDialogText(String? text,
    {double? transparency, String? padding}) {
  if (text == null || text.isEmpty) return null;

  var element = SpanElement();

  element.text = text;

  return showDialogElement(element,
      transparency: transparency, padding: padding);
}

/// Shows a [html] dialog.
///
/// [html] The HTML to show.
/// [transparency] The transparency of the dialog as double.
/// [padding] The padding of the dialog.
/// [validator] The [NodeValidator] for HTML generation.
DivElement? showDialogHTML(String? html,
    {double? transparency, String? padding, NodeValidator? validator}) {
  if (html == null || html.isEmpty) return null;

  var element = SpanElement();

  setElementInnerHTML(element, html, validator: validator);

  return showDialogElement(element,
      transparency: transparency, padding: padding);
}

/// Shows an image ([src]) dialog.
///
/// [src] The image source.
void showDialogImage(String src) {
  var img = ImageElement()
    // ignore: unsafe_html
    ..src = src
    ..style.width = '95%'
    ..style.height = 'auto'
    ..style.objectFit = 'contain';

  showDialogElement(img);
}

/// Shows an [Element] dialog.
///
/// [content] The element to show.
/// [transparency] The transparency of the dialog as double.
/// [padding] The padding of the dialog.
DivElement showDialogElement(Element content,
    {double? transparency, String? padding}) {
  if (transparency == null || transparency <= 0) transparency = 0.90;

  padding ??= '2vh 0 0 0';

  var dialog = DivElement()
    ..style.position = 'fixed'
    ..style.left = '0px'
    ..style.top = '0px'
    ..style.zIndex = '999999999'
    ..style.padding = padding
    ..style.width = '100vw'
    ..style.height = '100vh'
    ..style.overflow = 'auto'
    ..style.backgroundColor = 'rgba(0,0,0, $transparency)'
    ..style.textAlign = 'center'
    ..style.setProperty('backdrop-filter', 'blur(6px)');

  var close = SpanElement()
    ..innerHtml = '&times;'
    ..style.float = 'right'
    ..style.fontSize = '28px'
    ..style.fontWeight = 'bold'
    ..style.color = 'rgba(255,255,255,0.8)'
    ..style.margin = '0px 20px 10px 10px'
    ..style.cursor = 'pointer';

  close.onClick.listen((e) {
    dialog.style.display = 'none';
    dialog.remove();
  });

  dialog.children.add(close);

  String? src;
  String? title;
  var isImage = false;

  if (content is ImageElement) {
    src = content.src;
    title = content.title;
    isImage = true;
  } else if (content is VideoElement) {
    src = content.src;
    title = content.title;
  }

  AnchorElement? download;

  if (src != null) {
    String? file;

    if (src.startsWith('data:')) {
      var mimeType = DataURLBase64.parseMimeType(src);

      if (mimeType != null) {
        file = title != null && title.isNotEmpty && title.length <= 50
            ? mimeType.fileName(title)
            : mimeType.fileNameTimeMillis();
      }
    } else {
      file = getPathFileName(src);
    }

    if (file == null || file.isEmpty) file = 'file.download';

    download = AnchorElement(href: src)
      ..download = file
      ..innerHtml = '&#8675;'
      ..style.float = 'right'
      ..style.textDecoration = 'none'
      ..style.fontSize = '24px'
      ..style.fontWeight = 'bold'
      ..style.color = 'rgba(255,255,255,0.8)'
      ..style.margin = '4px 10px 10px 10px'
      ..title = 'Download'
      ..style.cursor = 'pointer';

    dialog.children.add(download);
  }

  if (isImage) {
    var rotate = SpanElement()
      ..innerHtml = '&#10549;'
      ..style.float = 'right'
      ..style.textDecoration = 'none'
      ..style.fontSize = '19px'
      ..style.fontWeight = 'bold'
      ..style.color = 'rgba(255,255,255,0.8)'
      ..style.margin = '4px 10px 10px 10px'
      ..title = 'Rotate Right'
      ..style.cursor = 'pointer';

    rotate.onClick.listen((e) {
      var img = dialog.children
          .where((e) => e is ImageElement || e is CanvasImageSource)
          .first;

      late CanvasElement canvasRotated;

      if (img is CanvasElement) {
        canvasRotated = rotateCanvasImageSource(img, img.width!, img.height!);
      } else if (img is ImageElement) {
        canvasRotated =
            rotateCanvasImageSource(img, img.naturalWidth, img.naturalHeight);
      }

      var imgRotated = canvasToImageElement(canvasRotated);
      imgRotated.style.cssText = img.style.cssText;

      if (download != null) {
        // ignore: unsafe_html
        download.href = imgRotated.src;
      }

      var idx = dialog.children.indexOf(img);
      assert(idx >= 0);
      img.remove();
      dialog.children.insert(idx, imgRotated);
    });

    dialog.children.add(rotate);
  }

  content
    ..style.maxWidth = '98vw'
    ..style.maxHeight = '90vh';

  dialog.children.add(content);

  document.body!.children.add(dialog);

  return dialog;
}
