import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BubbleWeeklyStatsWidget extends StatefulWidget {
  final String title;
  final WeeklyStatsValue stats;
  final double height;
  final Color baseColor;
  final Color textColor;
  final Color backgroundColor;

  const BubbleWeeklyStatsWidget({
    super.key,
    required this.title,
    required this.stats,
    this.height = 200,
    this.baseColor = const Color(0xFF7166F9),
    this.textColor = const Color(0xFFF5F5F5),
    this.backgroundColor = const Color(0xFF2D2D2D),
  });

  @override
  State<BubbleWeeklyStatsWidget> createState() => _BubbleWeeklyStatsWidgetState();
}

class _BubbleWeeklyStatsWidgetState extends State<BubbleWeeklyStatsWidget> {
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
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: _createSpots(),
                minX: -0.5,
                maxX: 6.5,
                minY: 0,
                maxY: widget.stats.maxValue + (widget.stats.maxValue * 0.2),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: widget.stats.maxValue / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: widget.textColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: widget.textColor.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        );
                      },
                      interval: widget.stats.maxValue / 4,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= widget.stats.dailyStats.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            widget.stats.dailyStats[value.toInt()].day,
                            style: TextStyle(
                              color: widget.textColor.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: true,
                  touchTooltipData: ScatterTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (ScatterSpot touchedSpot) {
                      return ScatterTooltipItem(
                        widget.stats.dailyStats[touchedSpot.x.toInt()].value.toStringAsFixed(1),
                        textStyle: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ScatterSpot> _createSpots() {
    return widget.stats.dailyStats.asMap().entries.map((entry) {
      final double normalizedValue = entry.value.value / widget.stats.maxValue;
      final spotSize = 16 + (normalizedValue * 24); // Size varies between 16 and 40

      return ScatterSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();
  }
}