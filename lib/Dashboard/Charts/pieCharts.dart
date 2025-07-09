import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../ShimmerEfect.dart';
import '../FirestoreService.dart';

class UserDistributionChart extends StatelessWidget {
  static const Color parentsColor = Color(0xFF5C6BC0); // Blue
  static const Color daycareColor = Color(0xFFEF5350); // Red
  static const Color doctorsColor = Color(0xFF26A69A);
  final FirestoreService _firestoreService = FirestoreService();

 // Teal
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: FutureBuilder<Map<String, int>>(
          future: _getUserCounts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerEffect(
                child: Column(
                  children: [
                    Container(width: 150, height: 20, color: Colors.white),
                    SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildLegendPlaceholder(),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading user distribution'));
            }

            if (!snapshot.hasData) {
              return Column(
                children: [
                  Text("User Distribution",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Center(child: Text('No user data available')),
                  ),
                  _buildLegendPlaceholder(),
                ],
              );
            }

            final counts = snapshot.data!;
            final totalUsers = counts['parents']! + counts['daycare']! + counts['doctors']!;
            final double parentsPercent = totalUsers > 0 ? (counts['parents']! / totalUsers * 100) : 0;
            final double daycarePercent = totalUsers > 0 ? (counts['daycare']! / totalUsers * 100) : 0;
            final double doctorsPercent = totalUsers > 0 ? (counts['doctors']! / totalUsers * 100) : 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("User Distribution",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text("Total Users: $totalUsers",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 8),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          value: parentsPercent,
                          color: parentsColor,
                          title: '${parentsPercent.toStringAsFixed(1)}%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: daycarePercent,
                          color: daycareColor,
                          title: '${daycarePercent.toStringAsFixed(1)}%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: doctorsPercent,
                          color: doctorsColor,
                          title: '${doctorsPercent.toStringAsFixed(1)}%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildLegend(
                  parents: counts['parents']!,
                  daycare: counts['daycare']!,
                  doctors: counts['doctors']!,
                  parentsPercent: parentsPercent,
                  daycarePercent: daycarePercent,
                  doctorsPercent: doctorsPercent,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, int>> _getUserCounts() async {
    final parentsCount = await _firestoreService.getActiveParentsCount();
    final daycareCount = await _firestoreService.getDaycareCentersCount();
    final doctorsCount = await _firestoreService.getActiveDoctorsCount();

    return {
      'parents': parentsCount,
      'daycare': daycareCount,
      'doctors': doctorsCount,
    };
  }

  Widget _buildLegend({
    required int parents,
    required int daycare,
    required int doctors,
    required double parentsPercent,
    required double daycarePercent,
    required double doctorsPercent,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Parents', parentsColor, parents, parentsPercent),
            _buildLegendItem('Daycare', daycareColor, daycare, daycarePercent),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Doctors', doctorsColor, doctors, doctorsPercent),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendPlaceholder() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Parents', parentsColor, 0, 0),
            _buildLegendItem('Daycare', daycareColor, 0, 0),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Doctors', doctorsColor, 0, 0),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count, double percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label (${count.toString()}, ${percent.toStringAsFixed(1)}%)',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class ReportAnalysisChart extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define colors for each category
  static const Color inappropriateColor = Color(0xFFFF3B30); // Red
  static const Color spamColor = Color(0xFFFF9500);         // Orange
  static const Color harassmentColor = Color(0xFF5856D6);   // Purple
  static const Color otherColor = Color(0xFFAEAEB2);        // Gray

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('reports')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerEffect(
                child: Column(
                  children: [
                    Container(width: 150, height: 20, color: Colors.white),
                    SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildLegendPlaceholder(),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading reports'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  Text("Report Analysis",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Center(child: Text('No pending reports')),
                  ),
                  _buildLegendPlaceholder(),
                ],
              );
            }

            final reports = snapshot.data!.docs;
            final reportCounts = {
              'Inappropriate content': 0,
              'Spam or misleading': 0,
              'Harassment or bullying': 0,
              'Other violation': 0,
            };

            for (final report in reports) {
              final data = report.data() as Map<String, dynamic>;
              final reason = data['reason'] as String? ?? 'Other violation';
              reportCounts[reason] = (reportCounts[reason] ?? 0) + 1;
            }

            final totalReports = reports.length;
            final inappropriatePercent = (reportCounts['Inappropriate content']! / totalReports * 100).round();
            final spamPercent = (reportCounts['Spam or misleading']! / totalReports * 100).round();
            final harassmentPercent = (reportCounts['Harassment or bullying']! / totalReports * 100).round();
            final otherPercent = (reportCounts['Other violation']! / totalReports * 100).round();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Report Analysis",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text("Total Pending Reports: $totalReports",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 8),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(
                          value: reportCounts['Inappropriate content']!.toDouble(),
                          color: inappropriateColor,
                          title: '$inappropriatePercent%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: reportCounts['Spam or misleading']!.toDouble(),
                          color: spamColor,
                          title: '$spamPercent%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: reportCounts['Harassment or bullying']!.toDouble(),
                          color: harassmentColor,
                          title: '$harassmentPercent%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: reportCounts['Other violation']!.toDouble(),
                          color: otherColor,
                          title: '$otherPercent%',
                          titlePositionPercentageOffset: 0.55,
                          radius: 60,
                          titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildLegend(
                  inappropriate: reportCounts['Inappropriate content']!,
                  spam: reportCounts['Spam or misleading']!,
                  harassment: reportCounts['Harassment or bullying']!,
                  other: reportCounts['Other violation']!,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend({
    required int inappropriate,
    required int spam,
    required int harassment,
    required int other,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Inappropriate', inappropriateColor, inappropriate),
            _buildLegendItem('Spam', spamColor, spam),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Harassment', harassmentColor, harassment),
            _buildLegendItem('Other', otherColor, other),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendPlaceholder() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Inappropriate', inappropriateColor, 0),
            _buildLegendItem('Spam', spamColor, 0),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Harassment', harassmentColor, 0),
            _buildLegendItem('Other', otherColor, 0),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
