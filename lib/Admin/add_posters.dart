// // import 'dart:convert';
// // import 'dart:io';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:image/image.dart' as img;
// // import 'package:cached_network_image/cached_network_image.dart';

// // class AddImagePage extends StatefulWidget {
// //   const AddImagePage({super.key});

// //   @override
// //   State<AddImagePage> createState() => _AddImagePageState();
// // }

// // class _AddImagePageState extends State<AddImagePage> {
// //   final _firebaseAuth = FirebaseAuth.instance;
// //   List<File> _selectedImages = [];
// //   bool _isUploading = false;
// //   bool _isDeleting = false;

// //   List<Map<String, String>> _galleryImages = [];

// //   final List<String> _categories = [
// //     'Nature',
// //     'Portrait',
// //     'Architecture',
// //     'Food',
// //     'Travel',
// //     'Other'
// //   ];
// //   String _selectedCategory = 'Other';

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadGalleryImages();
// //   }

// //   Future<void> _loadGalleryImages() async {
// //     final currentUser = _firebaseAuth.currentUser;
// //     if (currentUser == null) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text('No user is currently signed in.')),
// //         );
// //       }
// //       return;
// //     }

// //     try {
// //       final snapshot = await FirebaseFirestore.instance
// //           .collection('admin_images')
// //           .doc(currentUser.uid)
// //           .collection('images')
// //           .orderBy('timestamp', descending: true)
// //           .get();

// //       if (mounted) {
// //         setState(() {
// //           _galleryImages = snapshot.docs
// //               .map((doc) => {
// //                     'id': doc.id,
// //                     'url': doc['image_url'] as String,
// //                     'category': (doc.data().containsKey('category')
// //                         ? doc['category']
// //                         : 'Other') as String,
// //                   })
// //               .toList();
// //         });

// //         print('Loaded ${_galleryImages.length} images');
// //         for (var img in _galleryImages) {
// //           print('Image URL: ${img['url']}');
// //         }
// //       }
// //     } catch (e) {
// //       print('Error loading gallery images: $e');
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text('Error loading gallery: $e')),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> _pickImages() async {
// //     final picker = ImagePicker();
// //     final pickedFiles = await picker.pickMultiImage();

// //     if (pickedFiles.isNotEmpty) {
// //       setState(() {
// //         _selectedImages
// //             .addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
// //       });
// //     }
// //   }

// //   Future<File> _compressImage(File imageFile) async {
// //     final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
// //     if (image == null) return imageFile;

// //     final img.Image resized = img.copyResize(image,
// //         width: 800, interpolation: img.Interpolation.average);
// //     final compressedBytes = img.encodeJpg(resized, quality: 80);

// //     final tempDir = Directory.systemTemp;
// //     final tempFile = File(
// //         '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
// //     await tempFile.writeAsBytes(compressedBytes);

// //     return tempFile;
// //   }

// //   Future<String?> _uploadToCloudinary(File image) async {
// //     try {
// //       final compressedImage = await _compressImage(image);

// //       final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
// //       final request = http.MultipartRequest('POST', url);

// //       request.fields['upload_preset'] = 'TempApp';
// //       request.files
// //           .add(await http.MultipartFile.fromPath('file', compressedImage.path));

// //       final response = await request.send();
// //       if (response.statusCode == 200) {
// //         final responseData = await response.stream.toBytes();
// //         final responseString = String.fromCharCodes(responseData);
// //         final jsonMap = jsonDecode(responseString);
// //         return jsonMap['secure_url'] as String;
// //       } else {
// //         throw HttpException('Upload failed with status ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error uploading image: $e')),
// //       );
// //       return null;
// //     }
// //   }

// //   Future<void> _uploadImages() async {
// //     final currentUser = _firebaseAuth.currentUser;
// //     if (currentUser == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No user is currently signed in.')),
// //       );
// //       return;
// //     }

// //     if (_selectedImages.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No images selected.')),
// //       );
// //       return;
// //     }

// //     setState(() => _isUploading = true);

// //     try {
// //       for (var image in _selectedImages) {
// //         final imageUrl = await _uploadToCloudinary(image);
// //         if (imageUrl != null) {
// //           print('Uploading image with URL: $imageUrl');
// //           print('Category: $_selectedCategory');

// //           await FirebaseFirestore.instance
// //               .collection('admin_images')
// //               .doc(currentUser.uid)
// //               .collection('images')
// //               .add({
// //             'image_url': imageUrl,
// //             'category': _selectedCategory,
// //             'timestamp': FieldValue.serverTimestamp(),
// //           });
// //         }
// //       }

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Images uploaded successfully')),
// //       );
// //     } catch (e) {
// //       print('Error uploading images: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error uploading images: $e')),
// //       );
// //     } finally {
// //       setState(() {
// //         _isUploading = false;
// //         _selectedImages.clear();
// //       });
// //       await _loadGalleryImages();
// //     }
// //   }

// //   Future<void> _deleteImage(String docId, String imageUrl) async {
// //     final currentUser = _firebaseAuth.currentUser;
// //     if (currentUser == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('No user is currently signed in.')),
// //       );
// //       return;
// //     }

// //     final confirmed = await showDialog<bool>(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text('Delete Image'),
// //         content: const Text('Are you sure you want to delete this image?'),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, false),
// //             child: const Text('Cancel'),
// //           ),
// //           TextButton(
// //             onPressed: () => Navigator.pop(context, true),
// //             child: const Text('Delete', style: TextStyle(color: Colors.red)),
// //           ),
// //         ],
// //       ),
// //     );

// //     if (confirmed != true) return;

// //     setState(() => _isDeleting = true);

// //     try {
// //       await FirebaseFirestore.instance
// //           .collection('admin_images')
// //           .doc(currentUser.uid)
// //           .collection('images')
// //           .doc(docId)
// //           .delete();

// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Image deleted successfully')),
// //       );
// //     } catch (e) {
// //       print('Error deleting image: $e');
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text('Error deleting image: $e')),
// //       );
// //     } finally {
// //       setState(() => _isDeleting = false);
// //       await _loadGalleryImages();
// //     }
// //   }

// //   String _optimizeCloudinaryUrl(String url) {
// //     try {
// //       final uri = Uri.parse(url);
// //       final path = uri.path;
// //       final optimizedPath =
// //           path.replaceFirst('/upload/', '/upload/w_300,h_300,q_80/');
// //       return '${uri.scheme}://${uri.host}$optimizedPath';
// //     } catch (e) {
// //       print('Error optimizing URL $url: $e');
// //       return url; // Fallback to original URL if optimization fails
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Add Images'),
// //         centerTitle: true,
// //       ),
// //       backgroundColor: Colors.white,
// //       body: _isUploading || _isDeleting
// //           ? const Center(child: CircularProgressIndicator())
// //           : Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Container(
// //                     padding: const EdgeInsets.symmetric(horizontal: 12),
// //                     decoration: BoxDecoration(
// //                       border: Border.all(color: Colors.grey.shade300),
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     child: DropdownButtonHideUnderline(
// //                       child: DropdownButton<String>(
// //                         isExpanded: true,
// //                         value: _selectedCategory,
// //                         hint: const Text('Select Category'),
// //                         items: _categories.map((String category) {
// //                           return DropdownMenuItem<String>(
// //                             value: category,
// //                             child: Text(category),
// //                           );
// //                         }).toList(),
// //                         onChanged: (String? newValue) {
// //                           if (newValue != null) {
// //                             setState(() {
// //                               _selectedCategory = newValue;
// //                             });
// //                           }
// //                         },
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   if (_selectedImages.isNotEmpty)
// //                     SizedBox(
// //                       height: 100,
// //                       child: ListView.builder(
// //                         scrollDirection: Axis.horizontal,
// //                         itemCount: _selectedImages.length,
// //                         itemBuilder: (context, index) {
// //                           return Padding(
// //                             padding: const EdgeInsets.only(right: 8.0),
// //                             child: Stack(
// //                               children: [
// //                                 ClipRRect(
// //                                   borderRadius: BorderRadius.circular(8),
// //                                   child: Image.file(
// //                                     _selectedImages[index],
// //                                     width: 80,
// //                                     height: 80,
// //                                     fit: BoxFit.cover,
// //                                   ),
// //                                 ),
// //                                 Positioned(
// //                                   top: 0,
// //                                   right: 0,
// //                                   child: IconButton(
// //                                     icon: const Icon(Icons.remove_circle,
// //                                         color: Colors.red),
// //                                     onPressed: () {
// //                                       setState(() {
// //                                         _selectedImages.removeAt(index);
// //                                       });
// //                                     },
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         },
// //                       ),
// //                     ),
// //                   const SizedBox(height: 10),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     children: [
// //                       ElevatedButton.icon(
// //                         onPressed: _pickImages,
// //                         icon: const Icon(Icons.add_photo_alternate),
// //                         label: const Text('Pick Images'),
// //                         style: ElevatedButton.styleFrom(
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                         ),
// //                       ),
// //                       ElevatedButton.icon(
// //                         onPressed:
// //                             _selectedImages.isNotEmpty ? _uploadImages : null,
// //                         icon: const Icon(Icons.cloud_upload),
// //                         label: const Text('Upload'),
// //                         style: ElevatedButton.styleFrom(
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(12),
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 20),
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       const Text(
// //                         'Image Gallery',
// //                         style: TextStyle(
// //                             fontSize: 18, fontWeight: FontWeight.bold),
// //                       ),
// //                       IconButton(
// //                         icon: const Icon(Icons.refresh),
// //                         onPressed: _loadGalleryImages,
// //                         tooltip: 'Refresh Gallery',
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 10),
// //                   Expanded(
// //                     child: _galleryImages.isEmpty
// //                         ? const Center(child: Text('No images in gallery.'))
// //                         : GridView.builder(
// //                             gridDelegate:
// //                                 const SliverGridDelegateWithFixedCrossAxisCount(
// //                               crossAxisCount: 3,
// //                               crossAxisSpacing: 8,
// //                               mainAxisSpacing: 8,
// //                               childAspectRatio: 1,
// //                             ),
// //                             itemCount: _galleryImages.length,
// //                             itemBuilder: (context, index) {
// //                               final image = _galleryImages[index];
// //                               final optimizedUrl =
// //                                   _optimizeCloudinaryUrl(image['url']!);
// //                               return Stack(
// //                                 fit: StackFit.expand,
// //                                 children: [
// //                                   ClipRRect(
// //                                     borderRadius: BorderRadius.circular(8),
// //                                     child: CachedNetworkImage(
// //                                       imageUrl: optimizedUrl,
// //                                       fit: BoxFit.cover,
// //                                       placeholder: (context, url) => Center(
// //                                         child: CircularProgressIndicator(),
// //                                       ),
// //                                       errorWidget: (context, url, error) {
// //                                         print(
// //                                             'Error loading image $url: $error');
// //                                         return Center(
// //                                           child: Column(
// //                                             mainAxisAlignment:
// //                                                 MainAxisAlignment.center,
// //                                             children: [
// //                                               Icon(Icons.error,
// //                                                   color: Colors.red),
// //                                               Text('Loading...',
// //                                                   style: TextStyle(
// //                                                       color: Colors.grey)),
// //                                             ],
// //                                           ),
// //                                         );
// //                                       },
// //                                       fadeInDuration:
// //                                           const Duration(milliseconds: 200),
// //                                     ),
// //                                   ),
// //                                   Positioned(
// //                                     top: 0,
// //                                     right: 0,
// //                                     child: Container(
// //                                       decoration: BoxDecoration(
// //                                         color: Colors.black.withOpacity(0.5),
// //                                         borderRadius: BorderRadius.circular(4),
// //                                       ),
// //                                       child: IconButton(
// //                                         icon: const Icon(Icons.delete,
// //                                             color: Colors.white, size: 20),
// //                                         padding: const EdgeInsets.all(4),
// //                                         constraints: const BoxConstraints(),
// //                                         onPressed: () => _deleteImage(
// //                                             image['id']!, image['url']!),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                   Positioned(
// //                                     bottom: 0,
// //                                     left: 0,
// //                                     right: 0,
// //                                     child: Container(
// //                                       color: Colors.black.withOpacity(0.6),
// //                                       padding: const EdgeInsets.symmetric(
// //                                           vertical: 4),
// //                                       child: Text(
// //                                         image['category'] ?? 'Other',
// //                                         textAlign: TextAlign.center,
// //                                         style: const TextStyle(
// //                                             color: Colors.white, fontSize: 10),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ],
// //                               );
// //                             },
// //                           ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //     );
// //   }
// // }
// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:cached_network_image/cached_network_image.dart';

// class AddImagePage extends StatefulWidget {
//   const AddImagePage({super.key});

//   @override
//   State<AddImagePage> createState() => _AddImagePageState();
// }

// class _AddImagePageState extends State<AddImagePage> {
//   final _firebaseAuth = FirebaseAuth.instance;
//   List<File> _selectedImages = [];
//   bool _isUploading = false;
//   bool _isDeleting = false;
//   bool _isCropping = false;

//   List<Map<String, String>> _galleryImages = [];

//   final List<String> categories = [
//     'Nature',
//     'Portrait',
//     'Architecture',
//     'Food',
//     'Travel',
//     'Other'
//   ];
//   String _selectedCategory = 'Other';

//   // Default crop dimensions for reference
//   final int _cropWidth = 941;
//   final int _cropHeight = 1280;

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
//       final snapshot = await FirebaseFirestore.instance
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
//                   })
//               .toList();
//         });

//         print('Loaded ${_galleryImages.length} images');
//         for (var img in _galleryImages) {
//           print('Image URL: ${img['url']}');
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

//   Future<void> _pickImages() async {
//     final picker = ImagePicker();
//     final pickedFiles = await picker.pickMultiImage();

//     if (pickedFiles.isNotEmpty) {
//       setState(() => _isCropping = true);

//       try {
//         List<File> processedImages = [];

//         for (var pickedFile in pickedFiles) {
//           // Use existing image processing instead of external cropper
//           File imageFile = File(pickedFile.path);
//           File processedFile = await _cropAndResizeImage(imageFile);
//           processedImages.add(processedFile);
//         }

//         if (mounted) {
//           setState(() {
//             _selectedImages.addAll(processedImages);
//           });
//         }
//       } catch (e) {
//         print('Error processing images: $e');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error processing images: $e')),
//           );
//         }
//       } finally {
//         if (mounted) {
//           setState(() => _isCropping = false);
//         }
//       }
//     }
//   }

//   // Crop and resize the image using the image package instead of image_cropper
//   Future<File> _cropAndResizeImage(File imageFile) async {
//     try {
//       final bytes = await imageFile.readAsBytes();
//       final originalImage = img.decodeImage(bytes);

//       if (originalImage == null) {
//         throw Exception('Could not decode image');
//       }

//       // Calculate crop dimensions to maintain aspect ratio
//       int srcWidth = originalImage.width;
//       int srcHeight = originalImage.height;

//       double srcAspect = srcWidth / srcHeight;
//       double targetAspect = _cropWidth / _cropHeight;

//       int cropWidth, cropHeight;
//       int x = 0, y = 0;

//       if (srcAspect > targetAspect) {
//         // Original is wider than target, crop width
//         cropHeight = srcHeight;
//         cropWidth = (srcHeight * targetAspect).round();
//         x = ((srcWidth - cropWidth) / 2).round();
//       } else {
//         // Original is taller than target, crop height
//         cropWidth = srcWidth;
//         cropHeight = (srcWidth / targetAspect).round();
//         y = ((srcHeight - cropHeight) / 2).round();
//       }

//       // Crop the image
//       final croppedImage = img.copyCrop(
//         originalImage,
//         x: x,
//         y: y,
//         width: cropWidth,
//         height: cropHeight,
//       );

//       // Resize to exact dimensions if needed
//       final resizedImage = img.copyResize(
//         croppedImage,
//         width: _cropWidth,
//         height: _cropHeight,
//         interpolation: img.Interpolation.linear,
//       );

//       // Save to temporary file
//       final tempDir = Directory.systemTemp;
//       final tempFile = File(
//           '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');

//       final encodedBytes = img.encodeJpg(resizedImage, quality: 90);
//       await tempFile.writeAsBytes(encodedBytes);

//       return tempFile;
//     } catch (e) {
//       print("Error during image crop and resize: $e");
//       // Return original file if processing fails
//       return imageFile;
//     }
//   }

//   Future<File> _compressImage(File imageFile) async {
//     final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
//     if (image == null) return imageFile;

//     final img.Image resized = img.copyResize(image,
//         width: 800, interpolation: img.Interpolation.average);
//     final compressedBytes = img.encodeJpg(resized, quality: 80);

//     final tempDir = Directory.systemTemp;
//     final tempFile = File(
//         '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
//     await tempFile.writeAsBytes(compressedBytes);

//     return tempFile;
//   }

//   Future<String?> _uploadToCloudinary(File image) async {
//     try {
//       final compressedImage = await _compressImage(image);

//       final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
//       final request = http.MultipartRequest('POST', url);

//       request.fields['upload_preset'] = 'TempApp';
//       request.files
//           .add(await http.MultipartFile.fromPath('file', compressedImage.path));

//       final response = await request.send();
//       if (response.statusCode == 200) {
//         final responseData = await response.stream.toBytes();
//         final responseString = String.fromCharCodes(responseData);
//         final jsonMap = jsonDecode(responseString);
//         return jsonMap['secure_url'] as String;
//       } else {
//         throw HttpException('Upload failed with status ${response.statusCode}');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error uploading image: $e')),
//       );
//       return null;
//     }
//   }

//   Future<void> _uploadImages() async {
//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No user is currently signed in.')),
//       );
//       return;
//     }

//     if (_selectedImages.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No images selected.')),
//       );
//       return;
//     }

//     setState(() => _isUploading = true);

//     try {
//       for (var image in _selectedImages) {
//         final imageUrl = await _uploadToCloudinary(image);
//         if (imageUrl != null) {
//           print('Uploading image with URL: $imageUrl');
//           print('Category: $_selectedCategory');

//           await FirebaseFirestore.instance
//               .collection('admin_images')
//               .doc(currentUser.uid)
//               .collection('images')
//               .add({
//             'image_url': imageUrl,
//             'category': _selectedCategory,
//             'timestamp': FieldValue.serverTimestamp(),
//           });
//         }
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Images uploaded successfully')),
//       );
//     } catch (e) {
//       print('Error uploading images: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error uploading images: $e')),
//       );
//     } finally {
//       setState(() {
//         _isUploading = false;
//         _selectedImages.clear();
//       });
//       await _loadGalleryImages();
//     }
//   }

//   Future<void> _deleteImage(String docId, String imageUrl) async {
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
//       await FirebaseFirestore.instance
//           .collection('admin_images')
//           .doc(currentUser.uid)
//           .collection('images')
//           .doc(docId)
//           .delete();

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
//       return url; // Fallback to original URL if optimization fails
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Images'),
//         centerTitle: true,
//       ),
//       backgroundColor: Colors.white,
//       body: _isUploading || _isDeleting || _isCropping
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text(
//                     _isCropping
//                         ? 'Processing images...'
//                         : _isUploading
//                             ? 'Uploading images...'
//                             : 'Deleting image...',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ],
//               ),
//             )
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         isExpanded: true,
//                         value: _selectedCategory,
//                         hint: const Text('Select Category'),
//                         items: categories.map((String category) {
//                           return DropdownMenuItem<String>(
//                             value: category,
//                             child: Text(category),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           if (newValue != null) {
//                             setState(() {
//                               _selectedCategory = newValue;
//                             });
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   if (_selectedImages.isNotEmpty)
//                     SizedBox(
//                       height: 100,
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _selectedImages.length,
//                         itemBuilder: (context, index) {
//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: Stack(
//                               children: [
//                                 ClipRRect(
//                                   borderRadius: BorderRadius.circular(8),
//                                   child: Image.file(
//                                     _selectedImages[index],
//                                     width: 80,
//                                     height: 80,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                                 Positioned(
//                                   top: 0,
//                                   right: 0,
//                                   child: IconButton(
//                                     icon: const Icon(Icons.remove_circle,
//                                         color: Colors.red),
//                                     onPressed: () {
//                                       setState(() {
//                                         _selectedImages.removeAt(index);
//                                       });
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: _pickImages,
//                         icon: const Icon(Icons.add_photo_alternate),
//                         label: const Text('Pick & Crop'),
//                         style: ElevatedButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                       ElevatedButton.icon(
//                         onPressed:
//                             _selectedImages.isNotEmpty ? _uploadImages : null,
//                         icon: const Icon(Icons.cloud_upload),
//                         label: const Text('Upload'),
//                         style: ElevatedButton.styleFrom(
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   // Display crop dimensions info
//                   Center(
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 8.0),
//                       child: Text(
//                         'Images will be cropped to $_cropWidth x $_cropHeight',
//                         style: TextStyle(color: Colors.grey, fontSize: 12),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Image Gallery',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.refresh),
//                         onPressed: _loadGalleryImages,
//                         tooltip: 'Refresh Gallery',
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Expanded(
//                     child: _galleryImages.isEmpty
//                         ? const Center(child: Text('No images in gallery.'))
//                         : GridView.builder(
//                             gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 3,
//                               crossAxisSpacing: 8,
//                               mainAxisSpacing: 8,
//                               childAspectRatio: 1,
//                             ),
//                             itemCount: _galleryImages.length,
//                             itemBuilder: (context, index) {
//                               final image = _galleryImages[index];
//                               final optimizedUrl =
//                                   _optimizeCloudinaryUrl(image['url']!);
//                               return Stack(
//                                 fit: StackFit.expand,
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: CachedNetworkImage(
//                                       imageUrl: optimizedUrl,
//                                       fit: BoxFit.cover,
//                                       placeholder: (context, url) => Center(
//                                         child: CircularProgressIndicator(),
//                                       ),
//                                       errorWidget: (context, url, error) {
//                                         print(
//                                             'Error loading image $url: $error');
//                                         return Center(
//                                           child: Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Icon(Icons.error,
//                                                   color: Colors.red),
//                                               Text('Loading...',
//                                                   style: TextStyle(
//                                                       color: Colors.grey)),
//                                             ],
//                                           ),
//                                         );
//                                       },
//                                       fadeInDuration:
//                                           const Duration(milliseconds: 200),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     top: 0,
//                                     right: 0,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         color: Colors.black.withOpacity(0.5),
//                                         borderRadius: BorderRadius.circular(4),
//                                       ),
//                                       child: IconButton(
//                                         icon: const Icon(Icons.delete,
//                                             color: Colors.white, size: 20),
//                                         padding: const EdgeInsets.all(4),
//                                         constraints: const BoxConstraints(),
//                                         onPressed: () => _deleteImage(
//                                             image['id']!, image['url']!),
//                                       ),
//                                     ),
//                                   ),
//                                   Positioned(
//                                     bottom: 0,
//                                     left: 0,
//                                     right: 0,
//                                     child: Container(
//                                       color: Colors.black.withOpacity(0.6),
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 4),
//                                       child: Text(
//                                         image['category'] ?? 'Other',
//                                         textAlign: TextAlign.center,
//                                         style: const TextStyle(
//                                             color: Colors.white, fontSize: 10),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';

class AddImagePage extends StatefulWidget {
  const AddImagePage({super.key});

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  bool _isDeleting = false;
  bool _isCropping = false;

  List<Map<String, String>> _galleryImages = [];

  final List<String> categories = [
    'Nature',
    'Portrait',
    'Architecture',
    'Food',
    'Travel',
    'Other'
  ];
  String _selectedCategory = 'Other';

  final int _cropWidth = 941;
  final int _cropHeight = 1280;

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
      final categoryCollection = FirebaseFirestore.instance
          .collection('admin_images')
          .doc(currentUser.uid)
          .collection('category');
      _galleryImages.clear();

      for (String category in categories) {
        final categorySnapshot = await categoryCollection
            .doc(category)
            .collection(category)
            .orderBy('timestamp', descending: true)
            .get();
        final categoryImages = categorySnapshot.docs.map((doc) => {
              'id': doc.id,
              'url': doc['image_url'] as String,
              'category': category,
            }).toList();
        _galleryImages.addAll(categoryImages);
      }

      if (mounted) {
        setState(() {});
        print('Loaded ${_galleryImages.length} images');
        for (var img in _galleryImages) {
          print('Image URL: ${img['url']}, Category: ${img['category']}');
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() => _isCropping = true);

      try {
        List<File> processedImages = [];

        for (var pickedFile in pickedFiles) {
          File imageFile = File(pickedFile.path);
          File processedFile = await _cropAndResizeImage(imageFile);
          processedImages.add(processedFile);
        }

        if (mounted) {
          setState(() {
            _selectedImages.addAll(processedImages);
          });
        }
      } catch (e) {
        print('Error processing images: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error processing images: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCropping = false);
        }
      }
    }
  }

  Future<File> _cropAndResizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      int srcWidth = originalImage.width;
      int srcHeight = originalImage.height;

      double srcAspect = srcWidth / srcHeight;
      double targetAspect = _cropWidth / _cropHeight;

      int cropWidth, cropHeight;
      int x = 0, y = 0;

      if (srcAspect > targetAspect) {
        cropHeight = srcHeight;
        cropWidth = (srcHeight * targetAspect).round();
        x = ((srcWidth - cropWidth) / 2).round();
      } else {
        cropWidth = srcWidth;
        cropHeight = (srcWidth / targetAspect).round();
        y = ((srcHeight - cropHeight) / 2).round();
      }

      final croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: cropWidth,
        height: cropHeight,
      );

      final resizedImage = img.copyResize(
        croppedImage,
        width: _cropWidth,
        height: _cropHeight,
        interpolation: img.Interpolation.linear,
      );

      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final encodedBytes = img.encodeJpg(resizedImage, quality: 90);
      await tempFile.writeAsBytes(encodedBytes);

      return tempFile;
    } catch (e) {
      print("Error during image crop and resize: $e");
      return imageFile;
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) return imageFile;

    final img.Image resized = img.copyResize(image,
        width: 800, interpolation: img.Interpolation.average);
    final compressedBytes = img.encodeJpg(resized, quality: 80);

    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final compressedImage = await _compressImage(image);

      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'TempApp';
      request.files
          .add(await http.MultipartFile.fromPath('file', compressedImage.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'] as String;
      } else {
        throw HttpException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _uploadImages() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user is currently signed in.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images selected.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (var image in _selectedImages) {
        final imageUrl = await _uploadToCloudinary(image);
        if (imageUrl != null) {
          print('Uploading image with URL: $imageUrl');
          print('Category: $_selectedCategory');

          await FirebaseFirestore.instance
              .collection('admin_images')
              .doc(currentUser.uid)
              .collection('category')
              .doc(_selectedCategory)
              .collection(_selectedCategory)
              .add({
            'image_url': imageUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully')),
      );
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImages.clear();
      });
      await _loadGalleryImages();
    }
  }

  Future<void> _deleteImage(String docId, String imageUrl) async {
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
      String? category;
      for (var img in _galleryImages) {
        if (img['id'] == docId && img['url'] == imageUrl) {
          category = img['category'];
          break;
        }
      }

      if (category != null) {
        await FirebaseFirestore.instance
            .collection('admin_images')
            .doc(currentUser.uid)
            .collection('category')
            .doc(category)
            .collection(category)
            .doc(docId)
            .delete();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Images'),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isUploading || _isDeleting || _isCropping
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    _isCropping
                        ? 'Processing images...'
                        : _isUploading
                            ? 'Uploading images...'
                            : 'Deleting image...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        hint: const Text('Select Category'),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Pick & Crop'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _selectedImages.isNotEmpty ? _uploadImages : null,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Images will be cropped to $_cropWidth x $_cropHeight',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Image Gallery',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadGalleryImages,
                        tooltip: 'Refresh Gallery',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _galleryImages.isEmpty
                        ? const Center(child: Text('No images in gallery.'))
                        : GridView.builder(
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
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) {
                                        print(
                                            'Error loading image $url: $error');
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error,
                                                  color: Colors.red),
                                              Text('Loading...',
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        );
                                      },
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
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
                                        onPressed: () => _deleteImage(
                                            image['id']!, image['url']!),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Text(
                                        image['category'] ?? 'Other',
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
                ],
              ),
            ),
    );
  }
}