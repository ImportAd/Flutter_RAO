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

  const SectionForm({super.key, required this.section, required this.answers,
      required this.errors, required this.onFieldChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < section.fields.length; i++) ...[
          _buildField(context, section.fields[i]),
          if (i < section.fields.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context, FieldModel field) {
    final errorKey = '${section.id}.${field.name}';
    final errorText = errors[errorKey];
    final currentValue = answers[field.name] ?? '';

    // Печать М.П. / Б.П.
    if (field.isStampField) {
      return _StampField(field: field,
          value: currentValue.isEmpty ? (field.defaultValue ?? 'М.П.') : currentValue,
          errorText: errorText, onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Поле с ОДНИМ дефолтным значением (номер/дата доверенности) → readonly + «Изменить»
    if (field.fieldDefaults.length == 1) {
      return _SingleDefaultField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Поле с несколькими дефолтами (выбор из вариантов)
    if (field.fieldDefaults.length > 1) {
      return _MultiDefaultsField(field: field, value: currentValue, errorText: errorText,
          onChanged: (v) => onFieldChanged(field.name, v));
    }

    // Обычное текстовое поле
    return AppTextField(
      label: field.label, hint: _hintForField(field), errorText: errorText,
      initialValue: currentValue, onChanged: (v) => onFieldChanged(field.name, v),
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

/// Поле с ОДНИМ дефолтом — readonly, серый фон, кнопка «Изменить» справа
class _SingleDefaultField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _SingleDefaultField({required this.field, required this.value,
      this.errorText, required this.onChanged});

  @override
  State<_SingleDefaultField> createState() => _SingleDefaultFieldState();
}

class _SingleDefaultFieldState extends State<_SingleDefaultField> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final defaultVal = widget.field.fieldDefaults.first;
    _ctrl = TextEditingController(
        text: widget.value.isNotEmpty ? widget.value : defaultVal);
    // Если значение ещё пустое — сразу подставляем дефолт
    if (widget.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(defaultVal);
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.field.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              enabled: _editing,
              readOnly: !_editing,
              style: TextStyle(
                color: _editing ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: _editing ? AppColors.fieldBackground : AppColors.fieldDisabled,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: _editing ? AppColors.fieldBorderFocused : AppColors.fieldBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.fieldBorderFocused)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: AppColors.fieldBorder)),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              if (_editing) {
                // Сохраняем и блокируем
                widget.onChanged(_ctrl.text);
                setState(() => _editing = false);
              } else {
                setState(() => _editing = true);
              }
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
      ],
    );
  }
}

/// Поле с несколькими дефолтами — выбор из вариантов + ручной ввод
class _MultiDefaultsField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _MultiDefaultsField({required this.field, required this.value,
      this.errorText, required this.onChanged});

  @override
  State<_MultiDefaultsField> createState() => _MultiDefaultsFieldState();
}

class _MultiDefaultsFieldState extends State<_MultiDefaultsField> {
  bool _manualInput = false;

  @override
  Widget build(BuildContext context) {
    if (_manualInput) {
      return AppTextField(
        label: widget.field.label, hint: widget.field.hint, errorText: widget.errorText,
        initialValue: widget.value, onChanged: widget.onChanged,
        actionLabel: 'Выбрать', onAction: () => setState(() => _manualInput = false),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.field.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AppChoiceChips(
          options: widget.field.fieldDefaults,
          selected: widget.value.isEmpty ? null : widget.value,
          onSelected: widget.onChanged,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _manualInput = true),
          child: Text('✍ Ввести вручную', style: TextStyle(color: AppColors.primary)),
        ),
        if (widget.errorText != null)
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(widget.errorText!, style: TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
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
