import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utm_around/Features/full_screen_image_viewer.dart'; 

class ClubEventHistory extends StatefulWidget {
  const ClubEventHistory({super.key});

  @override
  State<ClubEventHistory> createState() => _ClubEventsPageState();
}

class _ClubEventsPageState extends State<ClubEventHistory> {
  final User? user = FirebaseAuth.instance.currentUser;

  // --- CLUB EVENT PREVIEW ---
  void _showEventPreview(BuildContext context, Map<String, dynamic> data) {
    // Determine status colors for the badge
    Color statusColor = Colors.orange;
    String status = data['status']?.toString().toLowerCase() ?? 'pending';
    if (status == 'approved') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    // --- EXTRACTION LOGIC FOR PAYMENT ---
    final paymentType = data['paymentType'] ?? 'Free';
    final bool isPaid = paymentType == 'Paid';
    final paymentColor = isPaid ? Colors.orange : Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], 
                      borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(data['title'] ?? 'No Title', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // --- DYNAMIC TAGS WRAP ---
                  if (data['tag'] != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (data['tag'] as List).where((tag) => tag.toString().toLowerCase() != (data['mode']?.toString().toLowerCase() ?? 'physical')).map((tag) {
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
                    const SizedBox(height: 12),
                  ],

                  // --- BADGES (Mode, Fee, Status) ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Mode Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', 
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                      
                      // Payment Fee Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: paymentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          paymentType.toUpperCase(),
                          style: TextStyle(color: paymentColor[800], fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                      
                      // Status Badge (Pending/Approved/Rejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- VIEW ATTENDEES BUTTON ---
                  if (status == 'approved') ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.people, color: Colors.blue),
                        title: Text("${(data['attendees'] ?? []).length} Students Registered", style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                        onTap: () {
                          // Pass the attendees array to our new modal!
                          _showAttendeeList(context, data['attendees'] ?? []);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- Rejection Reason if Rejected ---
                  if (status == 'rejected' && data['rejectionReason'] != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), border: Border.all(color: Colors.red.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text("Reason for Rejection", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(data['rejectionReason'], style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Basic Info
                  _buildPreviewRow(Icons.calendar_today, "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}"),
                  const SizedBox(height: 12),
                  _buildPreviewRow(Icons.location_on, data['location'] ?? 'No Location'),
                  const SizedBox(height: 12),
                  _buildPreviewRow(data['mode'] == 'Online' ? Icons.video_call : Icons.info_outline, data['mode'] ?? 'Physical'), // Added Mode row
                  const SizedBox(height: 12),
                  
                  if (data['link'] != null && data['link'].toString().isNotEmpty)
                    _buildPreviewRow(
                      data['mode'] == 'Online' ? Icons.link : Icons.map, 
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
                  if (data['contact'] != null && (data['contact'] as List).isNotEmpty)
                    ...List.generate((data['contact'] as List).length, (index) {
                      var person = data['contact'][index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: utmMaroon),
                            const SizedBox(width: 8),
                            Text("${person['name']} • ${person['phone']}", style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      );
                    })
                  else
                    const Text("No contacts provided.", style: TextStyle(color: Colors.red)),

                  const SizedBox(height: 48), // Bottom bumper
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ATTENDEE LIST MODAL ---
  void _showAttendeeList(BuildContext context, List<dynamic> attendeeUids) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 16),
                // Drag handle
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                
                // Header
                Text("${attendeeUids.length} Registered Students", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: utmMaroon)),
                const Divider(height: 30),

                // List of Students
                Expanded(
                  child: attendeeUids.isEmpty
                      ? const Center(child: Text("No students have registered yet.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: attendeeUids.length,
                          itemBuilder: (context, index) {
                            String uid = attendeeUids[index];

                            // Fetch user profile from Firestore
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const ListTile(
                                    leading: CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                                    title: Text("Loading student..."),
                                  );
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return const ListTile(title: Text("Unknown User"));
                                }

                                var userData = snapshot.data!.data() as Map<String, dynamic>;
                                
                                String name = userData['name'] ?? userData['displayName'] ?? 'No Name Provided';
                                String email = userData['email'] ?? 'No Email';
                                String phone = userData['phone'] ?? 'No Phone Number';
                                String programme = userData['programme'] ?? 'Course not set';
                                String residency = userData['residency'] ?? 'Residential not set';

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: utmMaroon.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: utmMaroon),
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  
                                  // --- DISPLAY ---
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text("🎓 $programme  •  🏠 $residency", style: const TextStyle(color: utmMaroon, fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text("✉️ $email", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text("📞 $phone", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
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
          child: GestureDetector(
            // --- CLICKABLE ---
            onTap: isLink ? () async {
              // Try to format the text into a proper URL
              String urlString = text;
              if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
                urlString = 'https://$urlString';
              }
              
              final Uri url = Uri.parse(urlString);
              
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint("Could not launch link: $e");
              }
            } : null, 
            
            child: Text(
              text, 
              style: TextStyle(
                fontSize: 15, 
                color: isLink ? Colors.blue : Colors.black87, 
                decoration: isLink ? TextDecoration.underline : TextDecoration.none
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Not logged in")));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Registered Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: utmMaroon,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. We ONLY fetch events created by this specific club!
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('clubId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("FIREBASE ERROR: ${snapshot.error}"); 
          return Center(child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center)); 
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));

          var events = snapshot.data!.docs;

          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("You haven't registered for any events yet.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // 2. Sort them LOCALLY by newest first
          events.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp? aTime = aData['createdAt'] as Timestamp?;
            Timestamp? bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); 
          });

          // --- RESCHEDULE EVENT DIALOG ---
          Future<void> rescheduleEvent(String docId, String title) async {
            DateTime? pickedDate;
            TimeOfDay? pickedStartTime;
            TimeOfDay? pickedEndTime;
            bool isSubmitting = false;

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text("Reschedule Event", style: TextStyle(fontWeight: FontWeight.bold, color: utmMaroon)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Update the date and time for '$title'.", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 20),

                          // 1. DATE PICKER
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today, color: utmMaroon),
                            title: Text(pickedDate == null 
                                ? "Select New Date" 
                                : "${pickedDate!.day.toString().padLeft(2, '0')}/${pickedDate!.month.toString().padLeft(2, '0')}/${pickedDate!.year}"),
                            onTap: () async {
                              DateTime? date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) setDialogState(() => pickedDate = date);
                            },
                          ),

                          // 2. START TIME PICKER
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.access_time, color: utmMaroon),
                            title: Text(pickedStartTime == null ? "Select Start Time" : pickedStartTime!.format(context)),
                            onTap: () async {
                              TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) setDialogState(() => pickedStartTime = time);
                            },
                          ),

                          // 3. END TIME PICKER
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.access_time_filled, color: utmMaroon),
                            title: Text(pickedEndTime == null ? "Select End Time" : pickedEndTime!.format(context)),
                            onTap: () async {
                              TimeOfDay? time = await showTimePicker(
                                context: context,
                                initialTime: pickedStartTime ?? TimeOfDay.now(),
                              );
                              if (time != null) setDialogState(() => pickedEndTime = time);
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: utmMaroon, foregroundColor: Colors.white),
                          onPressed: isSubmitting ? null : () async {
                            if (pickedDate == null || pickedStartTime == null || pickedEndTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a date, start time, and end time!"), backgroundColor: Colors.red));
                              return;
                            }

                            setDialogState(() => isSubmitting = true);

                            // Format the date "DD/MM/YYYY"
                            String formattedDate = "${pickedDate!.day.toString().padLeft(2, '0')}/${pickedDate!.month.toString().padLeft(2, '0')}/${pickedDate!.year}";
                    
                            // Format the times (e.g., "10:00 AM")
                            String formattedStartTime = pickedStartTime!.format(context);
                            String formattedEndTime = pickedEndTime!.format(context);

                            // Update Firestore with the new times!
                            await FirebaseFirestore.instance.collection('events').doc(docId).update({
                              'date': formattedDate,
                              'time': formattedStartTime,
                              'endTime': formattedEndTime, 
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event rescheduled successfully!"), backgroundColor: Colors.green));
                            }
                          },
                          child: isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Confirm"),
                        ),
                      ],
                    );
                  }
                );
              }
            );
          }

          // --- UPDATE LOCATION & LINK DIALOG ---
          Future<void> _showUpdateLocationDialog(BuildContext context, String docId, Map<String, dynamic> data) async {
            final bool isOnline = data['mode'] == 'Online';
            TextEditingController locationController = TextEditingController(text: data['location'] ?? (isOnline ? 'Online Meeting' : ''));
            TextEditingController linkController = TextEditingController(text: data['link'] ?? '');
            bool isSubmitting = false;

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text("Update Location", style: TextStyle(color: utmMaroon, fontWeight: FontWeight.bold)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: locationController,
                            decoration: InputDecoration(
                              labelText: isOnline ? "Platform (e.g., Webex, Zoom)" : "Venue Name",
                              prefixIcon: Icon(isOnline ? Icons.video_call : Icons.location_on, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: linkController,
                            decoration: InputDecoration(
                              labelText: isOnline ? "Meeting Link" : "Google Maps Link",
                              prefixIcon: const Icon(Icons.link, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context), 
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: utmMaroon, foregroundColor: Colors.white),
                          onPressed: isSubmitting ? null : () async {
                            setDialogState(() => isSubmitting = true);
                            
                            // Update Firestore
                            await FirebaseFirestore.instance.collection('events').doc(docId).update({
                              'location': locationController.text.trim(),
                              'link': linkController.text.trim(),
                            });
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location successfully updated!"), backgroundColor: Colors.green));
                            }
                          },
                          child: isSubmitting 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text("Update"),
                        ),
                      ],
                    );
                  }
                );
              }
            );
          }
          // ------------------------------------------

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              var doc = events[index]; 
              var data = doc.data() as Map<String, dynamic>;
              
              String status = data['status'] ?? 'pending';
              String rejectionReason = data['rejectionReason'] ?? 'No reason provided by admin.';

              // 1. GET THE RSVP COUNT HERE
              List<dynamic> attendees = data['attendees'] ?? [];
              int rsvpCount = attendees.length;

              // --- EXTRACTION FOR CARD ---
              String paymentType = data['paymentType'] ?? 'Free';
              MaterialColor paymentColor = paymentType == 'Paid' ? Colors.orange : Colors.green;
              // ----------------------------------

              // Determine Badge Colors
              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.pending_actions;
              if (status == 'approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              }

              // WRAP THE CARD IN A GESTURE DETECTOR
              return GestureDetector(
                onTap: () => _showEventPreview(context, data),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        
                        // --- 1. NEW MAIN COLUMN ---
                        // We wrap the whole padding interior in a Column so the 
                        // top half (Image+Info) and bottom half (Buttons) stack perfectly!
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            // --- TOP HALF: POSTER & EVENT INFO ---
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Poster Thumbnail
                                if (data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FullScreenImageViewer(
                                            imageUrl: data['posterUrl'],
                                            heroTag: 'poster_${doc.id}', 
                                          ),
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: 'poster_${doc.id}',
                                      child: Container(
                                        width: 70, height: 70,
                                        margin: const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(image: NetworkImage(data['posterUrl']), fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 70, height: 70,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.event, color: Colors.grey),
                                  ),
                              
                                // Event Info (Right Side of Poster)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Untitled Event', 
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}", 
                                        style: const TextStyle(color: utmMaroon, fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Badges Row
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4, 
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(statusIcon, size: 14, color: statusColor),
                                                const SizedBox(width: 4),
                                                Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text(data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: paymentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: paymentColor.withValues(alpha: 0.3))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(paymentType == 'Paid' ? Icons.monetization_on_outlined : Icons.money_off, size: 14, color: paymentColor[800]),
                                                const SizedBox(width: 4),
                                                Text(paymentType.toUpperCase(), style: TextStyle(color: paymentColor[800], fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // RSVP BADGE
                                      if (status == 'approved')
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.people, size: 16, color: utmMaroon),
                                            const SizedBox(width: 4),
                                            Text("$rsvpCount Attending", style: const TextStyle(color: utmMaroon, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ), // <--- END OF TOP HALF ROW

                            // --- BOTTOM HALF: FULL WIDTH ACTION BUTTONS ---
                            // Because these are placed AFTER the row closes, they get the full width of the screen!
                            if (status == 'approved') ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        side: const BorderSide(color: Colors.blue),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.calendar_month, size: 16),
                                      label: const Text("Edit Date", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onPressed: () => rescheduleEvent(events[index].id, data['title'] ?? 'Event'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange[700],
                                        side: BorderSide(color: Colors.orange[700]!),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.edit_location_alt, size: 16),
                                      label: const Text("Edit Location", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      onPressed: () => _showUpdateLocationDialog(context, doc.id, data),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),

                      // --- REJECTION REASON BOX ---
                      if (status == 'rejected')
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.05),
                            border: Border(top: BorderSide(color: Colors.red.withValues(alpha: 0.2))),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                  SizedBox(width: 6),
                                  Text("Admin Feedback:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(rejectionReason, style: const TextStyle(color: Colors.black87, fontSize: 13)),
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
    );
  }
}