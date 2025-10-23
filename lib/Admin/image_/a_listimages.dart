// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:crypto/crypto.dart';

// class ListImagesPage extends StatefulWidget {
//   const ListImagesPage({Key? key}) : super(key: key);

//   @override
//   State<ListImagesPage> createState() => _ListImagesPageState();
// }

// class _ListImagesPageState extends State<ListImagesPage> {
//   final _firebaseAuth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   bool _isDeleting = false;
//   List<Map<String, String>> _galleryImages = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadGalleryImages();
//   }

//   Future<void> _loadGalleryImages() async {
//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('No user is currently signed in.')),
//         );
//       }
//       return;
//     }

//     try {
//       final snapshot = await _firestore
//           .collection('admin_images')
//           .doc(currentUser.uid)
//           .collection('images')
//           .orderBy('timestamp', descending: true)
//           .get();

//       if (mounted) {
//         setState(() {
//           _galleryImages = snapshot.docs
//               .map((doc) => {
//                     'id': doc.id,
//                     'url': doc['image_url'] as String,
//                     'category': (doc.data().containsKey('category')
//                         ? doc['category']
//                         : 'Other') as String,
//                     'subcategory': (doc.data().containsKey('subcategory')
//                         ? doc['subcategory']
//                         : 'Miscellaneous') as String,
//                   })
//               .toList();
//         });

//         print('Loaded ${_galleryImages.length} images');
//         for (var img in _galleryImages) {
//           print(
//               'Image URL: ${img['url']}, Category: ${img['category']}, Subcategory: ${img['subcategory']}');
//         }
//       }
//     } catch (e) {
//       print('Error loading gallery images: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading gallery: $e')),
//         );
//       }
//     }
//   }

//   // Future<void> _deleteImage(String docId) async {
//   //   final currentUser = _firebaseAuth.currentUser;
//   //   if (currentUser == null) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('No user is currently signed in.')),
//   //     );
//   //     return;
//   //   }

//   //   final confirmed = await showDialog<bool>(
//   //     context: context,
//   //     builder: (context) => AlertDialog(
//   //       title: const Text('Delete Image'),
//   //       content: const Text('Are you sure you want to delete this image?'),
//   //       actions: [
//   //         TextButton(
//   //           onPressed: () => Navigator.pop(context, false),
//   //           child: const Text('Cancel'),
//   //         ),
//   //         TextButton(
//   //           onPressed: () => Navigator.pop(context, true),
//   //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
//   //         ),
//   //       ],
//   //     ),
//   //   );

//   //   if (confirmed != true) return;

//   //   setState(() => _isDeleting = true);

//   //   try {
//   //     await _firestore
//   //         .collection('admin_images')
//   //         .doc(currentUser.uid)
//   //         .collection('images')
//   //         .doc(docId)
//   //         .delete();

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Image deleted successfully')),
//   //     );
//   //   } catch (e) {
//   //     print('Error deleting image: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Error deleting image: $e')),
//   //     );
//   //   } finally {
//   //     setState(() => _isDeleting = false);
//   //     await _loadGalleryImages();
//   //   }
//   // }

//   Future<void> _deleteFromCloudinary(String publicId) async {
//     const cloudName = 'dlacr6mpw';
//     const apiKey = '725816153519724';
//     const apiSecret = '2XjX4826vpnX_PVkbLf7_bWNus4';

//     final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

//     final signatureString =
//         'public_id=$publicId&timestamp=$timestamp$apiSecret';
//     final signature = sha1.convert(utf8.encode(signatureString)).toString();

//     final url =
//         Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

//     final response = await http.post(
//       url,
//       body: {
//         'public_id': publicId,
//         'api_key': apiKey,
//         'timestamp': '$timestamp',
//         'signature': signature,
//       },
//     );

//     if (response.statusCode != 200) {
//       throw Exception(
//           'Failed to delete image from Cloudinary: ${response.body}');
//     }
//   }

//   Future<void> _deleteImage(String docId) async {
//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No user is currently signed in.')),
//       );
//       return;
//     }

//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Image'),
//         content: const Text('Are you sure you want to delete this image?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true) return;

//     setState(() => _isDeleting = true);

//     try {
//       final docRef = _firestore
//           .collection('admin_images')
//           .doc(currentUser.uid)
//           .collection('images')
//           .doc(docId);

//       final docSnapshot = await docRef.get();
//       final data = docSnapshot.data();

//       if (data == null) throw Exception('Image data not found');

//       final cloudinaryPublicId = data['cloudinaryPublicId'];

//       // Delete from Firestore
//       await docRef.delete();

//       // Delete from Cloudinary if publicId is available
//       if (cloudinaryPublicId != null && cloudinaryPublicId.isNotEmpty) {
//         await _deleteFromCloudinary(cloudinaryPublicId);
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Image deleted successfully')),
//       );
//     } catch (e) {
//       print('Error deleting image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting image: $e')),
//       );
//     } finally {
//       setState(() => _isDeleting = false);
//       await _loadGalleryImages();
//     }
//   }

//   String _optimizeCloudinaryUrl(String url) {
//     try {
//       final uri = Uri.parse(url);
//       final path = uri.path;
//       final optimizedPath =
//           path.replaceFirst('/upload/', '/upload/w_300,h_300,q_80/');
//       return '${uri.scheme}://${uri.host}$optimizedPath';
//     } catch (e) {
//       print('Error optimizing URL $url: $e');
//       return url;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please sign in to view images')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Color(0xFF00B6B0),
//         title: Text(
//           'Image Gallery',
//           style: GoogleFonts.oswald(
//             fontSize: 25,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           color: Colors.white,
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             color: Colors.white,
//             onPressed: _loadGalleryImages,
//             tooltip: 'Refresh Gallery',
//           ),
//         ],
//       ),
//       body: Container(
//         color: Colors.white,
//         child: _isDeleting
//             ? const Center(child: CircularProgressIndicator())
//             : _galleryImages.isEmpty
//                 ? const Center(child: Text('No images in gallery.'))
//                 : GridView.builder(
//                     padding: const EdgeInsets.all(16.0),
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 3,
//                       crossAxisSpacing: 8,
//                       mainAxisSpacing: 8,
//                       childAspectRatio: 1,
//                     ),
//                     itemCount: _galleryImages.length,
//                     itemBuilder: (context, index) {
//                       final image = _galleryImages[index];
//                       final optimizedUrl =
//                           _optimizeCloudinaryUrl(image['url']!);
//                       return Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: CachedNetworkImage(
//                               imageUrl: optimizedUrl,
//                               fit: BoxFit.cover,
//                               placeholder: (context, url) => const Center(
//                                   child: CircularProgressIndicator()),
//                               errorWidget: (context, url, error) {
//                                 print('Error loading image $url: $error');
//                                 return Center(
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: const [
//                                       Icon(Icons.error, color: Colors.red),
//                                       Text('Loading...',
//                                           style: TextStyle(color: Colors.grey)),
//                                     ],
//                                   ),
//                                 );
//                               },
//                               fadeInDuration: const Duration(milliseconds: 200),
//                             ),
//                           ),
//                           Positioned(
//                             top: 0,
//                             right: 0,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withOpacity(0.5),
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: IconButton(
//                                 icon: const Icon(Icons.delete,
//                                     color: Colors.white, size: 20),
//                                 padding: const EdgeInsets.all(4),
//                                 constraints: const BoxConstraints(),
//                                 onPressed: () => _deleteImage(image['id']!),
//                               ),
//                             ),
//                           ),
//                           Positioned(
//                             bottom: 0,
//                             left: 0,
//                             right: 0,
//                             child: Container(
//                               color: Colors.black.withOpacity(0.6),
//                               padding: const EdgeInsets.symmetric(vertical: 4),
//                               child: Text(
//                                 '${image['category']}: ${image['subcategory']}',
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                     color: Colors.white, fontSize: 10),
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//       ),
//     );
//   }
// }
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ListImagesPage extends StatefulWidget {
  const ListImagesPage({Key? key}) : super(key: key);

  @override
  State<ListImagesPage> createState() => _ListImagesPageState();
}

class _ListImagesPageState extends State<ListImagesPage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isDeleting = false;
  List<Map<String, String>> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is currently signed in.')),
        );
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('admin_images')
          .doc(currentUser.uid)
          .collection('images')
          .orderBy('timestamp', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _galleryImages = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'url': doc['image_url'] as String,
                    'category': (doc.data().containsKey('category')
                        ? doc['category']
                        : 'Other') as String,
                    'subcategory': (doc.data().containsKey('subcategory')
                        ? doc['subcategory']
                        : 'Miscellaneous') as String,
                  })
              .toList();
        });

        print('Loaded ${_galleryImages.length} images');
        for (var img in _galleryImages) {
          print(
              'Image URL: ${img['url']}, Category: ${img['category']}, Subcategory: ${img['subcategory']}');
        }
      }
    } catch (e) {
      print('Error loading gallery images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gallery: $e')),
        );
      }
    }
  }

  Future<void> _deleteFromCloudinary(String publicId) async {
    const cloudName = 'dlacr6mpw';
    const apiKey = '725816153519724';
    const apiSecret =
        '2XjX4826vpnX_PVkbLf7_bWNus4'; // Verify this against your dashboard

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final signatureString = 'public_id=$publicId×tamp=$timestamp$apiSecret';
    final signature = sha1.convert(utf8.encode(signatureString)).toString();

    print('Signature string: $signatureString'); // Debug log
    print('Generated signature: $signature'); // Debug log

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': '$timestamp',
        'signature': signature,
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');
      throw Exception('Failed to delete image from Cloudinary: $errorMessage');
    }
  }

  Future<void> _deleteImage(String docId) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final docRef = _firestore
          .collection('admin_images')
          .doc(currentUser.uid)
          .collection('images')
          .doc(docId);

      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();

      if (data == null) throw Exception('Image data not found');

      final cloudinaryPublicId = data['cloudinaryPublicId'] as String?;

      // Delete from Firestore
      await docRef.delete();

      // Delete from Cloudinary if publicId is available
      if (cloudinaryPublicId != null && cloudinaryPublicId.isNotEmpty) {
        await _deleteFromCloudinary(cloudinaryPublicId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting image: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
      await _loadGalleryImages();
    }
  }

  String _optimizeCloudinaryUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final optimizedPath =
          path.replaceFirst('/upload/', '/upload/w_300,h_300,q_80/');
      return '${uri.scheme}://${uri.host}$optimizedPath';
    } catch (e) {
      print('Error optimizing URL $url: $e');
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view images')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF00B6B0),
        title: Text(
          'Image Gallery',
          style: GoogleFonts.oswald(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _loadGalleryImages,
            tooltip: 'Refresh Gallery',
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : _galleryImages.isEmpty
                ? const Center(child: Text('No images in gallery.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _galleryImages.length,
                    itemBuilder: (context, index) {
                      final image = _galleryImages[index];
                      final optimizedUrl =
                          _optimizeCloudinaryUrl(image['url']!);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: optimizedUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) {
                                print('Error loading image $url: $error');
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.error, color: Colors.red),
                                      Text('Loading...',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                              fadeInDuration: const Duration(milliseconds: 200),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white, size: 20),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteImage(image['id']!),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${image['category']}: ${image['subcategory']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
