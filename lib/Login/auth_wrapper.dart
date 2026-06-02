// lib/auth_wrapper.dart (STUDENT APP)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:utm_around/Features/dashboard_screen.dart'; 

const Color utmMaroon = Color(0xFF981D2D);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the user's login state in real-time
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        
        // 1. Waiting for Firebase to respond
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: utmMaroon)),
          );
        }
        
        // 2. User is logged in!
        if (authSnapshot.hasData && authSnapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).get(),
            builder: (context, userSnapshot) {
              
              // 1. Waiting state
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: utmMaroon)),
                );
              }

              // 2. Error state (just in case the database is unreachable)
              if (userSnapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text("Error loading profile. Please restart the app.")),
                );
              }
              
              // 3. Document EXISTS (Check role and route/block)
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String role = userSnapshot.data!['role'] ?? 'student';
                
                // --- ADMIN REJECTION BLOCK ---
                if (role == 'admin') {
                  return Scaffold(
                    backgroundColor: Colors.white,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.block, color: Colors.red, size: 60),
                          const SizedBox(height: 16),
                          const Text("Access Denied", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: utmMaroon)),
                          const SizedBox(height: 8),
                          const Text("Pls enter a proper club email.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: utmMaroon,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            child: const Text("Go Back", style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // If they are a student or club, let them in!
                return const DashboardScreen(); 
              }
              
              // 4. Document DOES NOT EXIST (First time logging in)
              if (userSnapshot.hasData && !userSnapshot.data!.exists) {
                 FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).set({
                  'role': 'student',
                  'name': authSnapshot.data!.displayName ?? 'New Student',
                  'email': authSnapshot.data!.email ?? '',
                  'profilePic': authSnapshot.data!.photoURL ?? '',
                  'faculty': 'Not set',
                  'preferences': [],
                  'notificationType': 'none', 
                  'notificationDays': 1,
                });
                
                return const DashboardScreen(); 
              }

              // 5. THE CATCH-ALL FALLBACK (This fixes your error!)
              // If literally none of the above match, just show a loading spinner.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: utmMaroon)),
              );
            },
          );
        }
        
        // 3. User is NOT logged in. Send them to the Login Page.
        return const LoginPage(); 
      },
    );
  }
}