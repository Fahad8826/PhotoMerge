import 'dart:convert';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ProfilePage
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Personal information controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _ageController;
  late TextEditingController _dobController;
  String _selectedGender = 'Male';

  // Company information controllers
  late TextEditingController _companyNameController;
  late TextEditingController _companyLocationController;
  late TextEditingController _pincodeController;
  late TextEditingController _designationController;
  late TextEditingController _companyWebsiteController;

  File? _userImage;
  String? _userImageUrl;
  File? _companyLogo;
  String? _companyLogoUrl;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _imageLoading = false;

  DateTime? _selectedDate;
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize personal info controllers
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phone1Controller = TextEditingController();
    _phone2Controller = TextEditingController();
    _ageController = TextEditingController();
    _dobController = TextEditingController();

    // Initialize company info controllers
    _companyNameController = TextEditingController();
    _companyLocationController = TextEditingController();
    _pincodeController = TextEditingController();
    _designationController = TextEditingController();
    _companyWebsiteController = TextEditingController();

    // Load data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    // Dispose personal info controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _ageController.dispose();
    _dobController.dispose();

    // Dispose company info controllers
    _companyNameController.dispose();
    _companyLocationController.dispose();
    _pincodeController.dispose();
    _designationController.dispose();
    _companyWebsiteController.dispose();

    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user is currently signed in.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final docSnapshot = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        if (mounted) {
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phone1Controller.text = userData['phone1'] ?? '';
          _phone2Controller.text = userData['phone2'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _selectedGender = userData['gender'] ?? 'Male';

          if (userData['dob'] != null) {
            final Timestamp timestamp = userData['dob'];
            _selectedDate = timestamp.toDate();
            _dobController.text =
                DateFormat('MM/dd/yyyy').format(_selectedDate!);
          }

          _companyNameController.text = userData['companyName'] ?? '';
          _companyLocationController.text = userData['companyLocation'] ?? '';
          _pincodeController.text = userData['pincode'] ?? '';
          _designationController.text = userData['designation'] ?? '';
          _companyWebsiteController.text = userData['companyWebsite'] ?? '';

          _userImageUrl = userData['userImage'] ?? '';
          _companyLogoUrl = userData['companyLogo'] ?? '';

          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isEditing = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source, bool isUserImage) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null && mounted) {
        File imageFile = File(pickedFile.path);
        if (!isUserImage) {
          imageFile = await _convertToPng(imageFile);
        }
        setState(() {
          if (isUserImage) {
            _userImage = imageFile;
          } else {
            _companyLogo = imageFile;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File> _convertToPng(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final pngBytes = img.encodePng(image);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/company_logo_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(pngBytes);

      print('Converted image to PNG: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      print('Error converting to PNG: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting image to PNG: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return imageFile;
    }
  }

  void _showImageSourceOptions(bool isUserImage) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, isUserImage);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, isUserImage);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImage(File? imageFile, String? currentUrl,
      {bool isCompanyLogo = false}) async {
    if (imageFile == null) return currentUrl;

    try {
      setState(() => _isSaving = true);
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/image/upload');
      final bytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'TempApp'
        ..fields['public_id'] = isCompanyLogo
            ? 'company_logo_${DateTime.now().millisecondsSinceEpoch}'
            : 'user_image_${DateTime.now().millisecondsSinceEpoch}';

      // Apply background removal for company logo
      if (isCompanyLogo) {
        request.fields['eager'] = 'e_background_removal,f_png';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename:
            'image_${DateTime.now().millisecondsSinceEpoch}.${isCompanyLogo ? 'png' : 'jpg'}',
        contentType: isCompanyLogo
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      print('Uploading image to: $url, isCompanyLogo: $isCompanyLogo');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw const HttpException('Upload timed out');
        },
      );
      print('Upload response status: ${streamedResponse.statusCode}');
      final responseData = await streamedResponse.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (streamedResponse.statusCode == 200) {
        final jsonMap = jsonDecode(responseString);
        // For company logo, use the eager transformation URL if available
        final imageUrl = isCompanyLogo &&
                jsonMap['eager'] != null &&
                jsonMap['eager'].isNotEmpty
            ? jsonMap['eager'][0]['secure_url'] as String
            : jsonMap['secure_url'] as String;
        print('Upload success: $imageUrl');
        return imageUrl;
      } else {
        print('Upload error response: $responseString');
        throw HttpException(
            'Upload failed with status ${streamedResponse.statusCode}: $responseString');
      }
    } catch (e) {
      print('Exception during upload: $e');
      return currentUrl;
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user is currently signed in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Upload user image if selected
      if (_userImage != null) {
        _userImageUrl = await _uploadImage(_userImage, _userImageUrl);
      }

      // Upload company logo if selected
      if (_companyLogo != null) {
        String? originalUrl = _companyLogoUrl;
        _companyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl,
            isCompanyLogo: true);
        if (_companyLogoUrl == originalUrl) {
          print('PNG upload failed, trying JPEG fallback');
          _companyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl,
              isCompanyLogo: false);
        }
      }

      // Prepare data
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone1': _phone1Controller.text.trim(),
        'phone2': _phone2Controller.text.trim(),
        'age': _ageController.text.isNotEmpty
            ? int.parse(_ageController.text)
            : null,
        'gender': _selectedGender,
        'dob':
            _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'companyName': _companyNameController.text.trim(),
        'companyLocation': _companyLocationController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'designation': _designationController.text.trim(),
        'companyWebsite': _companyWebsiteController.text.trim(),
        'userImage': _userImageUrl ?? '',
        'companyLogo': _companyLogoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
        final today = DateTime.now();
        final age = today.year -
            picked.year -
            (today.month < picked.month ||
                    (today.month == picked.month && today.day < picked.day)
                ? 1
                : 0);
        _ageController.text = age.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isLoading && !_isSaving)
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              onPressed: _isEditing
                  ? _updateUserData
                  : () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return _isSaving
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildInfoCards(),
                ],
              ),
            ),
          );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildProfileImage(_userImage, _userImageUrl),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _showImageSourceOptions(true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(File? imageFile, String? imageUrl) {
    if (imageFile != null) {
      return Image.file(imageFile, fit: BoxFit.cover);
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return _imageLoading
          ? const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                );
              },
            );
    } else {
      return const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      );
    }
  }

  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information'),
          const SizedBox(height: 16),
          _buildTextField('First Name', Icons.person, _firstNameController),
          const SizedBox(height: 16),
          _buildTextField(
              'Last Name', Icons.person_outline, _lastNameController),
          const SizedBox(height: 16),
          _buildTextField(
            'Email Address',
            Icons.email,
            _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Phone Number (Primary)',
            Icons.phone,
            _phone1Controller,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Phone Number (Secondary)',
            Icons.phone_android,
            _phone2Controller,
            keyboardType: TextInputType.phone,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildDateField('Date of Birth', Icons.cake),
          const SizedBox(height: 16),
          _buildTextField(
            'Age',
            Icons.person_outline,
            _ageController,
            keyboardType: TextInputType.number,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildGenderDropdown(),
          const SizedBox(height: 32),
          _buildSectionHeader('Company Information'),
          const SizedBox(height: 16),
          _buildTextField(
              'Company Name', Icons.business, _companyNameController),
          const SizedBox(height: 16),
          _buildTextField('Designation', Icons.work, _designationController),
          const SizedBox(height: 16),
          _buildTextField('Company Location', Icons.location_on,
              _companyLocationController),
          const SizedBox(height: 16),
          _buildTextField(
            'Pincode',
            Icons.pin_drop,
            _pincodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Company Website',
            Icons.language,
            _companyWebsiteController,
            keyboardType: TextInputType.url,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildCompanyLogo(),
          const SizedBox(height: 32),
          if (_isEditing) _buildSaveButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Logo',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildProfileImage(_companyLogo, _companyLogoUrl),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _showImageSourceOptions(false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isRequired = true,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing && !readOnly,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter your $label';
        }
        if (label == 'Email Address' &&
            value!.isNotEmpty &&
            !_isValidEmail(value)) {
          return 'Please enter a valid email';
        }
        if (label == 'Phone Number (Primary)' &&
            value!.isNotEmpty &&
            !_isValidPhone(value)) {
          return 'Please enter a valid phone number';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !_isEditing || readOnly,
        fillColor: (!_isEditing || readOnly) ? Colors.grey.shade100 : null,
      ),
    );
  }

  Widget _buildDateField(String label, IconData icon) {
    return GestureDetector(
      onTap: _isEditing ? () => _selectDate(context) : null,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dobController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your $label';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: !_isEditing,
            fillColor: !_isEditing ? Colors.grey.shade100 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      onChanged: _isEditing
          ? (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                });
              }
            }
          : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your gender';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_2_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !_isEditing,
        fillColor: !_isEditing ? Colors.grey.shade100 : null,
      ),
      items: _genderOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone);
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _updateUserData,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
