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
