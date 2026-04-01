import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Основная кнопка действия (заполнить, сформировать)
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expanded;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.buttonDisabled,
        disabledForegroundColor: AppColors.buttonTextDisabled,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Вторичная кнопка (отмена, назад)
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.fieldBorder),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Кнопка-чип выбора (М.П. / Б.П., окончания -ий/-его)
/// ≤2 опции: горизонтальная строка (50% каждая)
/// >2 опций: вертикальный столбик, каждая на всю ширину
/// Серые по умолчанию (#D3D3D3), бирюзовые при выборе (#01909B)
/// Текст: чёрный когда не выбрано, белый когда выбрано
class AppChoiceChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (options.length <= 2) {
      return _buildHorizontal();
    }
    return _buildVertical();
  }

  Widget _buildHorizontal() {
    return Row(
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final option = entry.value;
        final isSelected = option == selected;
        final isFirst = idx == 0;
        final isLast = idx == options.length - 1;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF01909B)
                    : const Color(0xFFD3D3D3),
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(6) : Radius.zero,
                  right: isLast ? const Radius.circular(6) : Radius.zero,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                option,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.asMap().entries.map((entry) {
        final idx = entry.key;
        final option = entry.value;
        final isSelected = option == selected;
        final isFirst = idx == 0;
        final isLast = idx == options.length - 1;

        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF01909B)
                  : const Color(0xFFD3D3D3),
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(6) : Radius.zero,
                bottom: isLast ? const Radius.circular(6) : Radius.zero,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              option,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF000000),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}