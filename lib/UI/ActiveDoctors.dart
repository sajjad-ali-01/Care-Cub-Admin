import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'Dashboard/Dashboard.dart';

class ActiveDoctors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unverified Doctors'),
        leading: IconButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>AdminDashboard()));
        }, icon: Icon(Icons.arrow_back)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Doctors')
            .where('isVerified', isEqualTo: true) // Fetch only unverified doctors
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No unverified doctors found.'));
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index].data()! as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text('${doctor['title']} ${doctor['name']}'),
                    subtitle: Text(doctor['email']),
                    trailing: IconButton(
                      icon: Icon(Icons.verified, color: Colors.green),
                      onPressed: () {
                        },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailsScreen(
                            doctorData: doctor,
                            doctorId: doctors[index].id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class DoctorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  const DoctorDetailsScreen({
    required this.doctorData,
    required this.doctorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Details'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: doctorData['photoUrl'] != null && doctorData['photoUrl'].isNotEmpty
                        ? NetworkImage(doctorData['photoUrl'])
                        : AssetImage('assets/default_doctor.png') as ImageProvider,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${doctorData['title']} ${doctorData['name']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctorData['Primary_specialization'] ?? "N/A",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
//new coment
            // Basic Info
            _buildSectionTitle('Basic Information'),
            _buildInfoRow('Email', doctorData['email'] ?? 'N/A'),
            _buildInfoRow('Phone', doctorData['phone'] ?? 'N/A'),
            _buildInfoRow('City', doctorData['city'] ?? 'N/A'),
            _buildInfoRow('Experience', doctorData['experience'] ?? 'N/A'),
            _buildInfoRow(
              'Registered On',
              doctorData['createdAt'] != null
                  ? DateFormat('MMMM dd, yyyy').format((doctorData['createdAt'] as Timestamp).toDate())
                  : 'N/A',
            ),
            _buildInfoRow('PMC Number', doctorData['PMCNumber'] ?? 'N/A'),

            // Specializations
            _buildSectionTitle('Specializations'),
            _buildInfoRow('Primary', doctorData['Primary_specialization'] ?? 'N/A'),
            _buildInfoRow('Secondary', doctorData['Secondary_specialization'] ?? 'N/A'),

            // Education
            _buildSectionTitle('Education'),
            if (doctorData['EDU_INFO'] != null)
              ...List<String>.from(doctorData['EDU_INFO']).map((edu) => _buildInfoRow('Degree', edu)),

            // Conditions Treated
            _buildSectionTitle('Conditions Treated'),
            if (doctorData['Condition'] != null)
              ...List<String>.from(doctorData['Condition']).map((condition) => _buildInfoRow('Condition', condition)),

            // Services Offered
            _buildSectionTitle('Services Offered'),
            if (doctorData['Service_Offered'] != null)
              ...List<String>.from(doctorData['Service_Offered']).map((service) => _buildInfoRow('Service', service)),

            // Clinics Information
            _buildSectionTitle('Clinics'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Doctors')
                  .doc(doctorId)
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
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic['ClinicName'] ?? 'Unnamed Clinic',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            _buildClinicInfoRow('Address', clinic['Address']),
                            _buildClinicInfoRow('City', clinic['ClinicCity']),
                            _buildClinicInfoRow('Fees', clinic['Fees']),
                            _buildClinicInfoRow('Location', clinic['Location']),

                            // Availability
                            if (clinic['Availability'] != null) ...[
                              SizedBox(height: 12),
                              Text(
                                'Availability:',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
            Center(
              child: ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('Doctors')
                      .doc(doctorId)
                      .update({'isVerified': true})
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Doctor verified successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pop(context);
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error verifying doctor: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                },
                child: Text('Verify Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ),
          ],
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
        padding: EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(day)),
            Text('${times['start']} - ${times['end']}'),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildClinicInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}