import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:photomerge/User/View/home.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Modern color palette based on image
  static const Color primaryColor = Color(0xFF00A19A); // Teal green
  static const Color accentColor = Color(0xFF005F5C); // Light teal
  static const Color backgroundColor = Color(0xFFF5F7FA); // Off-white
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121); // Dark blue-gray
  static const Color textSecondaryColor = Color(0xFF64748B); // Medium gray
  static const Color dividerColor = Color(0xFFE2E8F0); // Light gray
  static const Color errorColor = Color(0xFFE53E3E); // Red
  static const Color successColor = Color(0xFF38A169); // Green

  // static const Color primaryColor = Color(0xFF00A19A); // Teal main color
  // static const Color secondaryColor =Color(0xFFF8FAFA); // Very light background
  // static const Color accentColor = Color(0xFF005F5C); // Darker teal for accents
  // static const Color cardColor = Colors.white; // White card backgrounds
  // static const Color textColor = Color(0xFF212121); // Primary text
  // static const Color subtitleColor = Color(0xFF757575);

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
  bool _isEditing = false;
  bool _isSaving = false;
  int _selectedTabIndex = 0;

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
      // Fetch from 'users' collection
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      // Fetch from 'user_profile' collection
      final profileDoc = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        // From 'users' collection
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }

        // From 'user_profile' collection
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

        setState(() => _isEditing = false);
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isUserImage) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isUserImage) {
            _userImage = File(pickedFile.path);
          } else {
            _companyLogo = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  void _showImagePickerOptions(bool isUserImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Choose Image Source',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const Divider(height: 1, color: dividerColor),
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose from your photos',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, isUserImage);
              },
            ),
            const Divider(height: 1, color: dividerColor),
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a new photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, isUserImage);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File? imageFile, String? currentUrl) async {
    if (imageFile == null) return currentUrl;

    setState(() => _isSaving = true);
    try {
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'TempApp'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response =
          await request.send().timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return jsonDecode(responseData)['secure_url'];
      }
      throw Exception('Upload failed with status ${response.statusCode}');
    } catch (e) {
      _showSnackBar('Image upload failed: $e', isError: true);
      return currentUrl;
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      _userImageUrl = await _uploadImage(_userImage, _userImageUrl);
      _companyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl);

      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'designation': _designationController.text.trim(),
        'companyWebsite': _websiteController.text.trim(),
        'district': _districtController.text.trim(),
        'branch': _branchController.text.trim(),
        'userImage': _userImageUrl ?? '',
        'companyLogo': _companyLogoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Profile updated successfully');
        setState(() => _isEditing = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme.apply(
                bodyColor: textColor,
                displayColor: textColor,
              ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: dividerColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorColor, width: 2),
          ),
          labelStyle: GoogleFonts.poppins(
            color: textSecondaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          errorStyle: GoogleFonts.poppins(
            color: errorColor,
            fontSize: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            shadowColor: primaryColor.withOpacity(0.3),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          error: errorColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: _isLoading
            ? const _LoadingIndicator()
            : SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildTabSelector(),
                    Expanded(
                      child: _isSaving
                          ? const _LoadingIndicator()
                          : IndexedStack(
                              index: _selectedTabIndex,
                              children: [
                                _buildPersonalTab(),
                                _buildCompanyTab(),
                              ],
                            ),
                    ),
                    if (_isEditing) _buildSaveButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            'My Profile',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (!_isLoading && !_isSaving)
            Container(
              decoration: BoxDecoration(
                color: _isEditing ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color: _isEditing ? Colors.white : primaryColor,
                  size: 20,
                ),
                onPressed: _isEditing
                    ? _updateUserData
                    : () => setState(() => _isEditing = true),
                tooltip: _isEditing ? 'Save Profile' : 'Edit Profile',
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'Personal',
              Icons.person_rounded,
              0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              'Company',
              Icons.business_rounded,
              1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : textSecondaryColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab() {
    final fullName =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();

    return Form(
      key: _selectedTabIndex == 0 ? _formKey : null,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildProfileHeader(fullName),
            const SizedBox(height: 24),
            _buildSectionCard(
              'Personal Information',
              [
                _buildTextField(
                  'First Name',
                  Icons.person_outline_rounded,
                  _firstNameController,
                  semanticLabel: 'First Name',
                ),
                _buildTextField(
                  'Last Name',
                  Icons.person_rounded,
                  _lastNameController,
                  semanticLabel: 'Last Name',
                ),
                _buildTextField(
                  'Email',
                  Icons.email_outlined,
                  _emailController,
                  type: TextInputType.emailAddress,
                  semanticLabel: 'Email Address',
                  overrideEnabled: false, // make read-only
                ),
                _buildTextField(
                  'Phone',
                  Icons.phone_outlined,
                  _phoneController,
                  type: TextInputType.phone,
                  semanticLabel: 'Phone Number',
                  overrideEnabled: false, // make read-only
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyTab() {
    return Form(
      key: _selectedTabIndex == 1 ? _formKey : null,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildCompanyLogoCard(),
            const SizedBox(height: 24),
            _buildSectionCard(
              'Company Information',
              [
                _buildTextField(
                  'Company Name',
                  Icons.business_outlined,
                  _companyNameController,
                  semanticLabel: 'Company Name',
                ),
                _buildTextField(
                  'Designation',
                  Icons.work_outline_rounded,
                  _designationController,
                  semanticLabel: 'Designation',
                ),
                _buildTextField(
                  'District',
                  Icons.location_city_rounded,
                  _districtController,
                  semanticLabel: 'District',
                ),
                _buildTextField(
                  'Branch',
                  Icons.store_rounded,
                  _branchController,
                  semanticLabel: 'Branch',
                ),
                _buildTextField(
                  'Website',
                  Icons.link_rounded,
                  _websiteController,
                  type: TextInputType.url,
                  semanticLabel: 'Company Website',
                  prefix: 'https://',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String fullName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Semantics(
                  label: 'Profile Image',
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: dividerColor.withOpacity(0.4),
                    backgroundImage: _userImage != null
                        ? FileImage(_userImage!)
                        : _userImageUrl?.isNotEmpty ?? false
                            ? NetworkImage(_userImageUrl!)
                            : null,
                    child:
                        _userImage == null && (_userImageUrl?.isEmpty ?? true)
                            ? Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: textSecondaryColor,
                              )
                            : null,
                  ),
                ),
              ),
              if (_isEditing)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: GestureDetector(
                    onTap: () => _showImagePickerOptions(true),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            fullName.isEmpty ? 'Complete Your Profile' : fullName,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _emailController.text.isEmpty
                ? 'Add your email'
                : _emailController.text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (_phoneController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _phoneController.text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Company Logo',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isEditing ? () => _showImagePickerOptions(false) : null,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _isEditing ? primaryColor.withOpacity(0.5) : dividerColor,
                  width: _isEditing ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _companyLogo != null
                    ? Image.file(
                        _companyLogo!,
                        fit: BoxFit.cover,
                      )
                    : _companyLogoUrl?.isNotEmpty ?? false
                        ? Image.network(
                            _companyLogoUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: textSecondaryColor,
                                  size: 40,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  color: textSecondaryColor.withOpacity(0.6),
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEditing ? 'Add Logo' : 'No Logo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Tap to change company logo',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          ...children.expand((widget) => [widget, const SizedBox(height: 16)]),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool obscureText = false,
    String? prefix,
    bool Function(String)? validator,
    String? semanticLabel,
    bool? overrideEnabled,
  }) {
    final isEnabled = overrideEnabled ?? _isEditing;

    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscureText,
      enabled: isEnabled,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(
          icon,
          color: isEnabled ? primaryColor : textSecondaryColor,
          size: 22,
        ),
        suffixIcon: isEnabled && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => setState(() => controller.clear()),
                color: textSecondaryColor,
              )
            : null,
      ),
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isEnabled ? textColor : textSecondaryColor,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (validator != null && !validator(value)) {
          return 'Please enter a valid $label';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _updateUserData,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40), // Reduced height
                padding:
                    const EdgeInsets.symmetric(vertical: 10), // Reduced padding
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 14, // Smaller font size
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
            color: Color(0xFF06846A),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
