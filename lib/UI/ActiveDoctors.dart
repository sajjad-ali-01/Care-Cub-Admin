import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import 'Dashboard/Dashboard.dart';
import 'bookingScreen.dart';

class ActiveDoctors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verified Doctors'),
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
              colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
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
              .where('isVerified', isEqualTo: true)
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
                      'No doctors found',
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
                          builder: (context) =>
                              DoctorDetailsScreen(
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
                                : AssetImage(
                                'assets/default_doctor.png') as ImageProvider,
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
                                  doctor['Primary_specialization'] ??
                                      'Specialist',
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
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                                Icons.verified, color: Colors.white, size: 20),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Profile'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            child: Text("See Dr's Bookings"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingsScreen(
                    doctorId: widget.doctorId,
                    doctorName: widget.doctorData['name'],
                  ),
                ),
              );
              },
          ),
        ],
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
                    colors: [Colors.blue.shade600, Colors.lightBlue.shade300],
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
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.verified,
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
                          _buildStatItem(Icons.star, '${widget.doctorData['rating'] ?? '4.8'}', 'Rating'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.medical_services, '${widget.doctorData['experience'] ?? '0'}+', 'Years Exp.'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.people, '${widget.doctorData['patients'] ?? '100'}+', 'Patients'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Also update the verify button to be disabled when already verified
                          ElevatedButton.icon(
                            icon: Icon(Icons.verified_user, size: 20,color: Colors.deepOrange.shade500),
                            label: Text('Verified',style: TextStyle(color: Colors.deepOrange.shade500),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey ,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
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

                              final subject = Uri.encodeComponent('Care Cub Inquiry - ${widget.doctorData['name']}');
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
                  // About Section
                  _buildSectionTitle('About Doctor'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        widget.doctorData['about'] ?? 'No description available',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

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
                  ReviewCard(),

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
  Widget ReviewCard() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('doctor_reviews')
          .where('doctorId', isEqualTo: widget.doctorId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading reviews'));
        }

        final reviews = snapshot.data?.docs ?? [];
        final totalReviews = reviews.length;

        // Calculate average ratings
        double doctorRatingTotal = 0;
        double clinicRatingTotal = 0;
        double staffRatingTotal = 0;

        for (var review in reviews) {
          final data = review.data() as Map<String, dynamic>;
          doctorRatingTotal += (data['doctorRating'] as num).toDouble();
          clinicRatingTotal += (data['clinicRating'] as num).toDouble();
          staffRatingTotal += (data['staffRating'] as num).toDouble();
        }

        final avgDoctorRating = totalReviews > 0 ? (doctorRatingTotal / totalReviews) : 0;
        final avgClinicRating = totalReviews > 0 ? (clinicRatingTotal / totalReviews) : 0;
        final avgStaffRating = totalReviews > 0 ? (staffRatingTotal / totalReviews) : 0;
        final overallRating = totalReviews > 0
            ? ((avgDoctorRating + avgClinicRating + avgStaffRating) / 3)
            : 0;

        // Get latest 2 reviews for display
        final latestReviews = reviews.take(2).toList();

        return Card(
          color: Colors.white,
          margin: EdgeInsets.only(left: 16, right: 16, top: 16),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Icon(Icons.star, color: Colors.blueAccent.shade700),
                        SizedBox(width: 10),
                        Text(
                          "Dr. ${widget.doctorData['name']}'s Reviews",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.blueAccent.shade700, size: 24),
                        SizedBox(width: 4),
                        Text(
                          overallRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.black,
                          child: Text(
                            "${(overallRating * 20).toStringAsFixed(0)}%",
                            style: TextStyle(color: Colors.white, fontSize: 25),
                          ),
                        ),
                        Text(
                          "Satisfied out of ($totalReviews)",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 20),
                    Column(
                      children: [
                        RatingRow("Doctor Checkup", "${avgDoctorRating.toStringAsFixed(1)}/5"),
                        RatingRow("Clinic Environment", "${avgClinicRating.toStringAsFixed(1)}/5"),
                        RatingRow("Staff Behaviour", "${avgStaffRating.toStringAsFixed(1)}/5"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (latestReviews.isNotEmpty)
                  ...latestReviews.map((review) {
                    final data = review.data() as Map<String, dynamic>;
                    final date = (data['createdAt'] as Timestamp).toDate();
                    final formattedDate = DateFormat('MMM d, y').format(date);

                    return Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${data['feedback'] ?? 'No feedback provided'}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Verified patient: ${_obscureName(data['patientName'] ?? 'Anonymous')} · $formattedDate',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orangeAccent.shade700, size: 16),
                              Text(
                                ' ${data['overallRating']?.toStringAsFixed(1) ?? '0'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorReviewsScreen(
                          doctorId: widget.doctorId,
                          doctorName: widget.doctorData['name'],
                        ),
                      ),
                    );
                  },
                  child: Text("See All Reviews", style: TextStyle(fontSize: 15)),
                  style: OutlinedButton.styleFrom(shape: StadiumBorder()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _obscureName(String name) {
    if (name.isEmpty || name == 'Anonymous') return 'Anonymous';
    final parts = name.split(' ');
    if (parts.length == 1) return '${parts[0][0]}***';
    return '${parts[0][0]}*** ${parts.last[0]}***';
  }

  Widget RatingRow(String label, String rating) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            rating,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
class DoctorReviewsScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorReviewsScreen({
    required this.doctorId,
    required this.doctorName,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for Dr. $doctorName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctor_reviews')
            .where('doctorId', isEqualTo: doctorId)
        //.orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reviews: ${snapshot.error.toString()}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              try {
                final review = reviews[index].data() as Map<String, dynamic>;
                final date = review['createdAt'] != null
                    ? (review['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                final formattedDate = DateFormat('MMM d, y').format(date);

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review['patientName']?.toString() ?? 'Anonymous',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              ' ${(review['overallRating']?.toStringAsFixed(1)) ?? '0.0'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (review['feedback'] != null && review['feedback'].toString().isNotEmpty)
                          Text(
                            review['feedback'].toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (review['doctorRating'] != null)
                              Chip(
                                label: Text(
                                  'Doctor: ${review['doctorRating'].toStringAsFixed(1)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            if (review['clinicRating'] != null)
                              Chip(
                                label: Text(
                                  'Clinic: ${review['clinicRating'].toStringAsFixed(1)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            if (review['staffRating'] != null)
                              Chip(
                                label: Text(
                                  'Staff: ${review['staffRating'].toStringAsFixed(1)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.orange,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Error loading review: ${e.toString()}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}