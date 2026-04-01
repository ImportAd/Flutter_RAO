String normalizeMoneyEditable(String input) {
  var sanitized = input
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '')
      .replaceAll(RegExp(r'[^\d,.]'), '')
      .replaceAll('.', ',');

  if (sanitized.isEmpty) return '';

  final commaIndex = sanitized.indexOf(',');
  final hasComma = commaIndex >= 0;

  String intPart;
  String decPart = '';

  if (hasComma) {
    intPart = sanitized.substring(0, commaIndex).replaceAll(',', '');
    decPart = sanitized.substring(commaIndex + 1).replaceAll(',', '');
    if (decPart.length > 2) {
      decPart = decPart.substring(0, 2);
    }
  } else {
    intPart = sanitized.replaceAll(',', '');
  }

  if (intPart.length > 1) {
    intPart = intPart.replaceFirst(RegExp(r'^0+'), '');
    if (intPart.isEmpty) {
      intPart = '0';
    }
  }

  if (intPart.isEmpty && (hasComma || decPart.isNotEmpty)) {
    intPart = '0';
  }

  if (intPart.isEmpty && decPart.isEmpty && !hasComma) {
    return '';
  }

  return hasComma ? '$intPart,$decPart' : intPart;
}

String moneyToEditable(String input) {
  return normalizeMoneyEditable(input);
}

String moneyToRaw(String input) {
  final editable = normalizeMoneyEditable(input);
  if (editable.isEmpty) return '';
  return editable.replaceAll(',', '.');
}

double? parseMoney(String input) {
  final raw = moneyToRaw(input);
  if (raw.isEmpty) return null;
  return double.tryParse(raw);
}

String moneyToDisplay(String input) {
  final raw = moneyToRaw(input);
  if (raw.isEmpty) return '';

  final value = double.tryParse(raw);
  if (value == null) {
    return moneyToEditable(input);
  }

  int rub = value.truncate();
  int kop = ((value - rub) * 100).round();
  if (kop == 100) {
    rub += 1;
    kop = 0;
  }

  final rubSource = rub.toString();
  final rubBuffer = StringBuffer();
  for (int i = 0; i < rubSource.length; i++) {
    if (i > 0 && (rubSource.length - i) % 3 == 0) {
      rubBuffer.write(' ');
    }
    rubBuffer.write(rubSource[i]);
  }

  final hadFraction = moneyToEditable(input).contains(',');
  if (hadFraction) {
    return '${rubBuffer.toString()},${kop.toString().padLeft(2, '0')}';
  }

  return rubBuffer.toString();
}
