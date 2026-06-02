// lib/features/admin_home_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color utmMaroon = Color(0xFF981D2D);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  
  // Helper function to parse "DD/MM/YYYY" to Dart DateTime
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

  // Action: Approve Event
  Future<void> _updateEventStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('events').doc(docId).update({
      'status': status,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Event $status!"), 
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        )
      );
    }
  }

  // --- ADMIN EVENT PREVIEW ---
  void _showEventPreview(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take up more screen space
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Starts at 60% of the screen
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Little drag handle at the top
                  Center(
                    child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),

                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(data['title'] ?? 'No Title', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: utmMaroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(data['mode'] ?? 'Physical', style: const TextStyle(color: utmMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Basic Info
                  _buildPreviewRow(Icons.calendar_today, "${data['date']} at ${data['time']}"),
                  const SizedBox(height: 12),
                  _buildPreviewRow(Icons.location_on, data['location'] ?? 'No Location'),
                  const SizedBox(height: 12),
                  
                  // Show the link depending on the mode!
                  if (data['link'] != null && data['link'].toString().isNotEmpty)
                    _buildPreviewRow(
                      data['mode'] == 'Online' ? Icons.video_call : Icons.map, 
                      data['link'],
                      isLink: true,
                    ),
                  
                  const Divider(height: 40),

                  // Description
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(data['description'] ?? 'No description.', style: const TextStyle(fontSize: 15, height: 1.5)),
                  
                  const Divider(height: 40),

                  // Contacts
                  const Text("Contact Persons", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 12),
                  if (data['contacts'] != null)
                    ...List.generate((data['contacts'] as List).length, (index) {
                      var contact = data['contacts'][index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: utmMaroon),
                            const SizedBox(width: 8),
                            Text("${contact['name']} • ${contact['phone']}", style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      );
                    })
                  else
                    const Text("No contacts provided.", style: TextStyle(color: Colors.red)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget for the preview rows
  Widget _buildPreviewRow(IconData icon, String text, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(fontSize: 15, color: isLink ? Colors.blue : Colors.black87, decoration: isLink ? TextDecoration.underline : TextDecoration.none),
          ),
        ),
      ],
    );
  }

  // Action: Show popup to provide a rejection reason
  Future<void> _showRejectDialog(String docId) async {
    TextEditingController reasonController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false, // Forces them to click a button to close it
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Reject Event", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Please provide a reason so the club can fix their application.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "e.g., Venue is already booked for this date...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: isSubmitting ? null : () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must provide a reason!"), backgroundColor: Colors.red));
                      return;
                    }

                    setDialogState(() => isSubmitting = true);

                    // Update Firestore with the new status AND the reason!
                    await FirebaseFirestore.instance.collection('events').doc(docId).update({
                      'status': 'rejected',
                      'rejectionReason': reasonController.text.trim(), // Save the reason here!
                    });

                    if (mounted) {
                      Navigator.pop(context); // Close the dialog
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event Rejected"), backgroundColor: Colors.red));
                    }
                  },
                  child: isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Confirm Rejection"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  // Reusable Widget for Summary Cards
  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  // Reusable Widget for the List of Events (so we don't repeat code!)
  Widget _buildEventList(List<DocumentSnapshot> events, bool showActions) {
    if (events.isEmpty) {
      return const Center(child: Text("No events found in this category.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        var doc = events[index];
        var data = doc.data() as Map<String, dynamic>;

        // Determine status color
        Color statusColor = Colors.orange;
        if (data['status'] == 'approved') statusColor = Colors.green;
        if (data['status'] == 'rejected') statusColor = Colors.red;

        return GestureDetector(
          onTap: () => _showEventPreview(context, data), // Opens the preview panel!
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty)
                        Container(
                          width: 60, height: 60,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(image: NetworkImage(data['posterUrl']), fit: BoxFit.cover),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['title'] ?? 'No Title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${data['date']} • ${data['time']}", style: TextStyle(color: utmMaroon, fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['mode'] ?? 'Physical', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)), // Added mode here!
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    data['status']?.toString().toUpperCase() ?? 'PENDING', 
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Action buttons
                  if (showActions) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                            onPressed: () => _showRejectDialog(doc.id),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            icon: const Icon(Icons.check),
                            label: const Text("Approve"),
                            onPressed: () => _updateEventStatus(doc.id, 'approved'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hint for the admin
                    const Center(
                      child: Text("Tap card to review full details before approving", style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic)),
                    ),
                  ]
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
    // 1. Wrap the whole Scaffold in a DefaultTabController
    return DefaultTabController(
      length: 3, // We have 3 tabs
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Admin Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: utmMaroon,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => FirebaseAuth.instance.signOut(),
            )
          ],
          // 2. Add the TabBar to the bottom of the AppBar
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Dashboard"),
              Tab(text: "Upcoming"),
              Tab(text: "History"),
            ],
          ),
        ),
        
        // 3. One StreamBuilder handles data for ALL tabs
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));

            final events = snapshot.data!.docs;
            
            // Create buckets for our data
            List<DocumentSnapshot> pendingEvents = [];
            List<DocumentSnapshot> upcomingEvents = [];
            List<DocumentSnapshot> pastEvents = [];

            // Stats variables
            int ongoingTodayCount = 0;
            int upcomingThisWeekCount = 0;
            DateTime todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
            DateTime nextWeek = todayMidnight.add(const Duration(days: 7));

            // 4. Sort every event into the correct bucket
            for (var doc in events) {
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';
              DateTime? eventDate = _parseDate(data['date'] ?? '');

              if (status == 'pending') {
                pendingEvents.add(doc);
              } else {
                // If it's processed (Approved/Rejected), check the date
                if (eventDate != null) {
                  if (eventDate.isBefore(todayMidnight)) {
                    pastEvents.add(doc); // It happened in the past
                  } else {
                    upcomingEvents.add(doc); // It happens today or in the future
                    
                    // Add to stats if it's approved
                    if (status == 'approved') {
                      if (eventDate.isAtSameMomentAs(todayMidnight)) ongoingTodayCount++;
                      if (eventDate.isAfter(todayMidnight) && eventDate.isBefore(nextWeek)) upcomingThisWeekCount++;
                    }
                  }
                }
              }
            }

            // 5. Build the TabBarView
            return TabBarView(
              children: [
                
                // --- TAB 1: DASHBOARD (Summary + Pending) ---
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _buildSummaryCard("Pending Approval", pendingEvents.length.toString(), Icons.pending_actions, Colors.orange),
                            _buildSummaryCard("Ongoing Today", ongoingTodayCount.toString(), Icons.event_available, Colors.green),
                            _buildSummaryCard("Starts This Week", upcomingThisWeekCount.toString(), Icons.date_range, Colors.blue),
                            _buildSummaryCard("Total Past Events", pastEvents.length.toString(), Icons.history, utmMaroon),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(thickness: 1, height: 1)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("Pending Approvals (${pendingEvents.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // We use SliverFillRemaining so the list takes up the rest of the scroll view
                    SliverFillRemaining(
                      child: _buildEventList(pendingEvents, true), // TRUE = Show approve/reject buttons
                    ),
                  ],
                ),

                // --- TAB 2: UPCOMING EVENTS (Approved/Rejected) ---
                _buildEventList(upcomingEvents, false), // FALSE = Hide buttons

                // --- TAB 3: PAST EVENTS ---
                _buildEventList(pastEvents, false), // FALSE = Hide buttons

              ],
            );
          },
        ),
      ),
    );
  }
}