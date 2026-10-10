import 'package:intl/intl.dart';

String formatDecimal(
  double value,
  String localeName, {
  int minFractionDigits = 0,
  int maxFractionDigits = 2,
}) {
  final pattern = maxFractionDigits == 0
      ? '#,##0'
      : '#,##0.${'#' * maxFractionDigits}';
  final fmt = NumberFormat(pattern, localeName)
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
    final separatorIndex = result.indexOf(separator);
    if (separatorIndex >= 0) {
      // Strip trailing zeros only from the digit run immediately after the
      // decimal separator, stopping at the first non-digit character. This
      // keeps currency suffixes intact for locales where the currency name or
      // symbol follows the number (e.g. de/es/fr/it: "1,5000 EUR").
      var fractionEnd = separatorIndex + separator.length;
      while (fractionEnd < result.length &&
          result[fractionEnd].compareTo('0') >= 0 &&
          result[fractionEnd].compareTo('9') <= 0) {
        fractionEnd++;
      }
      var fraction = result.substring(separatorIndex + separator.length, fractionEnd);
      while (fraction.length > minFractionDigits && fraction.endsWith('0')) {
        fraction = fraction.substring(0, fraction.length - 1);
      }
      return '${result.substring(0, separatorIndex + separator.length)}$fraction${result.substring(fractionEnd)}';
    }
  }
  return result;
}
