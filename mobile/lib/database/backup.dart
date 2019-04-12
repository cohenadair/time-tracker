import 'dart:async';
import 'dart:convert';

import 'package:mobile/app_manager.dart';
import 'package:mobile/model/activity.dart';
import 'package:mobile/model/session.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:quiver/strings.dart';
import 'package:quiver/time.dart';

enum ImportResult {
  success,
  errorNullInput,
  errorClearingDatabase,
  errorDecodingJson,
  errorActivitiesNotList,
  errorActivityNotMap,
  errorActivityInvalid,
  errorSessionsNotList,
  errorSessionNotMap,
  errorSessionInvalid,
}

const _keyActivities = "activities";
const _keySessions = "sessions";

const _keyPreferences = "preferences";
const _keyPreferencesLargestDurationUnit = "largest_duration_unit";
const _keyPreferencesHomeDateRange = "home_date_range";

/// Returns a JSON [String] representation of the given [AppManager] database,
/// or `null` if there was an error.
Future<String> export(AppManager app, {
  Clock clock = const Clock(),
}) async {
  Map<String, dynamic> jsonMap = Map();

  // Activities.
  List<Activity> activityList = await app.dataManager.activities;
  jsonMap[_keyActivities] = activityList.map((activity) {
    if (activity.isRunning) {
      // End any running activities. This ensures that when the database
      // is imported, there isn't a potentially long session in progress.
      activity = (ActivityBuilder.fromActivity(activity)
        ..currentSessionId = null)
          .build;
    }

    return activity.toMap();
  }).toList();

  // Sessions.
  List<Session> sessionList = await app.dataManager.sessions;
  jsonMap[_keySessions] = sessionList.map((session) {
    if (session.inProgress) {
      // End any running sessions. This ensures that when the database
      // is imported, there isn't a potentially long session in progress.
      session = (SessionBuilder.fromSession(session)..clock = clock)
          .endNow()
          .build;
    }
    return session.toMap();
  }).toList();

  // Preferences.
  jsonMap[_keyPreferences] = Map<String, dynamic>();
  jsonMap[_keyPreferences][_keyPreferencesLargestDurationUnit] =
      app.preferencesManager.largestDurationUnit.index;
  jsonMap[_keyPreferences][_keyPreferencesHomeDateRange] =
      app.preferencesManager.homeDateRange.id;

  return jsonEncode(jsonMap);
}

/// Returns an [ImportResult] from parsing the given JSON and replacing the
/// current database contents.
///
/// This method will first clear the database, then insert the data from the
/// given JSON.
///
/// Note that this method includes aggressive error handling because the import
/// file is just a JSON file that can be modified by anyone. We can't
/// guarantee that the user didn't modify the file after it was exported, or
/// that they even selected the correct JSON file.
Future<ImportResult> import(AppManager app, {String json}) async {
  if (isEmpty(json)) {
    return ImportResult.errorNullInput;
  }

  Map<String, dynamic> jsonMap;
  try {
    jsonMap = jsonDecode(json);
  } on FormatException {
    return ImportResult.errorDecodingJson;
  }

  // Get activities to add.
  if (jsonMap[_keyActivities] is! List) {
    return ImportResult.errorActivitiesNotList;
  }

  List<dynamic> activityListJson = jsonMap[_keyActivities];
  List<Activity> activitiesToAdd = [];
  for (var activityJson in activityListJson) {
    if (activityJson is! Map<String, dynamic>) {
      return ImportResult.errorActivityNotMap;
    }

    Activity activity = Activity.fromMap(activityJson);

    // ID and name can't be empty, and the activity can't be running.
    if (isEmpty(activity.id) || isEmpty(activity.name) || activity.isRunning) {
      return ImportResult.errorActivityInvalid;
    } else {
      activitiesToAdd.add(activity);
    }
  }

  // Get sessions to add.
  if (jsonMap[_keySessions] is! List) {
    return ImportResult.errorSessionsNotList;
  }

  List<dynamic> sessionListJson = jsonMap[_keySessions];
  List<Session> sessionsToAdd = [];
  for (var sessionJson in sessionListJson) {
    if (sessionJson is! Map<String, dynamic>) {
      return ImportResult.errorSessionNotMap;
    }

    Session session = Session.fromMap(sessionJson);

    // ID and session ID can't be empty, and the session must be complete.
    if (isEmpty(session.id) || isEmpty(session.activityId)
        || session.startTimestamp == null || session.endTimestamp == null)
    {
      return ImportResult.errorSessionInvalid;
    } else {
      sessionsToAdd.add(session);
    }
  }

  // Clear the database. This is done _after_ checking the input data for
  // errors so the current database isn't cleared if there was an error.
  if (!(await app.dataManager.clearDatabase())) {
    return ImportResult.errorClearingDatabase;
  }

  // Update the database.
  await app.dataManager.addActivities(activitiesToAdd, notify: false);

  // Notify listeners after everything has been added.
  await app.dataManager.addSessions(sessionsToAdd, notify: true);

  // Update preferences. We have less strict error handling here since we can
  // just default to the current preferences.
  if (jsonMap[_keyPreferences] is Map<String, dynamic>) {
    Map<String, dynamic> preferences = jsonMap[_keyPreferences];

    if (preferences[_keyPreferencesHomeDateRange] is String) {
      String dateRangeId = preferences[_keyPreferencesHomeDateRange];
      if (!isEmpty(dateRangeId)) {
        app.preferencesManager.setHomeDateRange(
            DisplayDateRange.of(dateRangeId));
      }
    }

    if (preferences[_keyPreferencesLargestDurationUnit] is int) {
      int durationUnitIndex = preferences[_keyPreferencesLargestDurationUnit];

      if (durationUnitIndex >= 0
          && durationUnitIndex < DurationUnit.values.length)
      {
        app.preferencesManager.setLargestDurationUnit(
            DurationUnit.values[durationUnitIndex]);
      }
    }
  }

  return ImportResult.success;
}