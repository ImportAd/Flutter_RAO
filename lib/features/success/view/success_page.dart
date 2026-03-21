import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../shared/widgets/app_shell.dart';

class SuccessPage extends StatelessWidget {
  final String templateTitle;
  final String templateCode;

  const SuccessPage({
    super.key,
    required this.templateTitle,
    required this.templateCode,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Иконка успеха
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Заголовок
                Text(
                  'Договор $templateTitle\nуспешно сформирован',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Продолжить заполнение
                AppPrimaryButton(
                  label: 'Продолжить заполнение',
                  icon: Icons.edit_document,
                  onPressed: () => context.go('/fill/$templateCode'),
                ),
                const SizedBox(height: 12),

                // Выбрать другой договор
                AppSecondaryButton(
                  label: 'Выбрать другой договор',
                  icon: Icons.home_outlined,
                  onPressed: () => context.go('/'),
                ),

                const SizedBox(height: 32),

                // Разделитель
                const Divider(),
                const SizedBox(height: 16),

                // Выбор компании (как на макете)
                Text(
                  'Выберите компанию',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _CompanyChip(label: 'ФОРМАКС', onTap: () => context.go('/')),
                    _CompanyChip(label: 'РАО', onTap: () => context.go('/')),
                    _CompanyChip(label: 'ВОИС', onTap: () => context.go('/')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CompanyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.fieldBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}
