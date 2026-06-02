// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:utm_around/Login/auth_wrapper.dart';
import 'Features/notification_service.dart';

// Define your global UTM Maroon color here so it's accessible anywhere if needed
const Color utmMaroon = Color(0xFF981D2D);

void main() async {
  // Required to ensure Flutter framework is fully loaded before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Make sure you've added google-services.json to your android/app folder!)
  await Firebase.initializeApp();

  // Initialize Notifications
  await NotificationService().init();
  
  runApp(const UTMAroundApp());
}

class UTMAroundApp extends StatelessWidget {
  const UTMAroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTM Around',
      
      // Set this to false cuz examiners hate seeing the "DEBUG" banner during a demo!
      debugShowCheckedModeBanner: false, 
      
      // Global Theme Settings
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: utmMaroon,
          primary: utmMaroon,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: utmMaroon,
          foregroundColor: Colors.white, // Makes the back buttons and text white
          elevation: 0,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      
      // The first screen the app attempts to load
      home: const AuthWrapper(), 
    );
  }
}