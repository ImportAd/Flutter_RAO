import 'package:doc_generator/shared/widgets/header_nav_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/app_shell.dart';

/// Жёсткий маппинг выбора → код шаблона
String? resolveTemplateCode({
  required String company,
  required String form,
  String? docType,
  String? subType,
}) {
  final key = [company, form, docType ?? '', subType ?? '']
      .where((s) => s.isNotEmpty).join('|');

  const map = {
    // ФОРМАКС — ЛД
    'ФОРМАКС|ООО|ЛД|Постоянный': 'fm_ld_ooo',
    'ФОРМАКС|ООО|ЛД|Постоянный, сезонный': 'fm_ld_OOO_post',
    'ФОРМАКС|ООО|ЛД|Сезонный': 'fm_ld_OOO_s',
    'ФОРМАКС|ИП до 2017|ЛД|Постоянный': 'fm_ld_ip_do_2017',
    'ФОРМАКС|ИП до 2017|ЛД|Постоянный, сезонный': 'fm_ld_IP_do_2017_post',
    'ФОРМАКС|ИП до 2017|ЛД|Сезонный': 'fm_ld_ip_do_2017_s',
    'ФОРМАКС|ИП с 2017|ЛД|Постоянный': 'ds_ld_ip_s_2017',
    'ФОРМАКС|ИП с 2017|ЛД|Постоянный, сезонный': 'fm_ld_IP_s_2017_post',
    'ФОРМАКС|ИП с 2017|ЛД|Сезонный': 'fm_ld_ip_s_2017',
    // ФОРМАКС — ДС
    'ФОРМАКС|ООО|ДС': 'ds_ld_ooo',
    'ФОРМАКС|ИП до 2017|ДС': 'ds_ld_ip_do_2017',
    'ФОРМАКС|ИП с 2017|ДС': 'ds_ld_ip_s_pre2017',
    // ФОРМАКС — СОР
    'ФОРМАКС|ООО|СОР|С долгом': 'fm_sor_ooo_bd',
    'ФОРМАКС|ООО|СОР|Без долга': 'fm_sor_ooo_d',
    'ФОРМАКС|ИП до 2017|СОР|С долгом': 'fm_sor_ip_do_2017_bd',
    'ФОРМАКС|ИП до 2017|СОР|Без долга': 'fm_sor_ip_do_2017_d',
    'ФОРМАКС|ИП с 2017|СОР|С долгом': 'fm_sor_ip_s_2017_bd',
    'ФОРМАКС|ИП с 2017|СОР|Без долга': 'fm_sor_ip_s_2017_d',
    // РАО
    'РАО|ООО': 'rao_ld_ooo',
    'РАО|ИП до 2017': 'rao_ld_ip_do_2017',
    'РАО|ИП с 2017': 'rao_ld_ip_s_2017',
    // ВОИС
    'ВОИС|ООО': 'vois_ld_ooo',
    'ВОИС|ИП до 2017': 'vois_ld_ip_do_2017',
    'ВОИС|ИП с 2017': 'vois_ld_ip_s_2017',
  };
  return map[key];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _recentDocs = [];
  bool _loadingRecent = true;

  String? _company;
  String? _form;
  String? _docType;
  String? _subType;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final api = context.read<ApiClient>();
      _recentDocs = await api.getRecentDocuments();
    } catch (_) {}
    if (mounted) setState(() => _loadingRecent = false);
  }

  /// Нужен ли выбор типа документа (только для ФОРМАКС)
  bool get _needDocType => _company == 'ФОРМАКС';

  /// Нужен ли доп. параметр
  bool get _needSubType {
    if (_docType == 'ЛД') return true;   // тип договора
    if (_docType == 'СОР') return true;  // долг
    return false;
  }

  List<String> get _subTypeOptions {
    if (_docType == 'ЛД') return ['Постоянный', 'Постоянный, сезонный', 'Сезонный'];
    if (_docType == 'СОР') return ['С долгом', 'Без долга'];
    return [];
  }

  String get _subTypeLabel {
    if (_docType == 'ЛД') return 'Тип договора';
    if (_docType == 'СОР') return 'Долг';
    return '';
  }

  String? get _resolvedCode {
    if (_company == null || _form == null) return null;
    if (_needDocType && _docType == null) return null;
    if (_needSubType && _subType == null) return null;
    return resolveTemplateCode(
      company: _company!, form: _form!, docType: _docType, subType: _subType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Последние документы ===
                _buildRecentDocs(),
                const SizedBox(height: 48),

                // === Заполнить документ ===
                Text('Заполнить документ', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 28),

                // Компания
                Text('Компания', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _Segments(
                  options: const ['ФОРМАКС', 'РАО', 'ВОИС'],
                  selected: _company,
                  onSelected: (v) => setState(() {
                    _company = v; _form = null; _docType = null; _subType = null;
                  }),
                ),
                const SizedBox(height: 28),

                // Форма собственности
                if (_company != null) ...[
                  Text('Форма собственности', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _Segments(
                    options: const ['ООО', 'ИП до 2017', 'ИП с 2017'],
                    selected: _form,
                    onSelected: (v) => setState(() {
                      _form = v; _docType = null; _subType = null;
                    }),
                  ),
                  const SizedBox(height: 28),
                ],

                // Тип документа (только ФОРМАКС)
                if (_needDocType && _form != null) ...[
                  Text('Тип документа', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _Segments(
                    options: const [
                      'Лицензионный договор +\nАкт приёма-передачи',
                      'Доп. соглашения',
                      'СОР',
                    ],
                    values: const ['ЛД', 'ДС', 'СОР'],
                    selected: _docType,
                    onSelected: (v) => setState(() {
                      _docType = v; _subType = null;
                    }),
                  ),
                  const SizedBox(height: 28),
                ],

                // Доп. параметр
                if (_needDocType && _docType != null && _needSubType) ...[
                  Text(_subTypeLabel, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _Segments(
                    options: _subTypeOptions,
                    selected: _subType,
                    onSelected: (v) => setState(() => _subType = v),
                  ),
                  const SizedBox(height: 28),
                ],

                // Кнопка «Заполнить»
                const SizedBox(height: 8),
                if (_resolvedCode != null)
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/fill/$_resolvedCode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        foregroundColor: AppColors.textWhite,
                        overlayColor: AppColors.buttonActiveHover, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Заполнить', style: TextStyle(fontSize: 18,
                                      fontWeight: FontWeight.w400, 
                                      height: 22 / 18,
                                      ),
                                      ),
                    ),
                  )
                else if (_company != null)
                  Column(children: [
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: AppColors.buttonDisabled,
                          disabledForegroundColor: AppColors.buttonTextDisabled,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('Заполнить', style: TextStyle(fontSize: 18,                       
                                      fontWeight: FontWeight.w400, 
                                      height: 22 / 18,
                                      ),
                                      ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Недоступно пока не выбраны все поля',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentDocs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Последние заполненные документы', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 16),
           HeaderNavLink(
              label: 'Все документы',
              onTap: () => context.go('/documents'),
            ),
        ]),
        const SizedBox(height: 16),
        if (_loadingRecent)
          const Center(child: CircularProgressIndicator())
        else if (_recentDocs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Пока пусто, заполните документ и он отобразится здесь',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint, fontSize: 14),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < _recentDocs.length; i++) ...[
                    if (i > 0) VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
                    Expanded(
                      child: _RecentDocCell(
                        title: _recentDocs[i]['template_title'] ?? _recentDocs[i]['template_code'] ?? '',
                        onTap: () {
                          final d = _recentDocs[i];
                          context.go('/fill/${d['template_code']}?fromDoc=${d['id']}');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Ячейка последнего документа — при наведении подсвечивается полностью
class _RecentDocCell extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  const _RecentDocCell({required this.title, required this.onTap});
  @override
  State<_RecentDocCell> createState() => _RecentDocCellState();
}

class _RecentDocCellState extends State<_RecentDocCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// Сегментированный выбор — поддерживает разные labels и values
class _Segments extends StatelessWidget {
  final List<String> options;
  final List<String>? values; // если null — используем options как values
  final String? selected;
  final ValueChanged<String> onSelected;

  const _Segments({required this.options, this.values, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final vals = values ?? options;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.segmentBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(options.length, (i) {
            final isSelected = vals[i] == selected;
            final isFirst = i == 0;
            final isLast = i == options.length - 1;
            return Expanded(child: _SegBtn(
              label: options[i], isSelected: isSelected,
              isFirst: isFirst, isLast: isLast,
              onTap: () => onSelected(vals[i]),
            ));
          }),
        ),
      ),
    );
  }
}

class _SegBtn extends StatefulWidget {
  final String label; final bool isSelected, isFirst, isLast; final VoidCallback onTap;
  const _SegBtn({required this.label, required this.isSelected, required this.isFirst, required this.isLast, required this.onTap});
  @override State<_SegBtn> createState() => _SegBtnState();
}

class _SegBtnState extends State<_SegBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.segmentActiveBg
                : _h ? const Color(0xFFEEEEEE) : AppColors.segmentInactiveBg,
            border: Border(
              left: widget.isFirst ? BorderSide.none : BorderSide(color: AppColors.segmentBorder, width: 0.5),
            ),
            borderRadius: BorderRadius.horizontal(
              left: widget.isFirst ? const Radius.circular(3) : Radius.zero,
              right: widget.isLast ? const Radius.circular(3) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          alignment: Alignment.center,
          child: Text(widget.label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: widget.isSelected ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}