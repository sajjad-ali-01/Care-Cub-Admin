import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import '../Dashboard/Dashboard.dart';

class verifiedDaycareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verified Daycare',style: TextStyle(color: Colors.white),),
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
              .collection('DayCare')
              .where('isVerified', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading daycare center',
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
                      'No unverified Daycare found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final Daycare = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: Daycare.length,
              itemBuilder: (context, index) {
                final Daycares = Daycare[index].data()! as Map<String, dynamic>;
                final DaycaresId = Daycare[index].id;

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
                          builder: (context) => DaycaresDetailsScreen(
                            DaycareData: Daycares,
                            DaycaresId: DaycaresId,
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
                            backgroundImage: Daycares['profileImageUrl'] != null &&
                                Daycares['profileImageUrl'].isNotEmpty
                                ? NetworkImage(Daycares['profileImageUrl'])
                                : AssetImage('assets/default_Daycares.png') as ImageProvider,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${Daycares['name']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  Daycares['email'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
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
                            child: Icon(Icons.verified, color: Colors.white, size: 20),),
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

class DaycaresDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> DaycareData;
  final String DaycaresId;

  const DaycaresDetailsScreen({
    required this.DaycareData,
    required this.DaycaresId,
  });

  @override
  State<DaycaresDetailsScreen> createState() => _DaycaresDetailsScreenState();
}

class _DaycaresDetailsScreenState extends State<DaycaresDetailsScreen> {
  // In the DaycaresDetailsScreen class, add this state variable
  bool isVerified = false;
  late var totalReviews;
  double overallRating = 0.0;

  @override
  void initState() {
    super.initState();
    isVerified = widget.DaycareData['isVerified'] ?? false;
    _loadRating();
  }
  void _loadRating() async {
    double rating = await getOverallRating(widget.DaycaresId);
    if (mounted) {
      setState(() {
        overallRating = rating;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.DaycareData['name']} profile',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => verifiedDaycareScreen()),
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
                              backgroundImage: widget.DaycareData['profileImageUrl'] != null &&
                                  widget.DaycareData['profileImageUrl'].isNotEmpty
                                  ? NetworkImage(widget.DaycareData['profileImageUrl'])
                                  : AssetImage('assets/default_Daycares.png') as ImageProvider,
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
                        '${widget.DaycareData['name']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Specialist",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatItem(Icons.star, '${overallRating.toStringAsFixed(1)}', 'Rating'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.people, '${widget.DaycareData['childs'] ?? '100'}+', 'childs'),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Also update the verify button to be disabled when already verified
                          ElevatedButton.icon(
                            icon: Icon(Icons.verified_user, size: 20),
                            label: Text(isVerified ? 'Verified' : 'Verify Daycare',style: TextStyle(color: Colors.black),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isVerified ? Colors.grey : Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: isVerified ? null : () {
                              _verifyDaycares(context);
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
                              final email = widget.DaycareData['email'] ?? '';
                              if (email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Daycare email not available')),
                                );
                                return;
                              }

                              final subject = Uri.encodeComponent('Care Cub Registration Inquiry - ${widget.DaycareData['name']}');
                              final body = Uri.encodeComponent('Dear. ${widget.DaycareData['name']}, Daycare`s manager\n\n');

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
                      _buildInfoRow(Icons.email, 'Email', widget.DaycareData['email'] ?? 'N/A'),
                      _buildInfoRow(Icons.phone, 'Phone', widget.DaycareData['phone'] ?? 'N/A'),
                      _buildInfoRow(Icons.location_city, 'Address', widget.DaycareData['address'] ?? 'N/A'),
                      _buildInfoRow(
                        Icons.date_range,
                        'Registered On',
                        widget.DaycareData['createdAt'] != null
                            ? DateFormat('MMMM dd, yyyy').format((widget.DaycareData['createdAt'] as Timestamp).toDate())
                            : 'N/A',
                      ),
                      _buildInfoRow(Icons.medical_information, 'Licence number', widget.DaycareData['license'] ?? 'N/A'),
                    ],
                  ),
                  ReviewCard(),

                  // Specializations
                  _buildSectionTitle('Description'),
                  _buildInfoCard(
                    children: [
                      _buildInfoRow(Icons.description,'',widget.DaycareData['description'] ?? 'N/A'),
                    ],
                  ),
                  _buildGallerySection(),
                  _buildSectionTitle('safetyFeatures'),
                  if (widget.DaycareData['safetyFeatures'] != null)
                    _buildInfoCard(
                      children: List<String>.from(widget.DaycareData['safetyFeatures'])
                          .map((condition) => _buildInfoRow(Icons.health_and_safety, 'Condition', condition))
                          .toList(),
                    ),
                  _buildSectionTitle('Facilities'),
                  if (widget.DaycareData['facilities'] != null)
                    _buildInfoCard(
                      children: List<String>.from(widget.DaycareData['facilities'])
                          .map((condition) => _buildInfoRow(Icons.discount, 'facility', condition))
                          .toList(),
                    ),
                  _buildSectionTitle('Programs'),
                  if (widget.DaycareData['programs'] != null)
                    _buildInfoCard(
                      children: List<Map<String, dynamic>>.from(widget.DaycareData['programs'])
                          .map((program) => _buildInfoRow(Icons.school, 'Program', program['name'] ?? ''))
                          .toList(),
                    ),

                  // Clinics Information
                  _buildSectionTitle('Availability'),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('DayCare')
                        .doc(widget.DaycaresId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Error loading availability: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Text('No availability information found');
                      }

                      final daycareData = snapshot.data!.data() as Map<String, dynamic>;

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
                              if (daycareData['operatingDays'] != null && daycareData['operatingDays'] is List)
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Operating Days',
                                  (daycareData['operatingDays'] as List).join(', '),
                                ),

                              if (daycareData['hours'] != null)
                                _buildInfoRow(
                                  Icons.access_time,
                                  'Hours',
                                  daycareData['hours'].toString(),
                                ),

                              // If you have more complex availability data structure
                              if (daycareData['Availability'] != null)
                                ..._buildAvailabilityWidgets(daycareData['Availability']),
                            ],
                          ),
                        ),
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
  Widget _buildGallerySection() {
    if (widget.DaycareData['galleryImages'] == null ||
        (widget.DaycareData['galleryImages'] as List).isEmpty) {
      return SizedBox.shrink();
    }

    final galleryImages = List<String>.from(widget.DaycareData['galleryImages']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gallery'),
        SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showImagePreview(context, galleryImages, index);
                },
                child: Container(
                  width: 150,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(galleryImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _showImagePreview(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3,
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildAvailabilityWidgets(dynamic availability) {
    if (availability == null) return [SizedBox.shrink()];

    final widgets = <Widget>[];

    if (availability is Map) {
      // Handle map format availability
      if (availability['days'] != null) {
        widgets.add(
          _buildInfoRow(
            Icons.calendar_today,
            'Days',
            availability['days'] is List
                ? (availability['days'] as List).join(', ')
                : availability['days'].toString(),
          ),
        );
      }

      if (availability['hours'] != null) {
        widgets.add(
          _buildInfoRow(
            Icons.access_time,
            'Hours',
            availability['hours'].toString(),
          ),
        );
      }

      if (availability['timeSlots'] != null && availability['timeSlots'] is List) {
        widgets.addAll(
          (availability['timeSlots'] as List).map((slot) =>
              _buildInfoRow(
                Icons.schedule,
                slot['day'] ?? 'Time',
                '${slot['startTime']} - ${slot['endTime']}',
              ),
          ).toList(),
        );
      }
    }
    else if (availability is String) {
      // Handle simple string format
      widgets.add(
        _buildInfoRow(
          Icons.access_time,
          'Availability',
          availability,
        ),
      );
    }

    return widgets;
  }
  void _verifyDaycares(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verify Daycares'),
        content: Text('Are you sure you want to verify this Daycares?'),
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
                  .collection('DayCare')
                  .doc(widget.DaycaresId)
                  .update({'isVerified': true})
                  .then((_) {
                setState(() {
                  isVerified = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Daycare verified successfully!'),
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
          .collection('DaycareReviews')
          .where('daycareId', isEqualTo: widget.DaycaresId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading reviews'));
        }

        final reviews = snapshot.data?.docs ?? [];
        totalReviews = reviews.length;

        // Calculate average ratings
        double DaycareRatingTotal = 0;
        double clinicRatingTotal = 0;
        double staffRatingTotal = 0;

        for (var review in reviews) {
          final data = review.data() as Map<String, dynamic>;
          DaycareRatingTotal += (data['daycareRating'] as num).toDouble();
          clinicRatingTotal += (data['facilitiesRating'] as num).toDouble();
          staffRatingTotal += (data['staffRating'] as num).toDouble();
        }

        final avgDaycareRating = totalReviews > 0 ? (DaycareRatingTotal / totalReviews) : 0;
        final avgClinicRating = totalReviews > 0 ? (clinicRatingTotal / totalReviews) : 0;
        final avgStaffRating = totalReviews > 0 ? (staffRatingTotal / totalReviews) : 0;
        final overallRating = totalReviews > 0
            ? ((avgDaycareRating + avgClinicRating + avgStaffRating) / 3)
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
                          "${widget.DaycareData['name']}'s Reviews",
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
                        RatingRow("DayCare Center", "${avgDaycareRating.toStringAsFixed(1)}/5"),
                        RatingRow("facilities Rating", "${avgClinicRating.toStringAsFixed(1)}/5"),
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
                        builder: (context) => DaycareReviewsScreen(
                          DaycareId: widget.DaycaresId,
                          DaycareName: widget.DaycareData['name'],
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
  Future<double> getOverallRating(String doctorId) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore
        .collection('DaycareReviews')
        .where('daycareId', isEqualTo: doctorId)
        .get();

    final reviews = snapshot.docs;
    final totalReviews = reviews.length;

    if (totalReviews == 0) return 0.0;

    double doctorRatingTotal = 0;
    double clinicRatingTotal = 0;
    double staffRatingTotal = 0;

    for (var review in reviews) {
      final data = review.data();
      doctorRatingTotal += (data['daycareRating'] as num).toDouble();
      clinicRatingTotal += (data['facilitiesRating'] as num).toDouble();
      staffRatingTotal += (data['staffRating'] as num).toDouble();
    }

    final avgDoctorRating = doctorRatingTotal / totalReviews;
    final avgClinicRating = clinicRatingTotal / totalReviews;
    final avgStaffRating = staffRatingTotal / totalReviews;

    return (avgDoctorRating + avgClinicRating + avgStaffRating) / 3;
  }
}
class DaycareReviewsScreen extends StatelessWidget {
  final String DaycareId;
  final String DaycareName;

  const DaycareReviewsScreen({
    required this.DaycareId,
    required this.DaycareName,
    Key? key,
  }) : super(key: key);

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('DaycareReviews')
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
        title: Text('$DaycareName Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('DaycareReviews')
            .where('daycareId', isEqualTo: DaycareId)
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
                                    review['parentName']?.toString() ?? 'Anonymous',
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
                                if (review['daycareRating'] != null)
                                  Chip(
                                    label: Text(
                                      'Daycare: ${review['daycareRating'].toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.blue,
                                    padding: EdgeInsets.all(5),
                                  ),
                                if (review['staffRating'] != null)
                                  Chip(
                                    label: Text(
                                      'staff Rating: ${review['staffRating'].toStringAsFixed(1)}',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.all(5),
                                  ),
                                if (review['facilitiesRating'] != null)
                                  Chip(
                                    label: Text(
                                      'facilities: ${review['facilitiesRating'].toStringAsFixed(1)}',
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