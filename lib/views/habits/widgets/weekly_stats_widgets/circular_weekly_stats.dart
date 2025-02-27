import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RadarWeeklyStatsWidget extends StatelessWidget {
  final String title;
  final WeeklyStatsValue stats;
  final double height;
  final Color baseColor;
  final Color textColor;
  final Color backgroundColor;

  const RadarWeeklyStatsWidget({
    super.key,
    required this.title,
    required this.stats,
    this.height = 200,
    this.baseColor = const Color(0xFF7166F9),
    this.textColor = const Color(0xFFF5F5F5),
    this.backgroundColor = const Color(0xFF2D2D2D),
  });

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
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: [
                  RadarDataSet(
                    fillColor: baseColor.withOpacity(0.2),
                    borderColor: baseColor,
                    entryRadius: 5,
                    dataEntries: stats.dailyStats.map((stat) {
                      return RadarEntry(
                        value: stat.value,
                      );
                    }).toList(),
                    borderWidth: 2,
                  ),
                ],
                ticksTextStyle: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 10,
                ),
                tickBorderData: BorderSide(
                  color: textColor.withOpacity(0.2),
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: textColor.withOpacity(0.2),
                  width: 1,
                ),
                titleTextStyle: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
                tickCount: 5,
                titlePositionPercentageOffset: 0.2,
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: '${stats.dailyStats[index].day}\n${stats.dailyStats[index].value.toStringAsFixed(1)}',
                    angle: angle,
                  );
                },
                borderData: FlBorderData(show: false),
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}