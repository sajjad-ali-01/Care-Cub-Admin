import 'dart:async';
import 'dart:math';
import 'package:carecubadmin/Doctors/ActiveDoctors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../Community/Community.dart';
import '../../NutritionsGuide/NutritionGuide.dart';
import '../DayCareCenters/ActiveDaycare.dart';
import '../DayCareCenters/UnverifiedDaycare.dart';
import '../Login/profile.dart';
import '../Parents/parentsList.dart';
import '../ShimmerEfect.dart';
import '../../Doctors/pandingDoctors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'Charts/pieCharts.dart';
import 'FirestoreService.dart';


class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
      width: 210,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            )
          ),
          Divider(color: Colors.black, thickness: 1),
          Expanded(
            child: ListView(
              children: [
                SidebarButton(
                  icon: Icons.dashboard,
                  label: "Dashboard",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminDashboard()),
                  ),
                ),
                SidebarButton(
                  icon: Icons.people,
                  label: "Parents Community",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CommunityScreen()),
                  ),
                ),
                SidebarButton(
                  icon: Icons.apple,
                  label: "Nutrition Guidance",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NutritionsGuide()),
                  ),
                ),
                SidebarButton(
                  icon: Icons.person_add_disabled,
                  label: "Pendign Doctor's Approvals",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UnverifiedDoctorsScreen()),
                  ),
                ),
                SidebarButton(
                  icon: Icons.medical_services,
                  label: "Active Doctors",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActiveDoctors()),
                  ),
                ),
                SidebarButton(
                  icon: Icons.cabin,
                  label: "Active Daycare Centers",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => verifiedDaycareScreen()),
                  ),
                ),
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
  final VoidCallback onTap;

  const SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label, style: TextStyle(color: Colors.black, fontSize: 14)),
      onTap: onTap,
      hoverColor: Colors.grey[200],
    );
  }
}
class CareCubAppBar extends StatefulWidget {
  @override
  _CareCubAppBarState createState() => _CareCubAppBarState();
}

class _CareCubAppBarState extends State<CareCubAppBar> {
  DateTime _selectedDate = DateTime.now();
  int _unreadReportCount = 0;
  StreamSubscription? _reportSubscription;

  @override
  void initState() {
    super.initState();
    _setupReportNotificationsListener();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }

  void _setupReportNotificationsListener() {
    _reportSubscription = FirebaseFirestore.instance.collection('reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadReportCount = snapshot.size;
        });
      }
    });
  }

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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
                cursor: SystemMouseCursors.click,
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
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.black,size: 30,),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReportsScreen()),
                      );
                    },
                  ),
                  if (_unreadReportCount > 0)
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
                        child: Text('$_unreadReportCount',
                            style: TextStyle(color: Colors.white, fontSize: 8),
                            textAlign: TextAlign.center),
                      ),
                    )
                ],
              ),
              SizedBox(width: 20),
              //_NotificationBadge(),
              SizedBox(width: 20),
              GestureDetector(
                onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>UserProfileScreen()));},
                child:
                CircleAvatar(
                  backgroundImage: NetworkImage("https://res.cloudinary.com/dghmibjc3/image/upload/v1750298021/logo_sac7df.png"),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}


class DashboardGrid extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 2),
        child: Column(
          children: [
            // First row - Three metric cards with equal height
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: "Active Parents",
                    futureCount: _firestoreService.getActiveParentsCount(),
                    icon: Icons.family_restroom,
                    color: Color(0xFF5C6BC0),
                    onTap: () => UsersListScreen(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: "Pending Doctors Approvals",
                    futureCount: _firestoreService.getPendingDoctorsCount(),
                    icon: Icons.person_add_disabled,
                    color: Color(0xFF26A69A),
                    onTap: () => UnverifiedDoctorsScreen(),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    title: "Pending Daycare Approvals",
                    futureCount: _firestoreService.getPendingDayCare(),
                    icon: Icons.business,
                    color: Color(0xFFEF5350),
                    onTap: () => UnverifiedDaycareScreen(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 320,
                    child: _UserRegistrationChart(),
                  ),
                ),
                // Expanded(
                //   flex: 4,
                //   child: Container(
                //     height: 320,
                //     child: _WeeklyReportsTrendChart(),
                //   ),
                // ),
                SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 320, // Fixed height for graph cards
                    child: UserDistributionChart(),
                  ),
                ),
                // Expanded(
                //   flex: 2,
                //   child: Container(
                //     height: 320,
                //     child: _UserRegistrationChart(),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 16),

            // Second row - Two larger graph cards
            Row(
              children: [
                // Expanded(
                //   flex: 2,
                //   child: Container(
                //     height: 300, // Fixed height for graph cards
                //     child: _UserDistributionChart(),
                //   ),
                // ),
                // SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 320, // Fixed height for graph cards
                    child: ReportAnalysisChart(),
                  ),
                ),
                SizedBox(width: 10,),
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 320,
                    child: _PaymentTrendsChart(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Third row - Remaining cards with smaller height
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 200, // Smaller height for these cards
                    child: _MetricCard(
                      title: "Active Doctor",
                      futureCount: _firestoreService.getActiveDoctorsCount(),
                      icon: Icons.medical_services,
                      color: Color(0xFFAB47BC),
                      onTap: () => ActiveDoctors(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 200,
                    child: _MetricCard(
                      title: "Community",
                      futureCount: _firestoreService.getPendingReportsCount(),
                      icon: Icons.message_outlined,
                      color: Colors.deepOrange.shade600,
                      onTap: () => CommunityScreen(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Expanded(
                //   child: Container(
                //     height: 200,
                //     child: _UserActivityTimeline(),
                //   ),
                // ),
                Expanded(
                  child: Container(
                    height: 200, // Smaller height for these cards
                    child: _MetricCard(
                      title: "Active Daycare Centers",
                      futureCount: _firestoreService.getActiveDaycareCount(),
                      icon: Icons.business_sharp,
                      color: Color(0xFFAB47BC),
                      onTap: () => verifiedDaycareScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
    );
  }
}

class ReportsScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Reports'),
        backgroundColor: Colors.deepOrange.shade600,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading reports'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reports available'));
          }

          // Separate reports into pending and resolved
          final pendingReports = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          final resolvedReports = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'resolved';
          }).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Pending (${pendingReports.length})'),
                    Tab(text: 'History (${resolvedReports.length})'),
                  ],
                  indicatorColor: Colors.deepOrange.shade600,
                  labelColor: Colors.deepOrange.shade600,
                  unselectedLabelColor: Colors.grey,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildReportList(pendingReports, context),
                      _buildReportList(resolvedReports, context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportList(List<DocumentSnapshot> reports, BuildContext context) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        final data = report.data() as Map<String, dynamic>;
        final postData = data['postData'] as Map<String, dynamic>? ?? {};
        final timestamp = data['timestamp'] as Timestamp?;
        final timeAgo = timestamp != null
            ? DateFormat('MMM d, y - h:mm a').format(timestamp.toDate())
            : 'Unknown time';

        // Get reporter info
        final reporterName = data['reporterName'] ?? 'Anonymous';
        final reporterId = data['reporterId'] ?? '';

        return Card(
          margin: EdgeInsets.all(8),
          child: ListTile(
            title: Text(data['reason'] ?? 'Report'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reported by: $reporterName'),
                Text('Post by: ${postData['authorName'] ?? 'Unknown author'}'),
                Text('Content: ${postData['text'] ?? 'No content'}'),
                Text(timeAgo),
                if (data['status'] != null)
                  Chip(
                    label: Text(
                      data['status'],
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: data['status'] == 'pending'
                        ? Colors.orange
                        : data['status'] == 'resolved'
                        ? Colors.green
                        : Colors.red,
                  ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.visibility),
              onPressed: () {
                _showReportDetails(context, data, report.id);
              },
            ),
            onTap: () {
              if (data['status'] == 'resolved') return;
              _navigateToReportedPost(context, data['postId']);
            },
          ),
        );
      },
    );
  }

  void _navigateToReportedPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityScreen(scrollToPostId: postId),
      ),
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> data, String reportId) {
    final postData = data['postData'] as Map<String, dynamic>? ?? {};
    final reporterName = data['reporterName'] ?? 'Anonymous';
    final reviewedAt = data['reviewedAt'] as Timestamp?;
    final reviewedTime = reviewedAt != null
        ? DateFormat('MMM d, y - h:mm a').format(reviewedAt.toDate())
        : 'Not reviewed yet';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reason: ${data['reason']}', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Reported by: $reporterName'),
              Text('Post Author: ${postData['authorName'] ?? 'Unknown'}'),
              SizedBox(height: 10),
              Text('Status: ${data['status'] ?? 'pending'}'),
              if (data['status'] == 'resolved')
                Text('Reviewed at: $reviewedTime'),
              SizedBox(height: 20),
              Text('Post Content:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(postData['text'] ?? 'No content available'),
              if (postData['filePath'] != null && postData['filePath'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text('Media:', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (postData['fileType'] == 'image')
                      Image.network(postData['filePath'], width: 200),
                    if (postData['fileType'] == 'video')
                      Text('Video attachment'),
                  ],
                ),
              SizedBox(height: 20),
              if (data['actionTaken'] != null)
                Text('Action Taken: ${data['actionTaken']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          if (data['status'] == 'pending')
            TextButton(
              child: Text('Resolve', style: TextStyle(color: Colors.green)),
              onPressed: () {
                _resolveReport(context, data['postId'], reportId);
              },
            ),
          TextButton(
            child: Text('View Post'),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              _navigateToReportedPost(context, data['postId']);
            },
          ),
        ],
      ),
    );
  }

  void _resolveReport(BuildContext context, String postId, String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'actionTaken': 'Report reviewed and resolved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as resolved')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resolving report: $e')),
      );
    }
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
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
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
                  SizedBox(height: 8),

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

class _UserRegistrationChart extends StatefulWidget {
  @override
  _UserRegistrationChartState createState() => _UserRegistrationChartState();
}

class _UserRegistrationChartState extends State<_UserRegistrationChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String _selectedUserType = 'all'; // 'all', 'parents', 'doctors', 'daycare'

  @override
  void initState() {
    super.initState();
    // Set default range to last 6 months
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - 5, 1);
    _selectedDateRange = DateTimeRange(start: startDate, end: endDate);
    _updateDateControllers();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
        _updateDateControllers();
      });
    }
  }

  void _updateDateControllers() {
    _startDateController.text = DateFormat('MMM d, y').format(_selectedDateRange!.start);
    _endDateController.text = DateFormat('MMM d, y').format(_selectedDateRange!.end);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("User Registrations",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.calendar_today, size: 20),
                  onPressed: () => _selectDateRange(context),
                ),
              ],
            ),
            Row(
              children: [
                // Date fields (combined in half the space)
                Expanded(
                  flex: 5, // Takes 5 parts of available space
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        // Start Date field
                        Expanded(
                          child: TextField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Start',
                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            onTap: () => _selectDateRange(context),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        SizedBox(width: 4),
                        // End Date field
                        Expanded(
                          child: TextField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'End',
                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                            onTap: () => _selectDateRange(context),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // User Type dropdown (takes the other half)
                Expanded(
                  flex: 4, // Takes 5 parts of available space (same as date fields)
                  child: SizedBox(
                    height: 30,
                    child: DropdownButtonFormField<String>(
                      value: _selectedUserType,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'parents', child: Text('Parents', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'doctors', child: Text('Doctors', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'daycare', child: Text('Daycare', style: TextStyle(fontSize: 12))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 12),
                      icon: Icon(Icons.arrow_drop_down, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            Divider(thickness: 1,),
            SizedBox(height: 5),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingChart();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 40),
                          SizedBox(height: 16),
                          Text(
                            'Error loading data',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("No registration data available"),
                          SizedBox(height: 8),
                          Text("0 registrations found", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final userData = snapshot.data!;
                  final monthlyData = _processMonthlyUserData(userData);
                  final monthLabels = _generateMonthLabels(monthlyData);

                  return BarChart(
                    BarChartData(
                      barGroups: monthlyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                        BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getColorForUserType(),
                        width: 27,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
                        ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  value < monthLabels.length ? monthLabels[value.toInt()] : '',
                                  style: TextStyle(fontSize: 10),
                                ),
                              );
                            },
                            reservedSize: 24,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateInterval(monthlyData),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 28,
                          ),
                        ),
                        rightTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey[200]!,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserData() async {
    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    List<Map<String, dynamic>> allUsers = [];

    if (_selectedUserType == 'all' || _selectedUserType == 'parents') {
      final parents = await _firestore.collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      allUsers.addAll(parents.docs.map((doc) => doc.data()..['type'] = 'parent'));
    }

    if (_selectedUserType == 'all' || _selectedUserType == 'doctors') {
      final doctors = await _firestore.collection('Doctors')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      allUsers.addAll(doctors.docs.map((doc) => doc.data()..['type'] = 'doctor'));
    }

    if (_selectedUserType == 'all' || _selectedUserType == 'daycare') {
      final daycares = await _firestore.collection('DayCare')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      allUsers.addAll(daycares.docs.map((doc) => doc.data()..['type'] = 'daycare'));
    }

    return allUsers;
  }

  List<int> _processMonthlyUserData(List<Map<String, dynamic>> users) {
    final monthlyData = <int>[];
    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;

    final monthCount = _calculateMonthCount(startDate, endDate);

    for (int i = 0; i < monthCount; i++) {
      final monthStart = DateTime(startDate.year, startDate.month + i, 1);
      final monthEnd = DateTime(
        monthStart.year + (monthStart.month == 12 ? 1 : 0),
        monthStart.month == 12 ? 1 : monthStart.month + 1,
        1,
      );

      final monthUsers = users.where((user) {
        final timestamp = user['createdAt'] as Timestamp?;
        if (timestamp == null) return false;

        final date = timestamp.toDate();
        return !date.isBefore(monthStart) && date.isBefore(monthEnd);
      }).length;

      monthlyData.add(monthUsers);
    }

    return monthlyData;
  }

  int _calculateMonthCount(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month + 1;
  }

  List<String> _generateMonthLabels(List<int> monthlyData) {
    final startDate = _selectedDateRange!.start;
    final monthNames = DateFormat.MMM().dateSymbols.SHORTMONTHS;

    return List.generate(monthlyData.length, (i) {
      final monthDate = DateTime(startDate.year, startDate.month + i, 1);
      return monthNames[monthDate.month - 1];
    });
  }

  Color _getColorForUserType() {
    switch (_selectedUserType) {
      case 'parents':
        return Colors.blue[400]!;
      case 'doctors':
        return Colors.green[400]!;
      case 'daycare':
        return Colors.orange[400]!;
      default:
        return Colors.purple[400]!;
    }
  }

  double _calculateInterval(List<int> data) {
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return 50;
  }

  Widget _buildLoadingChart() {
    return ShimmerEffect(
      child: Column(
        children: [
          Container(width: 150, height: 20, color: Colors.white),
          SizedBox(height: 16),
          Expanded(
            child: Container(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
class _PaymentTrendsChart extends StatefulWidget {
  @override
  _PaymentTrendsChartState createState() => _PaymentTrendsChartState();
}

class _PaymentTrendsChartState extends State<_PaymentTrendsChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  double _totalPayments = 0;
  List<Map<String, dynamic>> _dailyPayments = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentsForDate(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fetchPaymentsForDate(picked);
      });
    }
  }

  Future<void> _fetchPaymentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    try {
      final snapshot = await _firestore.collection('Payments')
          .where('status', isEqualTo: 'paid')
         // .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          //.where('paymentDate', isLessThan: Timestamp.fromDate(endOfDay))
         // .orderBy('paymentDate')
          .get();

      double total = 0;
      final payments = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num).toDouble();
        return {
          'time': DateFormat('HH:mm').format((data['paymentDate'] as Timestamp).toDate()),
          'amount': (data['amount'] as num).toDouble(),
        };
      }).toList();

      setState(() {
        _totalPayments = total;
        _dailyPayments = payments;
      });
    } catch (e) {
      print('Error fetching payments: $e');
      setState(() {
        _totalPayments = 0;
        _dailyPayments = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Daily Payment Trends",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.cyan.shade300,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_sharp, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, y').format(_selectedDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Total Payments: \$${_totalPayments.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange.shade600,
              ),
            ),
            Divider(thickness: 1),
            SizedBox(height: 10),
            Expanded(
              child: _dailyPayments.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No payments for selected date",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : Padding(
                padding: EdgeInsets.only(top: 16),
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        //tooltipBgColor: Colors.white,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${_dailyPayments[spot.x.toInt()]['time']}\n\$${spot.y.toStringAsFixed(2)}',
                              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < _dailyPayments.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  _dailyPayments[value.toInt()]['time'],
                                  style: TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return Text('');
                          },
                          reservedSize: 24,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateInterval(_dailyPayments.map((p) => p['amount'] as double).toList()),
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '\$${value.toInt()}',
                              style: TextStyle(fontSize: 10),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      rightTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        left: BorderSide(color: Colors.grey[300]!, width: 1),
                        right: BorderSide(color: Colors.transparent, width: 0),
                        top: BorderSide(color: Colors.transparent, width: 0),
                      ),
                    ),
                    minX: 0,
                    maxX: _dailyPayments.length.toDouble() - 1,
                    minY: 0,
                    maxY: _dailyPayments.map((p) => p['amount'] as double).reduce((a, b) => a > b ? a : b) * 1.1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _dailyPayments.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value['amount'] as double);
                        }).toList(),
                        isCurved: true,
                        color: Colors.deepOrange.shade600,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
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

  double _calculateInterval(List<double> amounts) {
    if (amounts.isEmpty) return 100;
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    if (maxAmount <= 100) return 20;
    if (maxAmount <= 500) return 100;
    if (maxAmount <= 1000) return 200;
    return 500;
  }
}