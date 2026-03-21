/// Модели данных, соответствующие API бэкенда

// ──────────── Templates Tree ────────────

class TemplatesTree {
  final List<CategoryGroup> categories;
  TemplatesTree({required this.categories});

  factory TemplatesTree.fromJson(Map<String, dynamic> json) {
    return TemplatesTree(
      categories: (json['categories'] as List)
          .map((c) => CategoryGroup.fromJson(c))
          .toList(),
    );
  }
}

class CategoryGroup {
  final String name;
  final List<SubcategoryGroup> subcategories;
  CategoryGroup({required this.name, required this.subcategories});

  factory CategoryGroup.fromJson(Map<String, dynamic> json) {
    return CategoryGroup(
      name: json['name'] ?? '',
      subcategories: (json['subcategories'] as List)
          .map((s) => SubcategoryGroup.fromJson(s))
          .toList(),
    );
  }
}

class SubcategoryGroup {
  final String name;
  final List<TemplateListItem> templates;
  SubcategoryGroup({required this.name, required this.templates});

  factory SubcategoryGroup.fromJson(Map<String, dynamic> json) {
    return SubcategoryGroup(
      name: json['name'] ?? '',
      templates: (json['templates'] as List)
          .map((t) => TemplateListItem.fromJson(t))
          .toList(),
    );
  }
}

class TemplateListItem {
  final String code;
  final String name;
  final String menuTitle;
  final String description;
  TemplateListItem({
    required this.code,
    required this.name,
    required this.menuTitle,
    required this.description,
  });

  factory TemplateListItem.fromJson(Map<String, dynamic> json) {
    return TemplateListItem(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      menuTitle: json['menu_title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// ──────────── Template Detail ────────────

class TemplateDetail {
  final String code;
  final String name;
  final String menuTitle;
  final String description;
  final String category;
  final String subcategory;
  final List<SectionModel> sections;
  final List<String> computedFields;
  final List<String> skipFields;

  TemplateDetail({
    required this.code,
    required this.name,
    required this.menuTitle,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.sections,
    required this.computedFields,
    required this.skipFields,
  });

  /// Считаем шаблон «маленьким» если ≤ 1 секция без таблицы
  bool get isCompact {
    final hasTables = sections.any((s) => s.table != null);
    final totalFields = sections.fold<int>(0, (sum, s) => sum + s.fields.length);
    return !hasTables && totalFields <= 15;
  }

  /// Секции с полями (для табов/форм)
  List<SectionModel> get fieldSections =>
      sections.where((s) => s.fields.isNotEmpty).toList();

  /// Секции с таблицами
  List<SectionModel> get tableSections =>
      sections.where((s) => s.table != null).toList();

  factory TemplateDetail.fromJson(Map<String, dynamic> json) {
    return TemplateDetail(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      menuTitle: json['menu_title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      sections: (json['sections'] as List)
          .map((s) => SectionModel.fromJson(s))
          .toList(),
      computedFields: List<String>.from(json['computed_fields'] ?? []),
      skipFields: List<String>.from(json['skip_fields'] ?? []),
    );
  }
}

class SectionModel {
  final String id;
  final String title;
  final List<FieldModel> fields;
  final TableDefModel? table;

  SectionModel({
    required this.id,
    required this.title,
    required this.fields,
    this.table,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      fields: (json['fields'] as List?)
              ?.map((f) => FieldModel.fromJson(f))
              .toList() ??
          [],
      table: json['table'] != null
          ? TableDefModel.fromJson(json['table'])
          : null,
    );
  }
}

class FieldModel {
  final String name;
  final String label;
  final String type; // text, date, number, months_select, split_multi_select
  final bool required;
  final String? defaultValue;
  final String? hint;
  final String? dateHandler;
  final String? textHandler;
  final List<String>? leftOptions;
  final List<String>? rightOptions;
  final List<String> fieldDefaults;

  FieldModel({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    this.defaultValue,
    this.hint,
    this.dateHandler,
    this.textHandler,
    this.leftOptions,
    this.rightOptions,
    required this.fieldDefaults,
  });

  /// Это поле с кнопкой-быстрого выбора? (dov_num, dov_date, etc.)
  bool get hasDefaults => fieldDefaults.isNotEmpty;

  /// Это поле с выбором М.П./Б.П.?
  bool get isStampField => name == 'ip_stamp_abbr';

  /// Это поле с предопределёнными вариантами без ручного ввода?
  bool get isChoiceOnly => hasDefaults && (leftOptions != null || rightOptions != null);

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? true,
      defaultValue: json['default'],
      hint: json['hint'],
      dateHandler: json['date_handler'],
      textHandler: json['text_handler'],
      leftOptions: json['left_options'] != null
          ? List<String>.from(json['left_options'])
          : null,
      rightOptions: json['right_options'] != null
          ? List<String>.from(json['right_options'])
          : null,
      fieldDefaults: List<String>.from(json['field_defaults'] ?? []),
    );
  }
}

class TableDefModel {
  final int minRows;
  final int maxRows;
  final bool allowDynamicRows;
  final List<TableColumnModel> columns;

  TableDefModel({
    required this.minRows,
    required this.maxRows,
    required this.allowDynamicRows,
    required this.columns,
  });

  factory TableDefModel.fromJson(Map<String, dynamic> json) {
    return TableDefModel(
      minRows: json['min_rows'] ?? 1,
      maxRows: json['max_rows'] ?? 50,
      allowDynamicRows: json['allow_dynamic_rows'] ?? true,
      columns: (json['columns'] as List?)
              ?.map((c) => TableColumnModel.fromJson(c))
              .toList() ??
          [],
    );
  }
}

class TableColumnModel {
  final String name;
  final String label;
  final String type;
  final String? hint;
  final String? normalizer;

  TableColumnModel({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.normalizer,
  });

  factory TableColumnModel.fromJson(Map<String, dynamic> json) {
    return TableColumnModel(
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      hint: json['hint'],
      normalizer: json['normalizer'],
    );
  }
}
