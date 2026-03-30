import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';

/// Таблица на всю ширину с dropdown-дефолтами для определённых колонок.
class TableForm extends StatelessWidget {
  final SectionModel section;
  final List<Map<String, String>> rows;
  final void Function(int rowIndex, Map<String, String> row) onRowChanged;
  final VoidCallback onAddRow;
  final void Function(int rowIndex) onRemoveRow;
  /// Дефолтные значения для колонок: {columnName: [val1, val2, ...]}
  final Map<String, List<String>> columnDefaults;

  const TableForm({super.key, required this.section, required this.rows,
      required this.onRowChanged, required this.onAddRow, required this.onRemoveRow,
      this.columnDefaults = const {}});

  @override
  Widget build(BuildContext context) {
    final table = section.table!;
    final columns = table.columns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          border: TableBorder.all(
            color: AppColors.divider,
            width: 1,
            borderRadius: BorderRadius.circular(4),
          ),
          columnWidths: _buildColumnWidths(columns),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // ── Заголовки ──
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7), // светло-серый, не бирюзовый
              ),
              children: [
                _HCell('№'),
                for (final col in columns) _HCell(col.label),
                _HCell(''),
              ],
            ),
            // ── Строки данных ──
            for (int i = 0; i < rows.length; i++)
              TableRow(
                decoration: const BoxDecoration(
                  color: Colors.white, // белый фон строк
                ),
                children: [
                  _DCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  for (final col in columns)
                    _DCell(child: _buildCell(context, col, i)),
                  _DCell(
                    child: rows.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: AppColors.error,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => onRemoveRow(i),
                          )
                        : const SizedBox(width: 36),
                  ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (table.allowDynamicRows && rows.length < table.maxRows)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить строку', style: TextStyle(fontSize: 15)),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, TableColumnModel col, int rowIdx) {
    final row = rows[rowIdx];
    final currentVal = row[col.name] ?? '';
    final defaults = columnDefaults[col.name];

    // Если есть дефолтные значения для этой колонки — показываем dropdown
    if (defaults != null && defaults.isNotEmpty) {
      return _DropdownCell(
        value: currentVal,
        options: defaults,
        onChanged: (v) {
          final newRow = Map<String, String>.from(row);
          newRow[col.name] = v;
          onRowChanged(rowIdx, newRow);
        },
      );
    }

    // Обычная ячейка для ввода
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TextFormField(
        initialValue: currentVal,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
        style: const TextStyle(fontSize: 15),
        onChanged: (v) {
          final newRow = Map<String, String>.from(row);
          newRow[col.name] = v;
          onRowChanged(rowIdx, newRow);
        },
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(List<TableColumnModel> columns) {
    final w = <int, TableColumnWidth>{};
    w[0] = const FixedColumnWidth(42);                    // №
    w[columns.length + 1] = const FixedColumnWidth(42);   // удалить
    for (int i = 0; i < columns.length; i++) {
      w[i + 1] = FlexColumnWidth(_flex(columns[i]));
    }
    return w;
  }

  double _flex(TableColumnModel col) {
    switch (col.name) {
      case 'name': case 'address': return 2.5;
      case 'punkt': return 0.7;
      case 'area': case 'staf': case 'sum': case 'reg': case 'set': return 1.0;
      case 'period_fee': return 1.3;
      case 'category': return 1.2;
      case 'tariff': return 1.2;
      default: return 1.5;
    }
  }
}

/// Ячейка с dropdown-выбором дефолтных значений
class _DropdownCell extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownCell({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: PopupMenuButton<String>(
        onSelected: onChanged,
        tooltip: 'Выбрать значение',
        position: PopupMenuPosition.under,
        itemBuilder: (_) => options.map((o) => PopupMenuItem(
          value: o,
          child: Text(o, style: const TextStyle(fontSize: 14)),
        )).toList(),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(children: [
            Expanded(child: Text(
              value.isEmpty ? 'Выбрать' : value,
              style: TextStyle(
                fontSize: 15,
                color: value.isEmpty ? AppColors.textHint : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            )),
            Icon(Icons.arrow_drop_down, size: 20, color: AppColors.primary),
          ]),
        ),
      ),
    );
  }
}

/// Ячейка заголовка
class _HCell extends StatelessWidget {
  final String text;
  const _HCell(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
      );
}

/// Обёртка ячейки данных
class _DCell extends StatelessWidget {
  final Widget child;
  const _DCell({required this.child});
  @override
  Widget build(BuildContext context) => child;
}