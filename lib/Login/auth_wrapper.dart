import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Dashboard/Dashboard.dart';
import 'Login.dart';

class AuthWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _verifyAdmin(String email) async {
    try {
      DocumentSnapshot adminDoc = await _firestore
          .collection('admin')
          .doc(email)
          .get();
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          } else {
            // Verify if user is admin
            return FutureBuilder<bool>(
              future: _verifyAdmin(user.email!),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.done) {
                  if (adminSnapshot.data == true) {
                    return AdminDashboard();
                  } else {
                    // Not an admin, sign out and show login screen
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _auth.signOut();
                    });
                    return LoginScreen();
                  }
                } else {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            );
          }
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}