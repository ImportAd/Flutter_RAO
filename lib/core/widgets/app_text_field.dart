import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Текстовое поле, соответствующее UI-kit:
/// - Лейбл сверху
/// - Hint/ошибка снизу
/// - Опциональная кнопка «Действие» справа
/// - Состояния: normal, focused, error, disabled
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final String? actionLabel;    // текст кнопки справа (как «Изменить»)
  final VoidCallback? onAction; // callback кнопки справа
  final int maxLines;
  final TextInputType? keyboardType;
  final String? initialValue;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.actionLabel,
    this.onAction,
    this.maxLines = 1,
    this.keyboardType,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Лейбл
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: hasError ? AppColors.error : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),

        // Поле ввода
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                initialValue: controller == null ? initialValue : null,
                onChanged: onChanged,
                enabled: enabled,
                readOnly: readOnly,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                decoration: InputDecoration(
                  hintText: hint ?? label,
                  errorText: null, // мы показываем ошибку сами ниже
                  filled: true,
                  fillColor: enabled
                      ? AppColors.fieldBackground
                      : AppColors.fieldDisabled,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.error : AppColors.fieldBorder,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: hasError
                          ? AppColors.error
                          : AppColors.fieldBorderFocused,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),

            // Кнопка «Действие» справа
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: enabled ? onAction : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    side: BorderSide(
                      color: hasError ? AppColors.error : AppColors.fieldBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        // Ошибка или hint снизу
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          )
        // else if (hint != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4, left: 4),
        //     child: Text(
        //       hint!,
        //       style: Theme.of(context).textTheme.bodySmall,
        //     ),
        //   ),
      ],
    );
  }
}

/// Двойное поле (две колонки), например «Серия» и «Номер»
class AppDoubleField extends StatelessWidget {
  final AppTextField left;
  final AppTextField right;

  const AppDoubleField({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}
