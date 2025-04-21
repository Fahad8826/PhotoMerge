// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
// import 'dart:typed_data';
// import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class UserDashboard extends StatefulWidget {
//   const UserDashboard({Key? key}) : super(key: key);

//   @override
//   State<UserDashboard> createState() => _UserDashboardState();
// }

// class _UserDashboardState extends State<UserDashboard> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;
//   Map<String, dynamic>? userData;

//   // Map to store RepaintBoundary keys for each photo
//   final Map<String, GlobalKey> _photoKeys = {};

//   // Constants for Firestore collections
//   final String _adminImagesCollection = 'admin_images';
//   final String _adminDocId = 'NBhMBNH4AbZl0bNO3D0SYVPXstn1';
//   final String _imagesSubcollection = 'images';

//   @override
//   void initState() {
//     super.initState();
//     _getUserData();
//   }

//   Future<void> _getUserData() async {
//     if (userId != null) {
//       final doc = await _firestore.collection('user_profile').doc(userId).get();
//       if (doc.exists) {
//         setState(() {
//           userData = doc.data();
//         });
//       }
//     }
//   }

//   Future<void> _captureAndSaveImage(String photoId) async {
//     try {
//       // Request storage permission
//       var status = await Permission.storage.request();
//       if (!status.isGranted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Storage permission denied')),
//         );
//         return;
//       }

//       final key = _photoKeys[photoId];
//       if (key == null || key.currentContext == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Cannot capture image at this time')),
//         );
//         return;
//       }

//       // Show loading indicator
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Processing image...')),
//       );

//       // Convert widget to image
//       RenderRepaintBoundary boundary =
//           key.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData =
//           await image.toByteData(format: ui.ImageByteFormat.png);
//       Uint8List pngBytes = byteData!.buffer.asUint8List();

//       // Save image using flutter_image_gallery_saver
//       // Version 0.0.2 returns void, so we can't check the result
//       await FlutterImageGallerySaver.saveImage(pngBytes);

//       // Since we can't check the result, we'll just assume success if no exception is thrown
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Image saved to gallery!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving image: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Photo Gallery'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _getUserData,
//           ),
//         ],
//       ),
//       drawer: userId != null
//           ? Drawer(
//               child: StreamBuilder<DocumentSnapshot>(
//                 stream: _firestore
//                     .collection('user_profile')
//                     .doc(userId)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData || snapshot.data == null) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   Map<String, dynamic>? userData = snapshot.data!.exists
//                       ? snapshot.data!.data() as Map<String, dynamic>
//                       : null;

//                   if (userData == null) {
//                     return const Center(child: Text('Profile not found'));
//                   }

//                   String name = userData['name'] ?? 'User';
//                   String email = userData['email'] ?? '';
//                   String imageUrl = userData['image'] ?? '';

//                   return ListView(
//                     padding: EdgeInsets.zero,
//                     children: <Widget>[
//                       UserAccountsDrawerHeader(
//                         accountName: Text(name),
//                         accountEmail: Text(email),
//                         currentAccountPicture: CircleAvatar(
//                           backgroundImage: imageUrl.isNotEmpty
//                               ? NetworkImage(imageUrl)
//                               : null,
//                           child: imageUrl.isEmpty
//                               ? const Icon(Icons.person,
//                                   size: 50, color: Colors.white)
//                               : null,
//                           backgroundColor:
//                               imageUrl.isEmpty ? Colors.grey : null,
//                         ),
//                         decoration: const BoxDecoration(
//                           color: Colors.blue,
//                         ),
//                       ),
//                       ListTile(
//                         leading: const Icon(Icons.edit),
//                         title: const Text('Edit Profile'),
//                         onTap: () {
//                           Navigator.pop(context);
//                           Navigator.pushNamed(context, '/profile');
//                         },
//                       ),
//                       ListTile(
//                         leading: const Icon(Icons.logout),
//                         title: const Text('Log Out'),
//                         onTap: () async {
//                           Navigator.pop(context);
//                           await FirebaseAuth.instance.signOut();
//                           Navigator.pushReplacementNamed(context, '/login');
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             )
//           : null,
//       body: StreamBuilder<QuerySnapshot>(
//         // Updated to access the correct nested collection
//         stream: _firestore
//             .collection(_adminImagesCollection)
//             .doc(_adminDocId)
//             .collection(_imagesSubcollection)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No photos available'));
//           }

//           return userData == null
//               ? const Center(child: Text('Loading user data...'))
//               : ListView.builder(
//                   padding: const EdgeInsets.all(10),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final photo = snapshot.data!.docs[index].data()
//                         as Map<String, dynamic>;
//                     final String photoId = snapshot.data!.docs[index].id;
//                     // Updated to use image_url field from your Firestore
//                     final String photoUrl = photo['image_url'] ?? '';

//                     // Create a unique key for each photo
//                     if (!_photoKeys.containsKey(photoId)) {
//                       _photoKeys[photoId] = GlobalKey();
//                     }

//                     return Card(
//                       elevation: 4,
//                       margin: const EdgeInsets.only(bottom: 16),
//                       child: Column(
//                         children: [
//                           // The content to be captured (image + user data)
//                           RepaintBoundary(
//                             key: _photoKeys[photoId],
//                             child: Column(
//                               children: [
//                                 // Photo
//                                 AspectRatio(
//                                   aspectRatio:
//                                       4 / 3, // Maintain image aspect ratio
//                                   child: CachedNetworkImage(
//                                     imageUrl: photoUrl,
//                                     fit: BoxFit.cover,
//                                     width: double.infinity,
//                                     placeholder: (context, url) => const Center(
//                                         child: CircularProgressIndicator()),
//                                     errorWidget: (context, url, error) =>
//                                         const Icon(Icons.error),
//                                   ),
//                                 ),

//                                 // User data footer
//                                 Container(
//                                   width: double.infinity,
//                                   color: Colors.white,
//                                   padding: const EdgeInsets.all(12.0),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           CircleAvatar(
//                                             radius: 20,
//                                             backgroundImage:
//                                                 userData!['userImage'] !=
//                                                             null &&
//                                                         userData!['userImage']
//                                                             .isNotEmpty
//                                                     ? NetworkImage(
//                                                         userData!['userImage'])
//                                                     : null,
//                                             child: (userData!['userImage'] ==
//                                                         null ||
//                                                     userData!['userImage']
//                                                         .isEmpty)
//                                                 ? const Icon(Icons.person,
//                                                     size: 20)
//                                                 : null,
//                                           ),
//                                           const SizedBox(width: 12),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 userData!['name'] ?? 'User',
//                                                 style: const TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 18,
//                                                 ),
//                                               ),
//                                               Text(
//                                                 userData!['designation'] ??
//                                                     'No designation',
//                                                 style: TextStyle(
//                                                   fontSize: 14,
//                                                   color: Colors.grey[700],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Row(
//                                         children: [
//                                           const Icon(Icons.email,
//                                               size: 16, color: Colors.grey),
//                                           const SizedBox(width: 4),
//                                           Text(
//                                             userData!['email'] ?? '',
//                                             style:
//                                                 const TextStyle(fontSize: 14),
//                                           ),
//                                         ],
//                                       ),
//                                       if (userData!['phone'] != null)
//                                         Row(
//                                           children: [
//                                             const Icon(Icons.phone,
//                                                 size: 16, color: Colors.grey),
//                                             const SizedBox(width: 4),
//                                             Text(
//                                               userData!['phone'],
//                                               style:
//                                                   const TextStyle(fontSize: 14),
//                                             ),
//                                           ],
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           // Download button (outside of RepaintBoundary)
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: ElevatedButton.icon(
//                               icon: const Icon(Icons.download),
//                               label: const Text('Download Merged Image'),
//                               style: ElevatedButton.styleFrom(
//                                 minimumSize: const Size(double.infinity, 40),
//                               ),
//                               onPressed: () => _captureAndSaveImage(photoId),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//         },
//       ),
//     );
//   }
// }
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

  // Map to store RepaintBoundary keys and dominant colors for each photo
  final Map<String, GlobalKey> _photoKeys = {};
  final Map<String, Color> _dominantColors = {};

  // Constants for Firestore collections
  final String _adminImagesCollection = 'admin_images';
  final String _adminDocId = 'NBhMBNH4AbZl0bNO3D0SYVPXstn1';
  final String _imagesSubcollection = 'images';

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    if (userId != null) {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
        });
      }
    }
  }

  // Extract dominant color from an image
  Future<Color> _getDominantColor(String imageUrl) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      final PaletteGenerator paletteGenerator =
          await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100), // Optimize for performance
        maximumColorCount: 10,
      );
      return paletteGenerator.dominantColor?.color ?? Colors.white;
    } catch (e) {
      return Colors.white; // Fallback color
    }
  }

  Future<void> _captureAndSaveImage(String photoId, String photoUrl) async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
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

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing image...')),
      );

      // Convert widget to image
      RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save image to gallery
      await FlutterImageGallerySaver.saveImage(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: $e')),
      );
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('user_profile')
                    .doc(userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic>? userData = snapshot.data!.exists
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : null;

                  if (userData == null) {
                    return const Center(child: Text('Profile not found'));
                  }

                  String name = userData['firstName'] ?? 'User';
                  String email = userData['email'] ?? '';
                  String imageUrl = userData['userImage'] ?? '';

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      UserAccountsDrawerHeader(
                        accountName: Text(name),
                        accountEmail: Text(email),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 50, color: Colors.white)
                              : null,
                          backgroundColor:
                              imageUrl.isEmpty ? Colors.grey : null,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit Profile'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/profile');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Log Out'),
                        onTap: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ],
                  );
                },
              ),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(_adminImagesCollection)
            .doc(_adminDocId)
            .collection(_imagesSubcollection)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No photos available'));
          }

          return userData == null
              ? const Center(child: Text('Loading user data...'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final photo = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    final String photoId = snapshot.data!.docs[index].id;
                    final String photoUrl = photo['image_url'] ?? '';

                    // Create a unique key for each photo
                    if (!_photoKeys.containsKey(photoId)) {
                      _photoKeys[photoId] = GlobalKey();
                    }

                    // Get dominant color for the photo
                    return FutureBuilder<Color>(
                      future: _getDominantColor(photoUrl),
                      builder: (context, colorSnapshot) {
                        if (!colorSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final backgroundColor = colorSnapshot.data!;

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              // The content to be captured
                              RepaintBoundary(
                                key: _photoKeys[photoId],
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        // Photo
                                        AspectRatio(
                                          aspectRatio: 4 / 3,
                                          child: CachedNetworkImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            placeholder: (context, url) =>
                                                const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                        // User data footer
                                        Container(
                                          width: double.infinity,
                                          color: backgroundColor,
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 20,
                                                    backgroundImage: userData![
                                                                'userImage'] !=
                                                            null
                                                        ? NetworkImage(
                                                            userData![
                                                                'userImage'])
                                                        : null,
                                                    child: userData![
                                                                'userImage'] ==
                                                            null
                                                        ? const Icon(
                                                            Icons.person,
                                                            size: 20)
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        userData![
                                                                'firstName'] ??
                                                            'User',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Text(
                                                        userData![
                                                                'designation'] ??
                                                            'No designation',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.email,
                                                      size: 16,
                                                      color: Colors.white70),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    userData!['email'] ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              if (userData!['phone1'] != null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.phone,
                                                        size: 16,
                                                        color: Colors.white70),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      userData!['phone1'],
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white),
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 8),
                                              // Company Logo
                                              if (userData!['companyLogo'] !=
                                                      null &&
                                                  userData!['companyLogo']
                                                      .isNotEmpty)
                                                SizedBox(
                                                  height: 40,
                                                  child: CachedNetworkImage(
                                                    imageUrl: userData![
                                                        'companyLogo'],
                                                    fit: BoxFit.contain,
                                                    placeholder: (context,
                                                            url) =>
                                                        const CircularProgressIndicator(),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Watermark
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: WatermarkPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Download button
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download Merged Image'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 40),
                                  ),
                                  onPressed: () =>
                                      _captureAndSaveImage(photoId, photoUrl),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}

// Custom painter for watermark
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
