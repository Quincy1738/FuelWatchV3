import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  final double totalRevenue;
  final List<double> last7DaysRevenue;
  final List<double> last30DaysRevenue;
  final List<double> last12MonthsRevenue;

  const AnalyticsPage({
    super.key,
    required this.totalRevenue,
    required this.last7DaysRevenue,
    required this.last30DaysRevenue,
    required this.last12MonthsRevenue,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPeriod = 'Week'; // 'Week', 'Month', 'Year'

  List<double> get _selectedRevenue {
    switch (_selectedPeriod) {
      case 'Month':
        return widget.last30DaysRevenue;
      case 'Year':
        return widget.last12MonthsRevenue;
      case 'Week':
      default:
        return widget.last7DaysRevenue;
    }
  }

  List<String> get _selectedLabels {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Month':
      // Label only every 6th day as "Week 1", "Week 2", etc.
        return List.generate(30, (i) {
          if (i % 6 == 0) {
            return 'Week ${(i ~/ 6) + 1}';
          }
          return '';
        });
      case 'Year':
        return [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
      case 'Week':
      default:
      // Show last 7 days with day name and date, e.g., Mon 01
        return List.generate(7, (i) {
          DateTime date = now.subtract(Duration(days: 6 - i));
          return DateFormat('EEE dd').format(date);
        });
    }
  }

  String formatCurrency(double value) {
    final absValue = value.abs();

    if (absValue >= 1e6) {
      return '₱${(value / 1e6).toStringAsFixed(1)}M';
    } else if (absValue >= 1e3) {
      return '₱${(value / 1e3).toStringAsFixed(1)}K';
    } else {
      final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
      return formatter.format(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final revenue = _selectedRevenue;
    final labels = _selectedLabels;
    final maxRevenue = revenue.isNotEmpty ? revenue.reduce((a, b) => a > b ? a : b) : 0.0;
    final verticalInterval = maxRevenue / 4 > 0 ? maxRevenue / 4 : 1.0;

    // Define primary gradient for accents
    final Gradient primaryGradient = LinearGradient(
      colors: [Colors.blue.shade600, Colors.blue.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF), // Soft light blue background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Analytics ($_selectedPeriod)",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.blue.shade700),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Total Revenue Card with neumorphic style and gradient icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-8, -8),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gradient chart icon
                  ShaderMask(
                    shaderCallback: (bounds) => primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: const Icon(Icons.show_chart, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Total Revenue Today",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "₱${widget.totalRevenue.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1556D6),
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Period Selector with pill-shaped buttons + shadow
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Week', 'Month', 'Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: isSelected ? primaryGradient : null,
                      color: isSelected ? null : Colors.white,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.blue.shade300.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ]
                          : [],
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),

            // Chart title with subtle styling
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Revenue Trend (Last $_selectedPeriod)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Line Chart Container with shadow and rounded corners
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxRevenue * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: verticalInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < labels.length) {
                              final label = labels[index];
                              if (label.isEmpty) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 56,
                          interval: verticalInterval,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              formatCurrency(value),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          revenue.length,
                              (index) => FlSpot(index.toDouble(), revenue[index]),
                        ),
                        isCurved: true,
                        barWidth: 5,
                        color: Colors.blue.shade700,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeColor: Colors.blue.shade700,
                              strokeWidth: 3,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.shade700.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
