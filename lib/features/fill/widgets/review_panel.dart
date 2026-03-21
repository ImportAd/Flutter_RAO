import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_buttons.dart';

/// Панель проверки данных перед генерацией.
/// Показывает все введённые значения с возможностью перейти к редактированию.
class ReviewPanel extends StatelessWidget {
  final TemplateDetail template;
  final Map<String, Map<String, String>> fieldAnswers;
  final Map<String, List<Map<String, String>>> tableAnswers;
  final Map<String, String> errors;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final void Function(String sectionId) onEditSection;

  const ReviewPanel({
    super.key,
    required this.template,
    required this.fieldAnswers,
    required this.tableAnswers,
    required this.errors,
    required this.isGenerating,
    required this.onGenerate,
    required this.onEditSection,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Проверка данных', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Проверьте введённые данные перед формированием документа',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Divider(height: 32),

        // Секции с полями
        for (final sec in template.sections) ...[
          _ReviewSection(
            section: sec,
            fieldAnswers: fieldAnswers[sec.id] ?? {},
            tableRows: tableAnswers[sec.id],
            onEdit: () => onEditSection(sec.id),
          ),
          const SizedBox(height: 16),
        ],

        // Ошибки
        if (errors.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Не заполнено обязательных полей: ${errors.length}',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Кнопка генерации
        AppPrimaryButton(
          label: 'Сформировать договор',
          icon: Icons.description,
          isLoading: isGenerating,
          onPressed: errors.isEmpty ? onGenerate : null,
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final SectionModel section;
  final Map<String, String> fieldAnswers;
  final List<Map<String, String>>? tableRows;
  final VoidCallback onEdit;

  const _ReviewSection({
    required this.section,
    required this.fieldAnswers,
    this.tableRows,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок секции
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Изменить'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),

          // Поля
          if (section.fields.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final field in section.fields)
                    _ReviewFieldRow(
                      label: field.label,
                      value: fieldAnswers[field.name] ?? '',
                    ),
                ],
              ),
            ),

          // Таблица
          if (tableRows != null && tableRows!.isNotEmpty && section.table != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Таблица:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    '${tableRows!.length} строк заполнено',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewFieldRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewFieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 260,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: value.isEmpty ? AppColors.textHint : AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
