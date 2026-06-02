// lib/features/club_profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:utm_around/Features/event_details.dart';

class ClubProfilePage extends StatelessWidget {
  final String clubId;

  const ClubProfilePage({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Club Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: utmMaroon,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(clubId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: utmMaroon));
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Club not found."));

          var clubData = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              // --- CLUB INFO HEADER ---
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: utmMaroon.withValues(alpha: 0.1),
                        backgroundImage: clubData['profilePic'] != null && clubData['profilePic'].toString().isNotEmpty
                            ? NetworkImage(clubData['profilePic'])
                            : null,
                        child: clubData['profilePic'] == null || clubData['profilePic'].toString().isEmpty
                            ? const Icon(Icons.groups, size: 50, color: utmMaroon)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(clubData['name'] ?? 'Unknown Club', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      
                      const SizedBox(height: 24),
                      if (clubData['description'] != null && clubData['description'].toString().isNotEmpty) ...[
                        const Align(alignment: Alignment.centerLeft, child: Text("About Us", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: Text(clubData['description'], style: const TextStyle(color: Colors.black87, height: 1.5))),
                        const SizedBox(height: 24),
                      ],

                      if (clubData['ajk'] != null && clubData['ajk'].toString().isNotEmpty) ...[
                        const Align(alignment: Alignment.centerLeft, child: Text("Committee (AJK)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: Text(clubData['ajk'], style: const TextStyle(color: Colors.black54, height: 1.5))),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // --- CLUB'S EVENTS SECTION ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text("Organized Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // Fetch this club's approved events!
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('clubId', isEqualTo: clubId)
                    .where('status', isEqualTo: 'approved') // Only show approved ones publicly!
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  if (!eventSnapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  var events = eventSnapshot.data!.docs;
                  if (events.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Text("No public events found.")));

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var doc = events[index];
                        var data = doc.data() as Map<String, dynamic>;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            backgroundImage: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty ? NetworkImage(data['posterUrl']) : null,
                            child: data['posterUrl'] == null || data['posterUrl'].toString().isEmpty ? const Icon(Icons.event, color: Colors.grey) : null,
                          ),
                          title: Text(data['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                          
                          // Safely checks for date, time, and endTime so it never says "null"
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}",
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              
                              // --- NEW: CATEGORY & MODE ROW ---
                              Row(
                                children: [
                                  // ONLY SHOW CATEGORY IF IT EXISTS
                                  if (data['category'] != null && data['category'].toString().trim().isNotEmpty) ...[
                                    Text(
                                      data['category'].toString().toUpperCase(),
                                      style: const TextStyle(fontSize: 11, color: utmMaroon, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text("•", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(width: 6),
                                  ],
                                  
                                  // ALWAYS SHOW MODE (Physical / Online)
                                  Text(
                                    data['mode']?.toString().toUpperCase() ?? 'PHYSICAL',
                                    style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // -----------------------
                          
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetails(eventId: doc.id, eventData: data)));
                          },
                        );
                      },
                      childCount: events.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}