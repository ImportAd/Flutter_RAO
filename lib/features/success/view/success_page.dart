import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/header_nav_link.dart';

class SuccessPage extends StatelessWidget {
  final String templateTitle, templateCode;
  final String? filename, aktFilename;

  const SuccessPage({super.key, required this.templateTitle, required this.templateCode,
      this.filename, this.aktFilename});

  bool get _hasAkt => aktFilename != null && aktFilename!.isNotEmpty;

  /// Скачивает ЛД и автоматически АКТ (если есть)
  Future<void> _downloadAll(BuildContext context) async {
    final api = context.read<ApiClient>();
    try {
      if (filename != null) {
        final bytes = await api.downloadFile(filename!);
        _saveBlobToFile(bytes, filename!);
      }
      // АКТ — автоматически вторым файлом
      if (aktFilename != null) {
        final aktBytes = await api.downloadFile(aktFilename!);
        await Future.delayed(const Duration(milliseconds: 500));
        _saveBlobToFile(aktBytes, aktFilename!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка скачивания: $e')));
      }
    }
  }

  void _saveBlobToFile(Uint8List bytes, String name) {
    final blob = html.Blob([bytes],
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute('download', name)..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(title: '', child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(children: [
          // Галочка
          Container(width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2)),
            child: const Icon(Icons.check, size: 36, color: AppColors.primary)),
          const SizedBox(height: 28),

          // Заголовок
          Text('Договор $templateTitle\nуспешно сформирован',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center),

          // Информация об АКТе (если есть)
          if (_hasAkt) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Акт приема-передачи | ЭДО заполнены',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Кнопка «Скачать файлы» + «На главную»
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _downloadAll(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    _hasAkt ? 'Скачать файлы' : 'Скачать файл',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              if (_hasAkt) ...[
                const SizedBox(width: 20),
                HeaderNavLink(
                  label: 'На главную',
                  onTap: () => context.go('/'),
                ),
              ],
            ],
          ),

          // Если нет АКТа — простая ссылка на главную
          if (!_hasAkt) ...[
            const SizedBox(height: 12),
            HeaderNavLink(
              label: 'На главную',
              onTap: () => context.go('/'),
            ),
          ],

          const SizedBox(height: 40),
          // Разделитель «или»
          Row(children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('или', style: Theme.of(context).textTheme.bodyMedium)),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 32),

          // Создать новый документ
          Text('Создать новый документ', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 28),

          Text('Компания', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _SegRow(options: const ['ФОРМАКС', 'РАО', 'ВОИС'], onTap: (_) => context.go('/')),
          const SizedBox(height: 24),

          Text('Форма собственности', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _SegRow(options: const ['ООО', 'ИП до 2017', 'ИП с 2017'], onTap: (_) => context.go('/')),
        ]),
      )),
    ));
  }
}

class _SegRow extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onTap;
  const _SegRow({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(4)),
      child: IntrinsicHeight(child: Row(
        children: options.map((o) => Expanded(child: InkWell(
          onTap: () => onTap(o),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(left: o == options.first ? BorderSide.none : BorderSide(color: AppColors.divider))),
            child: Text(o, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ))).toList(),
      )),
    );
  }
}