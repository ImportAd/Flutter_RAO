/// Число прописью (русский язык).
/// Портировано из word_renderer.py бота.

String intToWordsRu(int n, {String gender = 'm'}) {
  if (n == 0) return 'ноль';

  String sign = '';
  if (n < 0) { sign = 'минус '; n = n.abs(); }

  final triads = <int>[];
  int temp = n;
  while (temp > 0) { triads.add(temp % 1000); temp ~/= 1000; }

  final words = <String>[];

  for (int idx = triads.length - 1; idx >= 0; idx--) {
    final triad = triads[idx];
    if (triad == 0) continue;

    final g = idx > 0 ? _groups[idx].gender : gender;
    final part = _triadToWords(triad, g);
    if (part.isEmpty) continue;

    words.addAll(part);

    if (idx > 0 && idx < _groups.length) {
      words.add(_pluralRu(triad, _groups[idx].one, _groups[idx].twoFour, _groups[idx].five));
    }
  }

  return sign + words.where((w) => w.isNotEmpty).join(' ');
}

String moneyToWordsRu(int rub, int kop, {bool capitalize = true}) {
  var out = intToWordsRu(rub, gender: 'm').trim();
  if (capitalize && out.isNotEmpty) {
    out = out[0].toUpperCase() + out.substring(1);
  }
  return out;
}

// ──── Internal ────

const _unitsM = ['ноль','один','два','три','четыре','пять','шесть','семь','восемь','девять'];
const _unitsF = ['ноль','одна','две','три','четыре','пять','шесть','семь','восемь','девять'];
const _teens = ['десять','одиннадцать','двенадцать','тринадцать','четырнадцать',
    'пятнадцать','шестнадцать','семнадцать','восемнадцать','девятнадцать'];
const _tens = ['','','двадцать','тридцать','сорок','пятьдесят','шестьдесят','семьдесят','восемьдесят','девяносто'];
const _hundreds = ['','сто','двести','триста','четыреста','пятьсот','шестьсот','семьсот','восемьсот','девятьсот'];

class _Group {
  final String one, twoFour, five, gender;
  const _Group(this.one, this.twoFour, this.five, this.gender);
}

const _groups = [
  _Group('', '', '', 'm'),          // units
  _Group('тысяча', 'тысячи', 'тысяч', 'f'),
  _Group('миллион', 'миллиона', 'миллионов', 'm'),
  _Group('миллиард', 'миллиарда', 'миллиардов', 'm'),
  _Group('триллион', 'триллиона', 'триллионов', 'm'),
];

List<String> _triadToWords(int triad, String gender) {
  if (triad == 0) return [];

  final words = <String>[];
  final h = triad ~/ 100;
  final t = (triad ~/ 10) % 10;
  final u = triad % 10;

  if (h > 0) words.add(_hundreds[h]);

  if (t == 1) {
    words.add(_teens[u]);
    return words;
  }

  if (t > 0) words.add(_tens[t]);

  if (u > 0) {
    final units = gender == 'f' ? _unitsF : _unitsM;
    words.add(units[u]);
  }

  return words;
}

String _pluralRu(int n, String one, String twoFour, String five) {
  n = n.abs();
  final n10 = n % 10;
  final n100 = n % 100;
  if (n100 >= 11 && n100 <= 14) return five;
  if (n10 == 1) return one;
  if (n10 >= 2 && n10 <= 4) return twoFour;
  return five;
}
