import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import '../Dashboard/Dashboard.dart';
import 'bookingScreen.dart';

class Doctor {
  final String id;
  final String name;
  final String title;
  final String email;
  final String phone;
  final String city;
  final String photoUrl;
  final String about;
  final String experience;
  final String patients;
  final String Primary_specialization;
  final String Secondary_specialization;
  final String PMCNumber;
  final bool isVerified;
  final DateTime? createdAt;
  final List<String> EDU_INFO;
  final List<String> Condition;
  final List<String> Service_Offered;

  Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.email,
    required this.phone,
    required this.city,
    required this.photoUrl,
    required this.about,
    required this.experience,
    required this.patients,
    required this.Primary_specialization,
    required this.Secondary_specialization,
    required this.PMCNumber,
    required this.isVerified,
    this.createdAt,
    required this.EDU_INFO,
    required this.Condition,
    required this.Service_Offered,
  });

  factory Doctor.fromMap(Map<String, dynamic> data, String id) {
    return Doctor(
      id: id,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      city: data['city'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      about: data['about'] ?? '',
      experience: data['experience']?.toString() ?? '0',
      patients: data['patients']?.toString() ?? '0',
      Primary_specialization: data['Primary_specialization'] ?? '',
      Secondary_specialization: data['Secondary_specialization'] ?? '',
      PMCNumber: data['PMCNumber'] ?? '',
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      EDU_INFO: List<String>.from(data['EDU_INFO'] ?? []),
      Condition: List<String>.from(data['Condition'] ?? []),
      Service_Offered: List<String>.from(data['Service_Offered'] ?? []),
    );
  }
}

class Clinic {
  final String id;
  final String name;
  final String address;
  final String city;
  final String fees;
  final String location;
  final Map<String, dynamic>? availability;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.fees,
    required this.location,
    this.availability,
  });

  factory Clinic.fromMap(Map<String, dynamic> data, String id) {
    return Clinic(
      id: id,
      name: data['ClinicName'] ?? '',
      address: data['Address'] ?? '',
      city: data['ClinicCity'] ?? '',
      fees: data['Fees'] ?? '',
      location: data['Location'] ?? '',
      availability: data['Availability'],
    );
  }
}

class DoctorReview {
  final String id;
  final String doctorId;
  final String patientName;
  final String feedback;
  final double doctorRating;
  final double clinicRating;
  final double staffRating;
  final DateTime createdAt;

  DoctorReview({
    required this.id,
    required this.doctorId,
    required this.patientName,
    required this.feedback,
    required this.doctorRating,
    required this.clinicRating,
    required this.staffRating,
    required this.createdAt,
  });

  factory DoctorReview.fromMap(Map<String, dynamic> data, String id) {
    return DoctorReview(
      id: id,
      doctorId: data['doctorId'] ?? '',
      patientName: data['patientName'] ?? 'Anonymous',
      feedback: data['feedback'] ?? '',
      doctorRating: (data['doctorRating'] as num).toDouble(),
      clinicRating: (data['clinicRating'] as num).toDouble(),
      staffRating: (data['staffRating'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  double get overallRating {
    return (doctorRating + clinicRating + staffRating) / 3;
  }
}

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Doctor>> getVerifiedDoctors() {
    return _firestore
        .collection('Doctors')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Doctor.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<Doctor> getDoctorById(String doctorId) async {
    final doc = await _firestore.collection('Doctors').doc(doctorId).get();
    return Doctor.fromMap(doc.data()!, doc.id);
  }

  Stream<List<Clinic>> getDoctorClinics(String doctorId) {
    return _firestore
        .collection('Doctors')
        .doc(doctorId)
        .collection('clinics')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Clinic.fromMap(doc.data(), doc.id))
        .toList());
  }

  Stream<List<DoctorReview>> getDoctorReviews(String doctorId) {
    return _firestore
        .collection('doctor_reviews')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => DoctorReview.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<double> getOverallRating(String doctorId) async {
    final snapshot = await _firestore
        .collection('doctor_reviews')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final reviews = snapshot.docs;
    final totalReviews = reviews.length;

    if (totalReviews == 0) return 0.0;

    double doctorRatingTotal = 0;
    double clinicRatingTotal = 0;
    double staffRatingTotal = 0;

    for (var review in reviews) {
      final data = review.data();
      doctorRatingTotal += (data['doctorRating'] as num).toDouble();
      clinicRatingTotal += (data['clinicRating'] as num).toDouble();
      staffRatingTotal += (data['staffRating'] as num).toDouble();
    }

    final avgDoctorRating = doctorRatingTotal / totalReviews;
    final avgClinicRating = clinicRatingTotal / totalReviews;
    final avgStaffRating = staffRatingTotal / totalReviews;

    return (avgDoctorRating + avgClinicRating + avgStaffRating) / 3;
  }

  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection('doctor_reviews').doc(reviewId).delete();
  }
  // Add to DoctorService class
  Future<Map<String, int>> getBookingAnalytics(String doctorId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final analytics = {
      'pending': 0,
      'confirmed': 0,
      'cancelled': 0,
      'completed': 0,
      'total': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase() ?? 'pending';

      if (analytics.containsKey(status)) {
        analytics[status] = analytics[status]! + 1;
      }
      analytics['total'] = analytics['total']! + 1;
    }

    return analytics;
  }
}

class ActiveDoctors extends StatelessWidget {
  final DoctorService _doctorService = DoctorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text('Verified Doctors', style: TextStyle(color: Colors.white)),
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
            colors: [Colors.grey.shade200, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<Doctor>>(
          stream: _doctorService.getVerifiedDoctors(),
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

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

            final doctors = snapshot.data!;

            return GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.5
              ),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];

                return Card(
                  color: Colors.white,
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
                                doctorId: doctor.id,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 25,horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: doctor.photoUrl.isNotEmpty
                                ? NetworkImage(doctor.photoUrl)
                                : AssetImage('assets/default_doctor.png') as ImageProvider,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${doctor.title} ${doctor.name}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  doctor.EDU_INFO
                                      .map((e) => e.toString().split(RegExp(r'[\(\-]'))[0].trim())
                                      .join(', '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 4,),
                                Text(
                                  doctor.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  doctor.Primary_specialization,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepOrangeAccent.shade400,
                                  ),
                                ),
                                SizedBox(height: 4),
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
  final String doctorId;

  const DoctorDetailsScreen({
    required this.doctorId,
    Key? key,
  }) : super(key: key);

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final DoctorService _doctorService = DoctorService();
  late Future<Doctor> _doctorFuture;
  double overallRating = 0.0;

  @override
  void initState() {
    super.initState();
    _doctorFuture = _doctorService.getDoctorById(widget.doctorId);
    _loadRating();
  }

  void _loadRating() async {
    double rating = await _doctorService.getOverallRating(widget.doctorId);
    if (mounted) {
      setState(() {
        overallRating = rating;
      });
    }
  }

  void _sendEmail(String email, String name) {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor email not available')),
      );
      return;
    }

    final subject = Uri.encodeComponent('Care Cub Inquiry - $name');
    final body = Uri.encodeComponent('Dear Dr. $name,\n\n');

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Doctor>(
          future: _doctorFuture,
          builder: (context, snapshot) {
            final name = snapshot.hasData ? snapshot.data!.name : 'Doctor';
            return Text("$name's Details", style: const TextStyle(color: Colors.white));
          },
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            child: ElevatedButton(
              child: FutureBuilder<Doctor>(
                future: _doctorFuture,
                builder: (context, snapshot) {
                  final name = snapshot.hasData ? snapshot.data!.name : 'Doctor';
                  return Text("See $name's Bookings", style: const TextStyle(color: Colors.white));
                },
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingsScreen(
                      doctorId: widget.doctorId,
                      doctorName: '',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
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
        child: FutureBuilder<Doctor>(
          future: _doctorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading doctor details: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Doctor not found'));
            }

            final doctor = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(doctor),
                  _buildBasicInfoSection(doctor),
                  _buildSpecializationsSection(doctor),
                  _buildEducationSection(doctor),
                  _buildConditionsSection(doctor),
                  _buildServicesSection(doctor),
                  _buildReviewsSection(doctor),
                  _buildClinicsSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: doctor.photoUrl.isNotEmpty
                        ? NetworkImage(doctor.photoUrl)
                        : const AssetImage('assets/default_doctor.png') as ImageProvider,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${doctor.title} ${doctor.name}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              doctor.Primary_specialization,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(Icons.star, '${overallRating.toStringAsFixed(1)}', 'Rating'),
                const SizedBox(width: 20),
                _buildStatItem(Icons.medical_services, '${doctor.experience}+', 'Years Exp.'),
                const SizedBox(width: 20),
                // _buildStatItem(Icons.people, '${doctor.patients}+', 'Patients'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user, size: 20, color: Colors.black),
                  label: const Text('Verified', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.message, size: 20, color: Colors.white),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => _sendEmail(doctor.email, doctor.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
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

  Widget _buildAboutSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About Doctor'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              doctor.about,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBasicInfoSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        _buildInfoCard(
          children: [
            _buildInfoRow(Icons.email, 'Email', doctor.email),
            _buildInfoRow(Icons.phone, 'Phone', doctor.phone),
            _buildInfoRow(Icons.location_city, 'City', doctor.city),
            _buildInfoRow(Icons.work, 'Experience', '${doctor.experience} years'),
            _buildInfoRow(
              Icons.date_range,
              'Registered On',
              doctor.createdAt != null
                  ? DateFormat('MMMM dd, yyyy').format(doctor.createdAt!)
                  : 'N/A',
            ),
            _buildInfoRow(Icons.medical_information, 'PMC Number', doctor.PMCNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecializationsSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Specializations'),
        _buildInfoCard(
          children: [
            _buildInfoRow(Icons.medical_services, 'Primary', doctor.Primary_specialization),
            _buildInfoRow(Icons.medical_services, 'Secondary', doctor.Secondary_specialization),
          ],
        ),
      ],
    );
  }

  Widget _buildEducationSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Education'),
        if (doctor.EDU_INFO.isNotEmpty)
          _buildInfoCard(
            children: doctor.EDU_INFO
                .map((edu) => _buildInfoRow(Icons.school, 'Degree', edu))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildConditionsSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Conditions Treated'),
        if (doctor.Condition.isNotEmpty)
          _buildInfoCard(
            children: doctor.Condition
                .map((condition) => _buildInfoRow(Icons.health_and_safety, 'Condition', condition))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildServicesSection(Doctor doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Services Offered'),
        if (doctor.Service_Offered.isNotEmpty)
          _buildInfoCard(
            children: doctor.Service_Offered
                .map((service) => _buildInfoRow(Icons.local_hospital, 'Service', service))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildReviewsSection(Doctor doctor) {
    return StreamBuilder<List<DoctorReview>>(
      stream: _doctorService.getDoctorReviews(widget.doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading reviews: ${snapshot.error}'));
        }

        final reviews = snapshot.data ?? [];
        final totalReviews = reviews.length;

        // Calculate average ratings
        double doctorRatingTotal = 0;
        double clinicRatingTotal = 0;
        double staffRatingTotal = 0;

        for (var review in reviews) {
          doctorRatingTotal += review.doctorRating;
          clinicRatingTotal += review.clinicRating;
          staffRatingTotal += review.staffRating;
        }

        final avgDoctorRating = totalReviews > 0 ? (doctorRatingTotal / totalReviews) : 0;
        final avgClinicRating = totalReviews > 0 ? (clinicRatingTotal / totalReviews) : 0;
        final avgStaffRating = totalReviews > 0 ? (staffRatingTotal / totalReviews) : 0;

        // Get latest 2 reviews for display
        final latestReviews = reviews.take(2).toList();

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        Text(
                          "Dr. ${doctor.name}'s Reviews",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.blueAccent.shade700, size: 24),
                        const SizedBox(width: 4),
                        Text(
                          overallRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                            style: const TextStyle(color: Colors.white, fontSize: 25),
                          ),
                        ),
                        Text(
                          "Satisfied out of ($totalReviews)",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        _buildRatingRow("Doctor Checkup", "${avgDoctorRating.toStringAsFixed(1)}/5"),
                        _buildRatingRow("Clinic Environment", "${avgClinicRating.toStringAsFixed(1)}/5"),
                        _buildRatingRow("Staff Behaviour", "${avgStaffRating.toStringAsFixed(1)}/5"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (latestReviews.isNotEmpty)
                  ...latestReviews.map((review) {
                    final formattedDate = DateFormat('MMM d, y').format(review.createdAt);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '"${review.feedback}"',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Verified patient: ${_obscureName(review.patientName)} · $formattedDate',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.orangeAccent.shade700, size: 16),
                              Text(
                                ' ${review.overallRating.toStringAsFixed(1)}',
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
                          doctorName: doctor.name,
                        ),
                      ),
                    );
                  },
                  child: const Text("See All Reviews", style: TextStyle(fontSize: 15)),
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClinicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Clinics'),
        StreamBuilder<List<Clinic>>(
          stream: _doctorService.getDoctorClinics(widget.doctorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error loading clinics: ${snapshot.error}');
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No clinics found');
            }

            final clinics = snapshot.data!;

            return Column(
              children: clinics.map((clinic) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              clinic.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildClinicInfoRow(Icons.location_on, 'Address', clinic.address),
                        _buildClinicInfoRow(Icons.location_city, 'City', clinic.city),
                        _buildClinicInfoRow(Icons.attach_money, 'Fees', clinic.fees),
                        _buildClinicInfoRow(Icons.map, 'Location', clinic.location),

                        // Availability
                        if (clinic.availability != null) ...[
                          const SizedBox(height: 12),
                          const Row(
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
                          const SizedBox(height: 8),
                          ..._buildAvailabilityWidgets(clinic.availability!),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
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

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
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

  Widget _buildClinicInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
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

  List<Widget> _buildAvailabilityWidgets(Map<String, dynamic> availability) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.where((day) => availability[day] != null).map((day) {
      final times = availability[day];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 32),
        child: Row(
          children: [
            Container(
              width: 100,
              child: Text(
                day,
                style: const TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildRatingRow(String label, String rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Text(
            rating,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  String _obscureName(String name) {
    if (name.isEmpty || name == 'Anonymous') return 'Anonymous';
    final parts = name.split(' ');
    if (parts.length == 1) return '${parts[0][0]}***';
    return '${parts[0][0]}*** ${parts.last[0]}***';
  }
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
              color: Colors.grey[700],
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

class DoctorReviewsScreen extends StatelessWidget {
  final String doctorId;
  final String doctorName;

  const DoctorReviewsScreen({
    required this.doctorId,
    required this.doctorName,
    Key? key,
  }) : super(key: key);

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctor_reviews')
          .doc(reviewId)
          .delete();
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

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

          return GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.0, // Adjust this value to change card height
            ),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              try {
                final review = reviews[index].data() as Map<String, dynamic>;
                final reviewId = reviews[index].id;
                final date = review['createdAt'] != null
                    ? (review['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                final formattedDate = DateFormat('MMM d, y').format(date);

                return Card(
                  elevation: 5,

                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    review['patientName']?.toString() ?? 'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
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
                              Expanded(
                                child: Text(

                                  review['feedback'].toString(),
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                if (review['doctorRating'] != null)
                                  Chip(
                                    label: Text(
                                      'Dr: ${review['doctorRating'].toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.all(5),
                                  ),
                                if (review['clinicRating'] != null)
                                  Chip(
                                    label: Text(
                                      'Clinic: ${review['clinicRating'].toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.all(5),
                                  ),
                                if (review['staffRating'] != null)
                                  Chip(
                                    label: Text(
                                      'Staff: ${review['staffRating'].toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.orange,
                                    padding: EdgeInsets.all(5),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(Icons.delete, size: 30, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Review'),
                                content: Text('Are you sure you want to delete this review?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              try {
                                await _deleteReview(reviewId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Review deleted successfully')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete review: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                return Card(
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
