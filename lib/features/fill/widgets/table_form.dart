import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';

/// Динамическая таблица с добавлением/удалением строк.
/// Каждая строка — набор полей по колонкам из TableDefModel.
class TableForm extends StatelessWidget {
  final SectionModel section;
  final List<Map<String, String>> rows;
  final void Function(int rowIndex, Map<String, String> row) onRowChanged;
  final VoidCallback onAddRow;
  final void Function(int rowIndex) onRemoveRow;

  const TableForm({
    super.key,
    required this.section,
    required this.rows,
    required this.onRowChanged,
    required this.onAddRow,
    required this.onRemoveRow,
  });

  @override
  Widget build(BuildContext context) {
    final table = section.table!;
    final columns = table.columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовки колонок (горизонтальная прокрутка на узких экранах)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            border: TableBorder.all(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(6),
            ),
            columns: [
              const DataColumn(label: Text('№', style: TextStyle(fontWeight: FontWeight.w600))),
              for (final col in columns)
                DataColumn(
                  label: Text(
                    col.label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              const DataColumn(label: SizedBox.shrink()), // Удалить
            ],
            rows: List.generate(rows.length, (i) {
              final row = rows[i];
              return DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  for (final col in columns)
                    DataCell(
                      SizedBox(
                        width: _columnWidth(col),
                        child: TextFormField(
                          initialValue: row[col.name] ?? '',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            hintText: col.label,
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(color: AppColors.fieldBorder),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (value) {
                            final newRow = Map<String, String>.from(row);
                            newRow[col.name] = value;
                            onRowChanged(i, newRow);
                          },
                        ),
                      ),
                    ),
                  DataCell(
                    rows.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: AppColors.error,
                            tooltip: 'Удалить строку',
                            onPressed: () => onRemoveRow(i),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // Кнопка «Добавить строку»
        if (table.allowDynamicRows && rows.length < table.maxRows)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onAddRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить поле'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  double _columnWidth(TableColumnModel col) {
    // Подбираем ширину по типу данных
    switch (col.name) {
      case 'punkt':
        return 60;
      case 'name':
        return 180;
      case 'address':
        return 180;
      case 'area':
      case 'staf':
      case 'sum':
      case 'reg':
      case 'set':
      case 'period_fee':
        return 100;
      default:
        return 140;
    }
  }
}
