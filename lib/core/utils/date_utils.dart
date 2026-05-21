import 'package:intl/intl.dart';

String localizedDateTime(DateTime dt, String localeName) {
  return DateFormat.yMd(localeName).add_Hm().format(dt.toLocal());
}
