import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:utm_around/Features/event_details.dart';

class MainFeed extends StatefulWidget {
  const MainFeed({super.key});

  @override
  State<MainFeed> createState() => _MainFeedState();
}

class _MainFeedState extends State<MainFeed> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<String> _userPreferredTags = [];

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
  }

  Future<void> _fetchUserPreferences() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userPreferredTags = List<String>.from(data['preferredTags'] ?? []);
          });
        }
      }
    }
  }

  bool _isEventPassed(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    
    try {
      List<String> dateParts = dateStr.split('/');
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      int hour = 23;
      int minute = 59;

      if (timeStr != null && timeStr.isNotEmpty) {
        bool isPM = timeStr.toUpperCase().contains('PM');
        String cleanTime = timeStr.replaceAll(RegExp(r'[^0-9:]'), '');
        List<String> timeParts = cleanTime.split(':');
        
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
          if (isPM && hour < 12) {
            hour += 12;
          }
          else if (!isPM && hour == 12) {
            hour = 0;
          }
        }
      }

      DateTime eventDate = DateTime(year, month, day, hour, minute);
      return eventDate.isBefore(DateTime.now());
    } catch (e) {
      return false; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "UTM Around Events",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: utmMaroon,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- WELCOME HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: utmMaroon,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user?.displayName?.split(' ')[0] ?? 'Student'}! 👋", 
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Discover what's happening around campus.", 
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // --- EVENT FEED ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // fetch all events ordered by newest first
              stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading feed."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));

                // Filter the events locally!
                var allEvents = snapshot.data!.docs;
                var approvedUpcomingEvents = allEvents.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String status = data['status'] ?? 'pending';
                  
                  // ONLY keep it if it is Approved AND hasn't happened yet
                  return status == 'approved' && !_isEventPassed(data['date'], data['time']);
                }).toList();

                // --- SUPER-SORTING LOGIC ---
                // Put preferred events at the top, then sort by newest
                approvedUpcomingEvents.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;

                  if (_userPreferredTags.isNotEmpty) {
                    // 1. Safely grab the 'tag' field and force it to UPPERCASE so it matches
                    List<dynamic> rawTagsA = dataA['tag'] ?? [];
                    List<String> tagsA = rawTagsA.map((t) => t.toString().trim().toUpperCase()).toList();

                    List<dynamic> rawTagsB = dataB['tag'] ?? [];
                    List<String> tagsB = rawTagsB.map((t) => t.toString().trim().toUpperCase()).toList();

                    // 2. Check if event has a preferred tag
                    bool aHasPreferred = tagsA.any((tag) => _userPreferredTags.contains(tag));
                    bool bHasPreferred = tagsB.any((tag) => _userPreferredTags.contains(tag));

                    // 3. Move preferred events to the top
                    if (aHasPreferred && !bHasPreferred) return -1; // A moves up
                    if (!aHasPreferred && bHasPreferred) return 1; // B moves up
                  }

                  // 4. TIE-BREAKER: If both are preferred (or neither are), sort by newest
                  Timestamp? timeA = dataA['createdAt'] as Timestamp?;
                  Timestamp? timeB = dataB['createdAt'] as Timestamp?;
                  
                  if (timeA != null && timeB != null) {
                    return timeB.compareTo(timeA); // Descending (Newest first)
                  }
                  return 0; 
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: approvedUpcomingEvents.length,
                  itemBuilder: (context, index) {
                    var doc = approvedUpcomingEvents[index];
                    var data = doc.data() as Map<String, dynamic>;

                    // --- CORRECT LOCATION FOR EXTRACTION LOGIC ---
                    // This logic now runs once per item, making the variables available for the Card
                    // Extract paymentType and define style locally
                    // Use modern green for Free and Orange for Paid to align with standard UI patterns
                    final paymentType = data['paymentType'] ?? 'Free'; // Default to free for safety/legacy events
                    final bool isPaid = paymentType == 'Paid';
                    final paymentColor = isPaid ? Colors.orange : Colors.green;
                    final paymentIcon = isPaid ? Icons.monetization_on_outlined : Icons.money_off_outlined;

                    return GestureDetector(
                      onTap: () {
                        // Navigate to the Details Page, passing the specific Document ID and Data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetails(
                              eventId: doc.id, // Need this to save the RSVP in the right place
                              eventData: data, // Passes the data so the next page loads instantly
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        clipBehavior: Clip.antiAlias, // Ensures the image respects the rounded corners
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. POSTER IMAGE
                            if (data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty)
                              Image.network(
                                data['posterUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180, width: double.infinity, color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                                ),
                              )
                            else
                              Container( // Fallback if no poster is provided
                                height: 120, width: double.infinity, color: utmMaroon.withValues(alpha: 0.1),
                                child: const Icon(Icons.event, color: utmMaroon, size: 50),
                              ),

                            // --- EVENT DETAILS ---
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8, // Horizontal spacing between badges
                                    runSpacing: 4, // Vertical spacing if it wraps to a new line
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      // ONLY SHOW CATEGORY IF IT ACTUALLY EXISTS
                                      if (data['category'] != null && data['category'].toString().trim().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: utmMaroon.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            data['category'].toString().toUpperCase(),
                                            style: const TextStyle(color: utmMaroon, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        
                                      // --- Mode Tag (Physical/Online) ---
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          data['mode']?.toString().toUpperCase() ?? 'PHYSICAL',
                                          style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),

                                      // --- PAYMENT TYPE BADGE ---
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: paymentColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: paymentColor.withValues(alpha: 0.3)), // Subtle border for definition
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min, // Container tight around content
                                          children: [
                                            Icon(paymentIcon, size: 12, color: paymentColor[800]), // Darker shade for contrast
                                            const SizedBox(width: 4),
                                            Text(
                                              paymentType.toUpperCase(),
                                              style: TextStyle(color: paymentColor[800], fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // --- Title ---
                                  Text(
                                    data['title'] ?? 'Untitled Event',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // --- Date & Time ---
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "${data['date']} • ${data['time']} - ${data['endTime'] ?? 'TBA'}", 
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  
                                  // --- Location ---
                                  Row(
                                    children: [
                                      Icon(
                                        data['mode'] == 'Online' ? Icons.video_call : Icons.location_on_outlined, 
                                        size: 16, color: Colors.grey
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          data['mode'] == 'Online' ? 'Online Platform' : (data['location'] ?? 'TBA'), 
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                 ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}