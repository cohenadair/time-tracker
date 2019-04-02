import 'dart:async';

import 'package:date_range_picker/date_range_picker.dart' as DateRangePicker;
import 'package:flutter/material.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:mobile/utils/string_utils.dart';
import 'package:mobile/widgets/list_picker.dart';

/// A [ListPicker] wrapper widget for selecting a date range, such as the
/// "Last 7 days" or "This week" from a list.
class StatsDateRangePicker extends StatefulWidget {
  final DisplayDateRange initialValue;
  final OnListPickerChanged<DisplayDateRange> onDurationPicked;

  StatsDateRangePicker({
    @required this.initialValue,
    @required this.onDurationPicked
  }) : assert(initialValue != null),
       assert(onDurationPicked != null);

  @override
  _StatsDateRangePickerState createState() => _StatsDateRangePickerState();
}

class _StatsDateRangePickerState extends State<StatsDateRangePicker> {
  DisplayDateRange _customDateRange = DisplayDateRange.custom;

  @override
  Widget build(BuildContext context) {
    return ListPicker<DisplayDateRange>(
      initialValues: Set.of([widget.initialValue]),
      onChanged: (Set<DisplayDateRange> pickedDurations) {
        widget.onDurationPicked(pickedDurations.first);

        if (pickedDurations.first != _customDateRange) {
          // If anything other than the custom option is picked, reset the
          // custom text back to the default.
          setState(() {
            _customDateRange = DisplayDateRange.custom;
          });
        }
      },
      allItem: _buildItem(context, DisplayDateRange.allDates),
      items: [
        ListPickerItem.divider(),
        _buildItem(context, DisplayDateRange.today),
        _buildItem(context, DisplayDateRange.yesterday),
        ListPickerItem.divider(),
        _buildItem(context, DisplayDateRange.thisWeek),
        _buildItem(context, DisplayDateRange.thisMonth),
        _buildItem(context, DisplayDateRange.thisYear),
        ListPickerItem.divider(),
        _buildItem(context, DisplayDateRange.lastWeek),
        _buildItem(context, DisplayDateRange.lastMonth),
        _buildItem(context, DisplayDateRange.lastYear),
        ListPickerItem.divider(),
        _buildItem(context, DisplayDateRange.last7Days),
        _buildItem(context, DisplayDateRange.last14Days),
        _buildItem(context, DisplayDateRange.last30Days),
        _buildItem(context, DisplayDateRange.last60Days),
        _buildItem(context, DisplayDateRange.last12Months),
        ListPickerItem.divider(),
        ListPickerItem<DisplayDateRange>(
          popsListOnPicked: false,
          title: _customDateRange.getTitle(context),
          onTap: () => _onTapCustom(context),
          value: _customDateRange,
        ),
      ],
    );
  }

  ListPickerItem<DisplayDateRange> _buildItem(BuildContext context,
      DisplayDateRange duration)
  {
    return ListPickerItem<DisplayDateRange>(
      title: duration.getTitle(context),
      value: duration,
    );
  }

  Future<DisplayDateRange> _onTapCustom(BuildContext context) async {
    DateTime now = DateTime.now();
    DateRange customValue = _customDateRange.getValue(now);

    List<DateTime> pickedRange = await DateRangePicker.showDatePicker(
      context: context,
      initialFirstDate: customValue.startDate,
      initialLastDate: customValue.endDate,
      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
      lastDate: now,
    );

    DateTime endDate;
    if (pickedRange.first == pickedRange.last) {
      // If only the start date was picked, or the start and end time are equal,
      // set the end date to a range of 1 day.
      endDate = pickedRange.first.add(Duration(days: 1));
    }

    DateRange dateRange = DateRange(
      startDate: pickedRange.first,
      endDate: endDate ?? pickedRange.last,
    );

    // Reset StatsDateRange.custom properties to return the picked DateRange.
    setState(() {
      _customDateRange = DisplayDateRange.newCustom(
        getValue: (_) => dateRange,
        getTitle: (_) => formatDateRange(dateRange),
      );
    });

    return _customDateRange;
  }
}