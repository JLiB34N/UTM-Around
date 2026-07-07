// lib/features/notification_preferences_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utm_around/constant.dart';

class NotificationPreferences extends StatefulWidget {
  const NotificationPreferences({super.key});

  @override
  State<NotificationPreferences> createState() => _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<NotificationPreferences> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  bool _isLoading = true;
  bool _isSaving = false;

  // Notification Methods
  bool _notifyPush = true;

  // Timings (stored in minutes)
  final List<int> _availableTimings = [30, 60, 1440, 4320];
  List<int> _selectedTimings = [30, 60]; // Default to 30m and 1h

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _notifyPush = data['notifyPush'] ?? true;
          
          if (data['notifyTimings'] != null) {
            _selectedTimings = List<int>.from(data['notifyTimings']);
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    if (user == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'notifyPush': _notifyPush,
        'notifyTimings': _selectedTimings,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification preferences saved!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getTimingLabel(int minutes) {
    switch (minutes) {
      case 30: return "30 minutes before";
      case 60: return "1 hour before";
      case 1440: return "1 day before";
      case 4320: return "3 days before";
      default: return "$minutes mins before";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Notification Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: utmMaroon,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: utmMaroon, 
              foregroundColor: Colors.white, 
              minimumSize: const Size(double.infinity, 50), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            onPressed: _isLoading || _isSaving ? null : _savePreferences,
            child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Save Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: utmMaroon))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text("How should we notify you?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: SwitchListTile(
                  title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Alerts on your phone screen"),
                  activeThumbColor: utmMaroon,
                  value: _notifyPush,
                  onChanged: (val) => setState(() => _notifyPush = val),
                ),
              ),

              const SizedBox(height: 32),
              const Text("When do you want reminders?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Select all that apply for your upcoming events.", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 12),
              
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  children: _availableTimings.map((minutes) {
                    return CheckboxListTile(
                      title: Text(_getTimingLabel(minutes), style: const TextStyle(fontWeight: FontWeight.w600)),
                      activeColor: utmMaroon,
                      value: _selectedTimings.contains(minutes),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedTimings.add(minutes);
                          } else {
                            _selectedTimings.remove(minutes);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
    );
  }
}