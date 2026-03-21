import 'package:flutter/material.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';

/// Динамическая форма одной секции: рендерит поля из SectionModel
class SectionForm extends StatelessWidget {
  final SectionModel section;
  final Map<String, String> answers;
  final Map<String, String> errors;
  final void Function(String fieldName, String value) onFieldChanged;

  const SectionForm({
    super.key,
    required this.section,
    required this.answers,
    required this.errors,
    required this.onFieldChanged,
  });

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

    // Специальное поле: печать М.П. / Б.П.
    if (field.isStampField) {
      return _StampField(
        field: field,
        value: currentValue.isEmpty ? (field.defaultValue ?? 'М.П.') : currentValue,
        errorText: errorText,
        onChanged: (v) => onFieldChanged(field.name, v),
      );
    }

    // Поле с предустановленными вариантами (кнопки + ручной ввод)
    if (field.hasDefaults) {
      return _DefaultsField(
        field: field,
        value: currentValue,
        errorText: errorText,
        onChanged: (v) => onFieldChanged(field.name, v),
      );
    }

    // Обычное текстовое поле
    return AppTextField(
      label: field.label,
      hint: field.hint ?? _hintForType(field),
      errorText: errorText,
      initialValue: currentValue,
      onChanged: (v) => onFieldChanged(field.name, v),
      keyboardType: field.type == 'number'
          ? TextInputType.number
          : TextInputType.text,
    );
  }

  String? _hintForType(FieldModel field) {
    if (field.type == 'date') return 'формат 01.01.2025';
    if (field.textHandler == 'fio_full_and_initials') return 'Полностью';
    if (field.textHandler == 'org_form_full_and_abbr') return 'Полностью';
    if (field.textHandler == 'position_nom_and_gen') return 'в именительном падеже';
    return null;
  }
}

/// Поле с выбором М.П. / Б.П.
class _StampField extends StatelessWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _StampField({
    required this.field,
    required this.value,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AppChoiceChips(
          options: const ['М.П.', 'Б.П.'],
          selected: value,
          onSelected: onChanged,
        ),
        if (field.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              field.hint!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Обычно М.П.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    )),
          ),
      ],
    );
  }
}

/// Поле с кнопками предустановленных значений + возможность «Изменить» вручную
class _DefaultsField extends StatefulWidget {
  final FieldModel field;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _DefaultsField({
    required this.field,
    required this.value,
    this.errorText,
    required this.onChanged,
  });

  @override
  State<_DefaultsField> createState() => _DefaultsFieldState();
}

class _DefaultsFieldState extends State<_DefaultsField> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    // Если выбрано одно из предустановленных значений — показываем как readonly + кнопка «Изменить»
    final isDefaultSelected = widget.field.fieldDefaults.contains(widget.value);

    if (!_editing && isDefaultSelected && widget.value.isNotEmpty) {
      return AppTextField(
        label: widget.field.label,
        hint: widget.field.hint,
        errorText: widget.errorText,
        initialValue: widget.value,
        readOnly: true,
        actionLabel: 'Изменить',
        onAction: () => setState(() => _editing = true),
        onChanged: null,
      );
    }

    if (!_editing && widget.value.isEmpty) {
      // Показываем кнопки выбора
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.field.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AppChoiceChips(
            options: widget.field.fieldDefaults,
            selected: widget.value.isEmpty ? null : widget.value,
            onSelected: (v) {
              widget.onChanged(v);
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _editing = true),
            child: const Text('✍ Ввести вручную'),
          ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      )),
            ),
        ],
      );
    }

    // Режим ручного ввода
    return AppTextField(
      label: widget.field.label,
      hint: widget.field.hint ?? _hintForDefaults(),
      errorText: widget.errorText,
      initialValue: widget.value,
      onChanged: widget.onChanged,
      actionLabel: widget.field.fieldDefaults.isNotEmpty ? 'Выбрать' : null,
      onAction: () => setState(() => _editing = false),
    );
  }

  String _hintForDefaults() {
    if (widget.field.fieldDefaults.length == 1) {
      return widget.field.fieldDefaults.first;
    }
    return '';
  }
}
