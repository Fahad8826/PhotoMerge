import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:io';

class ImageDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic>? userData;
  Color _selectedBackgroundColor = Colors.grey.shade800;
  Color _selectedTextColor = Colors.white;
  bool _isLoading = true;
  bool isLoadingforbutton = false;
  String? _error;

  // Predefined color list for background
  static const List<Color> backgroundColorOptions = [
    Colors.grey,
    Colors.blueGrey,
    Colors.teal,
    Colors.indigo,
    Colors.deepPurple,
    Colors.black87,
    Colors.pink,
    Colors.orange,
    Colors.redAccent,
    // Colors.greenAccent,
    // Colors.lightGreen,
    // Colors.lightBlueAccent,
    // Colors.amberAccent,
    // Colors.cyanAccent,
    // Colors.limeAccent,
    // Colors.purpleAccent,
    // Colors.brown,
  ];

  // Predefined color list for text
  static const List<Color> textColorOptions = [
    Colors.white,
    Colors.black,
    Colors.yellow,
    Colors.cyan,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.amber,
    // Colors.brown,
    // Colors.deepOrange,
    // Colors.lightBlue,
    // Colors.lime,
    // Colors.pinkAccent,
    // Colors.tealAccent,
  ];

  Color get selectedBackgroundColor => _selectedBackgroundColor;
  Color get selectedTextColor => _selectedTextColor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoadingforbutton(bool value) {
    isLoadingforbutton = value;
    notifyListeners();
  }

  ImageDetailViewModel(String photoUrl) {
    _initialize(photoUrl);
  }

  Future<void> _initialize(String photoUrl) async {
    await Future.wait([
      _initializeNotifications(),
      _getUserData(),
      _loadSavedColors(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initializeNotifications() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Notification channel for basic notifications',
            defaultColor: const Color(0xFF4CAF50),
            ledColor: Colors.white,
          ),
        ],
      );
    } catch (e) {
      print('Error initializing notifications: $e');
      _error = 'Failed to initialize notifications';
      notifyListeners();
    }
  }

  Future<void> _getUserData() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists) {
        userData = doc.data();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _error = 'Failed to fetch user data';
      notifyListeners();
    }
  }

  Future<void> _loadSavedColors() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_profile').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['backgroundColor'] != null) {
          _selectedBackgroundColor = Color(data['backgroundColor']);
        }
        if (data['textColor'] != null) {
          _selectedTextColor = Color(data['textColor']);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved colors: $e');
    }
  }

  Future<void> _saveColors() async {
    if (userId == null) return;
    try {
      await _firestore.collection('user_profile').doc(userId).update({
        'backgroundColor': _selectedBackgroundColor.value,
        'textColor': _selectedTextColor.value,
      });
    } catch (e) {
      print('Error saving colors: $e');
    }
  }

  void showColorPickerDialog(BuildContext context) {
    Color tempBackgroundColor = _selectedBackgroundColor;
    Color tempTextColor = _selectedTextColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.palette, color: Color(0xFF00A19A)),
            const SizedBox(width: 8),
            const Text('Customize Colors'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: backgroundColorOptions
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          tempBackgroundColor = color;
                          // Use setState in dialog to update selection
                          (context as Element).markNeedsBuild();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: tempBackgroundColor == color
                                  ? Color(0xFF00A19A)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (tempBackgroundColor == color)
                                BoxShadow(
                                  color: Color(0xFF00A19A).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: tempBackgroundColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Text Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: textColorOptions
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          tempTextColor = color;
                          (context as Element).markNeedsBuild();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: tempTextColor == color
                                  ? Color(0xFF00A19A)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (tempTextColor == color)
                                BoxShadow(
                                  color: Color(0xFF00A19A).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: tempTextColor == color
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              _selectedBackgroundColor = tempBackgroundColor;
              _selectedTextColor = tempTextColor;
              await _saveColors();
              notifyListeners();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Apply',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A19A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> captureAndSaveImage(
    String photoId,
    String photoUrl,
    GlobalKey cardKey,
    BuildContext context, {
    required VoidCallback onStart,
    required VoidCallback onComplete,
  }) async {
    onStart();

    try {
      // ---------------------------------------------------------------
      // 1. Fetch User Data (Subscription / Free Download Logic)
      // ---------------------------------------------------------------
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _showSnackBar(context, 'User data not found');
        onComplete();
        return;
      }

      final userData = userDoc.data()!;
      final bool freeDownloadUsed = userData['freeDownloadUsed'] ?? false;
      final bool isSubscribed = userData['isSubscribed'] ?? false;
      final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

      bool hasActiveSubscription = isSubscribed && subscriptionExpiry != null;
      if (hasActiveSubscription &&
          !subscriptionExpiry.toDate().isAfter(DateTime.now())) {
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
        });
        hasActiveSubscription = false;
      }

      if (isSubscribed && subscriptionExpiry == null) {
        _showSnackBar(context,
            'Subscription data is incomplete. Please contact support.');
        onComplete();
        return;
      }

      // User allowed: subscription OR free first download
      if (hasActiveSubscription || !freeDownloadUsed) {
        _showSnackBar(context, 'Processing image...');

        // ---------------------------------------------------------------
        // 2. Capture Widget as Image
        // ---------------------------------------------------------------
        final boundary = cardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

        if (boundary == null) {
          _showSnackBar(context, 'Cannot capture image at this time');
          onComplete();
          return;
        }

        const double pixelRatio = 5.0;
        const double a4Width = 3540.0;
        const double a4Height = 5424.0;

        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception('Failed to capture image data');

        // Resize to A4 resolution
        final codec =
            await ui.instantiateImageCodec(byteData.buffer.asUint8List());
        final frameInfo = await codec.getNextFrame();

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        canvas.drawImageRect(
          frameInfo.image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(0, 0, a4Width, a4Height),
          Paint()..filterQuality = FilterQuality.high,
        );

        final picture = recorder.endRecording();
        final a4Image =
            await picture.toImage(a4Width.toInt(), a4Height.toInt());
        final a4ByteData =
            await a4Image.toByteData(format: ui.ImageByteFormat.png);
        final a4PngBytes = a4ByteData!.buffer.asUint8List();

        // ---------------------------------------------------------------
        // 3. SAVE TO GALLERY — NO PERMISSION REQUIRED ON ANDROID 10+
        // ---------------------------------------------------------------
        final result = await ImageGallerySaverPlus.saveImage(
          a4PngBytes,
          name: "my_image_${DateTime.now().millisecondsSinceEpoch}",
        );
        print(result);

        _showSnackBar(context, 'Image saved to gallery!', floating: true);

        // Mark free download used
        if (!hasActiveSubscription) {
          await _firestore.collection('users').doc(userId).update({
            'freeDownloadUsed': true,
            'lastSubscriptionUpdate': Timestamp.now(),
          });
        }
      } else {
        _showSnackBar(
          context,
          'You used your one-time free download. Please subscribe to download more.',
        );
        _showSubscriptionDialog(context);
      }
    } catch (e) {
      print('Error during capture: $e');
      _showSnackBar(context, 'Error: $e');
    } finally {
      onComplete();
    }
  }

  Future<void> shareImage(String photoId, String photoUrl, GlobalKey cardKey,
      BuildContext context) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _showSnackBar(context, 'User data not found');
        return;
      }

      final userData = userDoc.data()!;
      final bool isSubscribed = userData['isSubscribed'] ?? false;
      final Timestamp? subscriptionExpiry = userData['subscriptionExpiry'];

      bool hasActiveSubscription = isSubscribed && subscriptionExpiry != null;
      if (hasActiveSubscription &&
          !subscriptionExpiry.toDate().isAfter(DateTime.now())) {
        await _firestore.collection('users').doc(userId).update({
          'isSubscribed': false,
        });
        hasActiveSubscription = false;
      }

      if (isSubscribed && subscriptionExpiry == null) {
        _showSnackBar(context,
            'Subscription data is incomplete. Please contact support.');
        return;
      }

      if (hasActiveSubscription) {
        try {
          _showSnackBar(context, 'Preparing image for sharing...');

          final boundary = cardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary == null) {
            _showSnackBar(context, 'Cannot capture image at this time');
            return;
          }

          const double pixelRatio = 5.0;
          final image = await boundary.toImage(pixelRatio: pixelRatio);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData == null) throw Exception('Failed to capture image data');

          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/share_image_$photoId.png');
          await tempFile.writeAsBytes(byteData.buffer.asUint8List());

          await Share.shareXFiles(
            [XFile(tempFile.path)],
          );

          await tempFile.delete();
        } catch (e) {
          print('Error sharing image: $e');
          _showSnackBar(context, 'Error sharing image: $e');
        }
      } else {
        await _showNotification(
          title: 'Subscription Required',
          body: 'Please subscribe to share images. Choose a plan to continue.',
        );
        _showSubscriptionDialog(context);
      }
    } catch (e) {
      print('Error checking user subscription: $e');
      _showSnackBar(context, 'Error: $e');
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
          return;
        }
      }
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 10000,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You need an active subscription to share images. Please choose a subscription plan.',
              ),
              const SizedBox(height: 16),
              _buildPlanOption('Premium Plan', 2000, 'year', context),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(
      String planName, int price, String duration, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(planName),
        subtitle: Text('₹$price/$duration'),
        trailing: isLoadingforbutton
            ? const CircularProgressIndicator()
            : const Icon(Icons.arrow_forward),
        onTap: () {
          if (!isLoadingforbutton) {
            setLoadingforbutton(true);
            _redirectToWhatsApp(planName, price, duration, context);
          }
        },
      ),
    );
  }

  Future<void> _redirectToWhatsApp(
      String plan, int price, String duration, BuildContext context) async {
    const adminWhatsAppNumber = '+918075601175';
    final message =
        'Hello, I want to subscribe to the $plan (₹$price/$duration) for the BrandBuilder app.';
    final encodedMessage = Uri.encodeComponent(message);

    final whatsappUrl =
        'https://wa.me/$adminWhatsAppNumber?text=$encodedMessage';
    final uri = Uri.parse(whatsappUrl);

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showSnackBar(context,
              'Could not open WhatsApp. Please ensure WhatsApp is installed.');
        }
      } else {
        final fallbackUrl =
            'whatsapp://send?phone=$adminWhatsAppNumber&text=$encodedMessage';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        } else {
          _showSnackBar(
              context, 'WhatsApp is not installed or cannot be opened.');
        }
      }
    } catch (e) {
      print('Error launching WhatsApp: $e');
      _showSnackBar(context, 'Failed to open WhatsApp: $e');
    } finally {
      setLoadingforbutton(false);
      Navigator.pop(context);
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool floating = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: floating ? SnackBarBehavior.floating : null,
      ),
    );
  }

  void _showPermissionDeniedSnackBar(
      BuildContext context, String permissionType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$permissionType permission is permanently denied. Please enable it in app settings.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }
}
