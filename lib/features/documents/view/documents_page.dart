import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/header_nav_link.dart';

/// Коды шаблонов доп. соглашений (для фильтрации вкладки)
const _dsTemplateCodes = {
  'ds_ld_ip_do_2017',
  'ds_ld_ip_s_pre2017',
  'ds_ld_ooo',
};

bool _isDsTemplate(String code) {
  return _dsTemplateCodes.contains(code) || code.startsWith('ds_');
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> with SingleTickerProviderStateMixin {
  List<dynamic> _docs = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiClient>();
      final docs = await api.getAllDocuments();
      setState(() { _docs = docs; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filteredDocs {
    if (_tabController.index == 1) {
      // Только доп. соглашения
      return _docs.where((d) => _isDsTemplate(d['template_code'] ?? '')).toList();
    }
    return _docs;
  }

  /// Группировка документов по дате
  Map<String, List<dynamic>> _groupByDate(List<dynamic> docs) {
    final groups = <String, List<dynamic>>{};
    for (final d in docs) {
      final dateKey = _formatDateKey(d['created_at'] ?? '');
      groups.putIfAbsent(dateKey, () => []).add(d);
    }
    return groups;
  }

  String _formatDateKey(String iso) {
    if (iso.isEmpty) return 'Без даты';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return 'Без даты';
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Вы уверены, что хотите удалить все документы?',
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Да, удалить'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Нет, не удалять'),
          ),
        ],
      ),
    );
  }

  void _downloadFile(String fname) {
    if (fname.isEmpty) return;
    final base = Uri.base.origin;
    html.window.open('$base/api/v1/download/$fname', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      showBack: true,
      onBack: () => context.go('/'),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок + Очистить
                      Row(
                        children: [
                          Text('Заполненные документы',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(width: 20),
                          HeaderNavLink(
                            label: 'Очистить',
                            onTap: _showClearDialog,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Табы
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.divider)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textHint,
                          indicatorColor: AppColors.primary,
                          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                          tabs: const [
                            Tab(text: 'Все'),
                            Tab(text: 'Дополнительные соглашения'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Контент
                      _buildDocsList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDocsList() {
    final docs = _filteredDocs;
    if (docs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Документов пока нет')),
      );
    }

    final grouped = _groupByDate(docs);
    final dateKeys = grouped.keys.toList(); // уже отсортированы по дате (DESC из API)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final dateKey in dateKeys) ...[
          const SizedBox(height: 20),
          // Дата-группа
          Text(dateKey,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          // Карточки документов
          for (final d in grouped[dateKey]!) _DocCard(
            doc: d,
            onDuplicate: () {
              final code = d['template_code'] ?? '';
              final docId = d['id'];
              context.go('/fill/$code?fromDoc=$docId');
            },
            onDownload: () => _downloadFile(d['filename'] ?? ''),
            onTap: () {
              final code = d['template_code'] ?? '';
              final docId = d['id'];
              context.go('/fill/$code?fromDoc=$docId');
            },
          ),
        ],
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final VoidCallback onDuplicate;
  final VoidCallback onDownload;
  final VoidCallback onTap;

  const _DocCard({
    required this.doc,
    required this.onDuplicate,
    required this.onDownload,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = doc['template_title'] ?? doc['template_code'] ?? '';
    final hasFi = (doc['filename'] ?? '').isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Название документа
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),

              // «Дублировать»
              HeaderNavLink(
                label: 'Дублировать',
                onTap: onDuplicate,
              ),

              // Скачать
              if (hasFi) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.download_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Скачать',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDownload,
                ),
              ],

              // Шеврон
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}