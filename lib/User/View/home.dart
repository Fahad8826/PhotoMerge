import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _getUserData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Gallery'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: GallerySearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getUserData,
          ),
        ],
      ),
      drawer: userId != null
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
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
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.grey),
                    title: const Text('Edit Profile',
                        style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image, color: Colors.grey),
                    title: const Text('My Gallery',
                        style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/listimages');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image, color: Colors.grey),
                    title:
                        const Text('Category', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/Category');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.subscriptions_rounded,
                        color: Colors.grey),
                    title: const Text('My Subscription',
                        style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/usersubscription');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.grey),
                    title:
                        const Text('Log Out', style: TextStyle(fontSize: 16)),
                    onTap: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Featured Images',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('carousel_images')
                          .doc('images')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Error loading carousel images',
                                  style: TextStyle(color: Colors.red)));
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(
                              child: Text('No carousel images available'));
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final List<dynamic> imageUrls = data['urls'] ?? [];
                        if (imageUrls.isEmpty) {
                          return const Center(
                              child: Text('No carousel images available'));
                        }
                        return CarouselSlider(
                          options: CarouselOptions(
                            height: 150,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            autoPlayInterval: const Duration(seconds: 3),
                            viewportFraction: 0.8,
                          ),
                          items: imageUrls.asMap().entries.map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            return Builder(
                              builder: (BuildContext context) {
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error,
                                              color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Categories List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('categories')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading categories',
                                style: TextStyle(color: Colors.red)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No categories available'));
                      }
                      final categories = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final categoryData =
                              categories[index].data() as Map<String, dynamic>;
                          final name =
                              categoryData['name'] ?? 'Category ${index + 1}';
                          final imageUrl = categoryData['imageUrl'] ?? '';
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            const Icon(Icons.category,
                                                color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.category,
                                      color: Colors.grey),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              onTap: () {
                                Navigator.pushNamed(context, '/Category');
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GallerySearchDelegate extends SearchDelegate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('categories')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error searching categories'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No categories found'));
        }
        final categories = snapshot.data!.docs;
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final categoryData =
                categories[index].data() as Map<String, dynamic>;
            final name = categoryData['name'] ?? 'Category ${index + 1}';
            return ListTile(
              title: Text(name),
              onTap: () {
                close(context, null);
                Navigator.pushNamed(context, '/Category');
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('categories')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading suggestions'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No suggestions'));
        }
        final categories = snapshot.data!.docs;
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final categoryData =
                categories[index].data() as Map<String, dynamic>;
            final name = categoryData['name'] ?? 'Category ${index + 1}';
            return ListTile(
              title: Text(name),
              onTap: () {
                query = name;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }
}
