import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';

class FeedPreferencesPage extends StatefulWidget {
  const FeedPreferencesPage({super.key});

  @override
  State<FeedPreferencesPage> createState() => _FeedPreferencesPageState();
}

class _FeedPreferencesPageState extends State<FeedPreferencesPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  List<String> _selectedTags = [];
  bool _isLoadingUserData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  // 1. Load the tags the student previously saved
  Future<void> _loadUserPreferences() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _selectedTags = List<String>.from(data['preferredTags'] ?? []);
          _isLoadingUserData = false;
        });
      }
    }
  }

  // 2. Save preferences back to Firestore
  Future<void> _savePreferences() async {
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'preferredTags': _selectedTags,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feed preferences updated!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to settings/dashboard
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Toggle a tag on or off
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Customize Feed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: utmMaroon,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // STICKY BOTTOM BUTTON
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: utmMaroon, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: _isLoadingUserData || _isSaving ? null : _savePreferences,
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Save Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),

      body: _isLoadingUserData 
        ? const Center(child: CircularProgressIndicator(color: utmMaroon))
        : FutureBuilder<QuerySnapshot>(
            // Fetch all events to extract unique tags
            future: FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'approved').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: utmMaroon));
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text("No tags available right now."));
              }

              var events = snapshot.data!.docs;
              Map<String, int> tagFrequency = {};

              for (var doc in events) {
                var data = doc.data() as Map<String, dynamic>;
                List<dynamic> tags = data['tag'] ?? [];
                
                for (var tag in tags) {
                  // Trim spaces and convert to UPPERCASE
                  String t = tag.toString().trim().toUpperCase();
                  if (t.isNotEmpty) {
                    tagFrequency[t] = (tagFrequency[t] ?? 0) + 1;
                  }
                }
              }

              if (tagFrequency.isEmpty) {
                return const Center(child: Text("No tags found in approved events."));
              }

              var sortedTags = tagFrequency.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              List<MapEntry<String, int>> trendingTags = sortedTags.take(5).toList();
              List<MapEntry<String, int>> otherTags = sortedTags.skip(5).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Personalize your experience", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Select the topics you care about.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 32),

                    // --- TRENDING TAGS ---
                    const Text("🔥 Trending Right Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: trendingTags.map((entry) {
                        bool isSelected = _selectedTags.contains(entry.key);
                        return ChoiceChip(
                          label: Text("${entry.key} (${entry.value})", style: TextStyle(color: isSelected ? Colors.white : utmMaroon)),
                          selected: isSelected,
                          selectedColor: utmMaroon,
                          backgroundColor: utmMaroon.withValues(alpha: 0.1),
                          onSelected: (_) => _toggleTag(entry.key),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // --- OTHER TAGS ---
                    if (otherTags.isNotEmpty) ...[
                      const Text("Explore More Topics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: otherTags.map((entry) {
                          bool isSelected = _selectedTags.contains(entry.key);
                          return FilterChip(
                            label: Text(entry.key, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: Colors.black87,
                            onSelected: (_) => _toggleTag(entry.key),
                          );
                        }).toList(),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
    );
  }
}