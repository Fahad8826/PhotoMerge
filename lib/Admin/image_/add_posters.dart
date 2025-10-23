
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

class AddImagePage extends StatefulWidget {
  const AddImagePage({Key? key}) : super(key: key);

  @override
  State<AddImagePage> createState() => _AddImagePageState();
}

class _AddImagePageState extends State<AddImagePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  String? _selectedCategory = null;
  String? _selectedSubcategory;

  // Crop functionality
  Future<File?> cropImage(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      var croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarColor: Color(0xFF00B6B0),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            cropGridStrokeWidth: 2,
            cropFrameStrokeWidth: 3,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      print('Error cropping image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
      return null;
    }
  }

  // Compress functionality
  Future<File?> compress({
    required File image,
    int quality = 70,
    int minWidth = 800,
    int minHeight = 600,
  }) async {
    try {
      // Check if the input file exists
      if (!await image.exists()) {
        print('Input image file does not exist');
        return null;
      }

      print('Original file size: ${await image.length()} bytes');

      final dir = await getTemporaryDirectory();

      // Generate a unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(1000);
      final extension = path.extension(image.path);
      final targetPath =
          path.join(dir.path, 'compressed_${timestamp}_${random}$extension');

      print('Compressing to: $targetPath');

      final result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        print('Compressed file size: ${await compressedFile.length()} bytes');
        return compressedFile;
      } else {
        print('Compression failed - result is null');
        return null;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      List<File> processedImages = [];
      for (var pickedFile in pickedFiles) {
        File imageFile = File(pickedFile.path);

        // Show dialog to ask user if they want to crop the image
        bool? shouldCrop = await _showCropDialog();

        if (shouldCrop == true) {
          // Crop the image
          final croppedFile = await cropImage(imageFile);
          if (croppedFile != null) {
            imageFile = croppedFile;
          }
        }

        // Compress the image (optional)
        final compressedFile = await compress(image: imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
        }

        // Resize the image to final dimensions
        final resizedFile = await _resizeImage(imageFile);
        if (resizedFile != null) {
          processedImages.add(resizedFile);
        }
      }

      setState(() {
        _selectedImages.addAll(processedImages);
      });
    }
  }

  // Dialog to ask user if they want to crop
  Future<bool?> _showCropDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crop Image'),
          content:
              const Text('Do you want to crop this image before uploading?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Skip'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Crop'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Function to resize image to exactly 2480px width (maintaining aspect ratio)
  Future<File?> _resizeImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;

      // Resize the image to 2480px width
      final resizedImage = img.copyResize(
        originalImage,
        width: 2480,
      );

      // Save the resized image
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(targetPath);

      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 90));

      return resizedFile;
    } catch (e) {
      print('Error resizing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resizing image: $e')),
      );
      return null;
    }
  }

  // Function to crop a specific image from the selected list
  Future<void> _cropSelectedImage(int index) async {
    final croppedFile = await cropImage(_selectedImages[index]);
    if (croppedFile != null) {
      // Resize the cropped image
      final resizedFile = await _resizeImage(croppedFile);
      if (resizedFile != null) {
        setState(() {
          _selectedImages[index] = resizedFile;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image cropped successfully')),
        );
      }
    }
  }

  Future<String?> _uploadToCloudinary(File image) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dlacr6mpw/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = 'BrandBuilder';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

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
      print('Error uploading to Cloudinary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading to Cloudinary: $e')),
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

    if (_selectedCategory == null || _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category and subcategory.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (var i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final imageUrl = await _uploadToCloudinary(image);

        if (imageUrl != null) {
          await _firestore
              .collection('admin_images')
              .doc(currentUser.uid)
              .collection('images')
              .add({
            'image_url': imageUrl,
            'category': _selectedCategory,
            'subcategory': _selectedSubcategory,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to add images')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please wait for upload to complete.')),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF00B6B0),
          title: Text(
            'Add Images',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 25,
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
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 30.0),
          color: Colors.white,
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Dropdown
                      StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('categories')
                              .where('createdBy', isEqualTo: currentUser.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final categories = snapshot.data?.docs
                                    .map((doc) => doc['name'] as String)
                                    .toList() ??
                                [];

                            if (categories.isEmpty) {
                              return const Text(
                                'No categories available. Please add categories first.',
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 3,
                                    blurRadius: 6,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedCategory,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: const Text(
                                    'Select Category',
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 16),
                                  ),
                                ),
                                items: categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0, horizontal: 16.0),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                    _selectedSubcategory = null;
                                  });
                                },
                                underline: Container(),
                                iconSize: 30.0,
                                style: TextStyle(fontSize: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 10.0),
                              ),
                            );
                          }),
                      const SizedBox(height: 50),
                      // Subcategory Dropdown
                      StreamBuilder<DocumentSnapshot>(
                        stream: _selectedCategory != null
                            ? _firestore
                                .collection('categories')
                                .where('name', isEqualTo: _selectedCategory)
                                .where('createdBy', isEqualTo: currentUser.uid)
                                .snapshots()
                                .map((snapshot) => snapshot.docs.first)
                            : null,
                        builder: (context, snapshot) {
                          if (_selectedCategory == null ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          final subcategories = List<String>.from(
                              snapshot.data?['subcategories'] ?? []);
                          if (subcategories.isEmpty) {
                            return const Text(
                                'No subcategories available for this category.');
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedSubcategory,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  'Select Subcategory',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              items: subcategories.map((subcategory) {
                                return DropdownMenuItem<String>(
                                  value: subcategory,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      subcategory,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubcategory = value;
                                });
                              },
                              underline: Container(),
                              iconSize: 30.0,
                              style: const TextStyle(fontSize: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selected Images Preview with crop option
                      if (_selectedImages.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Images (Processed)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.file(
                                            _selectedImages[index],
                                            width: 80,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        // Remove button
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                          ),
                                        ),
                                        // Crop button
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.crop,
                                                color: Color(0xFF00B6B0),
                                                size: 20),
                                            onPressed: () {
                                              _cropSelectedImage(index);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Pick Images',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B6B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectedImages.isNotEmpty
                                ? _uploadImages
                                : null,
                            icon: const Icon(Icons.cloud_upload,
                                color: Colors.white),
                            label: const Text('Upload',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00B6B0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
