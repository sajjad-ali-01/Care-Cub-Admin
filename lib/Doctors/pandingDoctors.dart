import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import '../Dashboard/Dashboard.dart';

class UnverifiedDoctorsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unverified Doctors',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminDashboard()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.lightBlue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Doctors')
              .where('isVerified', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading doctors',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No unverified doctors found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final doctors = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index].data()! as Map<String, dynamic>;
                final doctorId = doctors[index].id;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(
                            doctorData: doctor,
                            doctorId: doctorId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: doctor['photoUrl'] != null &&
                                doctor['photoUrl'].isNotEmpty
                                ? NetworkImage(doctor['photoUrl'])
                                : AssetImage('assets/default_doctor.png') as ImageProvider,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${doctor['title']} ${doctor['name']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  doctor['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  doctor['Primary_specialization'] ?? 'Specialist',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepOrangeAccent.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class DoctorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  const DoctorDetailsScreen({
    required this.doctorData,
    required this.doctorId,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  // In the DoctorDetailsScreen class, add this state variable
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    isVerified = widget.doctorData['isVerified'] ?? false;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Profile',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => UnverifiedDoctorsScreen()),
                  (Route<dynamic> route) => false,
            );
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.lightBlue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade50, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.lightBlue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Update the verification icon in the Stack widget
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundImage: widget.doctorData['photoUrl'] != null &&
                                  widget.doctorData['photoUrl'].isNotEmpty
                                  ? NetworkImage(widget.doctorData['photoUrl'])
                                  : AssetImage('assets/default_doctor.png') as ImageProvider,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isVerified ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              isVerified ? Icons.verified : Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${widget.doctorData['title']} ${widget.doctorData['name']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.doctorData['Primary_specialization'] ?? "Specialist",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem(Icons.star, '${widget.doctorData['rating'] ?? '0.0'}', 'Rating'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.medical_services, '${widget.doctorData['experience'] ?? '0'}+', 'Years Exp.'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.people, '${widget.doctorData['patients'] ?? '0'}+', 'Patients'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Also update the verify button to be disabled when already verified
                          ElevatedButton.icon(
                            icon: Icon(Icons.verified_user, size: 20),
                            label: Text(isVerified ? 'Verified' : 'Verify Doctor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? Colors.grey : Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: isVerified ? null : () {
                              _verifyDoctor(context);
                            },
                          ),
                          SizedBox(width: 16),
                          OutlinedButton.icon(
                            icon: Icon(Icons.message, size: 20),
                            label: Text('Message'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              final email = widget.doctorData['email'] ?? '';
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Doctor email not available')),
                                );
                                return;
                              }

                              final subject = Uri.encodeComponent('Care Cub Registration Inquiry - ${widget.doctorData['name']}');
                              final body = Uri.encodeComponent('Dear Dr. ${widget.doctorData['name']},\n\n');

                              // Direct Gmail compose URL
                              final gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1'
                                  '&to=$email'
                                  '&su=$subject'
                                  '&body=$body';

                              // For web browsers
                              if (kIsWeb) {
                                html.window.open(gmailUrl, '_blank');
                              }
                              // For mobile devices
                              else {
                                final gmailAppUri = Uri(
                                  scheme: 'https',
                                  host: 'mail.google.com',
                                  path: '/mail/u/0/',
                                  queryParameters: {
                                    'view': 'cm',
                                    'fs': '1',
                                    'to': email,
                                    'su': subject,
                                    'body': body,
                                  },
                                );

                                launchUrl(gmailAppUri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Details Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 8),

                  // Basic Info
                  _buildSectionTitle('Basic Information'),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow(Icons.email, 'Email', widget.doctorData['email'] ?? 'N/A'),
                      _buildInfoRow(Icons.phone, 'Phone', widget.doctorData['phone'] ?? 'N/A'),
                      _buildInfoRow(Icons.location_city, 'City', widget.doctorData['city'] ?? 'N/A'),
                      _buildInfoRow(Icons.work, 'Experience', '${widget.doctorData['experience'] ?? 'N/A'} years'),
                      _buildInfoRow(
                        Icons.date_range,
                        'Registered On',
                        widget.doctorData['createdAt'] != null
                            ? DateFormat('MMMM dd, yyyy').format((widget.doctorData['createdAt'] as Timestamp).toDate())
                            : 'N/A',
                      ),
                      _buildInfoRow(Icons.medical_information, 'PMC Number', widget.doctorData['PMCNumber'] ?? 'N/A'),
                    ],
                  ),

                  // Specializations
                  _buildSectionTitle('Specializations'),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow(Icons.medical_services, 'Primary', widget.doctorData['Primary_specialization'] ?? 'N/A'),
                      _buildInfoRow(Icons.medical_services, 'Secondary', widget.doctorData['Secondary_specialization'] ?? 'N/A'),
                    ],
                  ),

                  // Education
                  _buildSectionTitle('Education'),
                  if (widget.doctorData['EDU_INFO'] != null)
                    _buildInfoCard(
                      children: List<String>.from(widget.doctorData['EDU_INFO'])
                          .map((edu) => _buildInfoRow(Icons.school, 'Degree', edu))
                          .toList(),
                    ),

                  // Conditions Treated
                  _buildSectionTitle('Conditions Treated'),
                  if (widget.doctorData['Condition'] != null)
                    _buildInfoCard(
                      children: List<String>.from(widget.doctorData['Condition'])
                          .map((condition) => _buildInfoRow(Icons.health_and_safety, 'Condition', condition))
                          .toList(),
                    ),

                  // Services Offered
                  _buildSectionTitle('Services Offered'),
                  if (widget.doctorData['Service_Offered'] != null)
                    _buildInfoCard(
                      children: List<String>.from(widget.doctorData['Service_Offered'])
                          .map((service) => _buildInfoRow(Icons.local_hospital, 'Service', service))
                          .toList(),
                    ),

                  // Clinics Information
                  _buildSectionTitle('Clinics'),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Doctors')
                        .doc(widget.doctorId)
                        .collection('clinics')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Error loading clinics: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No clinics found');
                      }

                      final clinics = snapshot.data!.docs;

                      return Column(
                        children: clinics.map((clinicDoc) {
                          final clinic = clinicDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.business, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        clinic['ClinicName'] ?? 'Unnamed Clinic',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  _buildClinicInfoRow(Icons.location_on, 'Address', clinic['Address']),
                                  _buildClinicInfoRow(Icons.location_city, 'City', clinic['ClinicCity']),
                                  _buildClinicInfoRow(Icons.attach_money, 'Fees', clinic['Fees']),
                                  _buildClinicInfoRow(Icons.map, 'Location', clinic['Location']),

                                  // Availability
                                  if (clinic['Availability'] != null) ...[
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Availability:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    ..._buildAvailabilityWidgets(clinic['Availability']),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyDoctor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Doctor'),
        content: Text('Are you sure you want to verify this doctor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('Doctors')
                  .doc(widget.doctorId)
                  .update({'isVerified': true})
                  .then((_) {
                setState(() {
                  isVerified = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Doctor verified successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context); // Go back to previous screen
              });
            },
            child: Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  List<Widget> _buildAvailabilityWidgets(Map<String, dynamic>? availability) {
    if (availability == null) return [];

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.where((day) => availability[day] != null).map((day) {
      final times = availability[day];
      return Padding(
        padding: EdgeInsets.only(bottom: 8, left: 32),
        child: Row(
          children: [
            Container(
              width: 100,
              child: Text(
                day,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Chip(
              label: Text('${times['start']} - ${times['end']}'),
              backgroundColor: Colors.blue.shade50,
              labelStyle: TextStyle(color: Colors.blue.shade800),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildClinicInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value ?? 'Not specified',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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