import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  BookingsScreen({Key? key, required this.doctorId, required this.doctorName}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = 'all';
  Map<String, int> _statusCounts = {
    'all': 0,
    'pending': 0,
    'confirmed': 0,
    'completed': 0,
    'declined': 0,
  };

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('Bookings')
        .where('doctorId', isEqualTo: widget.doctorId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _updateStatusCounts(snapshot.docs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.doctorName}`s Bookings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Bookings')
                  .where('doctorId', isEqualTo: widget.doctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading bookings', style: TextStyle(color: Colors.red)));
                }

                final bookings = snapshot.data?.docs ?? [];
                final filteredBookings = _filterBookings(bookings);

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No bookings found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: filteredBookings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index].data() as Map<String, dynamic>;
                      final bookingId = filteredBookings[index].id;
                      return BookingCard(booking: booking, bookingId: bookingId);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatusCounts(List<QueryDocumentSnapshot> bookings) {
    final counts = {
      'all': bookings.length,
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'declined': 0,
    };

    for (var booking in bookings) {
      final status = (booking.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
      if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }

    if (mounted) {
      setState(() {
        _statusCounts = counts;
      });
    }
  }

  List<QueryDocumentSnapshot> _filterBookings(List<QueryDocumentSnapshot> bookings) {
    if (_selectedFilter == 'all') {
      return bookings;
    }
    return bookings.where((booking) {
      final status = (booking.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
      return status == _selectedFilter;
    }).toList();
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
        child: Row(
          children: [
            _buildFilterButton('All', 'all'),
            _buildFilterButton('Pending', 'pending'),
            _buildFilterButton('Confirmed', 'confirmed'),
            _buildFilterButton('Completed', 'completed'),
            _buildFilterButton('Declined', 'declined'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    final count = _statusCounts[value] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.deepOrange,
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.deepOrange : Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.deepOrange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? Colors.deepOrange : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final String bookingId;

  BookingCard({required this.booking, required this.bookingId});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = booking['paymentStatus']?.toString().toLowerCase() == 'paid';
    final isCompleted = booking['status']?.toString().toLowerCase() == 'completed';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with patient name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking['childName'] ?? 'Patient Name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    booking['status']?.toUpperCase() ?? 'STATUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(booking['status'] ?? 'pending'),
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Payment status
            if (isPaid)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Payment completed',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (booking['paidAt'] != null)
                      Text(
                        ' on ${_formatDateTime(booking['paidAt'])}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

            // Clinic information
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                      booking['clinicName'] ?? 'Clinic Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                    ),
                )
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  booking['clinicAddress'] ?? 'Clinic Address',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Divider
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 5),

            // Patient information
            Row(
              children: [
                Icon(Icons.person, size: 18, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Patient: ${booking['childName'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 16),
                Icon(Icons.family_restroom_sharp, size: 18, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  booking['gender'] ?? 'N/A',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 5),

            // Contact information
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.deepOrange),
                SizedBox(width: 5),
                Text(
                  'Contact: ${booking['contactNumber'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 5),

            // Divider
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 5),

            // Appointment details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(booking['date']),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        booking['time'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Payment amount
            Row(
              children: [
                Icon(Icons.money, size: 18, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Amount: PKR ${booking['fees'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Created at information
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Booked on ${_formatDateTime(booking['createdAt'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM dd, yyyy hh:mm a').format(timestamp.toDate());
  }
}