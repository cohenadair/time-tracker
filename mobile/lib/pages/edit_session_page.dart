import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/app_manager.dart';
import 'package:mobile/i18n/strings.dart';
import 'package:mobile/model/activity.dart';
import 'package:mobile/model/session.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:mobile/widgets/date_time_picker.dart';
import 'package:mobile/widgets/edit_page.dart';
import 'package:mobile/res/dimen.dart';
import 'package:mobile/utils/string_utils.dart';
import 'package:mobile/widgets/text.dart';

class EditSessionPage extends StatefulWidget {
  final AppManager _app;
  final Activity _activity;
  final Session _editingSession;

  EditSessionPage({
    @required AppManager app,
    @required Activity activity,
    Session editingSession
  }) : assert(app != null),
       assert(activity != null),
       _app = app,
       _activity = activity,
       _editingSession = editingSession;

  @override
  _EditSessionPageState createState() => _EditSessionPageState();
}

class _EditSessionPageState extends State<EditSessionPage> {
  final _formKey = GlobalKey<FormState>();

  AppManager get _app => widget._app;
  Activity get _activity => widget._activity;
  Session get _editingSession => widget._editingSession;
  bool get _isEditing => _editingSession != null;
  bool get _isEditingInProgress => _isEditing && _editingSession.inProgress;

  DateTime _startDate;
  TimeOfDay _startTime;
  DateTime _endDate;
  TimeOfDay _endTime;

  String _formValidationValue;

  @override
  void initState() {
    if (_isEditing) {
      _startDate = _editingSession.startDateTime;
      _endDate = _isEditingInProgress
          ? _startDate : _editingSession.endDateTime;
    } else {
      _startDate = DateTime.now();
      _endDate = _startDate;
    }

    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endTime = _isEditingInProgress
        ? _startTime : TimeOfDay.fromDateTime(_endDate);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return EditPage(
      title: _isEditing
          ? format(Strings.of(context).editSessionPageEditTitle,
              [_activity.name])
          : format(Strings.of(context).editSessionPageNewTitle,
              [_activity.name]),
      padding: insetsRowDefault,
      onSave: _onPressedSaveButton,
      onDelete: () => _app.dataManager.removeSession(_editingSession),
      deleteDescription: Strings.of(context).sessionListDeleteMessage,
      isEditingCallback: () => _isEditing,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ErrorText(
              _formValidationValue,
              padding: insetsVerticalSmall,
            ),
            DateTimePickerContainer(
              datePicker: DatePicker(
                label: Strings.of(context).editSessionPageStartDate,
                initialDate: _startDate,
                validator: _validateStartDate,
                onChange: (DateTime dateTime) {
                  _startDate = dateTime;
                },
              ),
              timePicker: TimePicker(
                label: Strings.of(context).editSessionPageStartTime,
                initialTime: _startTime,
                validator: _validateStartTime,
                onChange: (TimeOfDay time) {
                  _startTime = time;
                },
              ),
            ),
            Container(height: paddingDefault),
            DateTimePickerContainer(
              datePicker: DatePicker(
                label: Strings.of(context).editSessionPageEndDate,
                initialDate: _endDate,
                validator: _validateEndDate,
                enabled: !_isEditingInProgress,
                onChange: (DateTime dateTime) {
                  _endDate = dateTime;
                },
              ),
              timePicker: TimePicker(
                label: Strings.of(context).editSessionPageEndTime,
                initialTime: _endTime,
                validator: _validateEndTime,
                enabled: !_isEditingInProgress,
                onChange: (TimeOfDay time) {
                  _endTime = time;
                },
              ),
              helper: _isEditingInProgress
                  ? WarningText(Strings.of(context).editSessionPageInProgress)
                  : null,
            ),
            Container(height: paddingDefault),
          ],
        ),
      ),
    );
  }

  void _onPressedSaveButton() {
    _clearFormValidationText();

    if (!_formKey.currentState.validate()) {
      return;
    }

    SessionBuilder builder;
    if (_isEditing) {
      builder = SessionBuilder.fromSession(_editingSession);
    } else {
      builder = SessionBuilder(_activity.id);
    }

    Session session = (builder
        ..startTimestamp = combine(_startDate, _startTime)
            .millisecondsSinceEpoch
        ..endTimestamp = _isEditingInProgress
            ? null : combine(_endDate, _endTime).millisecondsSinceEpoch)
        .build;

    _app.dataManager.getOverlappingSession(session)
        .then((Session overlappingSession) {
          if (overlappingSession != null) {
            setState(() {
              _formValidationValue =
                  format(Strings.of(context).editSessionPageOverlap, [
                    DateFormat(monthDayFormat)
                        .format(overlappingSession.startDateTime)
                            + ", "
                            + formatTimeOfDay(context,
                                overlappingSession.startTimeOfDay)
                            + " - "
                            + formatTimeOfDay(context,
                                overlappingSession.endTimeOfDay)
                  ]
              );
            });
            return;
          }

          if (_isEditing) {
            _app.dataManager.updateSession(session);
          } else {
            _app.dataManager.addSession(session);
          }

          Navigator.pop(context);
        });
  }

  void _clearFormValidationText() {
    setState(() {
      _formValidationValue = null;
    });
  }

  String _validateStartDate(DateTime dateTime) {
    // Start time is always valid if the session is in progress.
    if (_isEditingInProgress) {
      return null;
    }

    // Don't compare times because they are selected and validated separately.
    if (isInFutureWithDayAccuracy(_startDate, _endDate)) {
      return Strings.of(context).editSessionPageInvalidStartDate;
    }

    return null;
  }

  String _validateEndDate(DateTime dateTime) {
    // Nothing required.
    return null;
  }

  String _validateStartTime(TimeOfDay time) {
    // Start time comes after end time.
    if (!_isEditingInProgress
        && isSameDate(_startDate, _endDate)
        && isLater(_startTime, _endTime))
    {
      return Strings.of(context).editSessionPageInvalidStartTime;
    }

    // Start time is in the future.
    if (isInFutureWithMinuteAccuracy(combine(_startDate, _endTime), DateTime.now())) {
      return Strings.of(context).editSessionPageFutureStartTime;
    }

    return null;
  }

  String _validateEndTime(TimeOfDay time) {
    // Don't validate end time for in progress sessions. The user can't
    // modify it anyway.
    if (_isEditingInProgress) {
      return null;
    }

    // Start and end times are equal.
    if (isSameDate(_startDate, _endDate) && _startTime == _endTime) {
      return Strings.of(context).editSessionPageInvalidEndTime;
    }

    // End time is in the future.
    if (isInFutureWithMinuteAccuracy(combine(_endDate, _endTime), DateTime.now())) {
      return Strings.of(context).editSessionPageFutureEndTime;
    }

    // The case of the end time coming before the start time is handled in
    // the start time validation.

    return null;
  }
}