import 'package:doc_generator/shared/widgets/header_nav_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/api/api_client.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// Общий каркас страницы: шапка + контент + «Сообщить о проблеме»
class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final ValueChanged<String>? onTitleChanged;

  const AppShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBack = false,
    this.onBack,
     this.onTitleChanged,
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
            onTitleChanged: onTitleChanged,
          ),

          // Контент
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final ValueChanged<String>? onTitleChanged;

  const _Header({
    required this.title,
    required this.showBack,
    this.onBack,
    this.actions,
    this.onTitleChanged,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _editing = false;
  bool _iconHovered = false;
  late TextEditingController _ctrl;
  double? _titleTextWidth;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant _Header old) {
    super.didUpdateWidget(old);
    if (!_editing && old.title != widget.title) {
      _ctrl.text = widget.title;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    widget.onTitleChanged?.call(_ctrl.text);
    setState(() {
      _editing = false;
      _titleTextWidth = null;
    });
  }

  double _measureTextWidth(String text, TextStyle? style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.onTitleChanged != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            HeaderNavLink(
              label: 'Главная',
              onTap: () => GoRouter.of(context).go('/'),
            ),
            const SizedBox(width: 20),
            HeaderNavLink(
              label: 'Личный кабинет',
              onTap: () => GoRouter.of(context).go('/documents'),
            ),
            if (widget.showBack) ...[
              const SizedBox(width: 20),
              HeaderNavLink(
                label: 'Назад',
                onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ],
            const Spacer(),

            // ── Центр: title + иконка Edit ──
            if (widget.title.isNotEmpty) ...[
              if (_editing)
                SizedBox(
                  width: _titleTextWidth ?? 360,
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.title,
                      hintStyle: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textPrimary.withOpacity(0.4)),
                    ),
                    onSubmitted: (_) => _commit(),
                    onEditingComplete: _commit,
                  ),
                )
              else
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              if (editable) ...[
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _iconHovered = true),
                  onExit: (_) => setState(() => _iconHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      if (_editing) {
                        _commit();
                      } else {
                        setState(() {
                          _ctrl.text = widget.title;
                          _ctrl.selection = TextSelection(
                              baseOffset: 0, extentOffset: _ctrl.text.length);
                          _editing = true;
                          _titleTextWidth = _measureTextWidth(
                            widget.title,
                            Theme.of(context).textTheme.titleMedium,
                          );
                          _titleTextWidth = _titleTextWidth! + 12;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SvgPicture.asset(
                        _editing ? 'assets/icons/chek.svg' : 'assets/icons/edit.svg',
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          _iconHovered ? AppColors.primaryDark : AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            const Spacer(),

            HeaderNavLink(
              label: 'Сообщить о проблеме',
              onTap: () => _showReportDialog(context),
            ),
            if (widget.actions != null) ...widget.actions!,
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    // ← оставь прежнюю реализацию без изменений
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сообщить о проблеме'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Опишите проблему...'),
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