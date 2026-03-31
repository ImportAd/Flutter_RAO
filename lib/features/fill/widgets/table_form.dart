import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../core/models/template_models.dart';
import '../widgets/section_form.dart' show DateMaskFormatter, dateToDisplay;

/// Маркер для опции «Ввести вручную» в dropdown-ячейках
const _kManualEntry = 'Ввести вручную';

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
                color: Color(0xFFF7F7F7),
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
                decoration: const BoxDecoration(color: Colors.white),
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

    // ── Колонки с type: date → маска __.__.____  ──
    if (col.type == 'date') {
      return _DateTableCell(
        value: currentVal,
        onChanged: (v) {
          final newRow = Map<String, String>.from(row);
          newRow[col.name] = v;
          onRowChanged(rowIdx, newRow);
        },
      );
    }

    // ── Dropdown с дефолтами (включая «Ввести вручную») ──
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
    w[0] = const FixedColumnWidth(42);
    w[columns.length + 1] = const FixedColumnWidth(42);
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
      case 'start_date': return 1.4;
      case 'payment_terms': return 1.4;
      default: return 1.5;
    }
  }
}


// ══════════════════════════════════════════
//  Ячейка даты в таблице (маска __.__.____) 
// ══════════════════════════════════════════

class _DateTableCell extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _DateTableCell({required this.value, required this.onChanged});
  @override
  State<_DateTableCell> createState() => _DateTableCellState();
}

class _DateTableCellState extends State<_DateTableCell> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: dateToDisplay(widget.value));
  }

  @override
  void didUpdateWidget(covariant _DateTableCell old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final d = dateToDisplay(widget.value);
      if (_ctrl.text != d) _ctrl.text = d;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: TextFormField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        inputFormatters: [DateMaskFormatter()],
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        ),
        style: const TextStyle(fontSize: 15, letterSpacing: 1.2),
        onChanged: widget.onChanged,
      ),
    );
  }
}


// ══════════════════════════════════════════
//  Dropdown-ячейка с поддержкой «Ввести вручную»
// ══════════════════════════════════════════

class _DropdownCell extends StatefulWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownCell({required this.value, required this.options, required this.onChanged});

  @override
  State<_DropdownCell> createState() => _DropdownCellState();
}

class _DropdownCellState extends State<_DropdownCell> {
  bool _manualMode = false;
  late TextEditingController _ctrl;

  /// Есть ли опция «Ввести вручную» в списке
  bool get _hasManualOption =>
      widget.options.any((o) => o.trim().toLowerCase() == _kManualEntry.toLowerCase());

  /// Опции БЕЗ «Ввести вручную» (для dropdown)
  List<String> get _realOptions =>
      widget.options.where((o) => o.trim().toLowerCase() != _kManualEntry.toLowerCase()).toList();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    // Если текущее значение не среди реальных опций и не пустое — значит ручной ввод
    if (widget.value.isNotEmpty && !_realOptions.contains(widget.value)) {
      _manualMode = true;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_manualMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  hintText: 'Введите значение',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                ),
                style: const TextStyle(fontSize: 15),
                onChanged: widget.onChanged,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _manualMode = false;
                _ctrl.clear();
                widget.onChanged('');
              }),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.list, size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // Обычный dropdown
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == _kManualEntry) {
            setState(() {
              _manualMode = true;
              _ctrl.text = '';
              widget.onChanged('');
            });
          } else {
            widget.onChanged(v);
          }
        },
        tooltip: 'Выбрать значение',
        position: PopupMenuPosition.under,
        itemBuilder: (_) {
          final items = <PopupMenuEntry<String>>[];
          for (final o in _realOptions) {
            items.add(PopupMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14))));
          }
          // Добавляем «Ввести вручную» если есть в исходных опциях
          if (_hasManualOption) {
            items.add(const PopupMenuDivider());
            items.add(PopupMenuItem(
              value: _kManualEntry,
              child: Text(_kManualEntry,
                  style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ));
          }
          return items;
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(children: [
            Expanded(child: Text(
              widget.value.isEmpty ? 'Выбрать' : widget.value,
              style: TextStyle(
                fontSize: 15,
                color: widget.value.isEmpty ? AppColors.textHint : AppColors.textPrimary,
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


// ══════════════════════════════════════════
//  Helper cells
// ══════════════════════════════════════════

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

class _DCell extends StatelessWidget {
  final Widget child;
  const _DCell({required this.child});
  @override
  Widget build(BuildContext context) => child;
}