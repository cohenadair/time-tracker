import 'dart:async';

import 'package:mobile/model/activity.dart';
import 'package:mobile/model/session.dart';

/// Returns true if the stream should be notified immediately.
typedef StreamHandler<T> = bool Function(Stream<T>);

abstract class DataManageable {
  Future<bool> initialize();

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

  /// Returns `true` if the given session overlaps with another session in
  /// the same activity.
  Future<bool> isSessionOverlapping(Session session);

  /// Returns the current session for the given Activity ID, or `null` if
  /// the given Activity isn't running.
  Future<Session> getCurrentSession(String activityId);

  /// Case-insensitive compare of a given name to all other activity names.
  Future<bool> activityNameExists(String name);
}