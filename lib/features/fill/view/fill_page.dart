import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../shared/widgets/app_shell.dart';
import '../widgets/section_form.dart';
import '../widgets/table_form.dart';
import '../widgets/review_panel.dart';

class FillPage extends StatefulWidget {
  final String templateCode;
  const FillPage({super.key, required this.templateCode});

  @override
  State<FillPage> createState() => _FillPageState();
}

class _FillPageState extends State<FillPage> with TickerProviderStateMixin {
  TemplateDetail? _template;
  bool _loading = true;
  String? _error;
  bool _generating = false;

  /// Ответы пользователя: {section_id: {field_name: value}}
  final Map<String, Map<String, String>> _fieldAnswers = {};

  /// Ответы по таблицам: {section_id: [row1, row2, ...]}
  final Map<String, List<Map<String, String>>> _tableAnswers = {};

  /// Ошибки валидации: {section_id.field_name: error_text}
  final Map<String, String> _errors = {};

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

      // Инициализируем ответы дефолтными значениями
      for (final sec in tmpl.sections) {
        _fieldAnswers[sec.id] = {};
        for (final f in sec.fields) {
          if (f.defaultValue != null && f.defaultValue!.isNotEmpty) {
            _fieldAnswers[sec.id]![f.name] = f.defaultValue!;
          }
        }
        if (sec.table != null) {
          // Начинаем с одной пустой строки
          _tableAnswers[sec.id] = [{}];
        }
      }

      // Создаём TabController для многостраничных шаблонов
      if (!tmpl.isCompact) {
        final tabCount = _buildTabs(tmpl).length;
        _tabController = TabController(length: tabCount, vsync: this);
      }

      setState(() {
        _template = tmpl;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить шаблон: $e';
        _loading = false;
      });
    }
  }

  List<_TabInfo> _buildTabs(TemplateDetail tmpl) {
    final tabs = <_TabInfo>[];
    for (final sec in tmpl.sections) {
      if (sec.fields.isNotEmpty) {
        tabs.add(_TabInfo(sectionId: sec.id, title: sec.title, type: _TabType.fields));
      }
      if (sec.table != null) {
        final tableTitle = sec.title.contains('табл') || sec.title.contains('объект')
            ? sec.title
            : 'Таблица: ${sec.title}';
        tabs.add(_TabInfo(sectionId: sec.id, title: tableTitle, type: _TabType.table));
      }
    }
    // Всегда добавляем таб «Проверка данных»
    tabs.add(_TabInfo(sectionId: '_review', title: 'Проверка данных', type: _TabType.review));
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
      _tableAnswers[sectionId]![rowIndex] = row;
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
      }
    });
  }

  bool _validate() {
    final tmpl = _template!;
    _errors.clear();

    for (final sec in tmpl.sections) {
      final secAnswers = _fieldAnswers[sec.id] ?? {};
      for (final f in sec.fields) {
        if (f.required) {
          final val = secAnswers[f.name]?.trim() ?? '';
          if (val.isEmpty) {
            _errors['${sec.id}.${f.name}'] = 'Обязательное поле';
          }
        }
      }
    }

    setState(() {});
    return _errors.isEmpty;
  }

  Future<void> _generate() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final api = context.read<ApiClient>();
      final bytes = await api.generateDocument(
        templateCode: widget.templateCode,
        answers: {
          'fields': _fieldAnswers,
          'tables': _tableAnswers,
        },
      );

      // Скачиваем файл сразу
      final filename = '${_template!.menuTitle.replaceAll(' ', '_')}.docx';
      _triggerBrowserDownload(bytes, filename);

      if (mounted) {
        context.go('/success', extra: {
          'title': _template!.menuTitle,
          'code': _template!.code,
          'fileBytes': bytes,
          'fileName': filename,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка генерации: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// Скачивание файла в браузере через Blob URL
  void _triggerBrowserDownload(Uint8List bytes, String filename) {
    try {
      _downloadViaBlob(bytes, filename);
    } catch (_) {
      // Не критично — на success-странице будет кнопка «Скачать»
    }
  }

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
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : tmpl!.isCompact
                  ? _buildCompactForm(tmpl)
                  : _buildTabbedForm(tmpl),
    );
  }

  /// Сценарий 1: Компактная форма (все поля на одной странице)
  Widget _buildCompactForm(TemplateDetail tmpl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Заголовок шаблона
                  Text(
                    tmpl.menuTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tmpl.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 32),

                  // Все секции подряд
                  for (final sec in tmpl.sections) ...[
                    if (sec.fields.isNotEmpty)
                      SectionForm(
                        section: sec,
                        answers: _fieldAnswers[sec.id] ?? {},
                        errors: _errors,
                        onFieldChanged: (name, value) =>
                            _setFieldValue(sec.id, name, value),
                      ),
                    if (sec.table != null)
                      TableForm(
                        section: sec,
                        rows: _tableAnswers[sec.id] ?? [{}],
                        onRowChanged: (idx, row) => _setTableRow(sec.id, idx, row),
                        onAddRow: () => _addTableRow(sec.id),
                        onRemoveRow: (idx) => _removeTableRow(sec.id, idx),
                      ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  // Кнопка генерации
                  AppPrimaryButton(
                    label: 'Заполнить договор',
                    icon: Icons.description,
                    isLoading: _generating,
                    onPressed: _generate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Сценарий 2: Форма с табами (многостраничные шаблоны)
  Widget _buildTabbedForm(TemplateDetail tmpl) {
    final tabs = _buildTabs(tmpl);

    return Column(
      children: [
        // Таб-бар
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: tabs.map((t) => Tab(text: t.title)).toList(),
          ),
        ),

        // Контент таба
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((tab) => _buildTabContent(tmpl, tab)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(TemplateDetail tmpl, _TabInfo tab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _buildTabInner(tmpl, tab),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabInner(TemplateDetail tmpl, _TabInfo tab) {
    switch (tab.type) {
      case _TabType.fields:
        final sec = tmpl.sections.firstWhere((s) => s.id == tab.sectionId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sec.title, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 32),
            SectionForm(
              section: sec,
              answers: _fieldAnswers[sec.id] ?? {},
              errors: _errors,
              onFieldChanged: (name, value) => _setFieldValue(sec.id, name, value),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppPrimaryButton(
                  label: 'Далее',
                  expanded: false,
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    if (_tabController != null &&
                        _tabController!.index < _tabController!.length - 1) {
                      _tabController!.animateTo(_tabController!.index + 1);
                    }
                  },
                ),
              ],
            ),
          ],
        );

      case _TabType.table:
        final sec = tmpl.sections.firstWhere((s) => s.id == tab.sectionId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(sec.title, style: Theme.of(context).textTheme.headlineMedium),
            const Divider(height: 32),
            TableForm(
              section: sec,
              rows: _tableAnswers[sec.id] ?? [{}],
              onRowChanged: (idx, row) => _setTableRow(sec.id, idx, row),
              onAddRow: () => _addTableRow(sec.id),
              onRemoveRow: (idx) => _removeTableRow(sec.id, idx),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSecondaryButton(
                  label: 'Назад',
                  expanded: false,
                  onPressed: () => _tabController?.animateTo(_tabController!.index - 1),
                ),
                AppPrimaryButton(
                  label: 'Далее',
                  expanded: false,
                  icon: Icons.arrow_forward,
                  onPressed: () => _tabController?.animateTo(_tabController!.index + 1),
                ),
              ],
            ),
          ],
        );

      case _TabType.review:
        return ReviewPanel(
          template: tmpl,
          fieldAnswers: _fieldAnswers,
          tableAnswers: _tableAnswers,
          errors: _errors,
          isGenerating: _generating,
          onGenerate: _generate,
          onEditSection: (sectionId) {
            final idx = _buildTabs(tmpl)
                .indexWhere((t) => t.sectionId == sectionId);
            if (idx >= 0) _tabController?.animateTo(idx);
          },
        );
    }
  }
}

enum _TabType { fields, table, review }

class _TabInfo {
  final String sectionId;
  final String title;
  final _TabType type;
  _TabInfo({required this.sectionId, required this.title, required this.type});
}

/// Скачивание файла в браузере через Blob URL (Flutter Web)
void _downloadViaBlob(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
