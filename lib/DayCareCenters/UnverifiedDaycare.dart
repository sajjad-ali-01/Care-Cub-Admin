import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;

import '../Dashboard/Dashboard.dart';

class UnverifiedDaycareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unverified Daycare',style: TextStyle(color: Colors.white),),
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
              .where('isVerified', isEqualTo: false)
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

  @override
  void initState() {
    super.initState();
    isVerified = widget.DaycareData['isVerified'] ?? false;
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
              MaterialPageRoute(builder: (context) => UnverifiedDaycareScreen()),
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
                          _buildStatItem(Icons.star, '${widget.DaycareData['rating'] ?? '0.0'}', 'Rating'),
                          SizedBox(width: 20),
                          _buildStatItem(Icons.people, '${widget.DaycareData['childs'] ?? '0'}+', 'childs'),
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
}