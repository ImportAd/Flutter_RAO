import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/app_shell.dart';

class SuccessPage extends StatelessWidget {
  final String templateTitle;
  final String templateCode;
  final String? filename;       // имя файла на сервере
  final String? aktFilename;    // имя АКТа (ФОРМАКС)
  final Uint8List? fileBytes;   // байты основного файла (если передали)

  const SuccessPage({
    super.key, required this.templateTitle, required this.templateCode,
    this.filename, this.aktFilename, this.fileBytes,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                // Галочка
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 28),

                // Заголовок
                Text(
                  'Договор $templateTitle\nуспешно сформирован',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Кнопка «Скачать файл»
                SizedBox(
                  width: 340, height: 48,
                  child: OutlinedButton(
                    onPressed: () => _download(context, filename, fileBytes),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Скачать файл', style: TextStyle(fontSize: 15)),
                  ),
                ),

                // Кнопка «Скачать акт» (ФОРМАКС)
                if (aktFilename != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 340, height: 48,
                    child: OutlinedButton(
                      onPressed: () => _downloadFromServer(context, aktFilename!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Скачать акт', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Разделитель «или»
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('или', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 32),

                // Создать новый документ
                Text('Создать новый документ', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 28),

                // Компания
                Text('Компания', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _CompanyRow(onTap: (company) => context.go('/')),

                const SizedBox(height: 24),

                // Форма собственности
                Text('Форма собственности', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _FormRow(onTap: (form) => context.go('/')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _download(BuildContext context, String? fname, Uint8List? bytes) {
    if (bytes != null) {
      _downloadBlob(bytes, fname ?? '$templateCode.docx');
    } else if (fname != null) {
      _downloadFromServer(context, fname);
    }
  }

  void _downloadBlob(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes],
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)..setAttribute('download', filename)..click();
    html.Url.revokeObjectUrl(url);
  }

  void _downloadFromServer(BuildContext context, String fname) {
    // Открываем URL скачивания
    final base = Uri.base.origin;
    html.window.open('$base/api/v1/download/$fname', '_blank');
  }
}

class _CompanyRow extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _CompanyRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(4)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final c in ['ФОРМАКС', 'РАО', 'ВОИС'])
              Expanded(
                child: InkWell(
                  onTap: () => onTap(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(left: c == 'ФОРМАКС' ? BorderSide.none : BorderSide(color: AppColors.divider)),
                    ),
                    child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _FormRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(4)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final f in ['ООО', 'ИП до 2017', 'ИП с 2017'])
              Expanded(
                child: InkWell(
                  onTap: () => onTap(f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(left: f == 'ООО' ? BorderSide.none : BorderSide(color: AppColors.divider)),
                    ),
                    child: Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
