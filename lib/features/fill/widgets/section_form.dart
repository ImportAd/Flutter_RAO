import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';

/// Имена полей dg_months — переносятся на вкладку таблицы
const kMonthsFieldNames = {'dg_months', 'dg_months_1', 'dg_months_2'};

/// Динамическая форма одной секции
class SectionForm extends StatelessWidget {
  final SectionModel section;
  final Map<String, String> answers;
  final Map<String, String> errors;
  final void Function(String fieldName, String value) onFieldChanged;
  final Set<String> computedFields;
  /// Поля, которые нужно скрыть (перенесены в другое место UI)
  final Set<String> hiddenFieldNames;

  const SectionForm({super.key, required this.section, required this.answers,
      required this.errors, required this.onFieldChanged,
      this.computedFields = const {},
      this.hiddenFieldNames = const {}});

  @override
  Widget build(BuildContext context) {
    final visibleFields = section.fields
        .where((f) => !computedFields.contains(f.name))
        .where((f) => !hiddenFieldNames.contains(f.name))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < visibleFields.length; i++) ...[
          _buildField(context, visibleFields[i]),
          if (i < visibleFields.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context, FieldModel field) {
    final errorKey = '${section.id}.${field.name}';
    final errorText = errors[errorKey];
    final currentValue = answers[field.name] ?? '';

    if (field.type == 'months_select') {
      return MonthsSelector(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }
    if (field.isStampField) {
      return _StampField(field: field,
          value: currentValue.isEmpty ? (field.defaultValue ?? 'М.П.') : currentValue,
          errorText: errorText, onChanged: (v) => onFieldChanged(field.name, v));
    }
    if (field.textHandler == 'org_form_full_and_abbr') {
      return _SingleDefaultField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v), overrideDefault: 'ООО');
    }
    if (field.fieldDefaults.length == 1) {
      return _SingleDefaultField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }
    if (field.fieldDefaults.length > 1) {
      return _MultiDefaultsField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }
    if (field.type == 'date') {
      return DateMaskField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }
    if (field.name == 'phone') {
      return _PhoneMaskField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }
    return AppTextField(label: field.label, hint: _hintForField(field), errorText: errorText,
        initialValue: currentValue, onChanged: (v) => onFieldChanged(field.name, v),
        keyboardType: field.type == 'number' ? TextInputType.number : TextInputType.text);
  }

  String? _hintForField(FieldModel field) {
    const emptyHintFields = {'ld_num', 'add_num', 'ooo_name', 'dol'};
    if (emptyHintFields.contains(field.name)) return '';
    if (field.type == 'date') return 'формат 01.01.2025';
    if (field.textHandler == 'fio_full_and_initials') return 'Полностью';
    if (field.textHandler == 'org_form_full_and_abbr') return '';
    if (field.textHandler == 'position_nom_and_gen') return 'в именительном падеже';
    return null;
  }
}

// ── Валидатор форматов ──
String? validateFieldFormat(FieldModel field, String value) {
  if (value.isEmpty) return null;
  if (field.type == 'date') {
    final clean = value.replaceAll('_', '');
    if (clean == '..') return null;
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(value)) return 'Формат: дд.мм.гггг';
    final p = value.split('.');
    if ((int.tryParse(p[1]) ?? 0) < 1 || (int.tryParse(p[1]) ?? 0) > 12) return 'Неверный месяц';
    if ((int.tryParse(p[0]) ?? 0) < 1 || (int.tryParse(p[0]) ?? 0) > 31) return 'Неверный день';
  }
  if (field.type == 'number') {
    final c = value.replaceAll(' ', '').replaceAll(',', '.').replaceAll('\u00A0', '');
    if (double.tryParse(c) == null) return 'Введите число';
  }
  if (field.textHandler == 'fio_full_and_initials') {
    if (value.trim().split(RegExp(r'\s+')).length < 2) return 'Минимум Фамилия и Имя';
  }
  if (field.name == 'phone') {
    if (value.replaceAll(RegExp(r'\D'), '').length < 11) return 'Введите полный номер';
  }
  if (field.name == 'inn') {
    final d = value.replaceAll(RegExp(r'\D'), '');
    if (d.length != 10 && d.length != 12) return 'ИНН: 10 или 12 цифр';
  }
  if (field.name == 'bik') {
    if (value.replaceAll(RegExp(r'\D'), '').length != 9) return 'БИК: 9 цифр';
  }
  return null;
}

// ══════════════════════════════════════════
//  Маска даты  __.__.____  (public)
// ══════════════════════════════════════════

class DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length > 8) d = d.substring(0, 8);
    final buf = StringBuffer();
    for (int i = 0; i < 8; i++) {
      if (i == 2 || i == 4) buf.write('.');
      buf.write(i < d.length ? d[i] : '_');
    }
    final text = buf.toString();
    int cur = d.length + (d.length > 2 ? 1 : 0) + (d.length > 4 ? 1 : 0);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cur.clamp(0, 10)));
  }
}

String dateToDisplay(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '__.__.____';
  String c(int i) => i < digits.length ? digits[i] : '_';
  return '${c(0)}${c(1)}.${c(2)}${c(3)}.${c(4)}${c(5)}${c(6)}${c(7)}';
}

class DateMaskField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;
  const DateMaskField({super.key, required this.field, required this.value,
      this.errorText, required this.onChanged});
  @override
  State<DateMaskField> createState() => _DateMaskFieldState();
}

class _DateMaskFieldState extends State<DateMaskField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: dateToDisplay(widget.value));
  }

  @override
  void didUpdateWidget(covariant DateMaskField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final disp = dateToDisplay(widget.value);
      if (_ctrl.text != disp) {
        _ctrl.text = disp;
        final dl = widget.value.replaceAll(RegExp(r'[^0-9]'), '').length;
        _ctrl.selection = TextSelection.collapsed(
            offset: (dl + (dl > 2 ? 1 : 0) + (dl > 4 ? 1 : 0)).clamp(0, 10));
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasErr = widget.errorText != null && widget.errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.field.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: hasErr ? AppColors.error : AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [DateMaskFormatter()],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary, letterSpacing: 1.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: hasErr ? AppColors.error : AppColors.fieldBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                    color: hasErr ? AppColors.error : AppColors.fieldBorderFocused, width: 1.5)),
          ),
          onChanged: widget.onChanged,
        ),
        if (hasErr)
          Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(widget.errorText!,
                  style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }
}

// ══════════════════════════════════════════
//  Маска телефона  +7 (___) ___-__-__
// ══════════════════════════════════════════

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty && digits[0] == '8') digits = '7${digits.substring(1)}';
    if (digits.isNotEmpty && digits[0] != '7') digits = '7$digits';
    if (digits.length > 11) digits = digits.substring(0, 11);

    final d = digits.length > 1 ? digits.substring(1) : '';
    final buf = StringBuffer('+7 (');
    for (int i = 0; i < 10; i++) {
      if (i == 3) buf.write(') ');
      if (i == 6 || i == 8) buf.write('-');
      buf.write(i < d.length ? d[i] : '_');
    }
    final text = buf.toString();

    int cur = 4;
    for (int i = 0; i < d.length && i < 10; i++) {
      cur++;
      if (i == 2) cur += 2;
      if (i == 5 || i == 7) cur++;
    }
    return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cur.clamp(0, text.length)));
  }
}

class _PhoneMaskField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _PhoneMaskField(
      {required this.field,
      required this.value,
      this.errorText,
      required this.onChanged});

  @override
  State<_PhoneMaskField> createState() => _PhoneMaskFieldState();
}

class _PhoneMaskFieldState extends State<_PhoneMaskField> {
  late TextEditingController _ctrl;

  String _toDisplay(String v) {
    var digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '+7 (___) ___-__-__';
    if (digits[0] == '8') digits = '7${digits.substring(1)}';
    if (digits[0] != '7') digits = '7$digits';
    if (digits.length > 11) digits = digits.substring(0, 11);
    final d = digits.substring(1);
    final buf = StringBuffer('+7 (');
    for (int i = 0; i < 10; i++) {
      if (i == 3) buf.write(') ');
      if (i == 6 || i == 8) buf.write('-');
      buf.write(i < d.length ? d[i] : '_');
    }
    return buf.toString();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _toDisplay(widget.value));
  }

  @override
  void didUpdateWidget(covariant _PhoneMaskField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final disp = _toDisplay(widget.value);
      if (_ctrl.text != disp) _ctrl.text = disp;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasErr = widget.errorText != null && widget.errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.field.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: hasErr ? AppColors.error : AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _ctrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [_PhoneMaskFormatter()],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimary, letterSpacing: 1.2),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: hasErr ? AppColors.error : AppColors.fieldBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                    color: hasErr ? AppColors.error : AppColors.fieldBorderFocused, width: 1.5)),
          ),
          onChanged: widget.onChanged,
        ),
        if (hasErr)
          Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(widget.errorText!,
                  style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }
}

// ══════════════════════════════════════════
//  _ActionLink (стиль HeaderNavLink)
// ══════════════════════════════════════════

class _ActionLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionLink({required this.label, required this.onTap});
  @override
  State<_ActionLink> createState() => _ActionLinkState();
}

class _ActionLinkState extends State<_ActionLink> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
          onTap: widget.onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(widget.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _h ? AppColors.primaryDark : AppColors.primary)))));
}

// ══════════════════════════════════════════
//  MonthsSelector (публичный — используется и из fill_page)
// ══════════════════════════════════════════

class MonthsSelector extends StatelessWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const MonthsSelector(
      {super.key,
      required this.field,
      required this.value,
      this.errorText,
      required this.onChanged});

  static const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  Set<String> get _selected {
    if (value.isEmpty) return {};
    return value.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
  }

  void _toggle(String month) {
    final sel = _selected;
    final key = month.toLowerCase();
    sel.contains(key) ? sel.remove(key) : sel.add(key);
    onChanged(months
        .where((m) => sel.contains(m.toLowerCase()))
        .map((m) => m.toLowerCase())
        .join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: AppColors.divider, width: 0.5),
          children: List.generate(
              4,
              (row) => TableRow(
                  children: List.generate(3, (col) {
                    final m = months[row * 3 + col];
                    final isSel = sel.contains(m.toLowerCase());
                    return GestureDetector(
                      onTap: () => _toggle(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        color: isSel ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                        child: Text(m,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                                color: isSel ? AppColors.primary : AppColors.textPrimary)),
                      ),
                    );
                  }))),
        ),
        if (errorText != null)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(errorText!,
                  style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }
}

// ══════════════════════════════════════════
//  _SingleDefaultField (readonly + «Изменить»)
// ══════════════════════════════════════════

class _SingleDefaultField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final String? overrideDefault;

  const _SingleDefaultField(
      {required this.field,
      required this.value,
      this.errorText,
      required this.onChanged,
      this.overrideDefault});

  @override
  State<_SingleDefaultField> createState() => _SingleDefaultFieldState();
}

class _SingleDefaultFieldState extends State<_SingleDefaultField> {
  bool _editing = false;
  late TextEditingController _ctrl;

  String get _def =>
      widget.overrideDefault ??
      (widget.field.fieldDefaults.isNotEmpty ? widget.field.fieldDefaults.first : '');
  bool get _isDate => widget.field.type == 'date';

  @override
  void initState() {
    super.initState();
    final init = widget.value.isNotEmpty ? widget.value : _def;
    _ctrl = TextEditingController(text: _isDate ? dateToDisplay(init) : init);
    if (widget.value.isEmpty && _def.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(_def));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasErr = widget.errorText != null && widget.errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.field.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: hasErr ? AppColors.error : AppColors.textPrimary)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              enabled: _editing,
              readOnly: !_editing,
              keyboardType: _isDate ? TextInputType.number : null,
              inputFormatters: (_editing && _isDate) ? [DateMaskFormatter()] : null,
              style: TextStyle(
                  color: _editing ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 15,
                  letterSpacing: _isDate ? 1.5 : null),
              decoration: InputDecoration(
                filled: true,
                fillColor: _editing ? AppColors.fieldBackground : AppColors.fieldDisabled,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.fieldBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.fieldBorderFocused)),
                disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.fieldBorder)),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(width: 12),
          _ActionLink(
            label: _editing ? 'Готово' : 'Изменить',
            onTap: () {
              if (_editing) {
                widget.onChanged(_ctrl.text);
                setState(() => _editing = false);
              } else {
                if (_isDate) _ctrl.text = dateToDisplay(_ctrl.text);
                setState(() => _editing = true);
              }
            },
          ),
        ]),
        if (hasErr)
          Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(widget.errorText!,
                  style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }
}

// ══════════════════════════════════════════
//  _MultiDefaultsField
// ══════════════════════════════════════════

class _MultiDefaultsField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _MultiDefaultsField(
      {required this.field, required this.value, this.errorText, required this.onChanged});

  @override
  State<_MultiDefaultsField> createState() => _MultiDefaultsFieldState();
}

class _MultiDefaultsFieldState extends State<_MultiDefaultsField> {
  bool _manual = false;

  @override
  Widget build(BuildContext context) {
    if (_manual) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppTextField(
            label: widget.field.label,
            hint: widget.field.hint,
            errorText: widget.errorText,
            initialValue: widget.value,
            onChanged: widget.onChanged),
        const SizedBox(height: 4),
        _ActionLink(
            label: 'Выбрать из списка',
            onTap: () => setState(() => _manual = false)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.field.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      AppChoiceChips(
          options: widget.field.fieldDefaults,
          selected: widget.value.isEmpty ? null : widget.value,
          onSelected: widget.onChanged),
      const SizedBox(height: 4),
      _ActionLink(label: '✍ Ввести вручную', onTap: () => setState(() => _manual = true)),
      if (widget.errorText != null)
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.errorText!,
                style: TextStyle(color: AppColors.error, fontSize: 12))),
    ]);
  }
}

// ══════════════════════════════════════════
//  _StampField (М.П./Б.П.)
// ══════════════════════════════════════════

class _StampField extends StatelessWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _StampField(
      {required this.field, required this.value, this.errorText, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AppChoiceChips(
              options: const ['М.П.', 'Б.П.'], selected: value, onSelected: onChanged),
          const SizedBox(height: 4),
          Text('Обычно М.П.', style: Theme.of(context).textTheme.bodySmall),
          if (errorText != null)
            Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(errorText!,
                    style: TextStyle(color: AppColors.error, fontSize: 12))),
        ],
      );
}