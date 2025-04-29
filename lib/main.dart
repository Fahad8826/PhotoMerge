import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:photomerge/Admin/add_posters.dart';
import 'package:photomerge/Admin/adminhome.dart';
import 'package:photomerge/Admin/create_admin.dart';
import 'package:photomerge/Authentication/authservice.dart';
import 'package:photomerge/Authentication/signin.dart';
import 'package:photomerge/Authentication/signup.dart';
import 'package:photomerge/User/View/categorey.dart';
import 'package:photomerge/User/View/categorylist.dart';
import 'package:photomerge/User/View/home.dart';
import 'package:photomerge/User/View/listimages.dart';
import 'package:photomerge/User/View/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Role Based Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/signup': (context) => SignupPage(),
        '/login': (context) => LoginPage(),
        '/user': (context) => UserDashboard(),
        '/admin': (context) => AdminDashboard(),
        '/profile': (context) => ProfilePage(),
        '/createadmin': (context) => create_admin(),
        '/craeteimage': (context) => AddImagePage(),
        '/listimages': (context) => Listimages(),
        '/Category': (context) => CategoryListPage(),
      },
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.white
                .withOpacity(0.4), // Light, semi-transparent background
            child: const Center(
              child: Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
