import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../domain/entities/daily_summary.dart';

class FeedingTrendChart extends StatelessWidget {
  const FeedingTrendChart({super.key, required this.summaries});

  final List<DailySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summaries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data')),
      );
    }

    final maxY = summaries
        .fold<int>(0, (max, s) => s.feedingCount > max ? s.feedingCount : max)
        .toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feedings per Day',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: (maxY + 2).ceilToDouble(),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _labelInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= summaries.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.MMMd()
                                  .format(summaries[index].date),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        summaries.length,
                        (i) => FlSpot(
                            i.toDouble(), summaries[i].feedingCount.toDouble()),
                      ),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColorSchemes.feedColor,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: summaries.length <= 14,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColorSchemes.feedColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _labelInterval {
    if (summaries.length <= 7) return 1;
    if (summaries.length <= 14) return 2;
    return 5;
  }
}
