import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

import '../widgets/charts_tab.dart';
import '../widgets/events_tab.dart';
import '../../../../core/widgets/scaled_tab.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The title keeps the bar to itself: a Calendar action beside it cut
        // "Timeline" to "Time…" at 320dp and large text. Calendar lives at
        // the top of Events, the day-by-day view it belongs with.
        title: const Text('Timeline'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            scaledTab(context, 'Charts'),
            scaledTab(context, 'Events'),
          ],
        ),
      ),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: TabBarView(
          controller: _tabController,
          children: const [
            ChartsTab(),
            EventsTab(),
          ],
        ),
      ),
    );
  }
}
