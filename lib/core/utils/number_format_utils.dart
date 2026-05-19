import 'package:intl/intl.dart';

String formatDecimal(
  double value,
  String localeName, {
  int minFractionDigits = 0,
  int maxFractionDigits = 2,
}) {
  final fmt = NumberFormat('#,##0.${'#' * maxFractionDigits}', localeName)
    ..minimumFractionDigits = minFractionDigits
    ..maximumFractionDigits = maxFractionDigits;
  return fmt.format(value);
}

String formatPercent(
  double value,
  String localeName, {
  int minFractionDigits = 1,
  int maxFractionDigits = 1,
}) {
  final fmt = NumberFormat.percentPattern(localeName)
    ..minimumFractionDigits = minFractionDigits
    ..maximumFractionDigits = maxFractionDigits;
  return fmt.format(value / 100);
}

String formatCompactNumber(int value, String localeName) {
  if (value >= 1000000) {
    final fmt = NumberFormat.compact(locale: localeName);
    return fmt.format(value);
  }
  if (value >= 1000) {
    final fmt = NumberFormat.compact(locale: localeName);
    return fmt.format(value);
  }
  final fmt = NumberFormat.decimalPattern(localeName);
  return fmt.format(value);
}

String formatHours(double totalSeconds, String localeName) {
  final hours = totalSeconds / 3600;
  return formatDecimal(hours, localeName, minFractionDigits: 1, maxFractionDigits: 1);
}

String formatCurrency(
  double value,
  String localeName, {
  int minFractionDigits = 2,
  int maxFractionDigits = 4,
  String? symbol,
}) {
  final fmt = NumberFormat.currency(
    locale: localeName,
    symbol: symbol,
    decimalDigits: maxFractionDigits,
  );
  if (minFractionDigits == maxFractionDigits) {
    return fmt.format(value);
  }
  final result = fmt.format(value);
  if (minFractionDigits < maxFractionDigits) {
    final separator = NumberFormat.decimalPattern(localeName)
        .format(0.1)
        .substring(1, 2);
    final parts = result.split(separator);
    if (parts.length == 2) {
      var fraction = parts[1];
      while (fraction.length > minFractionDigits &&
          fraction.endsWith('0')) {
        fraction = fraction.substring(0, fraction.length - 1);
      }
      return '${parts[0]}$separator$fraction';
    }
  }
  return result;
}
