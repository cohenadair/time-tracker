import 'package:flutter/material.dart';
import 'package:mobile/app_manager.dart';
import 'package:mobile/model/summarized_activity.dart';
import 'package:mobile/utils/date_time_utils.dart';
import 'package:mobile/widgets/activity_summary.dart';
import 'package:mobile/widgets/page.dart';

class StatsActivitySummaryPage extends StatelessWidget {
  final AppManager app;
  final SummarizedActivity activity;
  final scrollController = ScrollController();

  StatsActivitySummaryPage({
    @required this.app,
    @required this.activity
  }) : assert(app != null),
       assert(activity != null);

  @override
  Widget build(BuildContext context) {
    return Page(
      appBarStyle: PageAppBarStyle(
        title: activity.value.name,
        subtitle: activity.displayDateRange == null
            ? DisplayDateRange.allDates.getTitle(context)
            : activity.displayDateRange.getTitle(context),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: ActivitySummary(
          app: app,
          activity: activity,
          scrollController: scrollController,
        ),
      ),
    );
  }
}