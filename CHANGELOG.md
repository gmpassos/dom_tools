## 1.3.18

- Fix `reloadAssets`:
  - Fix timeout issue.
  - Improve reload behavior.
- Added `File` operations.

## 1.3.17

- Added `replaceElement`, `reloadIframe` and `reloadAssets`.
- swiss_knife: ^2.5.21 

## 1.3.16

- Added `prefetchHref`.
- Fix `TrackElementResize` behavior due issue with `dart:html` `ResizeObserver`.

## 1.3.15

- Added `setDivCentered` and `setTreeElementsDivCentered`.
- Added `isInlineElement`, `addElementsClasses` and `setTreeElementsBackgroundBlur`.
- Added `CSSAnimationConfig` and `animateCSSSequence`.
- swiss_knife: ^2.5.18

## 1.3.14

- `callObjectMethod` renamed to `callJSObjectMethod`.
- `callFunction` renamed to `callJSFunction`.
- Added `jsObjectKeys`, `jsToDart`, `jsArrayToList`, `jsObjectToMap`.
- markdown: ^3.0.0
- swiss_knife: ^2.5.16

## 1.3.13

- `getElementWidth`/`getElementHeight`:
  - Added optional `def` parameter.

## 1.3.12

- Added: `getElementWidth`, `getElementHeight`, `copyElementToClipboard`.  
- Added: `parseCSSLength`.
- Added: `getURLData`.
- Improve `DataAssets`.
- Fix: `removeElementScrollColors`. 
- swiss_knife: ^2.5.15
- html_unescape: ^1.0.2
- enum_to_string: ^1.0.13

## 1.3.11

- Added: `htmlToText`, `createStandardNodeValidator`, `downloadDataURL`.
- `DataAssets`: New class to handle assets object URL.
- Added a parameter for [NodeValidator] when creating HTML.
- CSS helpers: `getAllViewportMediaCssRuleAsClassRule`, `getAllOutOfViewportMediaCssRuleAsClassRule`, `getAllOutOfViewportMediaCssRule`, `getAllViewportMediaCssRule`, `getAllMediaCssRule`, `getAllCssStyleSheet`, `parseCssRuleSelectors`.
- json_object_mapper: ^1.1.3
- swiss_knife: ^2.5.14
- enum_to_string: ^1.0.11

## 1.3.10

- `CanvasImageViewer`: Fix NPE for `_renderLabels`.
- intl: ^0.16.1
- pedantic: ^1.9.2
- test: ^1.15.3

## 1.3.9

- `CanvasImageViewer`: Better hint box. Added support for `maxWidth` and `maxHeight`. 
- Added: `setElementScrollColors`, `removeElementScrollColors`, `setElementBackgroundBlur`, `removeElementBackgroundBlur`.
- Added: `getElementZIndex`, `getElementPreComputedStyle`, `getElementAllCssProperties`, `getElementAllCssRule`, `selectCssRuleWithSelector`, `getAllCssRuleBySelector`.
- Added: `downloadBytes` and `downloadBlob`.
- `createHTML` now uses `Element.nodes` instead of `Element.childNodes` while generating root element.
- Fix `TrackElementResize` issue with `ResizeObserverEntry`.
- swiss_knife: ^2.5.12
- markdown: ^2.1.8
- enum_to_string: ^1.0.9

## 1.3.8

- Added: `htmlToText`.
- export 'package:json_object_mapper/json_object_mapper.dart';
- Fix typo.
- json_object_mapper: ^1.1.2
- swiss_knife: ^2.5.10

## 1.3.7

- Fix `animateCSS`: NPE when `callback` parameter is null.
- Fix `touchEventToMouseEvent`.
- `addJavaScriptSource`: added `async` parameter.

## 1.3.6

- Added `HSLColor` and `HSVColor` class.
- Added `animateCSS`: for animation/transition of CSS properties.
- Touch helpers: `detectTouchDevice`, `touchEventToMouseEvent`, `redirect_onTouchStart_to_MouseEvent`, `redirect_onTouchMove_to_MouseEvent`, `redirect_onTouchEnd_to_MouseEvent`.
- Renamed abstract class `CSSValue` to `CSSValueBase`.
- Fix `Color.parse` for `r,g,b` parameters.
- Fix `getImageDimension`, to avoid `NaN` for `0` width or height. 
- swiss_knife: ^2.5.8 

## 1.3.5

- dartfmt.
- swiss_knife: ^2.5.6

## 1.3.4

- Added `setElementValue`, `getElementValue`.
- Added `isElementWithSRC`, `setElementSRC`, `isElementWithHREF`, `setElementHREF`.
- Added `downloadContent`.
- swiss_knife: ^2.5.5

## 1.3.3

- Added: `getElementTagName, detectTouchDevice, addCSSCode`
- Added `contenteditable` to allowed `_HTML_BASIC_ATTRS`.
- Added Color: `GREY, GREY_LIGHT, GREY_LIGHTER, GREY_DARK, GREY_DARKER`.
- Added Color: `alphaRatio, hasAlpha, withAlphaRatio`.
- CanvasImageViewer with labels and hints. 
- CanvasImageViewer: added `EditionType`: `RECTANGLES, LABELS`.
- Fix `createHTML` for table tags. 
- Fix `addJavaScriptCode` cache.
- Fix `getImageWithPerspective` when image dimension can't be defined.
- dartfmt.
- swiss_knife: ^2.5.4
- markdown: ^2.1.3

## 1.3.2

- Removed dependency `highlight`: reduce generated code, files and Browser time to load code.
- Removed codeToHighlightHtml()

## 1.3.1

- Added example.
- dartfmt

## 1.3.0

- addCssSource( insertIndex ): a new parameter for index insertion.
- Added API Documentation.

## 1.2.9

- getElementHref(), getElementSrc().
- getElementByValues(), getElementByHref(), getElementBySrc().
- getAnchorElementByHref(), getLinkElementByHref(), getScriptElementBySrc().
- elementOnLoad().
- toCanvasElement(), canvasToImageElement(), rotateImageElement(), rotateCanvasImageSource().
- NodeValidatorBuilder: Added tags svg, nav, li, ul, ol, label.
- addJavaScriptCode(), addJavaScriptSource().
- addCssSource(), getComputedStyle().
- showDialogText(), showDialogHTML(), showDialogImage(), showDialogElement().
- swiss_knife: ^2.4.0
- highlight: ^0.6.0

## 1.2.8

- addJScriptSource()
- markdownToHtml(): markdown now accepts attributes for url. For example: `[GitHub](https://github.com/){:target="_blank"}`

## 1.2.7

- createDiv(), createDivInline(), createHTML()
- setElementInnerHTML(), appendElementInnerHTML() (with NodeValidatorBuilder).
- scrollToTop(), scrollToTopAsync(), scrollToBottom(), scrollToLeft(), scrollToRight()
- setZoom(), resetZoom(), setMetaViewportScale()
- getElementAttribute(), getElementAttributeRegExp(), getElementAttributeStr()
- getHrefBaseHost(), getHrefHostAndPort(), getHrefHost(), getHrefPort(), getHrefScheme()
- isLocalhostHref(), isIPHref(), isIP(), clearSelections(), toHTML(Element)
- elementMatchesAttributes(), getElementsWithAttributes()
- isMobileAppStatusBarTranslucent()
- addJScript(), evalJS(), mapJSFunction(), callObjectMethod(), disableScrolling(), enableScrolling(), disableZooming()
- swiss_knife: ^2.3.9

## 1.2.6

- nodeTreeContains(), nodeTreeContainsAny()

## 1.2.5

- isOrientationInPortraitMode(), isOrientationInLandscapeMode()
- onOrientationchange()
- swiss_knife: ^2.3.7

## 1.2.4

- CSSThemeSet
- TrackElementInViewport (refactor)
- TrackElementValue (new)
- TrackElementResize (new): based in ResizeObserver or TrackElementValue depending of platform.
- swiss_knife: ^2.3.4

## 1.2.3

- CSS tools.
- Document: markdown and coding highlight.
- html_unescape: ^1.0.1+3
- markdown: ^2.1.3
- highlight: ^0.5.0
- enum_to_string: ^1.0.8

## 1.2.2

- DataStorageType: browser transparent storage over IdbFactory or window.sessionStorage.
- json_object_mapper: ^1.0.0
- swiss_knife: ^2.3.1

## 1.2.1

- CanvasImageViewer.cropPerspective.

## 1.2.0

- CanvasImageViewer support for perspective filter.
- Caches: ImageScaledCache, ImagePerspectiveFilterCache.

## 1.0.1

- CSS functions: applyCSS(), defineCSS(), hasCSS()
- Class Color (from dart:ui).
- Class CanvasImageViewer.

## 1.0.0

- Initial version, created by Stagehand
