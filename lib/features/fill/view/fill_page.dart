import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/template_models.dart';
import '../../../core/utils/number_to_words_ru.dart';
import '../../../shared/widgets/app_shell.dart';
import '../widgets/section_form.dart';
import '../widgets/table_form.dart';

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

  /// Дефолты для колонок таблиц: {columnName: [val1, val2]}
  final Map<String, List<String>> _tableColumnDefaults = {};

  /// Computed поля (пропускаем при рендеринге)
  final Set<String> _computedFieldNames = {
    'total_sum_num', 'total_kop', 'total_sum_words',
    'total_sum', 'sum_words',
  };

  String _totalSumNum = '';
  String _totalKop = '';
  String _totalSumWords = '';

  TabController? _tabController;

  @override
  void initState() { super.initState(); _loadTemplate(); }

  @override
  void dispose() { _tabController?.dispose(); super.dispose(); }

  Future<void> _loadTemplate() async {
    try {
      final api = context.read<ApiClient>();
      final tmpl = await api.getTemplate(widget.templateCode);

      // Добавляем computed fields из шаблона
      _computedFieldNames.addAll(tmpl.computedFields.map((s) => s.toLowerCase()));

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
          // Загружаем дефолты для колонок таблицы
          for (final col in sec.table!.columns) {
            final key = '${sec.id}.${col.name}';
            try {
              final vals = await api.getSystemDefaults(key);
              if (vals.isNotEmpty) _tableColumnDefaults[col.name] = vals;
            } catch (_) {}
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
              _fieldAnswers[e.key] = Map<String, String>.from(
                  (e.value as Map).map((k, v) => MapEntry(k.toString(), v.toString())));
            }
          }
          for (final e in oldTables.entries) {
            if (e.value is List) {
              _tableAnswers[e.key] = (e.value as List)
                  .map((r) => Map<String, String>.from(
                      (r as Map).map((k, v) => MapEntry(k.toString(), v.toString()))))
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
      setState(() { _template = tmpl; _loading = false; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  List<_TabInfo> _buildTabs(TemplateDetail tmpl) {
    final tabs = <_TabInfo>[];
    for (final sec in tmpl.sections) {
      if (sec.fields.isNotEmpty) tabs.add(_TabInfo(sectionId: sec.id, title: sec.title, type: _TabType.fields));
      if (sec.table != null) tabs.add(_TabInfo(sectionId: sec.id, title: sec.title, type: _TabType.table));
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
      while (_tableAnswers[sectionId]!.length <= rowIndex) _tableAnswers[sectionId]!.add({});
      _tableAnswers[sectionId]![rowIndex] = row;
      _recalcTotals();
    });
  }

  void _addTableRow(String sectionId) {
    setState(() { _tableAnswers.putIfAbsent(sectionId, () => []); _tableAnswers[sectionId]!.add({}); });
  }

  void _removeTableRow(String sectionId, int index) {
    setState(() {
      if (_tableAnswers[sectionId] != null && _tableAnswers[sectionId]!.length > 1) {
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
        final val = double.tryParse(raw.replaceAll(',', '.').replaceAll(' ', '').replaceAll('\u00A0', ''));
        if (val != null) { total += val; hasAny = true; }
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
          final val = secAnswers[f.name]?.trim() ?? '';
          if (val.isEmpty) {
            _errors['${sec.id}.${f.name}'] = 'Обязательное поле';
            msgs.add('${sec.title}: ${f.label}');
            continue;
          }
          // Валидация формата
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
    if (missing.isNotEmpty) { _showValidationErrors(missing); return; }

    setState(() => _generating = true);
    try {
      final api = context.read<ApiClient>();
      final answers = <String, dynamic>{
        'fields': Map<String, dynamic>.from(_fieldAnswers),
        'tables': _tableAnswers,
      };
      // Подставляем итоги
      if (_totalSumNum.isNotEmpty) {
        (answers['fields'] as Map).putIfAbsent('totals', () => <String, String>{});
        final totals = (answers['fields'] as Map)['totals'];
        if (totals is Map) {
          totals['total_sum_num'] = _totalSumNum;
          totals['total_kop'] = _totalKop;
          totals['total_sum_words'] = _totalSumWords;
        }
      }

      final result = await api.generateDocument(templateCode: widget.templateCode, answers: answers);
      if (mounted) {
        context.go('/success', extra: {
          'title': _template!.menuTitle, 'code': _template!.code,
          'filename': result['filename'], 'akt_filename': result['akt_filename'],
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showValidationErrors(List<String> fields) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Не заполнены обязательные поля'),
      content: SizedBox(width: 400, child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: fields.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(Icons.warning_amber, size: 16, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
            ]),
          )).toList()),
      )),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Понятно'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tmpl = _template;
    return AppShell(title: tmpl?.menuTitle ?? 'Загрузка...', showBack: true,
      onBack: () => context.go('/'),
      child: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
          : tmpl!.isCompact ? _buildCompact(tmpl) : _buildTabbed(tmpl),
    );
  }

  Widget _buildCompact(TemplateDetail tmpl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: Card(child: Padding(padding: const EdgeInsets.all(32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(tmpl.menuTitle, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 32),
            for (final sec in tmpl.sections) ...[
              if (sec.fields.isNotEmpty) SectionForm(section: sec,
                  answers: _fieldAnswers[sec.id] ?? {}, errors: _errors,
                  computedFields: _computedFieldNames,
                  onFieldChanged: (n, v) => _setFieldValue(sec.id, n, v)),
              if (sec.table != null) ...[
                TableForm(section: sec, rows: _tableAnswers[sec.id] ?? [{}],
                    columnDefaults: _tableColumnDefaults,
                    onRowChanged: (i, r) => _setTableRow(sec.id, i, r),
                    onAddRow: () => _addTableRow(sec.id),
                    onRemoveRow: (i) => _removeTableRow(sec.id, i)),
                if (_totalSumNum.isNotEmpty) _buildTotalsReadonly(),
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

  Widget _buildTabbed(TemplateDetail tmpl) {
    final tabs = _buildTabs(tmpl);
    return Column(children: [
      Container(color: AppColors.surface, child: TabBar(
        controller: _tabController, isScrollable: true,
        tabs: tabs.map((t) => Tab(text: t.title)).toList())),
      Expanded(child: TabBarView(controller: _tabController,
        children: tabs.asMap().entries.map((e) =>
            _buildTabContent(tmpl, e.value, isLast: e.key == tabs.length - 1)).toList())),
    ]);
  }

  Widget _buildTabContent(TemplateDetail tmpl, _TabInfo tab, {required bool isLast}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
        child: Card(child: Padding(padding: const EdgeInsets.all(32),
          child: _buildTabInner(tmpl, tab, isLast: isLast))))),
    );
  }

  Widget _buildTabInner(TemplateDetail tmpl, _TabInfo tab, {required bool isLast}) {
    final sec = tmpl.sections.firstWhere((s) => s.id == tab.sectionId);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(sec.title, style: Theme.of(context).textTheme.headlineMedium),
      const Divider(height: 32),

      if (tab.type == _TabType.fields)
        SectionForm(section: sec, answers: _fieldAnswers[sec.id] ?? {},
            errors: _errors, computedFields: _computedFieldNames,
            onFieldChanged: (n, v) => _setFieldValue(sec.id, n, v)),

      if (tab.type == _TabType.table) ...[
        TableForm(section: sec, rows: _tableAnswers[sec.id] ?? [{}],
            columnDefaults: _tableColumnDefaults,
            onRowChanged: (i, r) => _setTableRow(sec.id, i, r),
            onAddRow: () => _addTableRow(sec.id),
            onRemoveRow: (i) => _removeTableRow(sec.id, i)),
        if (_totalSumNum.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildTotalsReadonly(),
        ],
      ],

      const SizedBox(height: 32),

      // Навигация
      if (!isLast) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          if (_tabController != null && _tabController!.index > 0)
            Expanded(child: Padding(padding: const EdgeInsets.only(right: 8),
              child: SizedBox(height: 48, child: ElevatedButton(
                onPressed: () => _tabController!.animateTo(_tabController!.index - 1),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                child: const Text('Назад')))))
          else const Spacer(),
          Expanded(child: Padding(padding: const EdgeInsets.only(left: 8),
            child: SizedBox(height: 48, child: ElevatedButton(
              onPressed: () => _tabController?.animateTo(_tabController!.index + 1),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
              child: const Text('Далее'))))),
        ]),
      ] else ...[
        // Последний таб — Назад + Сформировать
        if (_tabController != null && _tabController!.index > 0) ...[
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: ElevatedButton(
              onPressed: () => _tabController!.animateTo(_tabController!.index - 1),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
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
    return SizedBox(height: 48, child: ElevatedButton(
      onPressed: _generating ? null : _generate,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textPrimary, disabledBackgroundColor: AppColors.buttonDisabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
      child: _generating
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Сформировать документ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    ));
  }

  Widget _buildTotalsReadonly() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 32),
      _roField('Итоговая сумма, руб', _totalSumNum, 'цифрами'),
      const SizedBox(height: 12),
      _roField('Итоговая сумма, руб', _totalSumWords, 'прописью'),
      const SizedBox(height: 12),
      _roField('Итоговая сумма, копейки', _totalKop, 'цифрами'),
    ]);
  }

  Widget _roField(String label, String value, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 6),
      Container(width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.fieldDefaultBg,
            border: Border.all(color: AppColors.fieldBorder), borderRadius: BorderRadius.circular(4)),
        child: Text(value.isEmpty ? '—' : value,
            style: TextStyle(fontSize: 15, color: value.isEmpty ? AppColors.textHint : AppColors.textPrimary))),
      Padding(padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(hint, style: Theme.of(context).textTheme.bodySmall)),
    ]);
  }
}

enum _TabType { fields, table }

class _TabInfo {
  final String sectionId, title;
  final _TabType type;
  _TabInfo({required this.sectionId, required this.title, required this.type});
}
