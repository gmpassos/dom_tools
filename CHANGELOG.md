## 3.0.0-beta.11

- `DBSimpleStorage`:
  - `_transactionObjStore`: wrap calls to `db.transaction()`.
    - If the indexedDB doesn't have the ObjectStore (`objs`) re-create the indexedDB.

## 3.0.0-beta.10

- Added `createElement`: allow creation of `SVGElement` and non `HTMLElement` from HTML source.

- web_utils: ^1.0.15
- js_interop_utils: ^1.0.8
- async_extension: ^1.2.15
- http: ^1.4.0

- test: ^1.26.2
- dependency_validator: ^4.1.3

## 3.0.0-beta.9

- Fix `readFileDataAsArrayBuffer`.

## 3.0.0-beta.8

- `State`: use `_castTo<V>(...)` to return values and avoid casting errors.

- web_utils: ^1.0.11

## 3.0.0-beta.7

- Fix use of `identical` with `web` `Element`s (`JSObject`).

- web: ^1.1.1

## 3.0.0-beta.6

- `SimpleStorage`:
  - Fix handling of `time` when the stored value is a `num/double` and not an `int`.
    - Identified when compiled to Wasm.

## 3.0.0-beta.5

- web_utils: ^1.0.9
- js_interop_utils: ^1.0.6
- intl: ^0.20.2
- swiss_knife: ^3.3.0

## 3.0.0-beta.4

- 🚀 feat: update querySelectorAll in getAllCssStyleSheet to use
  isA<HTMLStyleElement>() and isA<HTMLLinkElement>() functions.

- web_utils: ^1.0.6
- js_interop_utils: ^1.0.5

## 3.0.0-beta.3

- Use `web_utils` and `js_interop_utils`.

- web_utils: ^1.0.4
- js_interop_utils: ^1.0.4
- collection: ^1.19.1
- http: ^1.3.0

- lints: ^5.1.1
- test: ^1.25.15

## 3.0.0-beta.2

- web_utils: ^1.0.2
- js_interop_utils: ^1.0.2

## 3.0.0-beta.1

- Change from `dart:html` to `package:web/web.dart`.
- Change to `dart:js_interop`.

- export 'package:js_interop_utils/js_interop_utils.dart'.

- CI: test with `dart2js` and `dart2wasm` (on Chrome).

- sdk: '>=3.6.0 <4.0.0'

- web_utils: ^1.0.2
- js_interop_utils: ^1.0.2
- collection: ^1.19.0
- web: ^1.1.0
- http: ^1.2.2

## 2.3.2

- `isInTree`:
  - Optimize using `Node.isConnected`, avoiding `Node.contains` when possible.

- sdk: '>=3.4.0 <4.0.0'

- async_extension: ^1.2.14
- swiss_knife: ^3.2.3

- lints: ^4.0.0
- test: ^1.25.14
- dependency_validator: ^4.1.2

## 2.3.1

- Optimize: avoid use of `Element.attributes` to find a matching attribute (`RegExp` or case-insensitive).

- async_extension: ^1.2.12
- test: ^1.25.7

## 2.3.0

- sdk: '>=3.3.0 <4.0.0'

- intl: ^0.19.0
- swiss_knife: ^3.2.0
- collection: ^1.18.0

- test: ^1.25.2

## 2.2.1

- Improve `scrollTo` and `scrollToElement`.
- swiss_knife: ^3.1.6

## 2.2.0

- `scrollToElement`:
  - Added optional parameter `scrollable`.

- sdk: '>=3.0.0 <4.0.0'
- async_extension: ^1.2.5
- collection: ^1.17.1
- lints: ^3.0.0
  - fix lints. 
- test: ^1.24.9
- dependency_validator: ^3.2.3

## 2.1.17

- `isInViewport`:
  - Fix `fully` coordinates calculation. 
- markdown: ^6.0.1

## 2.1.16

- `scrollToElement`:
  - Added parameters `translateX` and `translateY`.
- `isInViewport`:
  - Added parameter `fully`.
- Added `measureText` and `getParentElement`.
- intl: ^0.18.1
- test: ^1.24.1

## 2.1.15

- Added `isSafariIOS`.
- Added `scrollTo` with `smooth` and `delayMs` parameters.
- `scrollToTop`, `scrollToBottom`, `scrollToLeft`, `scrollToRight`:
  - Added `smooth` and `delayMs` parameters.
- Deprecated `scrollToTopDelayed` due new `delayMs` parameter in `scrollToTop`. 
- swiss_knife: ^3.1.5

## 2.1.14

- Added `disableDoubleClicks`.
- swiss_knife: ^3.1.4

## 2.1.13

- `DBSimpleStorage._openVersioned`: improve error handling.

## 2.1.12

- `_SimpleStorage`:
  - Added `isEmpty` and `isNotEmpty`.
- `LocalSimpleStorage`:
  - Fix `get` when not returning a `String`.
- `DBSimpleStorage`:
  - Add a timeout to `_indexedDBOpen` and then retry it. 
- test: ^1.23.1

## 2.1.11

- `State`:
  - Fix `remove` and `null` values.
- async_extension: ^1.1.0

## 2.1.10

- `DomElementExtension`:
  - Added `isDisplayNone`, `isVisibilityHidden` and `isInvisible`.
- test: ^1.22.2

## 2.1.9

- intl: ^0.18.0
- swiss_knife: ^3.1.3
- test: ^1.22.1

## 2.1.8

- Added `DomElementExtension`:
  - `querySelectorAllTyped`, `querySelectorTyped`.
  - `selectAnchorElements`, `selectAnchorLinks`, `selectAnchorLinksTargets`.
  - `selectDivElement`, `selectSpanElement`, `selectImageElement`, `selectButtonElements`.
  - `selectInputElement`:
    - `selectCheckboxInputElement`, `selectRadioButtonInputElement`.
    - `selectEmailInputElement`, `selectNumberInputElement`, `selectPasswordInputElement`.
    - `selectFileUploadInputElement`, `selectLocalDateTimeInputElement`, `selectButtonInputElement`.
  - `selectTextAreaElement`. `selectSelectElement`.
  - `selectTableElement`, `selectTableRowElement`, `selectTableCellElement`.
- Added `IterableDomElementExtension`:.
  - `addClass`, `removeClass`, `whithClass`, `whithClasses`, `withID`.
- swiss_knife: ^3.1.2

## 2.1.7

- `DataStorage`:
  - Adjust `_consoleLog`.
- collection: ^1.17.0
- lints: ^2.0.1

## 2.1.6

- `DataStorage`:
  - Fix loading of `Map` value from IndexDB.
    The returned `Map` is not cast to the same stored `Map<String,Object?>` type.

## 2.1.5

- `DataStorage`:
  - Added support to store JSON compatible values. 
  - Improve performance.
- async_extension: ^1.0.12

## 2.1.4

- test: ^1.21.6
- dependency_validator: ^3.2.2
- sdk: '>=2.17.0 <3.0.0'

## 2.1.3

- Added `blockScrollTraverse`, `blockHorizontalScrollTraverse`, `blockVerticalScrollTraverse`,
  `blockHorizontalScrollTraverseEvent` and `blockVerticalScrollTraverseEvent`.
- lints: ^2.0.0
- test: ^1.21.3

## 2.1.2

- Added `scrollToElement`, `getElementDocumentPosition` and `getVisibleNode`.

## 2.1.1

- `createStandardNodeValidator`:
- Tag `video` now allows attributes 'autoplay', 'controls' and 'muted'.
- Improve GitHub CI.
- markdown: ^5.0.0
- collection: ^1.16.0
- dependency_validator: ^3.1.0
- Removed dependency `html_unescape`.

## 2.1.0

- Dart `2.16`:
  - Organize imports.
  - Fix new lints (breaks some enum names).
- sdk: '>=2.13.0 <3.0.0'
- swiss_knife: ^3.0.8
- markdown: ^4.0.1
- lints: ^1.0.1

## 2.0.1

- Sound null safety compatibility.
- swiss_knife: ^3.0.6
- json_object_mapper: ^2.0.1
- enum_to_string: ^2.0.1
- html_unescape: ^2.0.0

## 2.0.0-nullsafety.1

- Dart 2.12.0:
  - Sound null safety compatibility.
  - Update CI dart commands.
  - sdk: '>=2.12.0 <3.0.0'
- swiss_knife: ^3.0.1
- collection: ^1.15.0

## 1.3.20

- swiss_knife: ^2.5.24
 - Fixed `TreeReferenceMap` (`DOMTreeReferenceMap`).

## 1.3.19

- Added `DOMTreeReferenceMap`.
- swiss_knife: ^2.5.23

## 1.3.18

- Fix `reloadAssets`:
  - Fix timeout issue.
  - Improve reload behavior.
- Added `File` operations.
- swiss_knife: ^2.5.22

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
