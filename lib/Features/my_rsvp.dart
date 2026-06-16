import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:utm_around/Features/event_details.dart';

class MyRSVP extends StatefulWidget {
  const MyRSVP({super.key});

  @override
  State<MyRSVP> createState() => _MyRSVPState();
}

class _MyRSVPState extends State<MyRSVP> {
  final User? user = FirebaseAuth.instance.currentUser;

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
          if (isPM && hour < 12) hour += 12;
          else if (!isPM && hour == 12) hour = 0;
        }
      }

      return DateTime(year, month, day, hour, minute).isBefore(DateTime.now());
    } catch (e) {
      return false; 
    }
  }

  // Helper to parse "DD/MM/YYYY" into Dart DateTime
  DateTime? _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Reusable widget to build the list of events
  Widget _buildEventList(List<DocumentSnapshot> events, String emptyMessage) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        var doc = events[index];
        var data = doc.data() as Map<String, dynamic>;

        // --- NEW: EXTRACTION LOGIC ---
        final paymentType = data['paymentType'] ?? 'Free';
        final bool isPaid = paymentType == 'Paid';
        final paymentColor = isPaid ? Colors.orange : Colors.green;
        final paymentIcon = isPaid ? Icons.monetization_on_outlined : Icons.money_off_outlined;
        // -----------------------------

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetails(eventId: doc.id, eventData: data))),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            // 1. Wrap the whole Row in padding so it breathes!
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 90, height: 90, // Shrunk slightly to account for the new padding
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      // 2. Round ALL corners uniformly
                      borderRadius: BorderRadius.circular(8), 
                      image: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty
                          ? DecorationImage(image: NetworkImage(data['posterUrl']), fit: BoxFit.cover)
                          : null,
                    ),
                    child: data['posterUrl'] == null || data['posterUrl'].toString().isEmpty
                        ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                  ),
                  
                  // 3. Add a clean gap between the image and the text
                  const SizedBox(width: 16), 
                  
                  Expanded(
                    // Removed the old Padding here because the outer Row handles it now
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Untitled', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis
                        ),
                        const SizedBox(height: 8),
                        
                        // Date + Time Row
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text("${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}", style: const TextStyle(color: utmMaroon, fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // --- UPDATED: Mode + Category + Payment Badge ---
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(data['mode'] == 'Online' ? Icons.video_call : Icons.location_on, size: 14, color: Colors.grey),
                            Text(data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                            
                            if (data['category'] != null && data['category'].toString().isNotEmpty) ...[
                              const Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                              Text(data['category'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                            
                            // FREE | PAID BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: paymentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: paymentColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(paymentIcon, size: 10, color: paymentColor[800]),
                                  const SizedBox(width: 2),
                                  Text(
                                    paymentType.toUpperCase(),
                                    style: TextStyle(color: paymentColor[800], fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // ------------------------------------------------
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("My RSVPs", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: utmMaroon,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          // FIREBASE MAGIC: Find all events where this user's ID is inside the 'attendees' list!
          stream: FirebaseFirestore.instance.collection('events').where('attendees', arrayContains: user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Error loading RSVPs."));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));

            var allEvents = snapshot.data!.docs;

            List<DocumentSnapshot> upcomingEvents = [];
            List<DocumentSnapshot> pastEvents = [];

            //DateTime todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

            // 1. Sort into buckets based on the date
            for (var doc in allEvents) {
                var data = doc.data() as Map<String, dynamic>;

                // --- CHANGED THIS IF STATEMENT ---
                if (_isEventPassed(data['date'], data['time'])) {
                  pastEvents.add(doc); // Event is dead, send to history
                } else {
                  upcomingEvents.add(doc); // Event is alive, send to upcoming
                }
            }

            // 2. Pro-Tip: Sort the lists for the best User Experience!
            // Upcoming: Closest date first (Ascending)
            upcomingEvents.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              DateTime dateA = _parseDate(dataA['date'] ?? '') ?? DateTime(2099);
              DateTime dateB = _parseDate(dataB['date'] ?? '') ?? DateTime(2099);
              return dateA.compareTo(dateB);
            });

            // History: Most recent past event first (Descending)
            pastEvents.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              DateTime dateA = _parseDate(dataA['date'] ?? '') ?? DateTime(2000);
              DateTime dateB = _parseDate(dataB['date'] ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA); 
            });

            return TabBarView(
              children: [
                _buildEventList(upcomingEvents, "You have no upcoming RSVPs."),
                _buildEventList(pastEvents, "You haven't attended any events yet."),
              ],
            );
          },
        ),
      ),
    );
  }
}