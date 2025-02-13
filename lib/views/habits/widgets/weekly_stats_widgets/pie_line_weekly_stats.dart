import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


class PieLineWeeklyStats extends StatefulWidget {
  final String title;
  final WeeklyStatsValue stats;
  final double height;
  final Color baseColor;
  final Color textColor;
  final Color backgroundColor;

  const PieLineWeeklyStats({
    Key? key,
    required this.title,
    required this.stats,
    this.height = 200,
    this.baseColor = const Color(0xFF7166F9),
    this.textColor = const Color(0xFFF5F5F5),
    this.backgroundColor = const Color(0xFF2D2D2D),
  }) : super(key: key);

  @override
  State<PieLineWeeklyStats> createState() => _PieLineWeeklyStatsState();
}
class _PieLineWeeklyStatsState extends State<PieLineWeeklyStats> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        startDegreeOffset: 270,
                        sectionsSpace: 2, // Reduced space between sections
                        centerSpaceRadius: widget.height * 0.12, // Slightly smaller center space
                        sections: showingSections(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.stats.dailyStats.asMap().entries.map((entry) {
                      final isTouched = touchedIndex == entry.key;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '${entry.value.day}: ${entry.value.value.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: isTouched ? widget.baseColor : widget.textColor.withOpacity(0.7),
                            fontSize: isTouched ? 13 : 11,
                            fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    double total = widget.stats.dailyStats.fold(0, (sum, item) => sum + item.value);

    return widget.stats.dailyStats.asMap().entries.map((entry) {
      final isTouched = touchedIndex == entry.key;
      final double fontSize = isTouched ? 16 : 12; // Smaller font sizes
      final double radius = isTouched ? widget.height * 0.2 : widget.height * 0.15; // Smaller radii
      final double value = entry.value.value;

      final color = widget.baseColor.withOpacity(0.5 + (value / widget.stats.maxValue) * 0.5);

      return PieChartSectionData(
        color: color,
        value: value,
        title: entry.value.day,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: widget.textColor,
        ),
        badgeWidget: isTouched ? _Badge(
          entry.value.value.toStringAsFixed(1),
          color: color,
          textColor: widget.textColor,
        ) : null,
        badgePositionPercentageOffset: .9, // Moved badges closer
      );
    }).toList();
  }
}

class _Badge extends StatelessWidget {
  final String value;
  final Color color;
  final Color textColor;

  const _Badge(
      this.value,
      {
        required this.color,
        required this.textColor,
      }
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}