import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';

/// Динамическая форма одной секции
class SectionForm extends StatelessWidget {
  final SectionModel section;
  final Map<String, String> answers;
  final Map<String, String> errors;
  final void Function(String fieldName, String value) onFieldChanged;
  /// Список имён computed-полей — их не рендерим
  final Set<String> computedFields;

  const SectionForm({super.key, required this.section, required this.answers,
      required this.errors, required this.onFieldChanged,
      this.computedFields = const {}});

  @override
  Widget build(BuildContext context) {
    final visibleFields = section.fields
        .where((f) => !computedFields.contains(f.name))
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

    // Выбор месяцев
    if (field.type == 'months_select') {
      return _MonthsSelector(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Печать М.П. / Б.П.
    if (field.isStampField) {
      return _StampField(field: field,
          value: currentValue.isEmpty ? (field.defaultValue ?? 'М.П.') : currentValue,
          errorText: errorText, onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Поле с ОДНИМ дефолтным значением → readonly + «Изменить»
    if (field.fieldDefaults.length == 1) {
      return _SingleDefaultField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Поле с несколькими дефолтами
    if (field.fieldDefaults.length > 1) {
      return _MultiDefaultsField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Обычное поле с валидацией
    return AppTextField(
      label: field.label, hint: _hintForField(field), errorText: errorText,
      initialValue: currentValue,
      onChanged: (v) {
        onFieldChanged(field.name, v);
      },
      keyboardType: field.type == 'number' ? TextInputType.number : TextInputType.text,
    );
  }

  String? _hintForField(FieldModel field) {
    if (field.type == 'date') return 'формат 01.01.2025';
    if (field.textHandler == 'fio_full_and_initials') return 'Полностью';
    if (field.textHandler == 'org_form_full_and_abbr') return 'Полностью';
    if (field.textHandler == 'position_nom_and_gen') return 'в именительном падеже';
    return null;
  }
}

/// Валидатор форматов — вызывается при потере фокуса / при генерации
String? validateFieldFormat(FieldModel field, String value) {
  if (value.isEmpty) return null; // пустое — отдельная проверка required

  if (field.type == 'date') {
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(value)) {
      return 'Формат: дд.мм.гггг (например 01.01.2025)';
    }
    final parts = value.split('.');
    final day = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return 'Неверный месяц';
    if (day < 1 || day > 31) return 'Неверный день';
  }

  if (field.type == 'number') {
    final cleaned = value.replaceAll(' ', '').replaceAll(',', '.').replaceAll('\u00A0', '');
    if (double.tryParse(cleaned) == null) {
      return 'Введите число';
    }
  }

  if (field.textHandler == 'fio_full_and_initials') {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'Введите Фамилию и Имя (минимум 2 слова)';
  }

  if (field.name == 'phone') {
    if (!RegExp(r'^[\d\s\+\(\)\-]+$').hasMatch(value)) {
      return 'Допустимы: цифры, +, (, ), -, пробелы';
    }
  }

  if (field.name == 'inn') {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 && digits.length != 12) {
      return 'ИНН: 10 или 12 цифр';
    }
  }

  if (field.name == 'bik') {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return 'БИК: 9 цифр';
  }

  return null;
}


// ══════════════════════════════════════════
// Виджеты полей
// ══════════════════════════════════════════

/// Выбор месяцев — сетка 4×3
class _MonthsSelector extends StatelessWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _MonthsSelector({required this.field, required this.value,
      this.errorText, required this.onChanged});

  static const _months = [
    'Январь','Февраль','Март','Апрель',
    'Май','Июнь','Июль','Август',
    'Сентябрь','Октябрь','Ноябрь','Декабрь',
  ];

  Set<String> get _selected {
    if (value.isEmpty) return {};
    return value.split(',').map((s) => s.trim().toLowerCase()).where((s) => s.isNotEmpty).toSet();
  }

  void _toggle(String month) {
    final sel = _selected;
    final key = month.toLowerCase();
    if (sel.contains(key)) { sel.remove(key); } else { sel.add(key); }
    // Собираем в порядке месяцев
    final ordered = _months.where((m) => sel.contains(m.toLowerCase())).map((m) => m.toLowerCase());
    onChanged(ordered.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Сетка 3 колонки × 4 строки
        Table(
          border: TableBorder.all(color: AppColors.divider, width: 0.5),
          children: List.generate(4, (row) => TableRow(
            children: List.generate(3, (col) {
              final idx = row * 3 + col;
              final month = _months[idx];
              final isSelected = sel.contains(month.toLowerCase());
              return GestureDetector(
                onTap: () => _toggle(month),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  child: Text(month, style: TextStyle(
                    fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  )),
                ),
              );
            }),
          )),
        ),
        if (errorText != null)
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(errorText!, style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }
}

/// Readonly поле с одним дефолтом + «Изменить»
class _SingleDefaultField extends StatefulWidget {
  final FieldModel field; final String value; final String? errorText;
  final ValueChanged<String> onChanged;
  const _SingleDefaultField({required this.field, required this.value,
      this.errorText, required this.onChanged});
  @override State<_SingleDefaultField> createState() => _SingleDefaultFieldState();
}

class _SingleDefaultFieldState extends State<_SingleDefaultField> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final defaultVal = widget.field.fieldDefaults.first;
    _ctrl = TextEditingController(text: widget.value.isNotEmpty ? widget.value : defaultVal);
    if (widget.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onChanged(defaultVal));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.field.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: TextFormField(
          controller: _ctrl, enabled: _editing, readOnly: !_editing,
          style: TextStyle(color: _editing ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: _editing ? AppColors.fieldBackground : AppColors.fieldDisabled,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.fieldBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.fieldBorderFocused)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: AppColors.fieldBorder)),
          ),
          onChanged: widget.onChanged,
        )),
        const SizedBox(width: 12),
        TextButton(
          onPressed: () {
            if (_editing) { widget.onChanged(_ctrl.text); setState(() => _editing = false); }
            else { setState(() => _editing = true); }
          },
          child: Text(_editing ? 'Готово' : 'Изменить',
              style: TextStyle(color: AppColors.primary, fontSize: 14)),
        ),
      ]),
      if (widget.field.type == 'date')
        Padding(padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text('формат 01.01.2025', style: Theme.of(context).textTheme.bodySmall)),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(widget.errorText!, style: TextStyle(color: AppColors.error, fontSize: 12))),
    ]);
  }
}

/// Поле с несколькими дефолтами — выбор + ручной ввод
class _MultiDefaultsField extends StatefulWidget {
  final FieldModel field; final String value; final String? errorText;
  final ValueChanged<String> onChanged;
  const _MultiDefaultsField({required this.field, required this.value,
      this.errorText, required this.onChanged});
  @override State<_MultiDefaultsField> createState() => _MultiDefaultsFieldState();
}

class _MultiDefaultsFieldState extends State<_MultiDefaultsField> {
  bool _manual = false;

  @override
  Widget build(BuildContext context) {
    if (_manual) {
      return AppTextField(label: widget.field.label, hint: widget.field.hint,
          errorText: widget.errorText, initialValue: widget.value, onChanged: widget.onChanged,
          actionLabel: 'Выбрать', onAction: () => setState(() => _manual = false));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.field.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      AppChoiceChips(options: widget.field.fieldDefaults,
          selected: widget.value.isEmpty ? null : widget.value, onSelected: widget.onChanged),
      const SizedBox(height: 8),
      TextButton(onPressed: () => setState(() => _manual = true),
          child: Text('✍ Ввести вручную', style: TextStyle(color: AppColors.primary))),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(widget.errorText!, style: TextStyle(color: AppColors.error, fontSize: 12))),
    ]);
  }
}

/// Печать М.П. / Б.П.
class _StampField extends StatelessWidget {
  final FieldModel field; final String value; final String? errorText;
  final ValueChanged<String> onChanged;
  const _StampField({required this.field, required this.value, this.errorText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      AppChoiceChips(options: const ['М.П.', 'Б.П.'], selected: value, onSelected: onChanged),
      const SizedBox(height: 4),
      Text('Обычно М.П.', style: Theme.of(context).textTheme.bodySmall),
      if (errorText != null)
        Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!, style: TextStyle(color: AppColors.error, fontSize: 12))),
    ]);
  }
}
