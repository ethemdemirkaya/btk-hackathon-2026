import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currency = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final _currencyCompact = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  static final _dateShort = DateFormat('dd MMM yyyy', 'tr_TR');
  static final _dateLong = DateFormat('dd MMMM yyyy', 'tr_TR');
  static final _dateMonth = DateFormat('MMMM yyyy', 'tr_TR');
  static final _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
  static final _time = DateFormat('HH:mm', 'tr_TR');

  static String currency(double amount) => _currency.format(amount);

  static String currencyCompact(double amount) =>
      _currencyCompact.format(amount);

  /// Tam sayıysa ondalık göstermez (₺290), değilse 2 basamak gösterir (₺72,99)
  static String currencyAuto(double amount) {
    if (amount == amount.truncateToDouble()) {
      return _currencyCompact.format(amount);
    }
    return _currency.format(amount);
  }

  static String currencyAbs(double amount) => _currency.format(amount.abs());

  static String dateShort(DateTime date) => _dateShort.format(date);
  static String dateLong(DateTime date) => _dateLong.format(date);
  static String dateMonth(DateTime date) => _dateMonth.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
  static String time(DateTime date) => _time.format(date);

  static String dateFromIso(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return dateLong(dt.toLocal());
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    return dateLong(date);
  }

  static String percentage(double value, {int decimals = 1}) =>
      '%${value.toStringAsFixed(decimals)}';

  static String pctWithSign(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${percentage(value)}';
  }
}
