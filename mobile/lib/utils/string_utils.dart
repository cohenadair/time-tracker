import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:mobile/widgets/text.dart';

/// A trimmed, case-insensitive string comparison.
bool isEqualTrimmedLowercase(String s1, String s2) {
  return s1.trim().toLowerCase() == s2.trim().toLowerCase();
}

/// Supported formats:
///   - %s
/// For each argument, toString() is called to replace %s.
String format(String s, List<dynamic> args) {
  int index = 0;
  return s.replaceAllMapped(RegExp(r'%s'), (Match match) {
    return args[index++].toString();
  });
}

/// Returns a formatted [String] for a time of day. The format depends on a
/// combination of the current locale and the user's system time format setting.
///
/// Example:
///   21:35, or
///   9:35 PM
String formatTimeOfDay(BuildContext context, TimeOfDay time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat
  );
}

/// Returns a formatted [DateRange] to be displayed to the user.
///
/// Example:
///   Dec. 8, 2018 - Dec. 29, 2018
String formatDateRange(DateRange dateRange) {
  return DateFormat(monthDayYearFormat).format(dateRange.startDate)
      + " - "
      + DateFormat(monthDayYearFormat).format(dateRange.endDate);
}