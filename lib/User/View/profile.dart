// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   final _firebaseAuth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _formKey = GlobalKey<FormState>();

//   late TextEditingController _nameController;
//   late TextEditingController _emailController;
//   late TextEditingController _phoneController;
//   late TextEditingController _designationController;

//   File? _image;
//   String? _imageUrl;
//   bool _isLoading = true;
//   bool _isEditing = false;
//   bool _isSaving = false;
//   bool _imageLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController();
//     _emailController = TextEditingController();
//     _phoneController = TextEditingController();
//     _designationController = TextEditingController();

//     // Load data after the first frame is rendered
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadUserData();
//     });
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _designationController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadUserData() async {
//     setState(() => _isLoading = true);

//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('No user is currently signed in.'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return;
//     }

//     try {
//       // Use a cache policy to load from cache if available
//       final docSnapshot = await _firestore
//           .collection('user_profile')
//           .doc(currentUser.uid)
//           .get(const GetOptions(source: Source.serverAndCache));

//       if (docSnapshot.exists) {
//         final userData = docSnapshot.data() as Map<String, dynamic>;
//         if (mounted) {
//           _nameController.text = userData['name'] ?? '';
//           _emailController.text = userData['email'] ?? '';
//           _phoneController.text = userData['phone'] ?? '';
//           _designationController.text = userData['designation'] ?? '';
//           _imageUrl = userData['image'] ?? '';

//           setState(() {
//             _isEditing = false;
//             _isLoading = false;
//           });
//         }
//       } else {
//         // First time user - start in edit mode
//         if (mounted) {
//           setState(() {
//             _isEditing = true;
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading profile: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final picker = ImagePicker();
//       final pickedFile = await picker.pickImage(
//         source: source,
//         imageQuality: 70, // Lower quality for faster upload
//         maxWidth: 800, // Limit image dimensions
//         maxHeight: 800,
//       );

//       if (pickedFile != null && mounted) {
//         setState(() {
//           _image = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error picking image: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _showImageSourceOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return SafeArea(
//           child: Wrap(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Gallery'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Camera'),
//                 onTap: () {
//                   Navigator.of(context).pop();
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<String?> _uploadImage() async {
//     if (_image == null) return _imageUrl;

//     try {
//       setState(() => _isSaving = true);

//       // Create multipart request
//       final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
//       final request = http.MultipartRequest('POST', url)
//         ..fields['upload_preset'] = 'TempApp'
//         ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

//       // Use a timeout for the request
//       final streamedResponse = await request.send().timeout(
//         const Duration(seconds: 30),
//         onTimeout: () {
//           throw const HttpException('Upload timed out');
//         },
//       );

//       if (streamedResponse.statusCode == 200) {
//         // Process response efficiently
//         final responseData = await streamedResponse.stream.toBytes();
//         final jsonMap = jsonDecode(String.fromCharCodes(responseData));
//         return jsonMap['secure_url'] as String;
//       } else {
//         throw HttpException(
//             'Upload failed with status ${streamedResponse.statusCode}');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error uploading image: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       return _imageUrl;
//     }
//   }

//   Future<void> _updateUserData() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     final currentUser = _firebaseAuth.currentUser;
//     if (currentUser == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No user is currently signed in.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     try {
//       setState(() => _isSaving = true);

//       // Only upload image if a new one was selected
//       if (_image != null) {
//         _imageUrl = await _uploadImage();
//       }

//       // Prepare data
//       final data = {
//         'name': _nameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'designation': _designationController.text.trim(),
//         'image': _imageUrl ?? '',
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       // Batch write for better performance
//       await _firestore
//           .collection('user_profile')
//           .doc(currentUser.uid)
//           .set(data, SetOptions(merge: true));

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Profile updated successfully'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );

//         setState(() {
//           _isSaving = false;
//           _isEditing = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating profile: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         setState(() => _isSaving = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           if (!_isLoading && !_isSaving)
//             IconButton(
//               icon: Icon(_isEditing ? Icons.check : Icons.edit),
//               onPressed: _isEditing
//                   ? _updateUserData
//                   : () => setState(() => _isEditing = true),
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     return _isSaving
//         ? const Center(child: CircularProgressIndicator())
//         : SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   _buildProfileHeader(),
//                   _buildInfoCard(),
//                 ],
//               ),
//             ),
//           );
//   }

//   Widget _buildProfileHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor.withOpacity(0.1),
//       ),
//       child: Center(
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 5,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: ClipOval(
//                 child: _buildProfileImage(),
//               ),
//             ),
//             if (_isEditing)
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: InkWell(
//                   onTap: _showImageSourceOptions,
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).primaryColor,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: const Icon(Icons.camera_alt,
//                         color: Colors.white, size: 20),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileImage() {
//     // Use file if available
//     if (_image != null) {
//       return Image.file(_image!, fit: BoxFit.cover);
//     }
//     // Use network image if URL is available
//     else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
//       return _imageLoading
//           ? const Center(
//               child: SizedBox(
//                 width: 30,
//                 height: 30,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             )
//           : Image.network(
//               _imageUrl!,
//               fit: BoxFit.cover,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) {
//                   return child;
//                 }
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                             loadingProgress.expectedTotalBytes!
//                         : null,
//                     strokeWidth: 2,
//                   ),
//                 );
//               },
//               errorBuilder: (context, error, stackTrace) {
//                 return const Icon(
//                   Icons.person,
//                   size: 60,
//                   color: Colors.grey,
//                 );
//               },
//             );
//     }
//     // Show placeholder if nothing available
//     else {
//       return const Icon(
//         Icons.person,
//         size: 60,
//         color: Colors.grey,
//       );
//     }
//   }

//   Widget _buildInfoCard() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader('Personal Information'),
//           const SizedBox(height: 16),
//           _buildTextField('Full Name', Icons.person, _nameController),
//           const SizedBox(height: 16),
//           _buildTextField(
//             'Email Address',
//             Icons.email,
//             _emailController,
//             keyboardType: TextInputType.emailAddress,
//           ),
//           const SizedBox(height: 16),
//           _buildTextField(
//             'Phone Number',
//             Icons.phone,
//             _phoneController,
//             keyboardType: TextInputType.phone,
//           ),
//           const SizedBox(height: 16),
//           _buildTextField('Designation', Icons.work, _designationController),
//           const SizedBox(height: 32),
//           if (_isEditing) _buildSaveButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).primaryColor,
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     IconData icon,
//     TextEditingController controller, {
//     TextInputType? keyboardType,
//   }) {
//     return TextFormField(
//       controller: controller,
//       enabled: _isEditing,
//       keyboardType: keyboardType,
//       textInputAction: TextInputAction.next,
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Please enter your $label';
//         }
//         if (label == 'Email Address' && !_isValidEmail(value)) {
//           return 'Please enter a valid email';
//         }
//         return null;
//       },
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         filled: !_isEditing,
//         fillColor: !_isEditing ? Colors.grey.shade100 : null,
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   Widget _buildSaveButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: ElevatedButton(
//         onPressed: _updateUserData,
//         style: ElevatedButton.styleFrom(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         child: const Text(
//           'Save Profile',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Using intl for date formatting

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
  String _selectedGender = 'Male'; // Default gender

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
      // Use a cache policy to load from cache if available
      final docSnapshot = await _firestore
          .collection('user_profile')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        if (mounted) {
          // Set personal info
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phone1Controller.text = userData['phone1'] ?? '';
          _phone2Controller.text = userData['phone2'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _selectedGender = userData['gender'] ?? 'Male';

          // Handle date of birth
          if (userData['dob'] != null) {
            final Timestamp timestamp = userData['dob'];
            _selectedDate = timestamp.toDate();
            _dobController.text =
                DateFormat('MM/dd/yyyy').format(_selectedDate!);
          }

          // Set company info
          _companyNameController.text = userData['companyName'] ?? '';
          _companyLocationController.text = userData['companyLocation'] ?? '';
          _pincodeController.text = userData['pincode'] ?? '';
          _designationController.text = userData['designation'] ?? '';
          _companyWebsiteController.text = userData['companyWebsite'] ?? '';

          // Set image urls
          _userImageUrl = userData['userImage'] ?? '';
          _companyLogoUrl = userData['companyLogo'] ?? '';

          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
        }
      } else {
        // First time user - start in edit mode
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
        imageQuality: 70, // Lower quality for faster upload
        maxWidth: 800, // Limit image dimensions
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

  Future<String?> _uploadImage(File? imageFile, String? currentUrl) async {
    if (imageFile == null) return currentUrl;

    try {
      setState(() => _isSaving = true);

      // Create multipart request
      final url = Uri.parse('https://api.cloudinary.com/v1_1/dfchqxsdz/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'TempApp'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Use a timeout for the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw const HttpException('Upload timed out');
        },
      );

      if (streamedResponse.statusCode == 200) {
        // Process response efficiently
        final responseData = await streamedResponse.stream.toBytes();
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));
        return jsonMap['secure_url'] as String;
      } else {
        throw HttpException(
            'Upload failed with status ${streamedResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return currentUrl;
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

      // Only upload images if new ones were selected
      if (_userImage != null) {
        _userImageUrl = await _uploadImage(_userImage, _userImageUrl);
      }

      if (_companyLogo != null) {
        _companyLogoUrl = await _uploadImage(_companyLogo, _companyLogoUrl);
      }

      // Prepare data
      final data = {
        // Personal info
        'firstName': _firstNameController.text.trim(),
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

        // Company info
        'companyName': _companyNameController.text.trim(),
        'companyLocation': _companyLocationController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'designation': _designationController.text.trim(),
        'companyWebsite': _companyWebsiteController.text.trim(),

        // Images
        'userImage': _userImageUrl ?? '',
        'companyLogo': _companyLogoUrl ?? '',

        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Batch write for better performance
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

        // Calculate age automatically
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
                  onTap: () =>
                      _showImageSourceOptions(true), // true for user image
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
    // Use file if available
    if (imageFile != null) {
      return Image.file(imageFile, fit: BoxFit.cover);
    }
    // Use network image if URL is available
    else if (imageUrl != null && imageUrl.isNotEmpty) {
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
    }
    // Show placeholder if nothing available
    else {
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
          // Personal Information Section
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
            readOnly: true, // Auto-calculated from DOB
          ),
          const SizedBox(height: 16),
          _buildGenderDropdown(),

          const SizedBox(height: 32),

          // Company Information Section
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
                      onTap: () => _showImageSourceOptions(
                          false), // false for company logo
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
