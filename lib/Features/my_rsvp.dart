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

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetails(eventId: doc.id, eventData: data))),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Row(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    image: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty
                        ? DecorationImage(image: NetworkImage(data['posterUrl']), fit: BoxFit.cover)
                        : null,
                  ),
                  child: data['posterUrl'] == null || data['posterUrl'].toString().isEmpty
                      ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? 'Untitled', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        // Date + Time Row
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(child: Text("${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}", style: const TextStyle(color: utmMaroon, fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Mode + Category Row
                        Row(
                          children: [
                            Icon(data['mode'] == 'Online' ? Icons.video_call : Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                            if (data['category'] != null) ...[
                              const Text(" • ", style: TextStyle(color: Colors.grey)),
                              Text(data['category'].toString().toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

            DateTime todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

            // 1. Sort into buckets based on the date
            for (var doc in allEvents) {
                var data = doc.data() as Map<String, dynamic>;
                DateTime? eventDate = _parseDate(data['date'] ?? '');

              if (eventDate != null) {
                if (eventDate.isBefore(todayMidnight)) {
                  pastEvents.add(doc);
                } else {
                  upcomingEvents.add(doc);
                }
              }
            }

            // 2. Pro-Tip: Sort the lists for the best User Experience!
            // Upcoming: Closest date first (Ascending)
            // 2. Safe Sorting
            upcomingEvents.sort((a, b) {
              var dataA = a.data() as Map<String, dynamic>;
              var dataB = b.data() as Map<String, dynamic>;
              DateTime dateA = _parseDate(dataA['date'] ?? '') ?? DateTime(2099);
              DateTime dateB = _parseDate(dataB['date'] ?? '') ?? DateTime(2099);
              return dateA.compareTo(dateB);
            });

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