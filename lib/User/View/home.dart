import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    final doc = await _firestore.collection('user_profile').doc(userId).get();
    if (doc.exists) {
      setState(() => userData = doc.data());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getUserData,
          ),
        ],
      ),
      drawer: userId != null
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero, // Ensure no extra padding at the top
                children: <Widget>[
                  // Drawer Header
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.blue, // Material Design primary color
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Edit Profile Tile
                  ListTile(
                    leading: const Icon(
                      Icons.edit,
                      color: Colors.grey, // Consistent icon color
                    ),
                    title: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.image,
                      color: Colors.grey, // Consistent icon color
                    ),
                    title: const Text(
                      'My gallery',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(context, '/listimages');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.image,
                      color: Colors.grey, // Consistent icon color
                    ),
                    title: const Text(
                      'Categoery',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(context, '/Category');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.subscriptions_rounded,
                      color: Colors.grey,
                    ),
                    title: const Text(
                      'my subscription',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer
                      Navigator.pushNamed(context, '/usersubscription');
                    },
                  ),
                  // Log Out Tile
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.grey,
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            )
          : null,
      body: Center(
        child: Text(
          'HOME',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
