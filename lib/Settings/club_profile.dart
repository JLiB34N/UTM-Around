import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:utm_around/Features/event_details.dart';
import 'package:url_launcher/url_launcher.dart';

class ClubProfile extends StatelessWidget {
  final String clubId;

  const ClubProfile({super.key, required this.clubId});

  // --- URL LAUNCHER ---
  Future<void> _launchSocialLink(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) return;
    
    // Auto-fix if forgot the https://
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }
    
    final Uri url = Uri.parse(urlString);
    try {
      // Forcefully open the browser.
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch link: $e");
    }
  }

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

                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          clubData['name'] ?? 'Unknown Club', 
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2), 
                          textAlign: TextAlign.center, 
                        ),
                      ),
                      
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
                      const SizedBox(height: 24),

                      // --- FOLLOW US SECTION ---
                      Builder(
                        builder: (context) {
                          // Extract the links
                          String ig = clubData['ig'] ?? '';
                          String xLink = clubData['x'] ?? '';
                          String fb = clubData['fb'] ?? '';
                          String web = clubData['website'] ?? '';

                          // Hide the entire section if the club left everything blank
                          if (ig.isEmpty && xLink.isEmpty && fb.isEmpty && web.isEmpty) {
                            return const SizedBox.shrink(); 
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Align(
                                alignment: Alignment.centerLeft, 
                                child: Text("Follow Us", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start, // Align to the left
                                children: [
                                  if (ig.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.pink, size: 28),
                                      onPressed: () => _launchSocialLink(ig),
                                    ),
                                  if (xLink.isNotEmpty)
                                    IconButton(
                                      icon: const Text("𝕏", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                                      onPressed: () => _launchSocialLink(xLink),
                                    ),
                                  if (fb.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.facebook, color: Colors.blue, size: 28),
                                      onPressed: () => _launchSocialLink(fb),
                                    ),
                                  if (web.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.language, color: Colors.green, size: 28),
                                      onPressed: () => _launchSocialLink(web),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }
                      ),
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

                        // --- EXTRACTION LOGIC ---
                        final paymentType = data['paymentType'] ?? 'Free';
                        final bool isPaid = paymentType == 'Paid';
                        final paymentColor = isPaid ? Colors.orange : Colors.green;
                        final paymentIcon = isPaid ? Icons.monetization_on_outlined : Icons.money_off_outlined;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty ? NetworkImage(data['posterUrl']) : null,
                              child: data['posterUrl'] == null || data['posterUrl'].toString().isEmpty ? const Icon(Icons.event, color: Colors.grey) : null,
                            ),
                            title: Text(data['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                            
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}",
                                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                
                                // --- Mode + Category + Payment Badge ---
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                    
                                    if (data['category'] != null && 
                                        data['category'].toString().trim().isNotEmpty &&
                                        data['category'].toString().toLowerCase() != (data['mode']?.toString().toLowerCase() ?? 'physical')) ...[
                                      
                                      const Text("•", style: TextStyle(color: Colors.grey, fontSize: 10)),
                                      Text(data['category'].toString().toUpperCase(), style: const TextStyle(color: utmMaroon, fontSize: 11, fontWeight: FontWeight.bold)),
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
                              ],
                            ),
                            
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetails(eventId: doc.id, eventData: data)));
                            },
                          ),
                        );
                      },
                      childCount: events.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }
}