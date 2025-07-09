import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch the count of pending doctors
  Future<int> getPendingDoctorsCount() async {
    final querySnapshot = await _firestore
        .collection('Doctors')
        .where('isVerified', isEqualTo: false)
        .get();
    return querySnapshot.docs.length;
  }
  Future<int> getPendingDayCare() async {
    final querySnapshot = await _firestore
        .collection('DayCare')
        .where('isVerified', isEqualTo: false)
        .get();
    return querySnapshot.docs.length;
  }
  // Fetch the count of active parents
  Future<int> getActiveParentsCount() async {
    final querySnapshot = await _firestore
        .collection('users')
        .get();
    return querySnapshot.docs.length;
  }
  Future<int> getActiveDaycareCount() async {
    final querySnapshot = await _firestore
        .collection('DayCare')
        .where('isVerified', isEqualTo: true)
        .get();
    return querySnapshot.docs.length;
  }


  // Fetch the count of active doctors
  Future<int> getActiveDoctorsCount() async {
    final querySnapshot = await _firestore
        .collection('Doctors')
        .where('isVerified', isEqualTo: true)
        .get();
    return querySnapshot.docs.length;
  }

  // Fetch the count of daycare centers
  Future<int> getDaycareCentersCount() async {
    final querySnapshot = await _firestore.collection('DayCare').get();
    return querySnapshot.docs.length;
  }

  // Calculate the percentage of each user type
  Future<Map<String, double>> getUserDistributionPercentages() async {
    final parentsCount = await getActiveParentsCount();
    final daycareCount = await getDaycareCentersCount();
    final doctorsCount = await getActiveDoctorsCount();
    final totalUsers = parentsCount + daycareCount + doctorsCount;

    if (totalUsers == 0) {
      return {
        'parents': 0.0,
        'daycare': 0.0,
        'doctors': 0.0,
      };
    }

    return {
      'parents': (parentsCount / totalUsers) * 100,
      'daycare': (daycareCount / totalUsers) * 100,
      'doctors': (doctorsCount / totalUsers) * 100,
    };
  }
  Future<int> getPendingReportsCount() async {
    try {
      final snapshot = await _firestore.collection('reports')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.size;
    } catch (e) {
      print('Error getting pending reports count: $e');
      return 0;
    }
  }

}