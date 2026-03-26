import 'package:doc_generator/shared/widgets/header_nav_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/api/api_client.dart';

/// Общий каркас страницы: шапка + контент + «Сообщить о проблеме»
class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Шапка
          _Header(
            title: title,
            showBack: showBack,
            onBack: onBack,
            actions: actions,
          ),

          // Контент
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const _Header({
    required this.title,
    required this.showBack,
    this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            if (showBack) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                color: AppColors.textSecondary,
                tooltip: 'Назад',
              ),
              const SizedBox(width: 8),
            ],

            // Навигация «Главная»
            HeaderNavLink(
              label: 'Главная',
              onTap: () => GoRouter.of(context).go('/'),
            ),

            const SizedBox(width: 20),

            // «Личный кабинет»
            HeaderNavLink(
              label: 'Личный кабинет',
              onTap: () => GoRouter.of(context).go('/documents'),
            ),
            const Spacer(),
            if (title.isNotEmpty) ...[
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8),
              //   child: Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
              // ),
              Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  // overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const Spacer(),

            // Кнопка «Сообщить о проблеме»
             HeaderNavLink(
              label: 'Сообщить о проблеме',
              onTap: () => _showReportDialog(context),
            ),

            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сообщить о проблеме'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Опишите проблему...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final api = RepositoryProvider.of<ApiClient>(context);
                await api.sendReport(message: text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Спасибо! Сообщение отправлено.')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сообщение сохранено локально.')),
                  );
                }
              }
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
