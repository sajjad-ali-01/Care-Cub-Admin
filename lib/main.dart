import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'Login/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAWMk9TCWycDJtQ-eUPbIPp46C18nV-TO8",
      authDomain: "care-cub.firebaseapp.com",
      projectId: "care-cub",
      storageBucket: "care-cub.appspot.com",
      messagingSenderId: "913168016292",
      appId: "1:913168016292:web:22fa035c7a87b154511731",
      measurementId: "G-TRH27068R0",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
    );
  }
}
