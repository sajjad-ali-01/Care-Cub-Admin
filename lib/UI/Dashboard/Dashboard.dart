import 'package:carecubadmin/UI/ActiveDoctors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../FirestoreService.dart';
import '../ShimmerEfect.dart';
import '../pandingDoctors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//
// class CareCubAdminApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         fontFamily: 'Roboto',
//       ),
//       home: AdminDashboard(),
//     );
//   }
// }


class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Row(
        children: [
          CareCubSidebar(),
          Expanded(
            child: Column(
              children: [
                CareCubAppBar(),
                Expanded(
                  child: DashboardGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CareCubSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Color(0xFF2A3A4E),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Image.asset('assets/images/CareCubLogo.png', width: 70),
          ),
          Divider(color: Colors.white54),
          Expanded(
            child: ListView(
              children: [
                SidebarButton(icon: Icons.dashboard, label: "Dashboard"),
                SidebarButton(icon: Icons.people, label: "User Management"),
                SidebarButton(icon: Icons.child_care, label: "Baby Profiles"),
                SidebarButton(icon: Icons.local_hospital, label: "Daycare Centers"),
                SidebarButton(icon: Icons.assignment_turned_in, label: "Approvals"),
                SidebarButton(icon: Icons.settings, label: "System Settings"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const SidebarButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(label,
          style: TextStyle(color: Colors.white, fontSize: 14)),
      onTap: () {},
    );
  }
}

class CareCubAppBar extends StatefulWidget {
  @override
  _CareCubAppBarState createState() => _CareCubAppBarState();
}

class _CareCubAppBarState extends State<CareCubAppBar> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.menu, color: Colors.blueGrey),
              SizedBox(width: 20),
              Text("Care Cub Admin Panel",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A3A4E))),
            ],
          ),
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click, // Change cursor to hand pointer
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.cyan.shade300,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month_sharp, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "${_selectedDate.toLocal()}".split(' ')[0],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              _NotificationBadge(),
              SizedBox(width: 20),
              CircleAvatar(
                backgroundImage: AssetImage('assets/images/image.webp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: Colors.blueGrey, size: 28),
          onPressed: () {},
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: BoxConstraints(minWidth: 14, minHeight: 14),
            child: Text('3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center),
          ),
        )
      ],
    );
  }
}

class DashboardGrid extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 15, 10, 2),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _UserDistributionChart(),
          _MetricCard(
            title: "Active Parents",
            futureCount: _firestoreService.getActiveParentsCount(),
            icon: Icons.family_restroom,
            color: Color(0xFF5C6BC0),
            onTap: () => UnverifiedDoctorsScreen(), // FIXED
          ),
          _MetricCard(
            title: "Active Doctors",
            futureCount: _firestoreService.getActiveDoctorsCount(),
            icon: Icons.medical_services,
            color: Color(0xFF26A69A),
            onTap: () => ActiveDoctors(), // FIXED
          ),
          _MetricCard(
            title: "Daycare Centers",
            futureCount: _firestoreService.getDaycareCentersCount(),
            icon: Icons.business,
            color: Color(0xFFEF5350),
            onTap: () => UnverifiedDoctorsScreen(), // FIXED

          ),
          _CompletedBookingsChart(),
          _MetricCard(
            title: "Pending Doctor Approvals",
            futureCount: _firestoreService.getPendingDoctorsCount(),
            icon: Icons.person_add_disabled,
            color: Color(0xFFAB47BC),
            onTap: () => UnverifiedDoctorsScreen(), // FIXED
          ),
          // _MetricCard(
          //   title: "Community Reports",
          //   value: "89", // Replace with dynamic data if available
          //   icon: Icons.report,
          //   color: Color(0xFFFFA726),
          // ),
          // _MetricCard(
          //   title: "Pending Daycare Approvals",
          //   value: "8", // Replace with dynamic data if available
          //   icon: Icons.business_center,
          //   color: Color(0xFFEC407A),
          // ),
          _UserActivityTimeline(),
        ],
      ),
    );
  }
}

class _UserDistributionChart extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: FutureBuilder<Map<String, double>>(
          future: _firestoreService.getUserDistributionPercentages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerEffect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer effect for the title
                    Container(
                      width: 150,
                      height: 20,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    // Shimmer effect for the pie chart area
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
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return Center(child: Text('No data available'));
            }

            final percentages = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: percentages['parents'] ?? 0,
                          color: Color(0xFF5C6BC0),
                          title: 'Parents\n${percentages['parents']?.toStringAsFixed(1)}%',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: percentages['daycare'] ?? 0,
                          color: Color(0xFFEF5350),
                          title: 'Daycare\n${percentages['daycare']?.toStringAsFixed(1)}%',
                          radius: 40,
                        ),
                        PieChartSectionData(
                          value: percentages['doctors'] ?? 0,
                          color: Color(0xFF26A69A),
                          title: 'Dr.\n${percentages['doctors']?.toStringAsFixed(1)}%',
                          radius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
class _CompletedBookingsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Completed Bookings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          ['Doctors', 'Daycare'][value.toInt()],
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 75,
                          color: Color(0xFF5C6BC0),
                          width: 20,
                        )
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 45,
                          color: Color(0xFF26A69A),
                          width: 20,
                        )
                      ],
                    ),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final Future<int> futureCount;
  final Widget Function() onTap; // Changed from String to Widget Function()
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.futureCount,
    required this.onTap, // Ensure this returns a Widget
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: futureCount,
      builder: (context, snapshot) {
        return GestureDetector(
          child: Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),

                      // Value
                      Text(
                        snapshot.hasData ? snapshot.data!.toString() : '0',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => onTap()), // Fix applied
            );
          },
        );
      },
    );
  }
}
class _CryAnalysisChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cry Reason Distribution",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                        value: 35,
                        color: Color(0xFF5C6BC0),
                        title: 'Hunger',
                        radius: 40),
                    PieChartSectionData(
                        value: 28,
                        color: Color(0xFF26A69A),
                        title: 'Discomfort',
                        radius: 40),
                    PieChartSectionData(
                        value: 22,
                        color: Color(0xFFEF5350),
                        title: 'Tired',
                        radius: 40),
                    PieChartSectionData(
                        value: 15,
                        color: Color(0xFFFFA726),
                        title: 'Other',
                        radius: 40),
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

class _MilestoneChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Milestone Achievements",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 2),
                        FlSpot(1, 3.5),
                        FlSpot(2, 4.5),
                        FlSpot(3, 6),
                        FlSpot(4, 8),
                      ],
                      isCurved: true,
                      color: Color(0xFF5C6BC0),
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
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

class _UserActivityTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Activities",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _ActivityItem("New user registration", Icons.person_add),
                  _ActivityItem("Cry analysis completed", Icons.analytics),
                  _ActivityItem("Daycare booking made", Icons.local_hospital),
                  _ActivityItem("Vaccination reminder sent", Icons.notifications),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String text;
  final IconData icon;

  const _ActivityItem(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(text, style: TextStyle(fontSize: 14)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}