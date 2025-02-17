import 'package:web_utils/web_utils.dart';

extension DomElementExtension on Element {
  /// Selects the [AnchorElement] elements.
  List<HTMLAnchorElement> selectAnchorElements() =>
      querySelectorAllTyped<HTMLAnchorElement>('a', Web.HTMLAnchorElement);

  /// Selects the [AnchorElement] links.
  List<String> selectAnchorLinks() =>
      selectAnchorElements().map((e) => e.href).nonNulls.toList();

  /// Selects the [AnchorElement] links targets/fragments.
  List<String> selectAnchorLinksTargets() => selectAnchorLinks()
      .where((e) => e.contains('#'))
      .map((e) => e.split('#').last)
      .toList();

  /// Selects the [InputElement] elements.
  List<HTMLInputElement> selectInputElement() =>
      querySelectorAllTyped<HTMLInputElement>('input', Web.HTMLInputElement);

  /// Selects the [CheckboxInputElement] elements (`<input type="checkbox">`).
  List<HTMLInputElement> selectCheckboxInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='checkbox']", Web.HTMLInputElement);

  /// Selects the [RadioButtonInputElement] elements (`<input type="radio">`).
  List<HTMLInputElement> selectRadioButtonInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='radio']", Web.HTMLInputElement);

  /// Selects the [NumberInputElement] elements (`<input type="number">`).
  List<HTMLInputElement> selectNumberInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='number']", Web.HTMLInputElement);

  /// Selects the [EmailInputElement] elements (`<input type="email">`).
  List<HTMLInputElement> selectEmailInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='email']", Web.HTMLInputElement);

  /// Selects the [LocalDateTimeInputElement] elements (`<input type="datetime-local">`).
  List<HTMLInputElement> selectLocalDateTimeInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='datetime-local']", Web.HTMLInputElement);

  /// Selects the [ButtonInputElement] elements (`<input type="button">`).
  List<HTMLInputElement> selectButtonInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='button']", Web.HTMLInputElement);

  /// Selects the [FileUploadInputElement] elements (`<input type="file">`).
  List<HTMLInputElement> selectFileUploadInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='file']", Web.HTMLInputElement);

  /// Selects the [PasswordInputElement] elements (`<input type="password">`).
  List<HTMLInputElement> selectPasswordInputElement() =>
      querySelectorAllTyped<HTMLInputElement>(
          "input[type='password']", Web.HTMLInputElement);

  /// Selects the [SelectElement] elements.
  List<HTMLSelectElement> selectSelectElement() =>
      querySelectorAllTyped<HTMLSelectElement>('select', Web.HTMLSelectElement);

  /// Selects the [TextAreaElement] elements.
  List<HTMLTextAreaElement> selectTextAreaElement() =>
      querySelectorAllTyped<HTMLTextAreaElement>(
          'textarea', Web.HTMLTextAreaElement);

  /// Selects the [ButtonElement] elements.
  List<HTMLButtonElement> selectButtonElements() =>
      querySelectorAllTyped<HTMLButtonElement>('button', Web.HTMLButtonElement);

  /// Selects the [HTMLImageElement] elements.
  List<HTMLImageElement> selectImageElement() =>
      querySelectorAllTyped<HTMLImageElement>('img', Web.HTMLImageElement);

  /// Selects the [DivElement] elements.
  List<HTMLDivElement> selectDivElement() =>
      querySelectorAllTyped<HTMLDivElement>('div', Web.HTMLDivElement);

  /// Selects the [SpanElement] elements.
  List<HTMLSpanElement> selectSpanElement() =>
      querySelectorAllTyped<HTMLSpanElement>('span', Web.HTMLSpanElement);

  /// Selects the [TableElement] elements.
  List<HTMLTableElement> selectTableElement() =>
      querySelectorAllTyped<HTMLTableElement>('table', Web.HTMLTableElement);

  /// Selects the [TableRowElement] elements.
  List<HTMLTableRowElement> selectTableRowElement() =>
      querySelectorAllTyped<HTMLTableRowElement>('tr', Web.HTMLTableRowElement);

  /// Selects the [TableCellElement] elements.
  List<HTMLTableCellElement> selectTableCellElement() =>
      querySelectorAllTyped<HTMLTableCellElement>(
          'td', Web.HTMLTableCellElement);

  bool get isDisplayNone => style?.display == 'none';

  bool get isVisibilityHidden => style?.visibility == 'hidden';

  bool get isInvisible => isDisplayNone || isVisibilityHidden || hidden;
}

extension IterableDomElementExtension<E extends Element> on Iterable<E> {
  /// Adds a class to all elements of this [Iterable] of [Element]s.
  void addClass(String clazz) {
    for (var e in this) {
      e.classList.add(clazz);
    }
  }

  /// Removes a class from all elements of this [Iterable] of [Element]s.
  void removeClass(String clazz) {
    for (var e in this) {
      e.classList.remove(clazz);
    }
  }

  /// Filter elements with [id].
  List<E> withID(String id) => where((e) => e.id == id).toList();

  /// Filter elements with [clazz].
  List<E> withClass(String clazz) {
    clazz = clazz.trim();
    var classes = clazz.split(RegExp(r'\s+'));
    return withClasses(classes);
  }

  /// Filter elements with all [classes].
  List<E> withClasses(List<String> classes) {
    classes = classes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (classes.isEmpty) return <E>[];
    return where((e) => e.classList.toList().containsAll(classes)).toList();
  }
}

extension _IterableExtension<T> on Iterable<T> {
  bool containsAll(Iterable<T> l) {
    var found = false;
    for (var e in l) {
      if (!contains(e)) {
        return false;
      } else {
        found = true;
      }
    }
    return found;
  }
}
