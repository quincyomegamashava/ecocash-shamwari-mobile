import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/shamwari_theme.dart';

class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.days});

  final List<SpendDay> days;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (days.isEmpty) return const SizedBox(height: 140);
    final maxY =
        days.map((day) => day.amountCents).reduce((a, b) => a > b ? a : b) /
        100;
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: (maxY <= 0 ? 1 : maxY) * 1.3,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[index].label,
                      style: TextStyle(
                        color: context.inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: days[i].amountCents / 100,
                    width: 16,
                    borderRadius: BorderRadius.circular(20),
                    color: days[i].peak
                        ? (palette.highContrast
                              ? palette.orange
                              : (palette.lightGlass
                                    ? palette.forest
                                    : Colors.white))
                        : (palette.lightGlass
                              ? palette.forest.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.28)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class WeekWave extends StatelessWidget {
  const WeekWave({super.key, required this.days});

  final List<SpendDay> days;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (days.isEmpty) return const SizedBox(height: 180);
    final peak = days.indexWhere((day) => day.peak);
    final marker = peak < 0 ? days.length - 1 : peak;
    final maxY = days
        .map((day) => day.amountCents)
        .reduce((a, b) => a > b ? a : b);
    final line = palette.highContrast
        ? palette.orange
        : (palette.lightGlass ? palette.forest : Colors.white);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY <= 0 ? 1 : maxY) * 1.35 / 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: marker.toDouble(),
                color: line.withValues(alpha: 0.85),
                strokeWidth: 1.6,
              ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      days[index].label,
                      style: TextStyle(
                        color: palette.onCardMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < days.length; i++)
                  FlSpot(i.toDouble(), days[i].amountCents / 100),
              ],
              isCurved: true,
              color: line,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, bar) => spot.x == marker,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    line.withValues(alpha: 0.35),
                    line.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PulseLine extends StatelessWidget {
  const PulseLine({super.key, required this.daily});

  final List<PulseDaily> daily;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (daily.isEmpty) return const SizedBox(height: 180);
    final spotsTotal = [
      for (var i = 0; i < daily.length; i++)
        FlSpot(i.toDouble(), daily[i].total.toDouble()),
    ];
    final spotsNeg = [
      for (var i = 0; i < daily.length; i++)
        FlSpot(i.toDouble(), daily[i].negative.toDouble()),
    ];
    final maxY = daily
        .map((day) => day.total)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: (maxY <= 0 ? 1 : maxY) * 1.25,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: palette.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: palette.faint, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (daily.length / 4).clamp(1, 6).toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= daily.length) {
                    return const SizedBox.shrink();
                  }
                  final date = daily[index].date;
                  final label = date.length >= 10 ? date.substring(5) : date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(color: context.inkMuted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: spotsTotal.isEmpty
                    ? 0
                    : spotsTotal
                          .reduce((a, b) => a.y >= b.y ? a : b)
                          .x,
                color: palette.lightGlass ? palette.forest : Colors.white,
                strokeWidth: 1.4,
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spotsTotal,
              isCurved: true,
              color: palette.lightGlass ? palette.forest : palette.teal,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: palette.teal.withValues(alpha: 0.12),
              ),
            ),
            LineChartBarData(
              spots: spotsNeg,
              isCurved: true,
              color: palette.orange,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeBars extends StatelessWidget {
  const ThemeBars({super.key, required this.themes});

  final List<PulseTheme> themes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (themes.isEmpty) return const SizedBox(height: 180);
    final maxY = themes
        .map((theme) => theme.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: (maxY <= 0 ? 1 : maxY) * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= themes.length) {
                    return const SizedBox.shrink();
                  }
                  final label = themes[index].label.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: context.inkMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < themes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: themes[i].count.toDouble(),
                    width: 14,
                    borderRadius: BorderRadius.circular(5),
                    color: i == 0
                        ? (palette.lightGlass ? palette.forest : Colors.white)
                        : palette.teal.withValues(alpha: 0.45),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class RegionBars extends StatelessWidget {
  const RegionBars({super.key, required this.regions});

  final List<PulseRegion> regions;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (regions.isEmpty) return const SizedBox(height: 180);
    final maxY = regions
        .map((region) => region.volume)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: (maxY <= 0 ? 1 : maxY) * 1.25,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= regions.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      regions[index].region,
                      style: TextStyle(
                        color: context.inkMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < regions.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 3,
                barRods: [
                  BarChartRodData(
                    toY: regions[i].negative.toDouble(),
                    width: 7,
                    color: palette.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  BarChartRodData(
                    toY: regions[i].neutral.toDouble(),
                    width: 7,
                    color: palette.teal,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  BarChartRodData(
                    toY: regions[i].positive.toDouble(),
                    width: 7,
                    color: palette.ok,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class RingGauge extends StatelessWidget {
  const RingGauge({
    super.key,
    required this.progress,
    required this.center,
    required this.caption,
    this.color,
  });

  final double progress;
  final String center;
  final String caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ring = color ?? palette.teal;
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0, 1),
          color: ring,
          track: palette.border,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: context.ink,
                ),
              ),
              Text(
                caption,
                style: TextStyle(color: context.inkMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(8),
      -1.5708,
      6.2832,
      false,
      paint..color = track,
    );
    canvas.drawArc(
      rect.deflate(8),
      -1.5708,
      6.2832 * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
