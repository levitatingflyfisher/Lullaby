import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../babies/domain/entities/baby.dart';
import '../../domain/entities/growth_record.dart';
import '../../domain/entities/who_percentile_data.dart';

class GrowthCurveChart extends StatefulWidget {
  const GrowthCurveChart({
    super.key,
    required this.records,
    required this.dateOfBirth,
    required this.gender,
  });

  final List<GrowthRecordEntity> records;
  final DateTime dateOfBirth;
  final Gender? gender;

  @override
  State<GrowthCurveChart> createState() => _GrowthCurveChartState();
}

class _GrowthCurveChartState extends State<GrowthCurveChart>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gender = widget.gender;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Growth Curves', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Weight'),
                Tab(text: 'Height'),
                Tab(text: 'Head'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              // WHO curves are sex-specific; without a known sex, prompt for it
              // rather than drawing misleading boys' bands (M8).
              child: gender == null
                  ? _buildNoSexHint(theme)
                  : _buildChart(_currentType, gender, theme),
            ),
          ],
        ),
      ),
    );
  }

  MeasurementType get _currentType => switch (_tabController.index) {
        0 => MeasurementType.weight,
        1 => MeasurementType.height,
        2 => MeasurementType.headCircumference,
        _ => MeasurementType.weight,
      };

  Widget _buildNoSexHint(ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Set the baby's sex in their profile to see WHO percentile curves.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _buildChart(
      MeasurementType type, Gender gender, ThemeData theme) {
    final calculator = const PercentileCalculator();
    final bands = calculator.getPercentileBands(gender, type);

    // Filter records that have the relevant measurement
    final dataPoints = <FlSpot>[];
    for (final r in widget.records) {
      final value = switch (type) {
        MeasurementType.weight => r.weightKg,
        MeasurementType.height => r.heightCm,
        MeasurementType.headCircumference => r.headCircumferenceCm,
      };
      if (value == null) continue;

      final ageMonths =
          r.measuredAt.difference(widget.dateOfBirth).inDays / 30.44;
      if (ageMonths >= 0 && ageMonths <= 24) {
        dataPoints.add(FlSpot(ageMonths, value));
      }
    }

    dataPoints.sort((a, b) => a.x.compareTo(b.x));

    final yLabel = switch (type) {
      MeasurementType.weight => 'kg',
      MeasurementType.height => 'cm',
      MeasurementType.headCircumference => 'cm',
    };

    // Calculate Y range from percentile bands
    final allValues = bands.expand((b) => b.values);
    final minY = allValues.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 1;

    final bandColors = [
      theme.colorScheme.primary.withValues(alpha: 0.05),
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.primary.withValues(alpha: 0.05),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24,
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 3,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}m',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}$yLabel',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        betweenBarsData: [
          for (int i = 0; i < 4; i++)
            BetweenBarsData(
              fromIndex: i,
              toIndex: i + 1,
              color: bandColors[i],
            ),
        ],
        lineBarsData: [
          // Percentile band lines
          for (final band in bands)
            LineChartBarData(
              spots: List.generate(
                25,
                (i) => FlSpot(i.toDouble(), band.values[i]),
              ),
              isCurved: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              barWidth: 1,
              dotData: const FlDotData(show: false),
            ),
          // Actual data points
          if (dataPoints.isNotEmpty)
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              preventCurveOverShooting: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
        ],
      ),
    );
  }
}
