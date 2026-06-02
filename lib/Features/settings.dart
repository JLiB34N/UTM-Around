import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/Features/edit_profile.dart';
import 'package:utm_around/Features/register_event.dart';
import 'package:utm_around/Features/club_event_history.dart';
import 'package:utm_around/Features/my_rsvp.dart';
import 'package:utm_around/Features/feed_preference.dart';
import 'package:utm_around/Features/notification_preference.dart';
import 'package:utm_around/constant.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Future<void> _updateFirestore(String uid, String field, dynamic value) async {
  //   await FirebaseFirestore.instance.collection('users').doc(uid).update({
  //     field: value,
  //   });
  // }

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

  //  // --- PREFERENCES BOTTOM SHEET ---
  // void _showPreferencesSheet(BuildContext context, String uid, List<dynamic> currentPrefs) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setModalState) {
  //           return Padding(
  //             padding: const EdgeInsets.all(24.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text("Feed Preferences", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: utmMaroon)),
  //                 const SizedBox(height: 8),
                  
  //                 // 1. Updated the helper text so the user knows the rule!
  //                 const Text("Select up to 3 categories to personalize your feed.", style: TextStyle(color: Colors.grey)),
                  
  //                 const SizedBox(height: 16),
  //                 Wrap(
  //                   spacing: 8.0,
  //                   children: eventCategories.map((tag) {
  //                     bool isSelected = currentPrefs.contains(tag);
  //                     return FilterChip(
  //                       label: Text(tag),
  //                       selected: isSelected,
  //                       selectedColor: utmMaroon.withValues(alpha: 0.2),
  //                       checkmarkColor: utmMaroon,
  //                       onSelected: (bool selected) {
                          
  //                         // 2. THE LIMIT LOGIC
  //                         if (selected && currentPrefs.length >= 3) {
  //                           // Close the bottom sheet briefly so the user can clearly see the error
  //                           Navigator.pop(context); 
                            
  //                           ScaffoldMessenger.of(context).showSnackBar(
  //                             const SnackBar(
  //                               content: Text("You can only select a maximum of 3 preferences."),
  //                               backgroundColor: Colors.red,
  //                               duration: Duration(seconds: 2),
  //                             ),
  //                           );
  //                           return; // Stop the code here so it doesn't add the 4th tag
  //                         }

  //                         // 3. Normal logic (if under the limit or deselecting)
  //                         setModalState(() {
  //                           if (selected) {
  //                             currentPrefs.add(tag);
  //                           } else {
  //                             currentPrefs.remove(tag);
  //                           }
  //                         });
                          
  //                         // Save to Firestore in the background
  //                         _updateFirestore(uid, 'preferences', currentPrefs);
  //                       },
  //                     );
  //                   }).toList(),
  //                 ),
  //                 const SizedBox(height: 30),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // // --- NOTIFICATIONS BOTTOM SHEET ---
  // void _showNotificationsSheet(BuildContext context, String uid, String notifType, int notifDays) {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setModalState) {
  //           return Padding(
  //             padding: const EdgeInsets.all(24.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text("Notification Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: utmMaroon)),
  //                 const SizedBox(height: 20),
  //                 ListTile(
  //                   contentPadding: EdgeInsets.zero,
  //                   title: const Text("Notify via"),
  //                   trailing: DropdownButton<String>(
  //                     underline: const SizedBox(),
  //                     value: notifType,
  //                     items: const [
  //                       DropdownMenuItem(value: 'none', child: Text("None")),
  //                       DropdownMenuItem(value: 'email', child: Text("Email")),
  //                       DropdownMenuItem(value: 'app', child: Text("App Notification")),
  //                     ],
  //                     onChanged: (val) {
  //                       if (val != null) {
  //                         setModalState(() => notifType = val);
  //                         _updateFirestore(uid, 'notificationType', val);
  //                       }
  //                     },
  //                   ),
  //                 ),
  //                 const Divider(),
  //                 ListTile(
  //                   contentPadding: EdgeInsets.zero,
  //                   title: const Text("Remind me"),
  //                   trailing: DropdownButton<int>(
  //                     underline: const SizedBox(),
  //                     value: notifDays,
  //                     items: const [
  //                       DropdownMenuItem(value: 1, child: Text("1 Day before")),
  //                       DropdownMenuItem(value: 3, child: Text("3 Days before")),
  //                       DropdownMenuItem(value: 7, child: Text("7 Days before")),
  //                     ],
  //                     onChanged: (val) {
  //                       if (val != null) {
  //                         setModalState(() => notifDays = val);
  //                         _updateFirestore(uid, 'notificationDays', val);
  //                       }
  //                     },
  //                   ),
  //                 ),
  //                 const SizedBox(height: 30),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  //------------------------------------------------------------------------------------------------------------
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
          
          // Using List.from to ensure we have a modifiable copy of the list
          // List<dynamic> userPrefs = List.from(userData['preferences'] ?? []); 
          // String notifType = userData['notificationType'] ?? 'none'; 
          // int notifDays = userData['notificationDays'] ?? 1; 

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
                    Text(userData['name'] ?? 'User Name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                    // Navigate to the History page!
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
            ],
          );
        },
      ),
    );
  }
}