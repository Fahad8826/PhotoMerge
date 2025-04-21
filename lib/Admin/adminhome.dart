import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:photomerge/main.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/createadmin");
                },
                child: Text("Add admin")),
            TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/craeteimage");
                },
                child: Text("Add iamge")),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        body: Center(child: Text("welcome admin")));
  }
}
