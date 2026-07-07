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
  DateTimeRange? _selectedDateRange;
  
  // --- FILTER STATES ---
  String _selectedMode = 'All Modes';
  String _selectedPayment = 'All Fees';

  // --- SHOW DATE RANGE PICKER ---
  Future<void> _pickDateRange() async {
    // 1. Grab the current year dynamically
    final int currentYear = DateTime.now().year;

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      // 2. Future-proof boundaries 
      firstDate: DateTime(currentYear - 8), // 8 years ago
      lastDate: DateTime(currentYear + 1, 12, 31), // December 31st of next year
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light( //auto fill in
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

  // --- Helper to check if an event is today or in the future ---
  bool _isUpcoming(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        DateTime eventDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        DateTime todayMidnight = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        return !eventDate.isBefore(todayMidnight); 
      }
    } catch (e) {
      return false; // If date is broken, hide it
    }
    return false;
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
        
        // Strip the times from range to prove strictly comparing midnight-to-midnight dates
        DateTime startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        DateTime endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);

        // Does the event fall inside or exactly on the start/end bounds
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // --- SEARCH AND FILTER HEADER ---
          Container(
            color: utmMaroon,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Text Search Bar
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
                
                // Date Range Filter Button
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
                              // Format: "12/5 - 15/5/2024"
                              : "${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}  to  ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickDateRange,
                      ),
                    ),
                    
                    // Show "Clear" button ONLY if a date range is selected
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
                const SizedBox(height: 12),

                // --- MODE & FEE DROPDOWNS ---
                Row(
                  children: [
                    // Mode Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedMode,
                            icon: const Icon(Icons.arrow_drop_down, color: utmMaroon),
                            items: ['All Modes', 'Physical', 'Online'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              );
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedMode = newValue!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Fee Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPayment,
                            icon: const Icon(Icons.arrow_drop_down, color: utmMaroon),
                            items: ['All Fees', 'Free', 'Paid'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                              );
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedPayment = newValue!),
                          ),
                        ),
                      ),
                    ),
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
                  String mode = data['mode'] ?? 'Physical';
                  String paymentType = data['paymentType'] ?? 'Free';

                  // Safely check for tags (handles both 'tag' array and old 'tags' array)
                  List<dynamic> rawTags = data['tag'] ?? data['tags'] ?? [];
                  String allTagsText = rawTags.join(" ").toLowerCase();

                  // Text Check
                  bool matchesText = title.contains(_searchQuery) || 
                                     location.contains(_searchQuery) || 
                                     allTagsText.contains(_searchQuery); 

                  // --- SMART DATE LOGIC ---
                  bool matchesDate;
                  if (_selectedDateRange == null) {
                    // If they haven't picked a date filter, ONLY show upcoming/today events! (Hide the past)
                    matchesDate = _isUpcoming(eventDateStr);
                  } else {
                    // If they picked a specific date range, use that! (Allows searching past events)
                    matchesDate = _matchesDateFilter(eventDateStr);
                  }

                  // Mode Check
                  bool matchesMode = _selectedMode == 'All Modes' || mode.toLowerCase() == _selectedMode.toLowerCase();

                  // Fee Check
                  bool matchesPayment = _selectedPayment == 'All Fees' || paymentType.toLowerCase() == _selectedPayment.toLowerCase();

                  return matchesText && matchesDate && matchesMode && matchesPayment;
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

                    // --- EXTRACTION LOGIC FOR UI ---
                    final paymentType = data['paymentType'] ?? 'Free';
                    final bool isPaid = paymentType == 'Paid';
                    final paymentColor = isPaid ? Colors.orange : Colors.green;

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
                            // Date & Time
                            Text(
                              "${data['date'] ?? 'TBA'} • ${data['time'] ?? 'TBA'} - ${data['endTime'] ?? 'TBA'}", 
                              style: const TextStyle(color: utmMaroon, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            
                            // --- BADGES & TAGS WRAP ---
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // 1. Mode Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(data['mode']?.toString().toUpperCase() ?? 'PHYSICAL', style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                // 2. Fee Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: paymentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: paymentColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(paymentType.toUpperCase(), style: TextStyle(color: paymentColor[800], fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                // 3. Dynamic Tags (Limit to 2 so the card doesn't get huge)
                                if (data['tag'] != null)
                                  ...((data['tag'] as List).where((tag) => tag.toString().toLowerCase() != (data['mode']?.toString().toLowerCase() ?? 'physical')).take(2).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: utmMaroon.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(tag.toString().toUpperCase(), style: const TextStyle(color: utmMaroon, fontSize: 9, fontWeight: FontWeight.bold)),
                                    );
                                  })),
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