import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';

/// Таблица на всю ширину — без горизонтального скролла.
/// Ячейки растягиваются, текст переносится.
class TableForm extends StatelessWidget {
  final SectionModel section;
  final List<Map<String, String>> rows;
  final void Function(int rowIndex, Map<String, String> row) onRowChanged;
  final VoidCallback onAddRow;
  final void Function(int rowIndex) onRemoveRow;

  const TableForm({super.key, required this.section, required this.rows,
      required this.onRowChanged, required this.onAddRow, required this.onRemoveRow});

  @override
  Widget build(BuildContext context) {
    final table = section.table!;
    final columns = table.columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Таблица на всю ширину
        Table(
          border: TableBorder.all(color: AppColors.divider, width: 0.5, borderRadius: BorderRadius.circular(4)),
          columnWidths: _buildColumnWidths(columns),
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            // Заголовки
            TableRow(
              decoration: BoxDecoration(color: AppColors.surfaceVariant),
              children: [
                _HeaderCell('№'),
                for (final col in columns) _HeaderCell(col.label),
                _HeaderCell(''),
              ],
            ),
            // Строки данных
            for (int i = 0; i < rows.length; i++)
              TableRow(children: [
                _DataCell(child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('${i + 1}', style: const TextStyle(fontSize: 13)),
                )),
                for (final col in columns)
                  _DataCell(child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: TextFormField(
                      initialValue: rows[i][col.name] ?? '',
                      decoration: const InputDecoration(
                        isDense: true, border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) {
                        final newRow = Map<String, String>.from(rows[i]);
                        newRow[col.name] = v;
                        onRowChanged(i, newRow);
                      },
                    ),
                  )),
                _DataCell(child: rows.length > 1
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: AppColors.error, padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Удалить', onPressed: () => onRemoveRow(i))
                    : const SizedBox(width: 32)),
              ]),
          ],
        ),

        const SizedBox(height: 12),

        // Кнопка «+ Добавить поле»
        if (table.allowDynamicRows && rows.length < table.maxRows)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить поле'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(List<TableColumnModel> columns) {
    final widths = <int, TableColumnWidth>{};
    // № — фиксированная узкая
    widths[0] = const FixedColumnWidth(40);
    // Кнопка удаления — фиксированная
    widths[columns.length + 1] = const FixedColumnWidth(40);
    // Остальные — flex, но с весами по типу данных
    for (int i = 0; i < columns.length; i++) {
      widths[i + 1] = FlexColumnWidth(_flexWeight(columns[i]));
    }
    return widths;
  }

  double _flexWeight(TableColumnModel col) {
    switch (col.name) {
      case 'name': case 'address': return 2.5;
      case 'punkt': return 0.8;
      case 'area': case 'staf': case 'sum': case 'reg': case 'set': return 1.0;
      case 'period_fee': return 1.2;
      default: return 1.5;
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;
  const _DataCell({required this.child});
  @override
  Widget build(BuildContext context) => child;
}
