// lib/features/event_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utm_around/Features/club_profile.dart';
import 'package:utm_around/Features/notification_service.dart';

class EventDetails extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetails({super.key, required this.eventId, required this.eventData});

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isAttending = false;
  bool _isLoadingRSVP = true;

  @override
  void initState() {
    super.initState();
    _checkRSVPStatus();
  }

  // --- CHECK IF USER IS ALREADY GOING ---
  Future<void> _checkRSVPStatus() async {
    if (user == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List<dynamic> attendees = data['attendees'] ?? [];
        
        if (mounted) {
          setState(() {
            _isAttending = attendees.contains(user!.uid);
            _isLoadingRSVP = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRSVP = false);
    }
  }

  DateTime? _getEventDateTime(String dateStr, String timeStr) {
    try {
      // Date format is usually DD/MM/YYYY
      List<String> dateParts = dateStr.split('/');
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      // Time format (Assuming standard 24h format "14:30" or 12h "2:30 PM")
      // Simple parse for "HH:mm"
      int hour = 0;
      int minute = 0;
      
      // Let's clean the string just in case
      timeStr = timeStr.replaceAll(RegExp(r'[^0-9:]'), ''); 
      List<String> timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null; // Return null if parsing fails
    }
  }

  // --- TOGGLE RSVP IN FIRESTORE ---
  Future<void> _toggleRSVP() async {
    if (user == null) return;
    
    // Optimistic UI update (feels faster to the user!)
    setState(() {
      _isAttending = !_isAttending;
      _isLoadingRSVP = true; // Show loading spinner on button
    });

    try {
      DocumentReference eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);

      if (_isAttending) {
        // 1. Add them to the attendees list
        await eventRef.update({'attendees': FieldValue.arrayUnion([user!.uid])});
        
        // 2. Fetch their notification preferences from Firestore!
        DocumentSnapshot userPrefs = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        var userData = userPrefs.data() as Map<String, dynamic>?;
        
        bool notifyPush = userData?['notifyPush'] ?? true;
        List<dynamic> timings = userData?['notifyTimings'] ?? [30, 60]; // Default if they haven't set it

        // 3. Schedule the specific Push Notifications
        DateTime? eventDateTime = _getEventDateTime(widget.eventData['date'] ?? '', widget.eventData['time'] ?? '');
        
        if (eventDateTime != null && notifyPush) {
          String eventTitle = widget.eventData['title'] ?? 'Your event';
          
          for (int minutes in timings) {
            // Generate a unique ID for this specific event and timing
            int notificationId = "${widget.eventId}_$minutes".hashCode;
            
            String timeLabel = "";
            if (minutes == 30) timeLabel = "30 minutes";
            else if (minutes == 60) timeLabel = "1 hour";
            else if (minutes == 1440) timeLabel = "1 day";
            else if (minutes == 4320) timeLabel = "3 days";

            NotificationService().scheduleNotification(
              id: notificationId,
              title: "Reminder: $eventTitle",
              body: "This event is starting in $timeLabel!",
              scheduledTime: eventDateTime.subtract(Duration(minutes: minutes)),
            );
          }
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RSVP Successful! 🎉"), backgroundColor: Colors.green));
      
      } else {
        // Remove them from the list
        await eventRef.update({'attendees': FieldValue.arrayRemove([user!.uid])});
        
        // Cancel all possible notifications for this event just to be safe
        List<int> allPossibleTimings = [30, 60, 1440, 4320];
        for (int minutes in allPossibleTimings) {
          NotificationService().cancelNotification("${widget.eventId}_$minutes".hashCode);
        }

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("RSVP Cancelled."), backgroundColor: Colors.grey));
      }
    } catch (e) {
      // Revert UI if it failed
      setState(() => _isAttending = !_isAttending);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingRSVP = false);
    }
  }

  // Function to launch external links securely
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the link."), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Function to open the phone's dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch phone dialer."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.eventData;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. STICKY BOTTOM RSVP BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAttending ? Colors.grey[300] : utmMaroon,
                foregroundColor: _isAttending ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _isAttending ? 0 : 2,
              ),
              onPressed: _isLoadingRSVP ? null : _toggleRSVP,
              child: _isLoadingRSVP
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      _isAttending ? "Cancel RSVP" : "RSVP Now", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
      
      // 2. SCROLLABLE CONTENT WITH HERO IMAGE
      body: CustomScrollView(
        slivers: [
          // The collapsing poster image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: utmMaroon,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty
                  ? Image.network(data['posterUrl'], fit: BoxFit.cover)
                  : Container(
                      color: utmMaroon.withValues(alpha: 0.8),
                      child: const Center(child: Icon(Icons.event, color: Colors.white, size: 80)),
                    ),
            ),
          ),

          // The Event Details text
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Multiple Tags Wrap
                  if (data['tags'] != null) 
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (data['tags'] as List).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: utmMaroon.withValues(alpha: 0.1), 
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: utmMaroon.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(color: utmMaroon, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),

                  // Title
                  Text(
                    data['title'] ?? 'Untitled Event',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 24),

                  // Info Rows (Date, Time, Location)
                  _buildInfoRow(Icons.calendar_today, "Date", data['date'] ?? 'TBA'),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.access_time, 
                    "Time", 
                    data['endTime'] != null && data['endTime'].toString().isNotEmpty
                        ? "${data['time'] ?? 'TBA'} - ${data['endTime']}"
                        : (data['time'] ?? 'TBA'),
                  ),
                  _buildInfoRow(Icons.location_on, "Location", data['location'] ?? 'TBA'),
                  const SizedBox(height: 12),
                  
                  // NEW: DYNAMIC ACTION BUTTON FOR LINKS
                  if (data['link'] != null && data['link'].toString().isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: utmMaroon,
                          side: const BorderSide(color: utmMaroon),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                        icon: Icon(data['mode'] == 'Online' ? Icons.video_camera_front : Icons.map),
                        label: Text(data['mode'] == 'Online' ? "Join Meeting" : "Open in Google Maps"),
                        onPressed: () => _launchURL(data['link']),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // --- NEW: HOSTED BY SECTION ---
                  if (data['clubId'] != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(data['clubId']).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                        
                        var clubData = snapshot.data!.data() as Map<String, dynamic>;
                        
                        return GestureDetector(
                          onTap: () {
                            // Navigate to the new Club Profile Page!
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ClubProfilePage(clubId: data['clubId'])),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: clubData['profilePic'] != null && clubData['profilePic'].toString().isNotEmpty
                                      ? NetworkImage(clubData['profilePic'])
                                      : null,
                                  backgroundColor: utmMaroon.withValues(alpha: 0.1),
                                  child: clubData['profilePic'] == null || clubData['profilePic'].toString().isEmpty
                                      ? const Icon(Icons.groups, color: utmMaroon)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Hosted by", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(clubData['name'] ?? 'Unknown Club', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Description
                  const Text("About this Event", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    data['description'] ?? 'No description provided.',
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 32), // Extra padding for scrolling

                  // --- CONTACT PERSONS SECTION ---
                  if (data['contact'] != null && (data['contact'] as List).isNotEmpty) ...[
                    const Text("For Inquiries, Contact:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    ...List.generate((data['contact'] as List).length, (index) {
                      var contact = data['contact'][index] as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: utmMaroon.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: utmMaroon),
                          ),
                          title: Text(contact['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(contact['phone'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => _makePhoneCall(contact['phone'] ?? ''), // Launches dialer!
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for the beautiful icon rows
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: utmMaroon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: utmMaroon, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}