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
