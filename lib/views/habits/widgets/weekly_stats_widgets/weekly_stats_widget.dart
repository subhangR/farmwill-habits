// weekly_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// weekly_stats_value.dart
class WeeklyStatsValue {
  final List<DayStats> dailyStats;

  WeeklyStatsValue({required this.dailyStats});

  double get maxValue => dailyStats.fold(
    0.0,
        (prev, curr) => curr.value > prev ? curr.value : prev,
  );
}

class DayStats {
  final String day;
  final double value;

  DayStats({required this.day, required this.value});
}
class WeeklyStatsWidget extends StatelessWidget {
  final String title;
  final WeeklyStatsValue stats;
  final double height;
  final Color barColor;
  final Color textColor;
  final Color backgroundColor;

  const WeeklyStatsWidget({
    Key? key,
    required this.title,
    required this.stats,
    this.height = 200,
    this.barColor = const Color(0xFF7166F9),
    this.textColor = const Color(0xFFF5F5F5),
    this.backgroundColor = const Color(0xFF2D2D2D),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: stats.maxValue + (stats.maxValue * 0.2), // Add 20% padding for value labels
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black54,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (
                        BarChartGroupData group,
                        int groupIndex,
                        BarChartRodData rod,
                        int rodIndex,
                        ) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(1),
                        TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        // Show values above bars
                        final index = value.toInt();
                        if (index >= 0 && index < stats.dailyStats.length) {
                          return Text(
                            stats.dailyStats[index].value.toStringAsFixed(1),
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            stats.dailyStats[value.toInt()].day,
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barGroups: stats.dailyStats.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: barColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            barColor,
                            barColor.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}