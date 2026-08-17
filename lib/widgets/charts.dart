import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/summaries.dart';

/// رسم بياني عمودي بسيط
class SimpleBarChart extends StatelessWidget {
  final List<ChartPoint> points;
  final Color color;
  final double height;
  final bool showValues;

  const SimpleBarChart({
    super.key,
    required this.points,
    this.color = AppTheme.cWages,
    this.height = 180,
    this.showValues = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty || points.every((p) => p.value == 0)) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('لا توجد بيانات كافية',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }

    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxV * 1.25,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[i].label,
                      style: TextStyle(
                          fontSize: 10.5, color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${points[group.x].label}\n${Fmt.num2(rod.toY)}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          barGroups: points.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color.withValues(alpha: 0.65), color],
                  ),
                ),
              ],
              showingTooltipIndicators: showValues ? [0] : const [],
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// رسم بياني دائري للتوزيع
class CategoryPieChart extends StatefulWidget {
  final List<ChartPoint> points;
  final String currency;
  final double height;

  const CategoryPieChart({
    super.key,
    required this.points,
    required this.currency,
    this.height = 210,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touched = -1;

  static const List<Color> _palette = [
    Color(0xFF6D4C2F),
    Color(0xFFC9A227),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFC62828),
    Color(0xFF00695C),
    Color(0xFF4527A0),
    Color(0xFFEF6C00),
    Color(0xFF546E7A),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pts = widget.points.where((p) => p.value > 0).toList();

    if (pts.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text('لا توجد مصروفات في هذه الفترة',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }

    final total = pts.fold<double>(0, (s, p) => s + p.value);

    return SizedBox(
      height: widget.height,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touched = response?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                sections: pts.asMap().entries.map((e) {
                  final isTouched = e.key == _touched;
                  final pct = (e.value.value / total) * 100;
                  return PieChartSectionData(
                    value: e.value.value,
                    color: _palette[e.key % _palette.length],
                    radius: isTouched ? 62 : 52,
                    title: pct < 6 ? '' : '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: pts.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _palette[i % _palette.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pts[i].label,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text(Fmt.num2(pts[i].value),
                              style: TextStyle(
                                  fontSize: 11, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسم خطي مزدوج للمقارنة الشهرية
class MonthlyComparisonChart extends StatelessWidget {
  final List<({DateTime month, double wages, double expenses})> data;
  final double height;

  const MonthlyComparisonChart({super.key, required this.data, this.height = 210});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('لا توجد بيانات',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }

    final maxV = data
        .expand((d) => [d.wages, d.expenses])
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxV == 0 ? 10 : maxV * 1.2,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          Fmt.arabicMonths[data[i].month.month - 1],
                          style: TextStyle(
                              fontSize: 10, color: scheme.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                _line(data.map((d) => d.wages).toList(), AppTheme.cWages),
                _line(data.map((d) => d.expenses).toList(), AppTheme.cExpenses),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(color: AppTheme.cWages, label: 'الأجور'),
            SizedBox(width: 18),
            _LegendDot(color: AppTheme.cExpenses, label: 'المصروفات'),
          ],
        ),
      ],
    );
  }

  LineChartBarData _line(List<double> values, Color color) => LineChartBarData(
        spots: values
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList(),
        isCurved: true,
        curveSmoothness: 0.28,
        color: color,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
            radius: 3.5,
            color: color,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.12),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      );
}

/// شريط أفقي لأكثر الموظفين إنتاجاً
class TopProducersList extends StatelessWidget {
  final List<ChartPoint> points;
  final String unitLabel;

  const TopProducersList({
    super.key,
    required this.points,
    this.unitLabel = 'قطعة',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text('لا توجد بيانات إنتاج',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }
    final maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: points.asMap().entries.map((e) {
        final ratio = maxV == 0 ? 0.0 : e.value.value / maxV;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('${e.key + 1}',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: scheme.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.value.label,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${Fmt.num2(e.value.value)} $unitLabel',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
