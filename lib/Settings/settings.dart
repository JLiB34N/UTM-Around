import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/Settings/edit_profile.dart';
import 'package:utm_around/Settings/register_event.dart';
import 'package:utm_around/Settings/club_event_history.dart';
import 'package:utm_around/Settings/my_rsvp.dart';
import 'package:utm_around/Settings/feed_preference.dart';
import 'package:utm_around/Settings/notification_preference.dart';
import 'package:utm_around/constant.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // --- CUSTOM BUTTON WIDGET ---
  Widget _buildActionButton({required IconData icon, required String title, required VoidCallback onTap, Color color = utmMaroon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 2,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: Icon(icon, size: 24),
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        onPressed: onTap,
      ),
    );
  }

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(title: const Text("Settings"), backgroundColor: utmMaroon),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));
          
          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String role = userData['role'] ?? 'student';

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // 1. PROFILE HEADER
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45, 
                      backgroundColor: utmMaroon.withValues(alpha: 0.2),
                      backgroundImage: userData['profilePic'] != null && userData['profilePic'].toString().isNotEmpty 
                          ? NetworkImage(userData['profilePic']) 
                          : null,
                      child: userData['profilePic'] == null || userData['profilePic'].toString().isEmpty 
                          ? const Icon(Icons.person, size: 40, color: utmMaroon) 
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(userData['name'] ?? 'User Name', 
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,)),
                    Text(role.toUpperCase(), style: const TextStyle(color: Colors.grey, letterSpacing: 1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. APP SETTINGS
              const Text("App Settings", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              // Preferences Button (Students Only)
              if (role == 'student') 
                _buildActionButton(
                  icon: Icons.tune, 
                  title: "Feed Preferences", 
                  onTap: () {//=> _showPreferencesSheet(context, user.uid, userPrefs)
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const FeedPreferencesPage())
                    );
                  }
                ),

              // Notifications Button (Students Only)
              if (role == 'student') 
                _buildActionButton(
                  icon: Icons.notifications_active_outlined, 
                  title: "Notifications", 
                  onTap: () {//=> _showNotificationsSheet(context, user.uid, notifType, notifDays)
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const NotificationPreferences()));
                  }
                ),

              const SizedBox(height: 20),

              // 3. ACCOUNT ACTIONS
              const Text("My Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              
              _buildActionButton(
                icon: Icons.edit_document, 
                title: "Edit Profile", 
                onTap: () { 
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const EditProfile()),
                  );
                }
              ),

              if (role == 'student') 
                _buildActionButton(
                  icon: Icons.event_available, 
                  title: "My RSVPs", 
                  onTap: () { 
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyRSVP()),
                    );
                  }
                ),

              if (role == 'club') ...[
                _buildActionButton(
                  icon: Icons.add_box, 
                  title: "Register New Event", 
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterEvent()),
                    );
                  }
                ),
                _buildActionButton(
                  icon: Icons.format_list_bulleted, 
                  title: "My Registered Events", 
                  onTap: () { 
                    // Navigate to the History page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClubEventHistory()),
                    ); }
                ),
              ],
              
              const SizedBox(height: 30),

              // 4. LOGOUT BUTTON
              _buildActionButton(
                icon: Icons.logout, 
                title: "Log Out", 
                color: Colors.red,
                onTap: () => FirebaseAuth.instance.signOut(),
              ),

              // 5. SUPPORT / BUG REPORT FOOTER 
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Encountered a bug or need help?",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        // Creates a pre-filled email draft
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'admin123@utm.my', 
                          query: 'subject=UTM Around App Bug Report', 
                        );
                        try {
                          await launchUrl(emailLaunchUri);
                        } catch (e) {
                          debugPrint("Could not launch email: $e");
                        }
                      },
                      child: const Text(
                        "Email: admin123@utm.my",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40), 
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}