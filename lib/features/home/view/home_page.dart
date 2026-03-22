import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/template_models.dart';
import '../../../shared/widgets/app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TemplatesTree? _tree;
  List<dynamic> _recentDocs = [];
  bool _loading = true;
  String? _error;

  int? _selectedCategoryIdx;
  int? _selectedSubcategoryIdx;
  String? _selectedTemplateCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final tree = await api.getTemplatesTree();
      List<dynamic> recent = [];
      try { recent = await api.getRecentDocuments(); } catch (_) {}
      setState(() { _tree = tree; _recentDocs = recent; _loading = false; });
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final tree = _tree;
    if (tree == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === Последние заполненные документы ===
              if (_recentDocs.isNotEmpty) ...[
                Row(
                  children: [
                    Text('Последние заполненные документы',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () => context.go('/documents'),
                      child: Text('Все документы',
                          style: TextStyle(color: AppColors.primary, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _RecentDocumentsRow(documents: _recentDocs),
                const SizedBox(height: 48),
              ],

              // === Заполнить документ ===
              Text('Заполнить документ', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 28),

              // Компания
              Text('Компания', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _SegmentedSelector(
                options: tree.categories.map((c) => c.name).toList(),
                selectedIndex: _selectedCategoryIdx,
                onSelected: (i) => setState(() {
                  _selectedCategoryIdx = i;
                  _selectedSubcategoryIdx = null;
                  _selectedTemplateCode = null;
                }),
              ),
              const SizedBox(height: 28),

              // Форма собственности → шаблоны (сгруппированные)
              if (_selectedCategoryIdx != null) ...[
                Text('Форма собственности', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildTemplateSelector(tree),
                const SizedBox(height: 28),
              ],

              // Тип документа (подкатегории) — если в выбранной форме > 1 шаблона
              if (_selectedCategoryIdx != null && _selectedSubcategoryIdx != null) ...[
                _buildSubcategoryTemplates(tree),
                const SizedBox(height: 28),
              ],

              // Кнопка «Заполнить»
              if (_selectedTemplateCode != null)
                _buildFillButton()
              else if (_selectedCategoryIdx != null)
                _buildDisabledButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateSelector(TemplatesTree tree) {
    // Собираем уникальные "формы собственности" из названий шаблонов
    final cat = tree.categories[_selectedCategoryIdx!];
    // Простой подход: показываем подкатегории как сегменты
    final subs = cat.subcategories;

    if (subs.length == 1 && subs[0].templates.length <= 3) {
      // Если одна подкатегория — показываем шаблоны напрямую
      final templates = subs[0].templates;
      // Определяем формы: ООО, ИП до 2017, ИП с 2017
      return _SegmentedSelector(
        options: templates.map((t) => _shortLabel(t.menuTitle)).toList(),
        selectedIndex: templates.indexWhere((t) => t.code == _selectedTemplateCode),
        onSelected: (i) => setState(() {
          _selectedTemplateCode = templates[i].code;
          _selectedSubcategoryIdx = 0;
        }),
      );
    }

    // Несколько подкатегорий — показываем их
    return _SegmentedSelector(
      options: subs.map((s) => s.name).toList(),
      selectedIndex: _selectedSubcategoryIdx,
      onSelected: (i) => setState(() {
        _selectedSubcategoryIdx = i;
        _selectedTemplateCode = null;
        // Если в подкатегории только один шаблон — автовыбор
        if (subs[i].templates.length == 1) {
          _selectedTemplateCode = subs[i].templates[0].code;
        }
      }),
    );
  }

  Widget _buildSubcategoryTemplates(TemplatesTree tree) {
    final cat = tree.categories[_selectedCategoryIdx!];
    if (_selectedSubcategoryIdx == null || _selectedSubcategoryIdx! >= cat.subcategories.length) {
      return const SizedBox.shrink();
    }
    final sub = cat.subcategories[_selectedSubcategoryIdx!];
    if (sub.templates.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Тип документа', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SegmentedSelector(
          options: sub.templates.map((t) => _shortLabel(t.menuTitle)).toList(),
          selectedIndex: sub.templates.indexWhere((t) => t.code == _selectedTemplateCode),
          onSelected: (i) => setState(() => _selectedTemplateCode = sub.templates[i].code),
        ),
      ],
    );
  }

  Widget _buildFillButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => context.go('/fill/$_selectedTemplateCode'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: const Text('Заполнить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildDisabledButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonDisabled,
              foregroundColor: AppColors.buttonTextDisabled,
              disabledBackgroundColor: AppColors.buttonDisabled,
              disabledForegroundColor: AppColors.buttonTextDisabled,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Заполнить'),
          ),
        ),
        const SizedBox(height: 8),
        Text('Недоступно пока не выбраны все поля',
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  String _shortLabel(String menuTitle) {
    // ФМ-ЛД-ИП до 2017 → ИП до 2017
    // ФМ-ЛД-ООО → ООО
    if (menuTitle.contains('ООО')) return 'ООО';
    if (menuTitle.contains('ИП до 2017')) return 'ИП до 2017';
    if (menuTitle.contains('ИП с 2017')) return 'ИП с 2017';
    return menuTitle;
  }
}

/// Горизонтальная строка последних документов
class _RecentDocumentsRow extends StatelessWidget {
  final List<dynamic> documents;
  const _RecentDocumentsRow({required this.documents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (int i = 0; i < documents.length; i++) ...[
              if (i > 0)
                VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final doc = documents[i];
                    final code = doc['template_code'] ?? '';
                    final docId = doc['id'];
                    // Переходим к заполнению с загрузкой старых данных
                    context.go('/fill/$code?fromDoc=$docId');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Text(
                      documents[i]['template_title'] ?? documents[i]['template_code'] ?? '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Сегментированный выбор (ФОРМАКС | РАО | ВОИС) — как в макете
class _SegmentedSelector extends StatelessWidget {
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _SegmentedSelector({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.segmentBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(options.length, (i) {
            final selected = i == selectedIndex;
            return Expanded(
              child: _SegmentButton(
                label: options[i],
                isSelected: selected,
                isFirst: i == 0,
                isLast: i == options.length - 1,
                onTap: () => onSelected(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label, required this.isSelected,
    required this.isFirst, required this.isLast, required this.onTap,
  });

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.segmentActiveBg
                : _hovered ? const Color(0xFFEEEEEE) : AppColors.segmentInactiveBg,
            border: Border(
              left: widget.isFirst ? BorderSide.none : BorderSide(color: AppColors.segmentBorder, width: 0.5),
            ),
            borderRadius: BorderRadius.horizontal(
              left: widget.isFirst ? const Radius.circular(3) : Radius.zero,
              right: widget.isLast ? const Radius.circular(3) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
