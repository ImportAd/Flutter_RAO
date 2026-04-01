import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/template_models.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/utils/number_to_words_ru.dart';
import '../../../shared/widgets/app_shell.dart';
import '../widgets/section_form.dart';
import '../widgets/table_form.dart';

/// Маппинг: id табличной секции → имя months-поля из секции contract
const _monthsFieldForTable = {
  'objects': 'dg_months',
  'objects_a': 'dg_months_1',
  'objects_b': 'dg_months_2',
};

class FillPage extends StatefulWidget {
  final String templateCode;
  final int? fromDocId;
  const FillPage({super.key, required this.templateCode, this.fromDocId});
  @override
  State<FillPage> createState() => _FillPageState();
}

class _FillPageState extends State<FillPage> with TickerProviderStateMixin {
  TemplateDetail? _template;
  bool _loading = true;
  String? _error;
  bool _generating = false;

  final Map<String, Map<String, String>> _fieldAnswers = {};
  final Map<String, List<Map<String, String>>> _tableAnswers = {};
  final Map<String, String> _errors = {};

  final Map<String, List<String>> _tableColumnDefaults = {};

  final Set<String> _computedFieldNames = {
    'total_sum_num',
    'total_kop',
    'total_sum_words',
    'total_sum',
    'sum_words',
  };

  /// Поля, перенесённые из contract в другие табы (скрываем из contract)
  final Set<String> _relocatedFieldNames = {};

  String _totalSumNum = '';
  String _totalKop = '';
  String _totalSumWords = '';

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    try {
      final api = context.read<ApiClient>();
      final tmpl = await api.getTemplate(widget.templateCode);

      _computedFieldNames
          .addAll(tmpl.computedFields.map((s) => s.toLowerCase()));

      // Определяем, какие months-поля нужно перенести
      _relocatedFieldNames.clear();
      final contractSec =
          tmpl.sections.where((s) => s.id == 'contract').firstOrNull;
      if (contractSec != null) {
        for (final entry in _monthsFieldForTable.entries) {
          final tableSectionExists =
              tmpl.sections.any((s) => s.id == entry.key && s.table != null);
          final fieldExists =
              contractSec.fields.any((f) => f.name == entry.value);
          if (tableSectionExists && fieldExists) {
            _relocatedFieldNames.add(entry.value);
          }
        }
      }

      // Инициализируем ответы
      for (final sec in tmpl.sections) {
        _fieldAnswers[sec.id] = {};
        for (final f in sec.fields) {
          if (f.defaultValue != null && f.defaultValue!.isNotEmpty) {
            _fieldAnswers[sec.id]![f.name] = f.defaultValue!;
          }
        }
        if (sec.table != null) {
          _tableAnswers[sec.id] = [{}];
          for (final col in sec.table!.columns) {
            final key = '${sec.id}.${col.name}';
            try {
              final vals = await api.getSystemDefaults(key);
              if (vals.isNotEmpty) {
                _tableColumnDefaults[col.name] = vals;
                continue;
              }
            } catch (_) {}
            for (final alias in _columnAliases(sec.id, col.name)) {
              try {
                final vals = await api.getSystemDefaults(alias);
                if (vals.isNotEmpty) {
                  _tableColumnDefaults[col.name] = vals;
                  break;
                }
              } catch (_) {}
            }
          }
        }
      }

      // Загрузка старых ответов из истории
      if (widget.fromDocId != null) {
        try {
          final oldDoc = await api.getDocument(widget.fromDocId!);
          final oldAnswers = oldDoc['answers'] as Map<String, dynamic>? ?? {};
          final oldFields = oldAnswers['fields'] as Map<String, dynamic>? ?? {};
          final oldTables = oldAnswers['tables'] as Map<String, dynamic>? ?? {};
          for (final e in oldFields.entries) {
            if (e.value is Map) {
              _fieldAnswers[e.key] = Map<String, String>.from((e.value as Map)
                  .map((k, v) => MapEntry(k.toString(), v.toString())));
            }
          }
          for (final e in oldTables.entries) {
            if (e.value is List) {
              _tableAnswers[e.key] = (e.value as List)
                  .map((r) => _normalizeTableRow(Map<String, String>.from((r
                          as Map)
                      .map((k, v) => MapEntry(k.toString(), v.toString())))))
                  .toList();
            }
          }
        } catch (_) {}
      }

      final tabs = _buildTabs(tmpl);
      if (tabs.length > 1) {
        _tabController = TabController(length: tabs.length, vsync: this);
      }

      _recalcTotals();
      setState(() {
        _template = tmpl;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<String> _columnAliases(String sectionId, String colName) {
    const aliases = {
      'payment_order': ['payment_terms'],
      'punkt': ['category'],
      'staf': ['tariff'],
    };
    final alts = aliases[colName] ?? [];
    return alts.map((a) => '$sectionId.$a').toList();
  }

  bool _isSectionHidden(SectionModel sec) {
    if (sec.fields.isEmpty) return false;
    return sec.fields.every((f) => _computedFieldNames.contains(f.name));
  }

  /// Набор полей для пропуска при рендере конкретной секции
  Set<String> _skipFieldsForSection(String sectionId) {
    final skip = Set<String>.from(_computedFieldNames);
    // Скрыть relocated months-поля из contract
    if (sectionId == 'contract') {
      skip.addAll(_relocatedFieldNames);
    }
    return skip;
  }

  List<_TabInfo> _buildTabs(TemplateDetail tmpl) {
    final tabs = <_TabInfo>[];
    for (final sec in tmpl.sections) {
      if (_isSectionHidden(sec)) continue;

      if (sec.fields.isNotEmpty) {
        // Проверяем: после скрытия relocated + computed полей остаётся ли что рендерить?
        final skip = _skipFieldsForSection(sec.id);
        final visibleCount =
            sec.fields.where((f) => !skip.contains(f.name)).length;
        if (visibleCount > 0) {
          tabs.add(_TabInfo(
              sectionId: sec.id, title: sec.title, type: _TabType.fields));
        }
      }
      if (sec.table != null) {
        tabs.add(_TabInfo(
            sectionId: sec.id, title: sec.title, type: _TabType.table));
      }
    }
    return tabs;
  }

  void _setFieldValue(String sectionId, String fieldName, String value) {
    setState(() {
      _fieldAnswers.putIfAbsent(sectionId, () => {});
      _fieldAnswers[sectionId]![fieldName] = value;
      _errors.remove('$sectionId.$fieldName');
    });
  }

  void _setTableRow(String sectionId, int rowIndex, Map<String, String> row) {
    setState(() {
      _tableAnswers.putIfAbsent(sectionId, () => []);
      while (_tableAnswers[sectionId]!.length <= rowIndex) {
        _tableAnswers[sectionId]!.add({});
      }
      _tableAnswers[sectionId]![rowIndex] = _normalizeTableRow(row);
      _recalcTotals();
    });
  }

  void _addTableRow(String sectionId) {
    setState(() {
      _tableAnswers.putIfAbsent(sectionId, () => []);
      _tableAnswers[sectionId]!.add({});
    });
  }

  void _removeTableRow(String sectionId, int index) {
    setState(() {
      if (_tableAnswers[sectionId] != null &&
          _tableAnswers[sectionId]!.length > 1) {
        _tableAnswers[sectionId]!.removeAt(index);
        _recalcTotals();
      }
    });
  }

  void _recalcTotals() {
    double total = 0;
    bool hasAny = false;
    for (final entry in _tableAnswers.entries) {
      for (final row in entry.value) {
        final raw = row['period_fee'] ?? '';
        if (raw.isEmpty) continue;
        final val = parseMoney(raw);
        if (val != null) {
          total += val;
          hasAny = true;
        }
      }
    }
    if (hasAny) {
      final rub = total.truncate();
      final kop = ((total - rub) * 100).round();
      _totalSumNum = '$rub';
      _totalKop = kop.toString().padLeft(2, '0');
      _totalSumWords = moneyToWordsRu(rub, kop);
    } else {
      _totalSumNum = '';
      _totalKop = '';
      _totalSumWords = '';
    }
  }

  List<String> _validateAll() {
    final tmpl = _template!;
    _errors.clear();
    final msgs = <String>[];

    for (final sec in tmpl.sections) {
      final secAnswers = _fieldAnswers[sec.id] ?? {};
      for (final f in sec.fields) {
        if (_computedFieldNames.contains(f.name)) continue;
        if (f.required) {
          var val = secAnswers[f.name]?.trim() ?? '';
          if (f.type == 'date' && val.contains('_')) val = '';
          // Маска телефона с подчёркиваниями = пусто
          if (f.name == 'phone' && val.contains('_')) val = '';
          if (val.isEmpty) {
            _errors['${sec.id}.${f.name}'] = 'Обязательное поле';
            msgs.add('${sec.title}: ${f.label}');
            continue;
          }
          final fmtErr = validateFieldFormat(f, val);
          if (fmtErr != null) {
            _errors['${sec.id}.${f.name}'] = fmtErr;
            msgs.add('${sec.title}: ${f.label} — $fmtErr');
          }
        }
      }
    }
    setState(() {});
    return msgs;
  }

  Future<void> _generate() async {
    final missing = _validateAll();
    if (missing.isNotEmpty) {
      _showValidationErrors(missing);
      return;
    }

    setState(() => _generating = true);
    try {
      final api = context.read<ApiClient>();
      final answers = <String, dynamic>{
        'fields': Map<String, dynamic>.from(_fieldAnswers),
        'tables': _buildRequestTables(),
      };
      if (_totalSumNum.isNotEmpty) {
        (answers['fields'] as Map)
            .putIfAbsent('totals', () => <String, String>{});
        final totals = (answers['fields'] as Map)['totals'];
        if (totals is Map) {
          totals['total_sum_num'] = _totalSumNum;
          totals['total_kop'] = _totalKop;
          totals['total_sum_words'] = _totalSumWords;
        }
      }

      final result = await api.generateDocument(
          templateCode: widget.templateCode, answers: answers);
      if (mounted) {
        context.go('/success', extra: {
          'title': _template!.menuTitle,
          'code': _template!.code,
          'filename': result['filename'],
          'akt_filename': result['akt_filename'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Map<String, String> _normalizeTableRow(Map<String, String> row) {
    final normalized = Map<String, String>.from(row);
    final rawPeriodFee = moneyToRaw(normalized['period_fee'] ?? '');

    if (rawPeriodFee.isEmpty) {
      normalized.remove('period_fee');
    } else {
      normalized['period_fee'] = rawPeriodFee;
    }

    return normalized;
  }

  Map<String, List<Map<String, String>>> _buildRequestTables() {
    return {
      for (final entry in _tableAnswers.entries)
        entry.key: entry.value.map((row) {
          final serialized = Map<String, String>.from(row);
          final rawPeriodFee = serialized['period_fee'] ?? '';
          if (rawPeriodFee.isNotEmpty) {
            serialized['period_fee'] = moneyToDisplay(rawPeriodFee);
          }
          return serialized;
        }).toList(),
    };
  }

  void _showValidationErrors(List<String> fields) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Не заполнены обязательные поля'),
              content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: fields
                            .map((f) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    Icon(Icons.warning_amber,
                                        size: 16, color: AppColors.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(f,
                                            style:
                                                const TextStyle(fontSize: 14))),
                                  ]),
                                ))
                            .toList()),
                  )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Понятно'))
              ],
            ));
  }

  // ──────────── Поиск months-поля для таблицы ────────────

  /// Найти FieldModel для months-поля, привязанного к этой таблице
  FieldModel? _findMonthsFieldForTable(
      TemplateDetail tmpl, String tableSectionId) {
    final monthsFieldName = _monthsFieldForTable[tableSectionId];
    if (monthsFieldName == null ||
        !_relocatedFieldNames.contains(monthsFieldName)) return null;

    final contractSec =
        tmpl.sections.where((s) => s.id == 'contract').firstOrNull;
    if (contractSec == null) return null;

    return contractSec.fields
        .where((f) => f.name == monthsFieldName)
        .firstOrNull;
  }

  /// Виджет MonthsSelector для перенесённого поля (данные хранятся в contract)
  Widget _buildRelocatedMonths(FieldModel field) {
    final value = _fieldAnswers['contract']?[field.name] ?? '';
    final errorKey = 'contract.${field.name}';
    return MonthsSelector(
      field: field,
      value: value,
      errorText: _errors[errorKey],
      onChanged: (v) => _setFieldValue('contract', field.name, v),
    );
  }

  // ──────────── Build ────────────

  @override
  Widget build(BuildContext context) {
    final tmpl = _template;
    return AppShell(
      title: tmpl?.menuTitle ?? 'Загрузка...',
      showBack: true,
      onBack: () => context.go('/'),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: TextStyle(color: AppColors.error)))
              : tmpl!.isCompact
                  ? _buildCompact(tmpl)
                  : _buildTabbed(tmpl),
    );
  }

  // ──────────── Compact layout ────────────

  Widget _buildCompact(TemplateDetail tmpl) {
    final visibleSections =
        tmpl.sections.where((s) => !_isSectionHidden(s)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tmpl.menuTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 32),
            for (final sec in visibleSections) ...[
              if (sec.fields.isNotEmpty)
                SectionForm(
                    section: sec,
                    answers: _fieldAnswers[sec.id] ?? {},
                    errors: _errors,
                    computedFields: _skipFieldsForSection(sec.id),
                    onFieldChanged: (n, v) => _setFieldValue(sec.id, n, v)),
              if (sec.table != null) ...[
                // Months-селектор над таблицей (если есть)
                _buildMonthsAboveTable(tmpl, sec.id),
                TableForm(
                    section: sec,
                    rows: _tableAnswers[sec.id] ?? [{}],
                    columnDefaults: _tableColumnDefaults,
                    onRowChanged: (i, r) => _setTableRow(sec.id, i, r),
                    onAddRow: () => _addTableRow(sec.id),
                    onRemoveRow: (i) => _removeTableRow(sec.id, i)),
              ],
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            _buildGenerateButton(),
          ]),
        )),
      )),
    );
  }

  /// Построить MonthsSelector над таблицей (если поле перенесено)
  Widget _buildMonthsAboveTable(TemplateDetail tmpl, String tableSectionId) {
    final field = _findMonthsFieldForTable(tmpl, tableSectionId);
    if (field == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildRelocatedMonths(field),
    );
  }

  // ──────────── Tabbed layout ────────────

  Widget _buildTabbed(TemplateDetail tmpl) {
    final tabs = _buildTabs(tmpl);
    return Column(children: [
      Container(
          color: AppColors.surface,
          child: TabBar(
              controller: _tabController,
              isScrollable: false,
              tabs: tabs.map((t) => Tab(text: t.title)).toList())),
      Expanded(
          child: TabBarView(
              controller: _tabController,
              children: tabs
                  .asMap()
                  .entries
                  .map((e) => _buildTabContent(tmpl, e.value,
                      isLast: e.key == tabs.length - 1))
                  .toList())),
    ]);
  }

  Widget _buildTabContent(TemplateDetail tmpl, _TabInfo tab,
      {required bool isLast}) {
    final isTable = tab.type == _TabType.table;
    final maxW = isTable ? 1400.0 : 900.0;
    final hPad = isTable ? 16.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: hPad),
      child: Center(
          child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: isTable
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: _buildTabInner(tmpl, tab, isLast: isLast),
              )
            : Card(
                child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildTabInner(tmpl, tab, isLast: isLast))),
      )),
    );
  }

  Widget _buildTabInner(TemplateDetail tmpl, _TabInfo tab,
      {required bool isLast}) {
    final sec = tmpl.sections.firstWhere((s) => s.id == tab.sectionId);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(sec.title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 64),

      if (tab.type == _TabType.fields)
        SectionForm(
            section: sec,
            answers: _fieldAnswers[sec.id] ?? {},
            errors: _errors,
            computedFields: _skipFieldsForSection(sec.id),
            onFieldChanged: (n, v) => _setFieldValue(sec.id, n, v)),

      if (tab.type == _TabType.table) ...[
        // ── Months-селектор над таблицей ──
        _buildMonthsAboveTable(tmpl, sec.id),
        TableForm(
            section: sec,
            rows: _tableAnswers[sec.id] ?? [{}],
            columnDefaults: _tableColumnDefaults,
            onRowChanged: (i, r) => _setTableRow(sec.id, i, r),
            onAddRow: () => _addTableRow(sec.id),
            onRemoveRow: (i) => _removeTableRow(sec.id, i)),
      ],

      const SizedBox(height: 32),

      // Навигация
      if (!isLast) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (_tabController != null && _tabController!.index > 0)
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                            onPressed: () => _tabController!
                                .animateTo(_tabController!.index - 1),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceVariant,
                                foregroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4))),
                            child: const Text('Назад')))))
          else
            const Spacer(),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                          onPressed: () => _tabController
                              ?.animateTo(_tabController!.index + 1),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceVariant,
                              foregroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4))),
                          child: const Text('Далее'))))),
        ]),
      ] else ...[
        if (_tabController != null && _tabController!.index > 0) ...[
          Row(children: [
            Expanded(
                child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                        onPressed: () => _tabController!
                            .animateTo(_tabController!.index - 1),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceVariant,
                            foregroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4))),
                        child: const Text('Назад')))),
            const SizedBox(width: 12),
            Expanded(child: _buildGenerateButton()),
          ]),
        ] else
          _buildGenerateButton(),
      ],
    ]);
  }

  Widget _buildGenerateButton() {
    return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _generating ? null : _generate,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.surface,
              disabledBackgroundColor: AppColors.buttonDisabled,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4))),
          child: _generating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Сформировать документ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ));
  }
}

enum _TabType { fields, table }

class _TabInfo {
  final String sectionId, title;
  final _TabType type;
  _TabInfo({required this.sectionId, required this.title, required this.type});
}
