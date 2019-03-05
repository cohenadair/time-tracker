import 'dart:async';

import 'package:mobile/model/activity.dart';
import 'package:mobile/model/session.dart';
import 'package:mobile/model/summarized_activity.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Returns true if the stream should be notified immediately.
typedef StreamHandler<T> = bool Function(Stream<T>);

abstract class DataManageable {
  void initialize(Database database);

  /// Call this method to be notified when activities are added,
  /// removed, or modified.
  ///
  /// If `notifyNow` returns true, the stream will be notified immediately,
  /// for example, when using a `StreamBuilder` widget.
  void getActivitiesUpdateStream(StreamHandler<List<Activity>> notifyNow);

  /// Call this method to be notified when sessions are added, removed,
  /// or modified from the given Activity ID.
  ///
  /// If `notifyNow` returns true, the stream will be notified immediately,
  /// for example, when using a `StreamBuilder` widget.
  void getSessionsUpdatedStream(String activityId,
      StreamHandler<List<Session>> notifyNow);

  void addActivity(Activity activity);
  void updateActivity(Activity activity);
  void removeActivity(String activityId);

  /// Creates and starts a new Session for the given Activity.
  void startSession(Activity activity);
  void endSession(Activity activity);
  void addSession(Session session);
  void updateSession(Session session);
  void removeSession(Session session);
  Future<List<Session>> getSessions(String activityId);
  Future<List<Session>> getRecentSessions(String activityId, int limit);
  Future<int> getSessionCount(String activityId);

  /// Returns the [Session] the given session overlaps with, if one exists;
  /// `null` otherwise.
  Future<Session> getOverlappingSession(Session session);

  /// Returns the current session for the given Activity ID, or `null` if
  /// the given Activity isn't running.
  Future<Session> getCurrentSession(String activityId);

  /// Case-insensitive compare of a given name to all other activity names.
  Future<bool> activityNameExists(String name);

  Future<SummarizedActivity> getSummarizedActivity(DateRange dateRange);
  Future<List<SummarizedActivity>> getSummarizedActivities(DateRange dateRange);
}