import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:awesome_notifications/awesome_notifications.dart'; // For notifications
import 'dart:async'; // For timer functionality
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AdminSubscriptionPage extends StatefulWidget {
  const AdminSubscriptionPage({Key? key}) : super(key: key);

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _adminId;
  // ...existing code...
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
// ...existing code...

  // Filter options
  String _filterOption = 'All';
  final List<String> _filterOptions = [
    'All',
    'Active',
    'Expired',
    'Never Subscribed'
  ];

  // For category-based plans
  final Map<String, List<SubscriptionPlan>> _categoryPlans = {};
  List<String> _categories = [];
  bool _isLoading = true;

  // For subscription alerts tracking
  final Map<String, StreamSubscription<DocumentSnapshot>>
      _subscriptionListeners = {};

  @override
  void initState() {
    super.initState();

    _loadCategories();
    _initializeNotifications();
  }

  @override
  void dispose() {
    // Cancel all subscription listeners when the page is disposed
    for (var subscription in _subscriptionListeners.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // No default icon
      [
        NotificationChannel(
          channelKey: 'subscription_channel',
          channelName: 'Subscription Notifications',
          channelDescription:
              'Notifications related to subscription status changes',
          importance: NotificationImportance.High,
          enableVibration: true,
        ),
      ],
    );
  }

  Future<void> _loadCategories() async {
    try {
      // Reset the loading state
      setState(() {
        _isLoading = true;
      });

      // First, load all categories
      final categorySnapshot = await _firestore.collection('categories').get();
      List<String> categories = [];

      for (var doc in categorySnapshot.docs) {
        final categoryName = doc['name'] as String;
        categories.add(categoryName);

        // For each category, define subscription plans
        _categoryPlans[categoryName] = [
          SubscriptionPlan(
            name: 'Premium Plan',
            duration: const Duration(days: 365),
            price: 2000,
            features: ['Access to all fetaures for 1 year'],
            categorySpecific: true,
          ),
        ];
      }

      // Add Universal to the list of categories
      categories.add('Universal');

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  Future<void> _setupSubscriptionAlert(String userId, String email) async {
    // Cancel any existing listener for this user
    if (_subscriptionListeners.containsKey(userId)) {
      await _subscriptionListeners[userId]?.cancel();
    }

    // Create a new listener
    final subscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((userDoc) async {
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final bool isSubscribed = userData['isSubscribed'] ?? false;
      final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

      if (isSubscribed && subscriptionExpiry != null) {
        final expiryDate = subscriptionExpiry.toDate();
        final now = DateTime.now();

        // Calculate days left
        final daysLeft = expiryDate.difference(now).inDays;

        // Send reminders at 10, 5, and 3 days before expiry
        if ([10, 5, 3].contains(daysLeft)) {
          await _sendExpiryReminderToUser(
            userId,
            email,
            daysLeft,
            userData['subscriptionPlan'] ?? 'your plan',
          );

          await _showNotification(
            title: 'Subscription Reminder',
            body: 'User $email subscription expires in $daysLeft days',
          );
        }

        // Send expiry notice on the day it expires
        if (daysLeft == 0) {
          await _sendExpiryNotificationToUser(
            userId,
            email,
            userData['subscriptionPlan'] ?? 'your plan',
          );

          await _firestore.collection('users').doc(userId).update({
            'isSubscribed': false,
            'lastSubscriptionUpdate': Timestamp.now(),
          });

          await _showNotification(
            title: 'Subscription Expired',
            body: 'User $email subscription has expired',
          );
        }
      }
    });

    // Store the subscription listener
    _subscriptionListeners[userId] = subscription;
  }

  Future<void> _sendExpiryReminderToUser(
      String userId, String email, int daysLeft, String planName) async {
    try {
      // Create a reminder notification in user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Expiring Soon',
        'message':
            'Your $planName subscription will expire in $daysLeft days. Renew now to continue downloading images.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_reminder',
      });
    } catch (e) {
      print('Error sending expiry reminder to user: $e');
    }
  }

  Future<void> _sendExpiryNotificationToUser(
      String userId, String email, String planName) async {
    try {
      // Create an expiry notification in user's notifications collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Expired',
        'message':
            'Your $planName subscription has expired. Renew now to continue downloading images.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_expired',
      });
    } catch (e) {
      print('Error sending expiry notification to user: $e');
    }
  }

  Future<void> _showNotification(
      {required String title, required String body}) async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Notification permission denied. Please enable it in settings.'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        channelKey: 'subscription_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void _approveSubscription(BuildContext context, String userId, String email) {
    String selectedCategory = _categories.isNotEmpty ? _categories[0] : '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Approve Subscription',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 20,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // User info
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.teal, size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscriber',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plans list
              Expanded(
                child: _categoryPlans[selectedCategory]?.isEmpty ?? true
                    ? Center(
                        child: Text(
                          'No plans available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            _categoryPlans[selectedCategory]?.length ?? 0,
                        itemBuilder: (context, index) {
                          final plan = _categoryPlans[selectedCategory]![index];
                          final durationText = plan.duration.inDays >= 365
                              ? '${plan.duration.inDays ~/ 365} year${plan.duration.inDays >= 730 ? 's' : ''}'
                              : '${plan.duration.inDays} days';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 4,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _updateSubscription(
                                  userId, email, selectedCategory, plan),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '₹${plan.price}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.teal,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '/ $durationText',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                          ),
                                          onPressed: () => _updateSubscription(
                                              userId,
                                              email,
                                              selectedCategory,
                                              plan),
                                          child: const Text(
                                            'Select',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    ...plan.features.map((feature) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.check_circle_outline,
                                                  color: Colors.teal,
                                                  size: 16),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  feature,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateSubscription(String userId, String email, String category,
      SubscriptionPlan plan) async {
    try {
      final now = DateTime.now();
      final expiryDate = now.add(plan.duration);

      // Update user's subscription information
      await _firestore.collection('users').doc(userId).update({
        'isSubscribed': true,
        'subscriptionPlan': plan.name,
        'subscriptionCategory': plan.categorySpecific ? category : 'Universal',
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionPrice': plan.price,
        'subscriptionFeatures': plan.features,
        'lastSubscriptionUpdate': Timestamp.now(),
      });

      // Create transaction record
      await _firestore.collection('subscription_transactions').add({
        'userId': userId,
        'userEmail': email,
        'plan': plan.name,
        'category': plan.categorySpecific ? category : 'Universal',
        'price': plan.price,
        'startDate': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'approvedBy': _adminId,
        'approvedAt': Timestamp.now(),
        'status': 'active',
      });

      // Add notification for the user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'Subscription Approved',
        'message':
            'Your ${plan.name} subscription has been approved! You can now download images until ${DateFormat('dd MMM yyyy').format(expiryDate)}.',
        'timestamp': Timestamp.now(),
        'read': false,
        'type': 'subscription_approved',
      });

      // Set up automatic subscription alert
      await _setupSubscriptionAlert(userId, email);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription approved for $email')),
        );
      }
    } catch (e) {
      print('Error updating subscription: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e')),
        );
      }
    }
  }

  Future<void> _revokeSubscription(
      BuildContext context, String userId, String email) async {
    // Show confirmation dialog before proceeding
    final bool confirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFFE0F7F6),
              title: Text('Confirm Revocation'),
              content: Text(
                  'Are you sure you want to revoke the subscription for $email?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF00B6B0)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: Text('Revoke'),
                ),
              ],
            );
          },
        ) ??
        false;

    // Return early if user canceled
    if (!confirmed) return;

    try {
      // Get current subscription details for record keeping
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        final currentPlan = userData['subscriptionPlan'];
        final currentCategory = userData['subscriptionCategory'];

        // Create transaction record for revocation
        await _firestore.collection('subscription_transactions').add({
          'userId': userId,
          'userEmail': email,
          'plan': currentPlan ?? 'Unknown',
          'category': currentCategory ?? 'Unknown',
          'revokedAt': Timestamp.now(),
          'revokedBy': _adminId,
          'status': 'revoked',
          'previousExpiryDate': userData['subscriptionExpiry'],
        });

        // Update user record
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
          'subscriptionPlan': '',
          'subscriptionCategory': '',
          'subscriptionExpiry': null,
          'lastSubscriptionUpdate': Timestamp.now(),
        });

        // Add notification for the user
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .add({
          'title': 'Subscription Revoked',
          'message':
              'Your subscription has been revoked. Please contact admin for details.',
          'timestamp': Timestamp.now(),
          'read': false,
          'type': 'subscription_revoked',
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subscription revoked for $email')),
          );
        }
      }
    } catch (e) {
      print('Error revoking subscription: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error revoking subscription: $e')),
        );
      }
    }
  }

  Future<void> _extendSubscription(BuildContext context, String userId,
      String email, Timestamp? currentExpiry) async {
    final TextEditingController daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFE0F7F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Extend Subscription',
          style: TextStyle(
            color: Color(0xFF00B6B0),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User: $email',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (currentExpiry != null)
              Text(
                'Current expiry: ${DateFormat('dd MMM yyyy').format(currentExpiry.toDate())}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              decoration: InputDecoration(
                labelText: 'Enter days to extend',
                labelStyle: TextStyle(color: Color(0xFF00B6B0)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00B6B0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00B6B0), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF00B6B0)),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              cursorColor: Color(0xFF00B6B0),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF00B6B0),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final days = int.tryParse(daysController.text);
                if (days == null || days <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid number of days'),
                      backgroundColor: Color(0xFF00B6B0),
                    ),
                  );
                  return;
                }

                final userDoc =
                    await _firestore.collection('users').doc(userId).get();
                if (!userDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User not found'),
                      backgroundColor: Color(0xFF00B6B0),
                    ),
                  );
                  return;
                }

                final userData = userDoc.data()!;
                final Timestamp? oldExpiry = userData['subscriptionExpiry'];
                final DateTime baseDate = oldExpiry?.toDate() ?? DateTime.now();
                final DateTime newExpiry = baseDate.add(Duration(days: days));

                await _firestore.collection('users').doc(userId).update({
                  'isSubscribed': true,
                  'subscriptionExpiry': Timestamp.fromDate(newExpiry),
                  'lastSubscriptionUpdate': Timestamp.now(),
                });

                // Add transaction record
                await _firestore.collection('subscription_transactions').add({
                  'userId': userId,
                  'userEmail': email,
                  'plan': userData['subscriptionPlan'] ?? 'Unknown',
                  'category': userData['subscriptionCategory'] ?? 'Unknown',
                  'extendedAt': Timestamp.now(),
                  'extendedBy': _adminId,
                  'extendedDays': days,
                  'previousExpiryDate': oldExpiry,
                  'newExpiryDate': Timestamp.fromDate(newExpiry),
                  'status': 'extended',
                });

                // Add notification for the user
                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .add({
                  'title': 'Subscription Extended',
                  'message':
                      'Your subscription has been extended by $days days. New expiry date: ${DateFormat('dd MMM yyyy').format(newExpiry)}.',
                  'timestamp': Timestamp.now(),
                  'read': false,
                  'type': 'subscription_extended',
                });

                // Set up automatic subscription alert
                await _setupSubscriptionAlert(userId, email);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subscription extended by $days days'),
                    backgroundColor: Color(0xFF00B6B0),
                  ),
                );
              } catch (e) {
                print('Error extending subscription: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error extending subscription: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00B6B0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  Query<Map<String, dynamic>> _getFilteredQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    switch (_filterOption) {
      case 'Active':
        query = query.where('isSubscribed', isEqualTo: true);
        break;
      case 'Expired':
        final now = Timestamp.now();
        query = query
            .where('isSubscribed', isEqualTo: false)
            .where('subscriptionExpiry', isLessThan: now);
        break;
      case 'Never Subscribed':
        query = query.where('subscriptionPlan', isEqualTo: '');
        break;
      case 'All':
      default:
        // No filter applied
        break;
    }

    return query;
  }

  String _getSubscriptionStatus(Map<String, dynamic> userData) {
    final bool isSubscribed = userData['isSubscribed'] ?? false;
    final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

    if (!isSubscribed) {
      final bool freeDownloadUsed = userData['freeDownloadUsed'] ?? false;
      return freeDownloadUsed ? 'Free download used' : 'Never subscribed';
    }

    if (subscriptionExpiry == null) {
      return 'Active (no expiry)';
    }

    final now = DateTime.now();
    final expiryDate = subscriptionExpiry.toDate();

    if (expiryDate.isBefore(now)) {
      return 'Expired';
    }

    final difference = expiryDate.difference(now).inDays;
    if (difference <= 7) {
      return 'Active (expires in $difference days)';
    }

    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00B6B0),
                Color(0xFF00B6B0).withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading subscriptions...',
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00B6B0),
                Color(0xFF00A5A0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF00B6B0).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'Manage Subscriptions',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // TextField(
                //   controller: _searchController,
                //   decoration: InputDecoration(
                //     hintText: 'Search by phone or first name',
                //     prefixIcon: Icon(Icons.search, color: Color(0xFF00B6B0)),
                //     filled: true,
                //     fillColor: Colors.white,
                //     contentPadding:
                //         const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(8),
                //       borderSide: BorderSide.none,
                //     ),
                //   ),
                //   onChanged: (value) {
                //     setState(() {
                //       _searchQuery = value.trim().toLowerCase();
                //     });
                //   },
                // ),
                StreamBuilder<QuerySnapshot>(
                  stream: _getFilteredQuery().snapshots(),
                  builder: (context, snapshot) {
                    final count =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      '$count ${count == 1 ? 'user' : 'users'}',
                      style: GoogleFonts.oswald(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    );
                  },
                ),
              ],
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadCategories,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by phone or first name',
              prefixIcon: Icon(Icons.search, color: Color(0xFF00B6B0)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF00B6B0)),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _filterOption = value;
                        });
                      }
                    },
                    items: _filterOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Row(
                          children: [
                            _getFilterIcon(option),
                            const SizedBox(width: 8),
                            Text(
                              option,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredQuery().snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00B6B0)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading users...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading data',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                color: Colors.red.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: Colors.grey.shade400,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filter settings',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final userDoc = snapshot.data!.docs[index];
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final userId = userDoc.id;
                      final email = userData['email'] ?? 'No email';

                      final isSubscribed = userData['isSubscribed'] ?? false;
                      final phone = userData['phone'] ?? '';

                      final subscriptionPlan =
                          userData['subscriptionPlan'] ?? 'None';
                      final subscriptionCategory =
                          userData['subscriptionCategory'] ?? 'None';
                      final subscriptionExpiry =
                          userData['subscriptionExpiry'] as Timestamp?;
                      final status = _getSubscriptionStatus(userData);

                      // Setup subscription alert listener for this user
                      _setupSubscriptionAlert(userId, email);
                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('user_profile')
                            .doc(userId)
                            .get(),
                        builder: (context, profileSnapshot) {
                          String firstName = '';
                          String lastName = '';
                          if (profileSnapshot.hasData &&
                              profileSnapshot.data!.exists) {
                            final profileData = profileSnapshot.data!.data()
                                as Map<String, dynamic>;
                            firstName = profileData['firstName'] ?? '';
                            lastName = profileData['lastName'] ?? '';
                          }
                          final fullName = '$firstName $lastName'.trim();

                          if (_searchQuery.isNotEmpty) {
                            final phoneMatch =
                                phone.toLowerCase().contains(_searchQuery);
                            final firstNameMatch =
                                firstName.toLowerCase().contains(_searchQuery);
                            if (!phoneMatch && !firstNameMatch) {
                              return const SizedBox.shrink();
                            }
                          }

                          return _buildEnhancedUserCard(
                            firstName: firstName,
                            lastName: lastName,
                            userId: userId,
                            email: email,
                            fullName: fullName,
                            phone: phone,
                            isSubscribed: isSubscribed,
                            subscriptionPlan: subscriptionPlan,
                            subscriptionCategory: subscriptionCategory,
                            subscriptionExpiry: subscriptionExpiry,
                            status: status,
                          );
                        },
                      );
                    },
                  );
                }),
          )
        ],
      ),
    );
  }

// Helper method to get filter icons
  Widget _getFilterIcon(String filter) {
    switch (filter) {
      case 'All Users':
        return Icon(Icons.people, size: 16, color: Colors.grey.shade600);
      case 'Subscribed':
        return Icon(Icons.verified, size: 16, color: Colors.green);
      case 'Not Subscribed':
        return Icon(Icons.pending, size: 16, color: Colors.grey);
      case 'Expired':
        return Icon(Icons.hourglass_bottom, size: 16, color: Colors.red);
      default:
        return Icon(Icons.filter_list, size: 16, color: Colors.grey.shade600);
    }
  }

// Enhanced user card widget
  Widget _buildEnhancedUserCard({
    required String userId,
    required String email,
    required String fullName,
    required String firstName,
    required String lastName,
    required String phone,
    required bool isSubscribed,
    required String subscriptionPlan,
    required String subscriptionCategory,
    required Timestamp? subscriptionExpiry,
    required String status,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.all(0),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSubscribed
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.grey.shade400, Colors.grey.shade600],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSubscribed ? Colors.green : Colors.grey)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isSubscribed ? Icons.verified : Icons.pending,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone.isNotEmpty ? phone : 'No phone',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                firstName.isNotEmpty ? firstName : 'No Name',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              if (subscriptionExpiry != null)
                Text(
                  'Exp: ${DateFormat('dd/MM/yy').format(subscriptionExpiry.toDate())}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isExpiringSoon(subscriptionExpiry.toDate())
                        ? Colors.orange.shade700
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Details Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Email', email),
                        const Divider(height: 16),
                        _buildInfoRow(Icons.card_membership_outlined, 'Plan',
                            subscriptionPlan),
                        const Divider(height: 16),
                        if (subscriptionExpiry != null) ...[
                          _buildInfoRow(
                            Icons.schedule_outlined,
                            'Expires',
                            DateFormat('dd MMM yyyy')
                                .format(subscriptionExpiry.toDate()),
                            valueColor:
                                _isExpiringSoon(subscriptionExpiry.toDate())
                                    ? Colors.orange.shade700
                                    : null,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildActionButton(
                              onPressed: () =>
                                  _approveSubscription(context, userId, email),
                              icon: Icons.add_circle_outline,
                              label: 'New Plan',
                              color: Colors.green,
                            ),
                            if (isSubscribed) ...[
                              _buildActionButton(
                                onPressed: () => _extendSubscription(
                                    context, userId, email, subscriptionExpiry),
                                icon: Icons.update,
                                label: 'Extend',
                                color: Colors.blue,
                              ),
                              _buildActionButton(
                                onPressed: () =>
                                    _revokeSubscription(context, userId, email),
                                icon: Icons.block,
                                label: 'Revoke',
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper Methods (add these to your class)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  bool _isExpiringSoon(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        elevation: 2,
        shadowColor: color.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

// Subscription plan model
class SubscriptionPlan {
  final String name;
  final Duration duration;
  final int price;
  final List<String> features;
  final bool categorySpecific;

  SubscriptionPlan({
    required this.name,
    required this.duration,
    required this.price,
    required this.features,
    required this.categorySpecific,
  });
}
