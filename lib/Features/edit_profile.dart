import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:utm_around/constant.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  
  String? _selectedFaculty;
  String? _existingProfilePicUrl; // To hold their current picture from Firestore
  
  // Image Picker Variables
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  // Add these new controllers at the top of your state class
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _ajkController = TextEditingController();
  String? _userRole; // To track if they are a student or club

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRole = data['role'] ?? 'student'; // Get their role!
          _nameController.text = data['name'] ?? '';
          _existingProfilePicUrl = data['profilePic'];
          
          if (_userRole == 'club') {
            _descController.text = data['description'] ?? '';
            _ajkController.text = data['ajk'] ?? '';
          } else {
            if (utmFaculties.contains(data['faculty'])) {
              _selectedFaculty = data['faculty'];
            }
          }
          _isLoading = false;
        });
      }
    }
  }

  // --- PICK IMAGE FROM GALLERY ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // High compression because avatars are small!
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // --- SAVE DATA & UPLOAD IMAGE ---
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? finalPicUrl = _existingProfilePicUrl;

      // 1. If they picked a new image, upload it first!
      if (_profileImage != null) {
        // We use their UID as the filename. This automatically overwrites their old picture!
        String fileName = 'profile_pictures/${user!.uid}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        UploadTask uploadTask = storageRef.putFile(_profileImage!);
        TaskSnapshot snapshot = await uploadTask;
        finalPicUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Save text data and image URL to Firestore
      // Change the Firestore update block to this:
      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'profilePic': finalPicUrl ?? '',
      };

      if (_userRole == 'club') {
        updateData['description'] = _descController.text.trim();
        updateData['ajk'] = _ajkController.text.trim();
      } else {
        updateData['faculty'] = _selectedFaculty ?? 'Not set';
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: utmMaroon)));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: utmMaroon,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- PROFILE PICTURE UPLOAD UI ---
            Center(
              child: GestureDetector(
                onTap: _pickImage, // Opens gallery when tapped
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: utmMaroon.withValues(alpha: 0.1),
                      // Logic: Show the newly picked file OR the old network image OR nothing
                      backgroundImage: _profileImage != null 
                          ? FileImage(_profileImage!) as ImageProvider
                          : (_existingProfilePicUrl != null && _existingProfilePicUrl!.isNotEmpty
                              ? NetworkImage(_existingProfilePicUrl!)
                              : null),
                      child: _profileImage == null && (_existingProfilePicUrl == null || _existingProfilePicUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 55, color: utmMaroon)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: utmMaroon, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2), // Nice white border
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(child: Text("Tap to change picture", style: TextStyle(color: Colors.grey, fontSize: 13))),
            const SizedBox(height: 35),

            // --- FULL NAME FIELD ---
            const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline, color: utmMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: utmMaroon, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // --- DYNAMIC FIELDS BASED ON ROLE ---
            if (_userRole == 'club') ...[
              const Text("Club Description", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "What does your club do?",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: utmMaroon, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Committee Members (AJK)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _ajkController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "e.g. President: Ahmad\nVice President: Sarah",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: utmMaroon, width: 2)),
                ),
              ),
            ] else ...[
              // Put your existing Faculty Dropdown UI here!
              const Text("Faculty", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select your Faculty"),
                    value: _selectedFaculty,
                    icon: const Icon(Icons.arrow_drop_down, color: utmMaroon),
                    items: utmFaculties.map((String faculty) {
                      return DropdownMenuItem<String>(
                        value: faculty,
                        child: Text(faculty),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedFaculty = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),

            // --- SAVE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: utmMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}