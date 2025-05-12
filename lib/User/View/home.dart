import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/User/View/categorey.dart';
import 'package:photomerge/User/View/imagedetails.dart';
import 'package:url_launcher/url_launcher.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  Map<String, dynamic>? userData;
  int _currentCarouselIndex = 0;
  final ScrollController _scrollController = ScrollController();

  // Modern UI theme colors
  static const Color primaryColor = Color(0xFF4CAF50); // Main green
  static const Color secondaryColor = Color(0xFFF5F9F6); // Light background
  static const Color accentColor = Color(0xFF2E7D32); // Dark green for accents
  static const Color cardColor = Colors.white; // White card backgrounds
  static const Color textColor = Color(0xFF212121); // Primary text
  static const Color subtitleColor = Color(0xFF757575); // Secondary text

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _getUserData();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists && mounted) {
        setState(() {
          userData = doc.data();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: secondaryColor,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: textColor),
          bodySmall: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        iconTheme: const IconThemeData(color: accentColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: primaryColor),
        ),
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      child: PopScope(
        canPop: false, // Prevent default pop
        onPopInvoked: (didPop) async {
          if (!didPop) {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Exit App',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Are you sure you want to exit the app?',
                  style: TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Exit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );

            if (shouldExit == true) {
              // Exit the app
              Navigator.of(context).maybePop(); // or SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: cardColor,
            title: Text(
              "HOME",
              style: GoogleFonts.oswald(color: Colors.green, fontSize: 25),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                      context: context, delegate: GallerySearchDelegate());
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _getUserData,
              ),
            ],
          ),
          drawer: userId != null ? _buildDrawer() : null,
          body: RefreshIndicator(
            color: primaryColor,
            onRefresh: _getUserData,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildCarousel()),
                SliverToBoxAdapter(child: _buildWelcomeSection()),
                SliverToBoxAdapter(child: _buildCategoriesSection()),
                SliverToBoxAdapter(child: _buildRecentImagesSection()),
                SliverToBoxAdapter(child: _buildManageProfileSection(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/listimages');
            },
            backgroundColor: primaryColor,
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    elevation: 4, // Adjust elevation for the shadow effect
                    shape:
                        CircleBorder(), // Ensures the Material stays circular
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Align(
                        alignment:
                            Alignment.center, // Ensures the text is centered
                        child: Text(
                          userData?['firstName']?.isNotEmpty == true
                              ? userData!['firstName'][0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 32, // Adjust font size as needed
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData?['firstName']?.isNotEmpty == true
                        ? userData!['firstName']
                        : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userData?['email']?.isNotEmpty == true
                        ? userData!['email']
                        : '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.account_circle_outlined,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _buildDrawerItem(
              icon: Icons.photo_library_outlined,
              title: 'My Gallery',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listimages');
              },
            ),
            _buildDrawerItem(
              icon: Icons.category_outlined,
              title: 'Categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/Category');
              },
            ),
            _buildDrawerItem(
              icon: Icons.video_library_outlined,
              title: 'My Videos',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/listvedios');
              },
            ),
            _buildDrawerItem(
              icon: Icons.workspace_premium_outlined,
              title: 'My Subscription',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/usersubscription');
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            _buildDrawerItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/support');
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Log Out',
              onTap: () async {
                Navigator.pop(context);
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Exit App',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to exit the app?',
                      style: TextStyle(color: Colors.black87),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Exit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true && mounted) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    // print('userData: $userData');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text:
                        'Welcome${userData?['firstName']?.isNotEmpty == true ? ", ${userData!['firstName']}" : ""}',
                    style: GoogleFonts.oswald(
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Discover and organize your photos and videos',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 15),
                )
              ],
            ),
          ),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.notifications_none_rounded,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          _firestore.collection('carousel_images').doc('images').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 210,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.hasError
                        ? 'Error loading images'
                        : 'No images available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<String> imageUrls =
            (data?['urls'] as List<dynamic>?)?.cast<String>() ?? [];

        if (imageUrls.isEmpty) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Text('No carousel images available')),
          );
        }

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                CarouselSlider(
                  key: const ValueKey('carousel'),
                  options: CarouselOptions(
                    height: 190,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOut,
                    enlargeCenterPage: true,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),
                  items: imageUrls.map((imageUrl) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      color: Colors.transparent,
                      child: AspectRatio(
                        aspectRatio: 1 / 4, // matches your image aspect ratio
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain, // prevents cropping
                          alignment: Alignment.center,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error_outline,
                                  color: Colors.red, size: 32),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: imageUrls.asMap().entries.map((entry) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentCarouselIndex == entry.key
                              ? Colors.white
                              : Colors.white.withAlpha(102),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/Category');
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                _firestore.collection('categories').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('Error loading categories')),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: Text('No categories available')),
                );
              }

              final categories = snapshot.data!.docs;

              return SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categoryData =
                        categories[index].data() as Map<String, dynamic>;
                    final name = categoryData['name'] as String? ??
                        'Category ${index + 1}';
                    final imageUrl = categoryData['image_url'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Mycategory(categoryFilter: name),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey[200],
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey[200],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentImagesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Images',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/listimages');
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collectionGroup('images')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 230,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const SizedBox(
                  height: 230,
                  child: Center(
                    child: Text(
                      'Error loading images',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                  height: 230,
                  child: Center(
                    child: Text('No images available'),
                  ),
                );
              }
              final images = snapshot.data!.docs;
              return SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imageData =
                        images[index].data() as Map<String, dynamic>;
                    final imageUrl = imageData['image_url'] as String? ?? '';
                    final category =
                        imageData['category'] as String? ?? 'Uncategorized';
                    final timestamp = imageData['timestamp'] as Timestamp?;
                    final timeAgo = timestamp != null
                        ? _getTimeAgo(timestamp.toDate())
                        : 'Unknown';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageDetailView(
                              photoId: images[index].id,
                              photoUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey,
                                            size: 40,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManageProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Account',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.8), primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'Personalize Your Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 360
                                          ? 18
                                          : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                'Update your info and customize settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 360
                                          ? 14
                                          : 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/profile');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(100, 32),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  String _extractYouTubeId(String url) {
    final RegExp youtubeRegex = RegExp(
      r'(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = youtubeRegex.firstMatch(url);
    return match?.group(1) ?? '';
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: accentColor),
      title: Text(title),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class GallerySearchDelegate extends SearchDelegate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: _UserDashboardState.primaryColor,
        foregroundColor: _UserDashboardState.textColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: _UserDashboardState.textColor.withOpacity(0.6),
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: _UserDashboardState.textColor),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: _UserDashboardState.textColor),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Container(
        color: _UserDashboardState.secondaryColor,
        child: Center(
          child: Text(
            'Enter a search term',
            style: TextStyle(
              color: _UserDashboardState.textColor.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Container(
      color: _UserDashboardState.secondaryColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: _UserDashboardState.accentColor,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading suggestions',
                style: TextStyle(
                  color: _UserDashboardState.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No suggestions found',
                style: TextStyle(
                  color: _UserDashboardState.textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }
          // Filter categories client-side for case-insensitive matching
          final searchQuery = query.toLowerCase();
          final categories = snapshot.data!.docs.where((doc) {
            final name = (doc['name'] as String? ?? '').toLowerCase();
            return name.contains(searchQuery);
          }).toList();

          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No suggestions found',
                style: TextStyle(
                  color: _UserDashboardState.textColor.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final categoryData =
                  categories[index].data() as Map<String, dynamic>;
              final name =
                  categoryData['name'] as String? ?? 'Category ${index + 1}';
              final imageUrl = categoryData['image_url'] as String?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.category,
                              color: _UserDashboardState.accentColor,
                              size: 40,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.category,
                          color: _UserDashboardState.accentColor,
                          size: 40,
                        ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _UserDashboardState.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Mycategory(categoryFilter: name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
