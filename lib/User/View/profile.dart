
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photomerge/Crop/helperclass.dart' as AppHelper;
import 'package:photomerge/User/View/home.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as flutterSecureStorage;

class CloudinaryConfig {
  static const String cloudName = 'dlacr6mpw';
  static const String uploadPreset = 'BrandBuilder';
  static const String apiKey =
      '725816153519724'; // Replace with your Cloudinary API Key
  static const String apiSecret =
      '2XjX4826vpnX_PVkbLf7_bWNus4'; // Replace with your Cloudinary API Secret
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Color palette
  static const Color primaryColor = Color(0xFF00A19A);
  static const Color accentColor = Color(0xFF005F5C);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color dividerColor = Color(0xFFE2E8F0);
  static const Color errorColor = Color(0xFFE53E3E);
  static const Color successColor = Color(0xFF38A169);

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyNameController;
  late TextEditingController _designationController;
  late TextEditingController _websiteController;
  late TextEditingController _districtController;
  late TextEditingController _branchController;

  // Image state
  File? _userImage;
  String? _userImageUrl;
  File? _companyLogo;
  String? _companyLogoUrl;

  // UI state
  bool _isLoading = true;
  bool _isEditing = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyNameController = TextEditingController();
    _designationController = TextEditingController();
    _websiteController = TextEditingController();
    _districtController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _designationController.dispose();
    _websiteController.dispose();
    _districtController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      _showSnackBar('No user signed in', isError: true);
      return;
    }

    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final profileDoc = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }

        if (profileDoc.exists) {
          final profileData = profileDoc.data()!;
          _firstNameController.text = profileData['firstName'] ?? '';
          _lastNameController.text = profileData['lastName'] ?? '';
          _companyNameController.text = profileData['companyName'] ?? '';
          _designationController.text = profileData['designation'] ?? '';
          _websiteController.text = profileData['companyWebsite'] ?? '';
          _districtController.text = profileData['district'] ?? '';
          _branchController.text = profileData['branch'] ?? '';
          _userImageUrl = profileData['userImage'];
          _companyLogoUrl = profileData['companyLogo'];
        }

        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleProcessedImage(File processedImage, bool isUserImage) {
    setState(() {
      if (isUserImage) {
        _userImage = processedImage;
      } else {
        _companyLogo = processedImage;
      }
    });
    _showSnackBar('Image processed successfully!');
  }

  Future<void> _pickImageWithCropCompress(
      ImageSource source, bool isUserImage) async {
    try {
      final XFile? pickedImage = await picker.pickImage(source: source);

      if (pickedImage != null) {
        File image = File(pickedImage.path);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final sizeInKbBefore = image.lengthSync() / 1024;
          print('Before Compress: ${sizeInKbBefore.toStringAsFixed(2)} KB');

          File? compressedImage = await AppHelper.compress(image: image);
          if (compressedImage == null) {
            Navigator.pop(context);
            _showSnackBar('Failed to compress image', isError: true);
            return;
          }

          final sizeInKbAfter = compressedImage.lengthSync() / 1024;
          print('After Compress: ${sizeInKbAfter.toStringAsFixed(2)} KB');

          File? croppedImage = await AppHelper.cropImage(compressedImage);
          Navigator.pop(context);

          if (croppedImage == null) {
            _showSnackBar('Image cropping cancelled', isError: true);
            return;
          }

          final finalSizeInKb = croppedImage.lengthSync() / 1024;
          print('Final size: ${finalSizeInKb.toStringAsFixed(2)} KB');

          _handleProcessedImage(croppedImage, isUserImage);
        } catch (e) {
          Navigator.pop(context);
          _showSnackBar('Error processing image: $e', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _showImagePickerOptions(bool isUserImage) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: cardColor,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Image Source',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.photo_library, color: primaryColor),
            title: Text(
              'Gallery',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Choose from your photos',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickImageWithCropCompress(ImageSource.gallery, isUserImage);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: primaryColor),
            title: Text(
              'Camera',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Take a new photo',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            onTap: () {
              Navigator.pop(context);
              _pickImageWithCropCompress(ImageSource.camera, isUserImage);
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(File? imageFile, String? currentUrl,
      {String? imageType}) async {
    if (imageFile == null) return currentUrl;

    setState(() => _isSaving = true);

    try {
      if (currentUrl != null && currentUrl.isNotEmpty) {
        print('Deleting previous image: $currentUrl');
        await _deleteImageFromCloudinary(currentUrl);
      }

      String folder = imageType ?? 'profile_images';
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..fields['folder'] = folder
        ..fields['public_id'] =
            '${_firebaseAuth.currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response =
          await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);

        final newUrl = jsonResponse['secure_url'];
        final publicId = jsonResponse['public_id'];

        print('Image uploaded successfully: $newUrl');
        print('Public ID: $publicId');

        return newUrl;
      }

      throw Exception('Upload failed with status ${response.statusCode}');
    } catch (e) {
      print('Image upload error: $e');
      _showSnackBar('Image upload failed: ${e.toString()}', isError: true);
      return currentUrl;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _deleteImageFromCloudinary(String imageUrl) async {
    try {
      String? publicId = _extractPublicIdFromUrl(imageUrl);
      if (publicId == null) {
        print('Could not extract public_id from URL: $imageUrl');
        _showSnackBar('Invalid image URL format', isError: true);
        return false;
      }

      print('Attempting to delete image with public_id: $publicId');

      final deleteUrl = Uri.parse(
          'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy');
      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final signatureString =
          'public_id=$publicId&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      print('Signature string: $signatureString'); // Debug log
      print('Generated signature: $signature'); // Debug log

      final response = await http.post(
        deleteUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'api_key': CloudinaryConfig.apiKey,
          'signature': signature,
        },
      ).timeout(const Duration(seconds: 30));

      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['result'] == 'ok') {
          print('Image deleted successfully from Cloudinary');
          _showSnackBar('Image deleted successfully');
          return true;
        } else {
          print('Delete failed: ${jsonResponse['result']}');
          // _showSnackBar('Failed to delete image: ${jsonResponse['result']}',
              // isError: true);
          return false;
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        print(
            'Failed to delete image. Status code: ${response.statusCode}, Body: ${response.body}');
        _showSnackBar('Failed to delete image: $errorMessage', isError: true);
        return false;
      }
    } catch (e, stackTrace) {
      print('Error deleting image from Cloudinary: $e');
      print('Stack trace: $stackTrace');
      _showSnackBar('Error deleting image: $e', isError: true);
      return false;
    }
  }

  String? _extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        print('Invalid Cloudinary URL format: $url');
        return null;
      }

      List<String> remainingSegments = pathSegments.sublist(uploadIndex + 1);
      if (remainingSegments.isNotEmpty &&
          RegExp(r'^v\d+$').hasMatch(remainingSegments.first)) {
        remainingSegments = remainingSegments.sublist(1);
      }

      if (remainingSegments.isEmpty) {
        print('No public_id found in URL: $url');
        return null;
      }

      String publicId = remainingSegments.join('/');
      if (publicId.contains('.')) {
        publicId = publicId.substring(0, publicId.lastIndexOf('.'));
      }

      if (publicId.isEmpty) {
        print('Extracted public_id is empty for URL: $url');
        return null;
      }

      print('Extracted public_id: $publicId');
      return publicId;
    } catch (e) {
      print('Error extracting public_id: $e');
      return null;
    }
  }

  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor!;
      } else if (kIsWeb) {
        const storage = flutterSecureStorage.FlutterSecureStorage();
        String? deviceId = await storage.read(key: 'device_id');

        if (deviceId == null) {
          deviceId = Uuid().v4();
          await storage.write(key: 'device_id', value: deviceId);
        }

        return deviceId;
      }

      return 'unknown_device';
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      _showSnackBar('No user signed in', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? newUserImageUrl = _userImageUrl;
      String? newCompanyLogoUrl = _companyLogoUrl;

      if (_userImage != null) {
        newUserImageUrl = await _uploadImage(_userImage, _userImageUrl,
            imageType: 'profile_images');
        if (newUserImageUrl != null) {
          _userImage = null;
        }
      }

      if (_companyLogo != null) {
        newCompanyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl,
            imageType: 'company_logos');
        if (newCompanyLogoUrl != null) {
          _companyLogo = null;
        }
      }

      final String deviceId = await _getDeviceId();

      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'designation': _designationController.text.trim(),
        'companyWebsite': _websiteController.text.trim(),
        'district': _districtController.text.trim(),
        'branch': _branchController.text.trim(),
        'userImage': newUserImageUrl ?? '',
        'companyLogo': newCompanyLogoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      bool isProfileComplete = _firstNameController.text.trim().isNotEmpty &&
          _lastNameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          (newUserImageUrl?.isNotEmpty ?? false);

      await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .set(profileData, SetOptions(merge: true));

      await _firestore.collection('users').doc(currentUser.uid).set({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'isActive': true,
        'role': 'user',
        'profile_status': isProfileComplete,
        'deviceId': deviceId,
        'isLoggedIn': true,
      }, SetOptions(merge: true));

      _userImageUrl = newUserImageUrl;
      _companyLogoUrl = newCompanyLogoUrl;

      if (mounted) {
        _showSnackBar('Profile updated successfully');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => UserDashboard()));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteImageManually(bool isUserImage) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Image',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete this ${isUserImage ? 'profile picture' : 'company logo'}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteImagePermanently(isUserImage);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                    color: errorColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteImagePermanently(bool isUserImage) async {
    setState(() => _isSaving = true);

    try {
      String? imageUrl = isUserImage ? _userImageUrl : _companyLogoUrl;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        bool deleted = await _deleteImageFromCloudinary(imageUrl);

        if (deleted) {
          await _firestore
              .collection('user_profile')
              .doc(_firebaseAuth.currentUser!.uid)
              .update({
            isUserImage ? 'userImage' : 'companyLogo': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            if (isUserImage) {
              _userImage = null;
              _userImageUrl = '';
            } else {
              _companyLogo = null;
              _companyLogoUrl = '';
            }
          });

          _showSnackBar(
              '${isUserImage ? 'Profile picture' : 'Company logo'} deleted successfully');
        } else {
          _showSnackBar('Failed to delete image from cloud storage',
              isError: true);
        }
      } else {
        setState(() {
          if (isUserImage) {
            _userImage = null;
            _userImageUrl = '';
          } else {
            _companyLogo = null;
            _companyLogoUrl = '';
          }
        });
        _showSnackBar('Image removed');
      }
    } catch (e) {
      _showSnackBar('Error deleting image: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Rest of the code (build method, helper methods, etc.) remains unchanged
  // Include the build method and other widgets as in the previous version
  // ...

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light()
              .textTheme
              .apply(bodyColor: textColor, displayColor: textColor),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          labelStyle:
              GoogleFonts.poppins(color: textSecondaryColor, fontSize: 14),
          floatingLabelStyle:
              GoogleFonts.poppins(color: primaryColor, fontSize: 14),
          errorStyle: GoogleFonts.poppins(color: errorColor, fontSize: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        colorScheme: ColorScheme.light(
            primary: primaryColor, secondary: accentColor, error: errorColor),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text('Complete Your Profile',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const _LoadingIndicator()
            : _isSaving
                ? const _LoadingIndicator()
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildProfileImageSection(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Personal Information'),
                        _buildTextFieldname(
                            'First Name', Icons.person, _firstNameController),
                        _buildTextFieldname(
                            'Last Name', Icons.person, _lastNameController),
                        _buildTextField('Email', Icons.email, _emailController,
                            type: TextInputType.emailAddress),
                        _buildTextField('Phone', Icons.phone, _phoneController,
                            type: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Company Information'),
                        _buildCompanyLogoSection(),
                        _buildcompanyname('Company Name', Icons.business,
                            _companyNameController),
                        _builddesignation(
                            'Designation', Icons.work, _designationController),
                        _builddistrict('District', Icons.location_city,
                            _districtController),
                        _buildbranch('Branch', Icons.store, _branchController),
                        _buildweb('Website', Icons.link, _websiteController,
                            type: TextInputType.url),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final shouldSave = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Save'),
                                  content: const Text(
                                      'Do you want to save your profile changes?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldSave == true) {
                              await _updateUserData();
                            }
                          },
                          child: const Text('Save Profile'),
                        )
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Profile Picture',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePickerOptions(true),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: backgroundColor,
                    backgroundImage: _getUserImageProvider(),
                    child: _shouldShowPlaceholder(true)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 30, color: textSecondaryColor),
                              const SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              if (_userImage != null || (_userImageUrl?.isNotEmpty ?? false))
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showDeleteImageDialog(true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getUserImageStatusText(),
            style: GoogleFonts.poppins(fontSize: 12, color: textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Company Logo',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImagePickerOptions(false),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _getCompanyLogoWidget(),
                  ),
                ),
              ),
              if (_companyLogo != null ||
                  (_companyLogoUrl?.isNotEmpty ?? false))
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: () => _showDeleteImageDialog(false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getCompanyLogoStatusText(),
            style: GoogleFonts.poppins(fontSize: 12, color: textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  ImageProvider? _getUserImageProvider() {
    if (_userImage != null) {
      return FileImage(_userImage!);
    } else if (_userImageUrl?.isNotEmpty ?? false) {
      return NetworkImage(_userImageUrl!);
    }
    return null;
  }

  bool _shouldShowPlaceholder(bool isUserImage) {
    if (isUserImage) {
      return _userImage == null && (_userImageUrl?.isEmpty ?? true);
    } else {
      return _companyLogo == null && (_companyLogoUrl?.isEmpty ?? true);
    }
  }

  String _getUserImageStatusText() {
    if (_userImage != null) {
      return 'New image selected • Tap save to upload';
    } else if (_userImageUrl?.isNotEmpty ?? false) {
      return 'Current profile picture • Tap to change';
    } else {
      return 'Tap to add your profile picture';
    }
  }

  Widget _getCompanyLogoWidget() {
    if (_companyLogo != null) {
      return Image.file(_companyLogo!, fit: BoxFit.cover);
    } else if (_companyLogoUrl?.isNotEmpty ?? false) {
      return Image.network(
        _companyLogoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildLogoPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: primaryColor,
            ),
          );
        },
      );
    } else {
      return _buildLogoPlaceholder();
    }
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_business, size: 30, color: textSecondaryColor),
          const SizedBox(height: 4),
          Text(
            'Add Logo',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getCompanyLogoStatusText() {
    if (_companyLogo != null) {
      return 'New logo selected • Tap save to upload';
    } else if (_companyLogoUrl?.isNotEmpty ?? false) {
      return 'Current company logo • Tap to change';
    } else {
      return 'Tap to add your company logo (optional)';
    }
  }

  void _showDeleteImageDialog(bool isUserImage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: errorColor),
              const SizedBox(width: 8),
              Text(
                'Delete Image',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this ${isUserImage ? 'profile picture' : 'company logo'}?\n\nThis action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                    color: textSecondaryColor, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteImagePermanently(isUserImage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextFieldname(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildweb(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }

  Widget _buildcompanyname(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }

  Widget _builddesignation(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }

  Widget _builddistrict(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }

  Widget _buildbranch(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? prefix,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        enabled: isEnabled,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          prefixIcon:
              Icon(icon, color: isEnabled ? primaryColor : textSecondaryColor),
          suffixIcon: isEnabled && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => controller.clear(),
                  color: textSecondaryColor,
                )
              : null,
        ),
        style: GoogleFonts.poppins(
            fontSize: 14, color: isEnabled ? textColor : textSecondaryColor),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              color: Color(0xFF00A19A), strokeWidth: 3),
          const SizedBox(height: 16),
          Text('Loading...',
              style:
                  GoogleFonts.poppins(fontSize: 16, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
