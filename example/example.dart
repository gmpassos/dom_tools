import 'package:dom_tools/dom_tools_kit.dart';

void main() {
  var imgSrc =
      'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png';

  // Example of an image that only loads when visualized in viewport:

  var tracker = TrackElementInViewport();
  var imageElement = HTMLImageElement();

  tracker.track(imageElement, onEnterViewport: (elem) {
    // ignore: unsafe_html
    imageElement.src = imgSrc;
  });

  document.body!.appendChild(imageElement);

  Future.delayed(Duration(seconds: 10), () {
    var img = getElementBySRC('img', imgSrc);
    if (img == null) {
      window.alert('After 10s the image is not visible in viewport yet');
    } else {
      window.alert('After 10s the image was visible in viewport.');
    }
  });
}
