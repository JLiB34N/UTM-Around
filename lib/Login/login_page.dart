// lib/login_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

const Color utmMaroon = Color(0xFF981D2D);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Use singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // New initialization with the Server Client ID
    _googleSignIn.initialize(serverClientId: '939798559504-gk624ou4b1ht4sqfcj8ld20gdmrqpcav.apps.googleusercontent.com'); //server client ID
  }

  // --- GOOGLE SIGN IN (NEW v7+ FLOW) ---
  Future<void> _signInWithGoogle() async {
    try {
      // Trigger the new authenticate method (Dart knows it's non-nullable)
      final googleUser = await _googleSignIn.authenticate();

      // UTM Email validation (No null check needed since authenticate() will throw if the user cancels)
      if (!googleUser.email.endsWith('utm.my') && !googleUser.email.endsWith('graduate.utm.my')) {
        await _googleSignIn.signOut();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Please use your UTM student email."))
           );
        }
        setState(() => _isLoading = false);
        return; // Stop the login process
      }

      // Get the auth details (Synchronous in v7)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Pass the idToken! Remove the accessToken parameter.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
        
      // 7. Sign into Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        
      // 8. Create the role in Firestore if they are a new student
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid);
      var doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'role': 'student',
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'profilePic': userCredential.user!.photoURL,
          'faculty': 'Not set',
        });
     }
    } catch (e) {
      debugPrint("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Sign-In Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- EMAIL/PASS SIGN IN (Clubs & Admins) ---
  Future<void> _signInWithEmail() async {
    // Assuming you created TextEditingControllers named _emailController and _passwordController
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Tell Firebase Auth to log them in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 2. You don't need to do anything else! 
      // The auth_wrapper is already listening and will automatically 
      // send them to the AdminHomeScreen or Dashboard based on their role!

    } on FirebaseAuthException catch (e) {
      // 1. Mount check
      if (!mounted) return;

      // Handle wrong password, user not found, etc.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed"), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: utmMaroon)) 
          : Column(
              children: [
                const SizedBox(height: 80),
                const Text("UTM Around", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: utmMaroon)),
                const SizedBox(height: 40),
                TabBar(
                  controller: _tabController,
                  labelColor: utmMaroon,
                  indicatorColor: utmMaroon,
                  tabs: const [Tab(text: "Student"), Tab(text: "Club")],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // STUDENT TAB
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Welcome Student!", style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.login),
                              label: const Text("Sign in with Google (UTM)"),
                              onPressed: _signInWithGoogle,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      // CLUB & ADMIN TAB
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Club Email")),
                            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _signInWithEmail,
                              style: ElevatedButton.styleFrom(backgroundColor: utmMaroon),
                              child: const Text("Login", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}