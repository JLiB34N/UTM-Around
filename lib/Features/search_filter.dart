// lib/features/search_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';
import 'package:utm_around/Features/event_details.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = "";
  
  // 1. Change from a single DateTime to a DateTimeRange!
  DateTimeRange? _selectedDateRange;

  // --- SHOW DATE RANGE PICKER ---
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2023), // Allow searching past events too!
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: utmMaroon, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  // --- CLEAR DATE FILTER ---
  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  // Helper to check if the event falls BETWEEN the selected dates
  bool _matchesDateFilter(String eventDateStr) {
    if (_selectedDateRange == null) return true; // If no filter, show everything

    try {
      List<String> parts = eventDateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        
        // Convert the event date string into a real DateTime object
        DateTime eventDate = DateTime(year, month, day);
        
        // Strip the times from our range so we are strictly comparing midnight-to-midnight dates
        DateTime startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        DateTime endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);

        // Does the event fall inside or exactly on the start/end bounds?
        return (eventDate.isAtSameMomentAs(startDate) || eventDate.isAfter(startDate)) && 
               (eventDate.isAtSameMomentAs(endDate) || eventDate.isBefore(endDate));
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Search Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: utmMaroon,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SEARCH AND FILTER HEADER ---
          Container(
            color: utmMaroon,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // 1. Text Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search by title, location, or category...",
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                
                // 2. Date Range Filter Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedDateRange == null ? Colors.white.withValues(alpha: 0.2) : Colors.white,
                          foregroundColor: _selectedDateRange == null ? Colors.white : utmMaroon,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _selectedDateRange == null 
                              ? "Filter by Date Range" 
                              // Format: "12/5 - 15/5/2024" so it fits nicely on the button
                              : "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}  to  ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickDateRange,
                      ),
                    ),
                    
                    // Show a "Clear" button ONLY if a date range is selected
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: "Clear Date Filter",
                      )
                    ]
                  ],
                ),
              ],
            ),
          ),

          // --- SEARCH RESULTS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'approved').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading search results."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: utmMaroon));

                var allEvents = snapshot.data!.docs;

                // --- FILTERING LOGIC ---
                var filteredEvents = allEvents.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String title = (data['title'] ?? '').toLowerCase();
                  String location = (data['location'] ?? '').toLowerCase();
                  String eventDateStr = data['date'] ?? '';
                  List<dynamic> rawTags = data['tags'] ?? [];
                  String allTagsText = rawTags.join(" ").toLowerCase();

                  // 1. Text Check (Fixed typo here!)
                  bool matchesText = title.contains(_searchQuery) || 
                                     location.contains(_searchQuery) || 
                                     allTagsText.contains(_searchQuery); 

                  // 2. Date Range Check
                  bool matchesDate = _matchesDateFilter(eventDateStr);

                  return matchesText && matchesDate;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("No events found matching your criteria.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  );
                }

                // Render the results list
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    var doc = filteredEvents[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                            image: data['posterUrl'] != null && data['posterUrl'].toString().isNotEmpty
                                ? DecorationImage(image: NetworkImage(data['posterUrl']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: data['posterUrl'] == null || data['posterUrl'].toString().isEmpty
                              ? const Icon(Icons.event, color: Colors.grey)
                              : null,
                        ),
                        title: Text(data['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            // --- UPDATED: Date & Time with End Time ---
                            Text(
                              "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}", 
                              style: const TextStyle(color: utmMaroon, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            
                            // --- NEW: Category and Mode Row ---
                            Row(
                              children: [
                                // ONLY show category if it exists
                                if (data['category'] != null && data['category'].toString().trim().isNotEmpty) ...[
                                  Text(
                                    data['category'].toString().toUpperCase(), 
                                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)
                                  ),
                                  const SizedBox(width: 6),
                                  const Text("•", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  const SizedBox(width: 6),
                                ],
                                // ALWAYS show Mode (Physical/Online)
                                Text(
                                  data['mode']?.toString().toUpperCase() ?? 'PHYSICAL',
                                  style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetails(
                                eventId: doc.id,
                                eventData: data,
                              ),
                            ),
                          );
                        },
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