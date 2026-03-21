import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/template_models.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../shared/widgets/app_shell.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TemplatesTree? _tree;
  bool _loading = true;
  String? _error;

  // Выбранные значения
  int? _selectedCategoryIdx;
  int? _selectedSubcategoryIdx;
  String? _selectedTemplateCode;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final api = context.read<ApiClient>();
      final tree = await api.getTemplatesTree();
      setState(() {
        _tree = tree;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить шаблоны: $e';
        _loading = false;
      });
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок
              Text(
                'Генератор документов',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите тип документа для заполнения',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Компания
              _SelectorSection(
                label: 'Компания',
                options: tree.categories.map((c) => c.name).toList(),
                selectedIndex: _selectedCategoryIdx,
                onSelected: (idx) {
                  setState(() {
                    _selectedCategoryIdx = idx;
                    _selectedSubcategoryIdx = null;
                    _selectedTemplateCode = null;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Тип документа (подкатегория)
              if (_selectedCategoryIdx != null) ...[
                _SelectorSection(
                  label: 'Тип документа',
                  options: tree.categories[_selectedCategoryIdx!].subcategories
                      .map((s) => s.name)
                      .toList(),
                  selectedIndex: _selectedSubcategoryIdx,
                  onSelected: (idx) {
                    setState(() {
                      _selectedSubcategoryIdx = idx;
                      _selectedTemplateCode = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Форма собственности (шаблон)
              if (_selectedCategoryIdx != null &&
                  _selectedSubcategoryIdx != null) ...[
                _TemplatePicker(
                  label: 'Форма собственности',
                  templates: tree
                      .categories[_selectedCategoryIdx!]
                      .subcategories[_selectedSubcategoryIdx!]
                      .templates,
                  selectedCode: _selectedTemplateCode,
                  onSelected: (code) {
                    setState(() => _selectedTemplateCode = code);
                  },
                ),
                const SizedBox(height: 40),
              ],

              // Кнопка «Заполнить договор»
              if (_selectedTemplateCode != null)
                AppPrimaryButton(
                  label: 'Заполнить договор',
                  icon: Icons.edit_document,
                  onPressed: () {
                    context.go('/fill/$_selectedTemplateCode');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Горизонтальный выбор из нескольких вариантов
class _SelectorSection extends StatelessWidget {
  final String label;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _SelectorSection({
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(options.length, (i) {
            final isSelected = i == selectedIndex;
            return _SelectionButton(
              label: options[i],
              isSelected: isSelected,
              onTap: () => onSelected(i),
            );
          }),
        ),
      ],
    );
  }
}

/// Выбор шаблона из списка
class _TemplatePicker extends StatelessWidget {
  final String label;
  final List<TemplateListItem> templates;
  final String? selectedCode;
  final ValueChanged<String> onSelected;

  const _TemplatePicker({
    required this.label,
    required this.templates,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: templates.map((t) {
            final isSelected = t.code == selectedCode;
            return _SelectionButton(
              label: t.menuTitle,
              isSelected: isSelected,
              onTap: () => onSelected(t.code),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Кнопка выбора — два состояния (из UI kit)
class _SelectionButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SelectionButton> createState() => _SelectionButtonState();
}

class _SelectionButtonState extends State<_SelectionButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.buttonPrimary
                : _hovered
                    ? AppColors.buttonSecondaryHover
                    : AppColors.buttonSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.buttonPrimary
                  : AppColors.fieldBorder,
              width: 1,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}


