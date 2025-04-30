import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user signed in');
      }

      await _firestore.collection('categories').add({
        'name': categoryName,
        'subcategories': [],
        'createdBy': currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
      _categoryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSubcategory() async {
    final subcategoryName = _subcategoryController.text.trim();
    if (_selectedCategory == null || subcategoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter a subcategory name')),
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
          const SnackBar(content: Text('Subcategory added successfully')),
        );
        _subcategoryController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected category not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding subcategory: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category and its subcategories?'),
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

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('categories').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _subcategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to manage categories')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Category
                  const Text(
                    'Add New Category',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addCategory,
                    child: const Text('Add Category'),
                  ),
                  const SizedBox(height: 16),
                  // Add Subcategory
                  const Text(
                    'Add Subcategory',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('categories')
                        .where('createdBy', isEqualTo: currentUser.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                        return const Text('No categories available');
                      }
                      if (_selectedCategory == null ||
                          !categories.contains(_selectedCategory)) {
                        _selectedCategory = categories.first;
                      }
                      return DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategory,
                        items: categories
                            .map((category) => DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subcategoryController,
                    decoration: InputDecoration(
                      labelText: 'Subcategory Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addSubcategory,
                    child: const Text('Add Subcategory'),
                  ),
                  const SizedBox(height: 16),
                  // List Categories and Subcategories
                  const Text(
                    'Categories and Subcategories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('categories')
                          .where('createdBy', isEqualTo: currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No categories found'));
                        }
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final categoryName = doc['name'] as String;
                            final subcategories =
                                List<String>.from(doc['subcategories'] ?? []);
                            return Card(
                              child: ListTile(
                                title: Text(categoryName),
                                subtitle: Text('Subcategories: ${subcategories.join(', ')}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(doc.id),
                                ),
                              ),
                            );
                          },
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