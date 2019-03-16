import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mobile/model/activity.dart';
import 'package:mobile/model/session.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:mobile/utils/tuple.dart';
import 'package:quiver/iterables.dart';

/// A class that stores summarized data for an [Activity].
class SummarizedActivity {
  final Activity value;

  /// The [DateRange] for the summary. Set to `null` for "all dates".
  final DateRange dateRange;

  final List<Session> sessions;

  Session _cachedShortestSession;
  Session _cachedLongestSession;

  Duration _cachedTotalDuration;
  Duration _cachedDurationPerDay;
  Duration _cachedDurationPerWeek;
  Duration _cachedDurationPerMonth;

  int _cachedLongestStreak;

  SummarizedActivity({
    @required this.value,
    @required this.dateRange,
    this.sessions,
  }) : assert(value != null);

  int get numberOfSessions => sessions == null ? 0 : sessions.length;

  Session get shortestSession {
    if (_cachedShortestSession == null) {
      _cachedShortestSession = min(sessions);
    }
    return _cachedShortestSession;
  }

  Session get longestSession {
    if (_cachedLongestSession == null) {
      _cachedLongestSession = max(sessions);
    }
    return _cachedLongestSession;
  }

  Duration get averageDurationOverall => getAverage(numberOfSessions);

  Duration get totalDuration {
    if (_cachedTotalDuration == null) {
      _calculate();
    }
    return _cachedTotalDuration;
  }

  Duration get averageDurationPerDay {
    if (_cachedDurationPerDay == null) {
      _calculate();
    }
    return _cachedDurationPerDay;
  }

  Duration get averageDurationPerWeek {
    if (_cachedDurationPerWeek == null) {
      _calculate();
    }
    return _cachedDurationPerWeek;
  }

  Duration get averageDurationPerMonth {
    if (_cachedDurationPerMonth == null) {
      _calculate();
    }
    return _cachedDurationPerMonth;
  }

  int get longestStreak {
    if (_cachedLongestStreak == null) {
      _calculate();
    }
    return _cachedLongestStreak;
  }

  void _calculate() {
    if (sessions == null || sessions.isEmpty) {
      _cachedTotalDuration = Duration();
      _cachedDurationPerDay = Duration();
      _cachedDurationPerWeek = Duration();
      _cachedDurationPerMonth = Duration();
      _cachedLongestStreak = 0;
      return;
    }

    Set<DateTime> allDateTimes = SplayTreeSet();
    Session earliestSession = sessions.first;
    Session latestSession = sessions.first;

    int totalMs = 0;
    sessions.forEach((Session session) {
      if (session.startTimestamp < earliestSession.startTimestamp) {
        earliestSession = session;
      }

      if (session.endTimestamp > latestSession.endTimestamp) {
        latestSession = session;
      }

      totalMs += session.millisecondsDuration;
      allDateTimes.add(dateTimeToDayAccuracy(session.startDateTime));
      allDateTimes.add(dateTimeToDayAccuracy(session.endDateTime));
    });

    _cachedTotalDuration = Duration(milliseconds: totalMs);

    // If the date range is null, restrict the range to the earliest
    // and latest sessions.
    DateRange range = dateRange ?? DateRange(
      startDate: earliestSession.startDateTime,
      endDate: latestSession.endDateTime,
    );

    Duration difference = range.endDate.difference(range.startDate);
    int numberOfDays = difference.inDays + 1;

    _cachedDurationPerDay = getAverage(numberOfDays);
    _cachedDurationPerWeek =
        getAverage((numberOfDays / DateTime.daysPerWeek).floor() + 1);

    int numberOfMonths = 0;
    if (isSameYear(range.startDate, range.endDate)) {
      numberOfMonths = range.endDate.month - range.startDate.month + 1;
    } else {
      numberOfMonths = range.endDate.month +
          (DateTime.monthsPerYear - range.startDate.month + 1);
    }

    _cachedDurationPerMonth = getAverage(numberOfMonths);

    // Iterate all days, keeping track of the longest streak.
    int currentStreak = 1;
    _cachedLongestStreak = currentStreak;

    List<DateTime> dateTimeList = List.from(allDateTimes);
    DateTime last = dateTimeList.first;

    for (int i = 1; i < dateTimeList.length; i++) {
      DateTime current = dateTimeList[i];
      if (isSameYear(current, last)
          && isSameMonth(current, last)
          && current.day == last.day + 1)
      {
        currentStreak++;
      } else {
        currentStreak = 1;
      }

      if (_cachedLongestStreak == null
          || currentStreak > _cachedLongestStreak)
      {
        _cachedLongestStreak = currentStreak;
      }

      last = current;
    }
  }

  Duration getAverage(int divisor) {
    if (divisor <= 0) {
      return Duration();
    }

    return Duration(milliseconds: (totalDuration.inMilliseconds / divisor)
        .round());
  }

  @override
  String toString() {
    return "{activity=${value.name}; duration=$totalDuration; "
        + "numberOfSessions=$numberOfSessions}";
  }
}

/// A class that stores summarized data for multiple [Activity] objects,
/// including summary data across all of its activities.
class SummarizedActivityList {
  final List<SummarizedActivity> activities;

  Tuple<Activity, Session> _cachedLongestSession;
  Tuple<Activity, int> _cachedMostFrequentActivity;

  /// A [Tuple] of [Activity] and its longest [Session].
  Tuple<Activity, Session> get longestSession {
    if (_cachedLongestSession == null) {
      _calculate();
    }
    return _cachedLongestSession;
  }

  /// A [Tuple] of [Activity] and its number of sessions.
  Tuple<Activity, int> get mostFrequentActivity {
    if (_cachedMostFrequentActivity == null) {
      _calculate();
    }
    return _cachedMostFrequentActivity;
  }

  SummarizedActivityList(this.activities);

  void _calculate() {
    activities.forEach((SummarizedActivity activity) {
      if (_cachedMostFrequentActivity == null
          || activity.sessions.length > _cachedMostFrequentActivity.second)
      {
        _cachedMostFrequentActivity =
            Tuple(activity.value, activity.sessions.length);
      }

      activity.sessions.forEach((Session session) {
        if (_cachedLongestSession == null
            || session > _cachedLongestSession.second)
        {
          _cachedLongestSession = Tuple(activity.value, session);
        }
      });
    });
  }
}