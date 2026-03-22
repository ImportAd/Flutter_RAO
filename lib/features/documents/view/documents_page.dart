import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_shell.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});
  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<dynamic> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Все документы',
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
                      Text('Все документы', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('${_docs.length} документов', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      if (_docs.isEmpty)
                        const Center(child: Text('Документов пока нет'))
                      else
                        ..._docs.map((d) => _DocumentCard(
                          doc: d,
                          onTap: () {
                            final code = d['template_code'] ?? '';
                            final docId = d['id'];
                            context.go('/fill/$code?fromDoc=$docId');
                          },
                          onDownload: () {
                            final fname = d['filename'] ?? '';
                            if (fname.isNotEmpty) {
                              _downloadFile(fname);
                            }
                          },
                        )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _downloadFile(String fname) {
    final base = Uri.base.origin;
    html.window.open('$base/api/v1/download/$fname', '_blank');
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _DocumentCard({required this.doc, required this.onTap, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final title = doc['template_title'] ?? doc['template_code'] ?? '';
    final date = _formatDate(doc['created_at'] ?? '');
    final status = doc['status'] ?? '';
    final timeMs = doc['generation_time_ms'] ?? 0;
    final hasFi = (doc['filename'] ?? '').isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                status == 'done' ? Icons.description : Icons.error_outline,
                color: status == 'done' ? AppColors.primary : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$date • ${(timeMs / 1000).toStringAsFixed(1)} сек',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
              if (hasFi)
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Скачать',
                  onPressed: onDownload,
                ),
              Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
