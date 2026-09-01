import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../babies/domain/entities/baby.dart';
import '../../domain/entities/growth_record.dart';
import '../../domain/entities/who_percentile_data.dart';
import '../../../../core/widgets/scaled_tab.dart';

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
              tabs: [
                scaledTab(context, 'Weight'),
                scaledTab(context, 'Height'),
                scaledTab(context, 'Head'),
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
            'Set the baby’s sex in their profile to see WHO percentile curves.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _buildChart(
      MeasurementType type, Gender gender, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _buildScaledChart(context, constraints, type, gender, theme),
    );
  }

  /// Axis steps chosen from the measured label size, so no two labels touch
  /// at any text scale (audit rank 11: "2kg" printed over "1kg" at 1.3).
  Widget _buildScaledChart(BuildContext context, BoxConstraints constraints,
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

    final unit = switch (type) {
      MeasurementType.weight => 'kg',
      MeasurementType.height => 'cm',
      MeasurementType.headCircumference => 'cm',
    };

    final labelStyle = theme.textTheme.bodySmall;
    final scaler = MediaQuery.textScalerOf(context);
    Size measure(String text) => (TextPainter(
          text: TextSpan(text: text, style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout())
            .size;

    // The unit is printed once, in the caption, not on every label.
    final caption = Text(
      '$unit, by age in months',
      style: labelStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
    final captionHeight = measure('kg').height + 4;

    // Y range from the percentile bands, snapped to a step whose labels
    // leave at least half a label of air between them.
    final allValues = bands.expand((b) => b.values);
    final lowest = allValues.reduce((a, b) => a < b ? a : b);
    final highest = allValues.reduce((a, b) => a > b ? a : b);
    final labelHeight = measure('0').height;
    final bottomReserved = labelHeight + 8;
    final plotHeight = constraints.maxHeight -
        captionHeight -
        labelHeight / 2 -
        bottomReserved;
    final maxLabels = (plotHeight / (labelHeight * 1.5)).floor().clamp(2, 12);
    final yStep = _niceStep((highest - lowest) / (maxLabels - 1));
    final minY = (lowest / yStep).floor() * yStep;
    final maxY = (highest / yStep).ceil() * yStep;

    final leftReserved = measure(maxY.toStringAsFixed(0)).width + 8;

    // Month labels every 3, 6, 12 or 24 months, whichever first gives each
    // label half its width again in clear space.
    final monthLabelWidth = measure('24').width;
    final plotWidth = constraints.maxWidth - leftReserved;
    final monthStep = [3.0, 6.0, 12.0].firstWhere(
      (step) => plotWidth / (24 / step) >= monthLabelWidth * 1.5,
      orElse: () => 24.0,
    );

    final bandColors = [
      theme.colorScheme.primary.withValues(alpha: 0.05),
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.primary.withValues(alpha: 0.05),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        caption,
        // Half a label of headroom: the top value label is centred on the
        // plot's top edge and would otherwise reach into the caption.
        SizedBox(height: 4 + labelHeight / 2),
        Expanded(
          child: LineChart(
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
                    reservedSize: bottomReserved,
                    interval: monthStep,
                    getTitlesWidget: (value, meta) {
                      // Birth needs no label, and a "0" here would collide with
                      // the lowest value label in the corner.
                      if (value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${value.toInt()}', style: labelStyle),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: leftReserved,
                    interval: yStep,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toStringAsFixed(0), style: labelStyle);
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
          ),
        ),
      ],
    );
  }

  /// The smallest of 1, 2, 5, 10, 20, 50… that is at least [raw].
  static double _niceStep(double raw) {
    var magnitude = 1.0;
    while (magnitude * 10 <= raw) {
      magnitude *= 10;
    }
    for (final m in [1.0, 2.0, 5.0, 10.0]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10 * magnitude;
  }
}
