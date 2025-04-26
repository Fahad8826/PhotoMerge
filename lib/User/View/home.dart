import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;

  // Cached maps for performance
  final Map<String, GlobalKey> _photoKeys = {};
  final Map<String, Color> _dominantColors = {};

  // Constants
  static const String adminImagesCollection = 'admin_images';
  static const String imagesSubcollection = 'images';
  static const double fadeHeight = 100.0;
  static const int maxColorCount = 10;
  static const double pixelRatio = 3.0;

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

  Future<Color> _getDominantColor(String imageUrl) async {
    if (_dominantColors.containsKey(imageUrl)) {
      return _dominantColors[imageUrl]!;
    }
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: maxColorCount,
      );
      final dominantColor =
          paletteGenerator.dominantColor?.color ?? Colors.white;
      _dominantColors[imageUrl] = dominantColor;
      return dominantColor;
    } catch (e) {
      print('Error getting dominant color for $imageUrl: $e');
      return Colors.white;
    }
  }

  Future<void> _captureAndSaveImage(String photoId, String photoUrl) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    final key = _photoKeys[photoId];
    if (key == null || key.currentContext == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot capture image at this time')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing image...')),
    );

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    await FlutterImageGallerySaver.saveImage(pngBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image saved to gallery!')),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _getAllImagesStream() {
    return _firestore
        .collectionGroup(imagesSubcollection)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Widget _buildPhotoCard(
      String photoId, String photoUrl, Color backgroundColor) {
    if (!_photoKeys.containsKey(photoId)) {
      _photoKeys[photoId] = GlobalKey();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          RepaintBoundary(
            key: _photoKeys[photoId],
            child: Stack(
              children: [
                Column(
                  children: [
                    // Main Photo with improved bottom fade
                    AspectRatio(
                      aspectRatio: 5 / 6,
                      child: Stack(
                        children: [
                          // Image
                          CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) {
                              print('Image load error for $url: $error');
                              return const Icon(Icons.error);
                            },
                          ),
                          // Enhanced gradient overlay with smoother transition
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: fadeHeight *
                                2.0, // Increased height for smoother fade
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    backgroundColor.withOpacity(
                                        0.1), // Start with very light opacity
                                    backgroundColor.withOpacity(0.3),
                                    backgroundColor.withOpacity(0.5),
                                    backgroundColor.withOpacity(0.7),
                                    backgroundColor.withOpacity(0.9),
                                    backgroundColor,
                                  ],
                                  stops: const [
                                    0.0,
                                    0.2,
                                    0.4,
                                    0.6,
                                    0.8,
                                    0.9,
                                    1.0
                                  ], // More gradient stops for smoother transition
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // User info section with improved top gradient
                    if (userData != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              backgroundColor, // Start with the solid color matching the fade from above
                              backgroundColor, // Maintain consistent color through the container
                              backgroundColor.withOpacity(
                                  0.95), // Very subtle fade for depth
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Row(
                          // Rest of your row content remains the same
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ... existing code for CircleAvatar
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: userData!['userImage'] != null
                                  ? NetworkImage(userData!['userImage'])
                                  : null,
                              child: userData!['userImage'] == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            // ... existing code for user details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData!['firstName'] ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        userData!['designation'] ??
                                            'No designation',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.email,
                                              size: 16, color: Colors.white70),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              userData!['email'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ]),
                              ),
                            ),
                            // ... existing code for company logo
                            if (userData!['companyLogo'] != null &&
                                userData!['companyLogo'].isNotEmpty)
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Image.network(
                                  userData!['companyLogo'],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Logo load error: $error');
                                    return const Icon(Icons.error);
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: WatermarkPainter(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download Merged Image'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () => _captureAndSaveImage(photoId, photoUrl),
            ),
          ),
        ],
      ),
    );
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
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _getAllImagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No photos available'));
          }
          return userData == null
              ? const Center(child: Text('Loading user data...'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final photo =
                        snapshot.data![index].data() as Map<String, dynamic>;
                    final photoId = snapshot.data![index].id;
                    final photoUrl = photo['image_url'] ?? '';
                    return FutureBuilder<Color>(
                      future: _getDominantColor(photoUrl),
                      builder: (context, colorSnapshot) {
                        if (!colorSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _buildPhotoCard(
                            photoId, photoUrl, colorSnapshot.data!);
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

// / Custom painter for watermark
class WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Generated by YourApp',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Rotate and position the watermark diagonally
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-45 * 3.14159 / 180); // 45-degree rotation
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
