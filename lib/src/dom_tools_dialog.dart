import 'package:swiss_knife/swiss_knife.dart';
import 'package:web_utils/web_utils.dart';

import 'dom_tools_base.dart';
import 'dom_tools_paint.dart';

/// Shows a text dialog.
///
/// [text] The text to show.
/// [transparency] The transparency of the dialog as double.
/// [padding] The padding of the dialog.
HTMLDivElement? showDialogText(String? text,
    {double? transparency, String? padding}) {
  if (text == null || text.isEmpty) return null;

  var element = HTMLSpanElement();

  element.text = text;

  return showDialogElement(element,
      transparency: transparency, padding: padding);
}

/// Shows a [html] dialog.
///
/// [html] The HTML to show.
/// [transparency] The transparency of the dialog as double.
/// [padding] The padding of the dialog.
HTMLDivElement? showDialogHTML(String? html,
    {double? transparency,
    String? padding,
    @Deprecated("`NodeValidator` not implemented on package `web`")
    Object? validator,
    bool unsafe = false}) {
  if (html == null || html.isEmpty) return null;

  var element = HTMLSpanElement();

  setElementInnerHTML(element, html, unsafe: unsafe);

  return showDialogElement(element,
      transparency: transparency, padding: padding);
}

/// Shows an image ([src]) dialog.
///
/// [src] The image source.
void showDialogImage(String src) {
  var img = HTMLImageElement()
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
HTMLDivElement showDialogElement(HTMLElement content,
    {double? transparency, String? padding}) {
  if (transparency == null || transparency <= 0) transparency = 0.90;

  padding ??= '2vh 0 0 0';

  var dialog = HTMLDivElement()
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

  var close = HTMLSpanElement()
    ..innerHTML = '&times;'.toJS
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

  dialog.appendChild(close);

  String? src;
  String? title;
  var isImage = false;

  if (content.isA<HTMLImageElement>()) {
    src = (content as HTMLImageElement).src;
    title = content.title;
    isImage = true;
  } else if (content.isA<HTMLVideoElement>()) {
    src = (content as HTMLVideoElement).src;
    title = content.title;
  }

  HTMLAnchorElement? download;

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

    download = HTMLAnchorElement()
      ..href = src
      ..download = file
      ..innerHTML = '&#8675;'.toJS
      ..style.float = 'right'
      ..style.textDecoration = 'none'
      ..style.fontSize = '24px'
      ..style.fontWeight = 'bold'
      ..style.color = 'rgba(255,255,255,0.8)'
      ..style.margin = '4px 10px 10px 10px'
      ..title = 'Download'
      ..style.cursor = 'pointer';

    dialog.appendChild(download);
  }

  if (isImage) {
    var rotate = HTMLSpanElement()
      ..innerHTML = '&#10549;'.toJS
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
          .whereType<HTMLElement>()
          .where((e) => e.isA<HTMLImageElement>() || e.isA<CanvasImageSource>())
          .first;

      late HTMLCanvasElement canvasRotated;

      if (img.isA<HTMLCanvasElement>()) {
        var canvas = img as HTMLCanvasElement;
        canvasRotated =
            rotateCanvasImageSource(img, canvas.width, canvas.height);
      } else if (img.isA<HTMLImageElement>()) {
        var img2 = img as HTMLImageElement;
        canvasRotated = rotateCanvasImageSource(
            img2, img2.naturalWidth, img2.naturalHeight);
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
      dialog.insertChild(idx, imgRotated);
    });

    dialog.appendChild(rotate);
  }

  content
    ..style.maxWidth = '98vw'
    ..style.maxHeight = '90vh';

  dialog.appendChild(content);

  document.body!.appendChild(dialog);

  return dialog;
}
