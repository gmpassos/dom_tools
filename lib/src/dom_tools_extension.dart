import 'dart:html';

import 'package:collection/collection.dart';

extension DomElementExtension on Element {
  /// Alias to [querySelector] casting to [T].
  T? querySelectorTyped<T extends Element>(String selectors) {
    var self = this;
    var elem = self.querySelector(selectors);
    return elem is T ? elem : null;
  }

  /// Alias to [querySelectorAll] casting elements to [T].
  List<T> querySelectorAllTyped<T extends Element>(String selectors) {
    var self = this;
    var list = self.querySelectorAll(selectors);
    return list.whereType<T>().toList();
  }

  /// Selects the [AnchorElement] elements.
  List<AnchorElement> selectAnchorElements() =>
      querySelectorAllTyped<AnchorElement>('a');

  /// Selects the [AnchorElement] links.
  List<String> selectAnchorLinks() =>
      selectAnchorElements().map((e) => e.href).whereNotNull().toList();

  /// Selects the [AnchorElement] links targets/fragmets.
  List<String> selectAnchorLinksTargets() => selectAnchorLinks()
      .where((e) => e.contains('#'))
      .map((e) => e.split('#').last)
      .toList();

  /// Selects the [InputElement] elements.
  List<InputElement> selectInputElement() =>
      querySelectorAllTyped<InputElement>('input');

  /// Selects the [CheckboxInputElement] elements (`<input type="checkbox">`).
  List<CheckboxInputElement> selectCheckboxInputElement() =>
      querySelectorAllTyped<CheckboxInputElement>("input[type='checkbox']");

  /// Selects the [RadioButtonInputElement] elements (`<input type="radio">`).
  List<RadioButtonInputElement> selectRadioButtonInputElement() =>
      querySelectorAllTyped<RadioButtonInputElement>("input[type='radio']");

  /// Selects the [NumberInputElement] elements (`<input type="number">`).
  List<NumberInputElement> selectNumberInputElement() =>
      querySelectorAllTyped<NumberInputElement>("input[type='number']");

  /// Selects the [EmailInputElement] elements (`<input type="email">`).
  List<EmailInputElement> selectEmailInputElement() =>
      querySelectorAllTyped<EmailInputElement>("input[type='email']");

  /// Selects the [LocalDateTimeInputElement] elements (`<input type="datetime-local">`).
  List<LocalDateTimeInputElement> selectLocalDateTimeInputElement() =>
      querySelectorAllTyped<LocalDateTimeInputElement>(
          "input[type='datetime-local']");

  /// Selects the [ButtonInputElement] elements (`<input type="button">`).
  List<ButtonInputElement> selectButtonInputElement() =>
      querySelectorAllTyped<ButtonInputElement>("input[type='button']");

  /// Selects the [FileUploadInputElement] elements (`<input type="file">`).
  List<FileUploadInputElement> selectFileUploadInputElement() =>
      querySelectorAllTyped<FileUploadInputElement>("input[type='file']");

  /// Selects the [PasswordInputElement] elements (`<input type="password">`).
  List<PasswordInputElement> selectPasswordInputElement() =>
      querySelectorAllTyped<PasswordInputElement>("input[type='password']");

  /// Selects the [SelectElement] elements.
  List<SelectElement> selectSelectElement() =>
      querySelectorAllTyped<SelectElement>('select');

  /// Selects the [TextAreaElement] elements.
  List<TextAreaElement> selectTextAreaElement() =>
      querySelectorAllTyped<TextAreaElement>('textarea');

  /// Selects the [ButtonElement] elements.
  List<ButtonElement> selectButtonElements() =>
      querySelectorAllTyped<ButtonElement>('button');

  /// Selects the [ImageElement] elements.
  List<ImageElement> selectImageElement() =>
      querySelectorAllTyped<ImageElement>('img');

  /// Selects the [DivElement] elements.
  List<DivElement> selectDivElement() =>
      querySelectorAllTyped<DivElement>('div');

  /// Selects the [SpanElement] elements.
  List<SpanElement> selectSpanElement() =>
      querySelectorAllTyped<SpanElement>('span');

  /// Selects the [TableElement] elements.
  List<TableElement> selectTableElement() =>
      querySelectorAllTyped<TableElement>('table');

  /// Selects the [TableRowElement] elements.
  List<TableRowElement> selectTableRowElement() =>
      querySelectorAllTyped<TableRowElement>('tr');

  /// Selects the [TableCellElement] elements.
  List<TableCellElement> selectTableCellElement() =>
      querySelectorAllTyped<TableCellElement>('td');

  bool get isDisplayNone => style.display == 'none';

  bool get isVisibilityHidden => style.visibility == 'hidden';

  bool get isInvisible => isDisplayNone || isVisibilityHidden || hidden;
}

extension IterableDomElementExtension<E extends Element> on Iterable<E> {
  /// Adds a class to all elements of this [Iterable] of [Element]s.
  void addClass(String clazz) {
    for (var e in this) {
      e.classes.add(clazz);
    }
  }

  /// Removes a class from all elements of this [Iterable] of [Element]s.
  void removeClass(String clazz) {
    for (var e in this) {
      e.classes.remove(clazz);
    }
  }

  /// Filter elements with [id].
  List<E> withID(String id) => where((e) => e.id == id).toList();

  /// Filter elements with [clazz].
  List<E> whithClass(String clazz) {
    clazz = clazz.trim();
    var classes = clazz.split(RegExp(r'\s+'));
    return whithClasses(classes);
  }

  /// Filter elements with all [classes].
  List<E> whithClasses(List<String> classes) {
    classes = classes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (classes.isEmpty) return <E>[];
    return where((e) => e.classes.containsAll(classes)).toList();
  }
}
