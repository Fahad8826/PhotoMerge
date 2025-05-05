// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/rendering.dart';
// import 'dart:ui' as ui;
// import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:palette_generator/palette_generator.dart';
// import 'package:shimmer/shimmer.dart';

// class ListImages extends StatefulWidget {
//   const ListImages({Key? key}) : super(key: key);

//   @override
//   State<ListImages> createState() => _ListImagesState();
// }

// class _ListImagesState extends State<ListImages> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final String? userId = FirebaseAuth.instance.currentUser?.uid;
//   Map<String, dynamic>? userData;

//   // Cached maps for performance
//   final Map<String, GlobalKey> _photoKeys = {};
//   final Map<String, Color> _dominantColors = {};

//   // Pagination variables
//   static const int _pageSize = 10;
//   DocumentSnapshot? _lastDocument;
//   bool _isLoadingMore = false;
//   bool _hasMoreData = true;
//   final List<QueryDocumentSnapshot> _images = [];

//   // Layout toggle
//   bool _isGridView = false;

//   // Constants
//   static const String imagesSubcollection = 'images';
//   static const double fadeHeight = 120.0;
//   static const int maxColorCount = 8;
//   static const double pixelRatio = 2.0;

//   @override
//   void initState() {
//     super.initState();
//     _getUserData();
//     _loadInitialImages();
//   }

//   Future<void> _getUserData() async {
//     if (userId == null) return;
//     try {
//       final doc = await _firestore.collection('user_profile').doc(userId).get();
//       if (doc.exists) {
//         setState(() => userData = doc.data());
//       }
//     } catch (e) {
//       print('Error fetching user data: $e');
//     }
//   }

//   Future<void> _loadInitialImages() async {
//     if (_isLoadingMore) return;
//     setState(() => _isLoadingMore = true);

//     try {
//       final query = _firestore
//           .collectionGroup(imagesSubcollection)
//           .orderBy('timestamp', descending: true)
//           .limit(_pageSize);

//       final snapshot = await query.get();
//       setState(() {
//         _images.addAll(snapshot.docs);
//         _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//         _hasMoreData = snapshot.docs.length == _pageSize;
//         _isLoadingMore = false;
//       });
//     } catch (e) {
//       print('Error loading images: $e');
//       setState(() => _isLoadingMore = false);
//     }
//   }

//   Future<void> _loadMoreImages() async {
//     if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
//     setState(() => _isLoadingMore = true);

//     try {
//       final query = _firestore
//           .collectionGroup(imagesSubcollection)
//           .orderBy('timestamp', descending: true)
//           .startAfterDocument(_lastDocument!)
//           .limit(_pageSize);

//       final snapshot = await query.get();
//       setState(() {
//         _images.addAll(snapshot.docs);
//         _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
//         _hasMoreData = snapshot.docs.length == _pageSize;
//         _isLoadingMore = false;
//       });
//     } catch (e) {
//       print('Error loading more images: $e');
//       setState(() => _isLoadingMore = false);
//     }
//   }

//   Future<Color> _getDominantColor(String imageUrl) async {
//     if (_dominantColors.containsKey(imageUrl)) {
//       return _dominantColors[imageUrl]!;
//     }
//     try {
//       final paletteGenerator = await PaletteGenerator.fromImageProvider(
//         NetworkImage(imageUrl),
//         size: const Size(80, 80),
//         maximumColorCount: maxColorCount,
//       );
//       final dominantColor =
//           paletteGenerator.dominantColor?.color ?? Colors.grey.shade800;
//       _dominantColors[imageUrl] = dominantColor;
//       return dominantColor;
//     } catch (e) {
//       print('Error getting dominant color for $imageUrl: $e');
//       return Colors.grey.shade800;
//     }
//   }

//   Future<void> _captureAndSaveImage(String photoId, String photoUrl) async {
//     final status = await Permission.storage.request();
//     if (!status.isGranted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Storage permission denied')),
//       );
//       return;
//     }

//     final key = _photoKeys[photoId];
//     if (key == null || key.currentContext == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cannot capture image at this time')),
//       );
//       return;
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Processing image...')),
//     );

//     try {
//       final boundary =
//           key.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       final image = await boundary.toImage(pixelRatio: pixelRatio);
//       final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       final pngBytes = byteData!.buffer.asUint8List();

//       await FlutterImageGallerySaver.saveImage(pngBytes);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Image saved to gallery!'),
//         ),
//       );
//     } catch (e) {
//       print('Error saving image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Error saving image')),
//       );
//     }
//   }

//   Widget _buildPhotoCard(
//       String photoId, String photoUrl, Color backgroundColor) {
//     if (!_photoKeys.containsKey(photoId)) {
//       _photoKeys[photoId] = GlobalKey();
//     }

//     return Card(
//       key: ValueKey(photoId),
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       child: Column(
//         children: [
//           RepaintBoundary(
//             key: _photoKeys[photoId],
//             child: Column(
//               children: [
//                 AspectRatio(
//                   aspectRatio: 4 / 5,
//                   child: Stack(
//                     children: [
//                       CachedNetworkImage(
//                         imageUrl: photoUrl,
//                         fit: BoxFit.cover,
//                         width: double.infinity,
//                         placeholder: (context, url) => Shimmer.fromColors(
//                           baseColor: Colors.grey[300]!,
//                           highlightColor: Colors.grey[100]!,
//                           child: Container(color: Colors.grey[300]),
//                         ),
//                         errorWidget: (context, url, error) {
//                           print('Image load error for $url: $error');
//                           return const Icon(Icons.error, size: 48);
//                         },
//                       ),
//                       Positioned.fill(
//                         child: CustomPaint(
//                           painter: WatermarkPainter(),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         left: 0,
//                         right: 0,
//                         height: fadeHeight,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               begin: Alignment.topCenter,
//                               end: Alignment.bottomCenter,
//                               colors: [
//                                 Colors.transparent,
//                                 backgroundColor.withOpacity(0.2),
//                                 backgroundColor.withOpacity(0.5),
//                                 backgroundColor.withOpacity(0.8),
//                                 backgroundColor,
//                               ],
//                               stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (userData != null)
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: backgroundColor,
//                       borderRadius: const BorderRadius.vertical(
//                           bottom: Radius.circular(12)),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         CircleAvatar(
//                           radius: 28,
//                           backgroundImage: userData!['userImage'] != null
//                               ? NetworkImage(userData!['userImage'])
//                               : null,
//                           child: userData!['userImage'] == null
//                               ? const Icon(Icons.person, size: 28)
//                               : null,
//                         ),
//                         Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   userData!['firstName'] ?? 'Unknown User',
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 Text(
//                                   userData!['designation'] ?? 'No designation',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.white70,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.email,
//                                         size: 14, color: Colors.white70),
//                                     const SizedBox(width: 4),
//                                     Expanded(
//                                       child: Text(
//                                         userData!['email'] ?? 'No email',
//                                         style: const TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.white70,
//                                         ),
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         if (userData!['companyLogo'] != null &&
//                             userData!['companyLogo'].isNotEmpty)
//                           SizedBox(
//                             width: 60,
//                             height: 60,
//                             child: CachedNetworkImage(
//                               imageUrl: userData!['companyLogo'],
//                               fit: BoxFit.contain,
//                               placeholder: (context, url) =>
//                                   const CircularProgressIndicator(),
//                               errorWidget: (context, error, stackTrace) =>
//                                   const Icon(Icons.error),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: ElevatedButton.icon(
//               icon: const Icon(Icons.download, size: 20),
//               label: const Text('Download'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 44),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8)),
//               ),
//               onPressed: () => _captureAndSaveImage(photoId, photoUrl),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGridView() {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (notification) {
//         if (notification is ScrollEndNotification &&
//             notification.metrics.extentAfter < 500) {
//           _loadMoreImages();
//         }
//         return false;
//       },
//       child: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.7,
//         ),
//         itemCount: _images.length + (_hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == _images.length) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           final photo = _images[index].data() as Map<String, dynamic>;
//           final photoId = _images[index].id;
//           final photoUrl = photo['image_url'] ?? '';
//           return FutureBuilder<Color>(
//             future: _getDominantColor(photoUrl),
//             builder: (context, colorSnapshot) {
//               if (!colorSnapshot.hasData) {
//                 return Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//               return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildListView() {
//     return NotificationListener<ScrollNotification>(
//       onNotification: (notification) {
//         if (notification is ScrollEndNotification &&
//             notification.metrics.extentAfter < 500) {
//           _loadMoreImages();
//         }
//         return false;
//       },
//       child: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: _images.length + (_hasMoreData ? 1 : 0),
//         itemBuilder: (context, index) {
//           if (index == _images.length) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           final photo = _images[index].data() as Map<String, dynamic>;
//           final photoId = _images[index].id;
//           final photoUrl = photo['image_url'] ?? '';
//           return FutureBuilder<Color>(
//             future: _getDominantColor(photoUrl),
//             builder: (context, colorSnapshot) {
//               if (!colorSnapshot.hasData) {
//                 return Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[100]!,
//                   child: Container(
//                     height: 400,
//                     margin: const EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//               return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
//             },
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Photo Gallery'),
//         actions: [
//           IconButton(
//             icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
//             onPressed: () {
//               setState(() => _isGridView = !_isGridView);
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 _images.clear();
//                 _lastDocument = null;
//                 _hasMoreData = true;
//               });
//               _loadInitialImages();
//               _getUserData();
//             },
//           ),
//         ],
//       ),
//       body: userData == null
//           ? const Center(child: CircularProgressIndicator())
//           : _isGridView
//               ? _buildGridView()
//               : _buildListView(),
//     );
//   }
// }

// class WatermarkPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.2)
//       ..style = PaintingStyle.fill;

//     final textPainter = TextPainter(
//       text: const TextSpan(
//         text: 'Maxgrow',
//         style: TextStyle(
//           color: Colors.white70,
//           fontSize: 28,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );

//     textPainter.layout();
//     canvas.save();
//     canvas.translate(size.width / 2, size.height / 2);
//     canvas.rotate(-45 * 3.14159 / 180);
//     canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
//     textPainter.paint(canvas, Offset.zero);
//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shimmer/shimmer.dart';

class ListImages extends StatefulWidget {
  const ListImages({Key? key}) : super(key: key);

  @override
  State<ListImages> createState() => _ListImagesState();
}

class _ListImagesState extends State<ListImages> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;

  // Cached maps for performance
  final Map<String, GlobalKey> _photoKeys = {};
  final Map<String, Color> _dominantColors = {};
  final Map<String, AnimationController> _animationControllers = {};

  // Pagination variables
  static const int _pageSize = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final List<QueryDocumentSnapshot> _images = [];

  // Layout toggle
  bool _isGridView = false;

  // Constants
  static const String imagesSubcollection = 'images';
  static const double fadeHeight = 120.0;
  static const int maxColorCount = 8;
  static const double pixelRatio = 2.0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadInitialImages();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    _animationControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        setState(() => userData = doc.data());
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _loadInitialImages() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collectionGroup(imagesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();
      setState(() {
        _images.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreData = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });

      // Create animation controllers for new items
      for (var doc in snapshot.docs) {
        _createAnimationController(doc.id);
      }
    } catch (e) {
      print('Error loading images: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoadingMore || !_hasMoreData || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final query = _firestore
          .collectionGroup(imagesSubcollection)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();
      setState(() {
        _images.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMoreData = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });

      // Create animation controllers for new items
      for (var doc in snapshot.docs) {
        _createAnimationController(doc.id);
      }
    } catch (e) {
      print('Error loading more images: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  void _createAnimationController(String id) {
    if (!_animationControllers.containsKey(id)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _animationControllers[id] = controller;

      // Start the animation after a small delay
      Future.delayed(
          Duration(milliseconds: 50 * _animationControllers.length % 10), () {
        if (mounted && controller.isAnimating != true) {
          controller.forward();
        }
      });
    }
  }

  Future<Color> _getDominantColor(String imageUrl) async {
    if (_dominantColors.containsKey(imageUrl)) {
      return _dominantColors[imageUrl]!;
    }
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80),
        maximumColorCount: maxColorCount,
      );

      // Choose vibrant color if available, otherwise use dominant color
      final color = paletteGenerator.vibrantColor?.color ??
          paletteGenerator.dominantColor?.color ??
          Colors.grey.shade800;

      // Ensure the color is dark enough for white text
      final HSLColor hsl = HSLColor.fromColor(color);
      final adjustedColor =
          hsl.lightness > 0.7 ? hsl.withLightness(0.6).toColor() : color;

      _dominantColors[imageUrl] = adjustedColor;
      return adjustedColor;
    } catch (e) {
      print('Error getting dominant color for $imageUrl: $e');
      return Colors.grey.shade800;
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
      const SnackBar(content: Text('Processing A4 image...')),
    );

    try {
      // Create an A4 sized render object
      // A4 has 1:√2 ratio (width:height)
      // Standard A4 is 210×297mm, converting to pixels at 300 DPI: 2480×3508 pixels
      // For practical rendering purposes, we'll use a scaled version maintaining the ratio

      // Get the original render object to extract content
      final originalBoundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Create an offscreen canvas with A4 proportions
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // A4 dimensions (at a reasonable scale for mobile)
      const double a4Width = 1240.0; // half of 2480 (A4 width @ 300dpi)
      const double a4Height = 1754.0; // half of 3508 (A4 height @ 300dpi)

      // Fill with white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, a4Width, a4Height),
        Paint()..color = Colors.white,
      );

      // Get the original content as an image
      final originalImage =
          await originalBoundary.toImage(pixelRatio: pixelRatio);
      final originalImageByteData = await originalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (originalImageByteData != null) {
        final codec = await ui.instantiateImageCodec(
          originalImageByteData.buffer.asUint8List(),
        );
        final frameInfo = await codec.getNextFrame();

        // Calculate the scaling to fit the content within A4 while preserving aspect ratio
        final originalWidth = originalImage.width.toDouble();
        final originalHeight = originalImage.height.toDouble();

        // Calculate scaling factors
        final widthScale = a4Width / originalWidth;
        final heightScale = a4Height / originalHeight;

        // Use the smaller scaling factor to ensure the image fits entirely
        final scale = widthScale < heightScale ? widthScale : heightScale;

        // Calculate centered position
        final centeredX = (a4Width - (originalWidth * scale)) / 2;
        final centeredY = (a4Height - (originalHeight * scale)) / 2;

        // Draw the original image scaled and centered on A4 canvas
        canvas.drawImageRect(
          frameInfo.image,
          Rect.fromLTWH(0, 0, originalWidth, originalHeight),
          Rect.fromLTWH(centeredX, centeredY, originalWidth * scale,
              originalHeight * scale),
          Paint(),
        );

        // Convert the A4 canvas to an image
        final picture = recorder.endRecording();
        final a4Image =
            await picture.toImage(a4Width.toInt(), a4Height.toInt());
        final a4ByteData =
            await a4Image.toByteData(format: ui.ImageByteFormat.png);
        final a4PngBytes = a4ByteData!.buffer.asUint8List();

        // Save the A4 formatted image
        await FlutterImageGallerySaver.saveImage(a4PngBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A4 image saved to gallery!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error saving A4 image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving A4 image')),
      );
    }
  }

  Widget _buildPhotoCard(
      String photoId, String photoUrl, Color backgroundColor) {
    if (!_photoKeys.containsKey(photoId)) {
      _photoKeys[photoId] = GlobalKey();
    }

    final AnimationController animController = _animationControllers[photoId] ??
        AnimationController(duration: Duration.zero, vsync: this)
      ..forward();
    final Animation<double> fadeAnimation = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - fadeAnimation.value)),
          child: Opacity(
            opacity: fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        key: ValueKey(photoId),
        elevation: 8,
        shadowColor: backgroundColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // The RepaintBoundary now encompasses the entire content to be captured for A4
              RepaintBoundary(
                key: _photoKeys[photoId],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors
                        .white, // Ensure background is white for A4 paper look
                    child: Column(
                      children: [
                        // Image section
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 4 / 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Hero(
                                  tag: 'photo_$photoId',
                                  child: CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      child: Container(color: Colors.grey[300]),
                                    ),
                                    errorWidget: (context, url, error) {
                                      print(
                                          'Image load error for $url: $error');
                                      return const Icon(Icons.error, size: 48);
                                    },
                                  ),
                                ),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: WatermarkPainter(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: fadeHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          backgroundColor.withOpacity(0.3),
                                          backgroundColor.withOpacity(0.6),
                                          backgroundColor.withOpacity(0.9),
                                          backgroundColor,
                                        ],
                                        stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // User info section - adjusted for more A4-friendly layout
                        if (userData != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // User avatar with border
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.7),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.2),
                                        backgroundImage:
                                            userData!['userImage'] != null
                                                ? NetworkImage(
                                                    userData!['userImage'])
                                                : null,
                                        child: userData!['userImage'] == null
                                            ? const Icon(Icons.person,
                                                size: 28, color: Colors.white)
                                            : null,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userData!['firstName'] ??
                                                  'Unknown User',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 2,
                                                    color: Colors.black26,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              userData!['designation'] ??
                                                  'No designation',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.email,
                                                    size: 14,
                                                    color: Colors.white70),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    userData!['email'] ??
                                                        'No email',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white70,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (userData!['companyLogo'] != null &&
                                        userData!['companyLogo'].isNotEmpty)
                                      Container(
                                        width: 64,
                                        height: 64,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: userData!['companyLogo'],
                                          fit: BoxFit.contain,
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(),
                                          errorWidget:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        ),
                                      ),
                                  ],
                                ),
                                // Add an A4-optimized footer
                                const SizedBox(height: 16),
                                const Divider(
                                    color: Colors.white24, thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.link,
                                        size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      userData!['companyWebsite'] ??
                                          'companyWebsite',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        // Bottom part with A4-friendly rounded corners
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'A4 Document - ${DateTime.now().toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: backgroundColor.withOpacity(0.7),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Actions outside the RepaintBoundary - won't be included in saved image
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () =>
                            _captureAndSaveImage(photoId, photoUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipOval(
                      child: Material(
                        color: Colors.grey.shade200,
                        child: InkWell(
                          onTap: () {
                            // Share functionality can be added here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Share functionality coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.share_rounded,
                              size: 22,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 500) {
          _loadMoreImages();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: _images.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final photo = _images[index].data() as Map<String, dynamic>;
          final photoId = _images[index].id;
          final photoUrl = photo['image_url'] ?? '';
          return FutureBuilder<Color>(
            future: _getDominantColor(photoUrl),
            builder: (context, colorSnapshot) {
              if (!colorSnapshot.hasData) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }
              return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 500) {
          _loadMoreImages();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _images.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _images.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final photo = _images[index].data() as Map<String, dynamic>;
          final photoId = _images[index].id;
          final photoUrl = photo['image_url'] ?? '';
          return FutureBuilder<Color>(
            future: _getDominantColor(photoUrl),
            builder: (context, colorSnapshot) {
              if (!colorSnapshot.hasData) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 400,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              }
              return _buildPhotoCard(photoId, photoUrl, colorSnapshot.data!);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Photo Gallery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _images.clear();
                _lastDocument = null;
                _hasMoreData = true;

                // Dispose and clear animation controllers
                _animationControllers.forEach((key, controller) {
                  controller.dispose();
                });
                _animationControllers.clear();
              });
              _loadInitialImages();
              _getUserData();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
            ],
          ),
        ),
        child: userData == null
            ? const Center(child: CircularProgressIndicator())
            : _isGridView
                ? _buildGridView()
                : _buildListView(),
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Maxgrow',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-45 * 3.14159 / 180);
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
