import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:photomerge/Admin/categories/list_admincategorys.dart';
import 'dart:convert';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  bool _isLoading = false;
  File? _selectedImage;

  // Color scheme
  final Color primaryColor = const Color(0xFF00B6B0);
  final Color secondaryColor = const Color(0xFFE0F7F6);
  final Color textColor = Colors.black87;
  final Color backgroundColor = Colors.white;

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
        SnackBar(
          content: Text('Error uploading to Cloudinary: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final imageUrl = await _uploadToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      await _firestore.collection('categories').add({
        'name': categoryName,
        'image_url': imageUrl,
        'subcategories': [],
        'createdBy': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Category added successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _categoryController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSubcategory() async {
    final subcategoryName = _subcategoryController.text.trim();
    if (_selectedCategory == null || subcategoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Please select a category and enter a subcategory name'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      final snapshot = await _firestore
          .collection('categories')
          .where('name', isEqualTo: _selectedCategory)
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await _firestore.collection('categories').doc(docId).update({
          'subcategories': FieldValue.arrayUnion([subcategoryName]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sub category added successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _subcategoryController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected category not found'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding subcategory: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subcategoryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {IconData? icon}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 48, color: Color(0xFF00B6B0)),
              const SizedBox(height: 12),
              Text(
                'Please sign in to manage categories',
                style: GoogleFonts.oswald(fontSize: 18, color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ListCategoriesAndSubcategories()),
            ),
            tooltip: 'View Categories',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add Category Section
                        _buildSectionTitle('Add New Category'),
                        TextFormField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'Category Name',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                            prefixIcon:
                                Icon(Icons.category, color: primaryColor),
                            fillColor: backgroundColor,
                            filled: true,
                          ),
                          maxLength: 15,
                          validator: (value) => value!.trim().isEmpty
                              ? 'Enter a category name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImage!,
                                      fit: BoxFit.cover),
                                )
                              : Center(
                                  child: Text(
                                    'No image selected',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _buildButton('Select Image', _pickImage,
                            icon: Icons.image),
                        const SizedBox(height: 12),
                        _buildButton('Add Category', _addCategory,
                            icon: Icons.add),
                        const SizedBox(height: 24),

                        // Add Subcategory Section
                        _buildSectionTitle('Add Subcategory'),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('categories')
                              .where('createdBy', isEqualTo: currentUser.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: CircularProgressIndicator(
                                      color: primaryColor));
                            }
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child:
                                            Text('Error: ${snapshot.error}')),
                                  ],
                                ),
                              );
                            }
                            final categories = snapshot.data?.docs
                                    .map((doc) => doc['name'] as String)
                                    .toList() ??
                                [];
                            if (categories.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: secondaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: primaryColor),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                          'No categories available. Please add a category first.'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              hint: const Text('Select Category'),
                              icon: Icon(Icons.arrow_drop_down,
                                  color: primaryColor),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                                prefixIcon:
                                    Icon(Icons.category, color: primaryColor),
                                fillColor: backgroundColor,
                                filled: true,
                              ),
                              items: categories
                                  .map((category) => DropdownMenuItem<String>(
                                        value: category,
                                        child: Text(category,
                                            style: TextStyle(color: textColor)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _subcategoryController.clear();
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _subcategoryController,
                          decoration: InputDecoration(
                            labelText: 'Sub category Name',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                            prefixIcon: Icon(Icons.subdirectory_arrow_right,
                                color: primaryColor),
                            fillColor: backgroundColor,
                            filled: true,
                          ),
                          maxLength: 15,
                          validator: (value) => value!.trim().isEmpty
                              ? 'Enter a subcategory name'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildButton('Add Sub category', _addSubcategory,
                            icon: Icons.add),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
