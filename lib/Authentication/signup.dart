// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lottie/lottie.dart';
// import 'package:photomerge/main.dart';

// class SignupPage extends StatefulWidget {
//   @override
//   _SignupPageState createState() => _SignupPageState();
// }

// class _SignupPageState extends State<SignupPage> {
//   final _formKey = GlobalKey<FormState>();

//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _phoneController = TextEditingController();

//   final FocusNode _phoneFocusNode = FocusNode();
//   final FocusNode _emailFocusNode = FocusNode();
//   final FocusNode _passwordFocusNode = FocusNode();
//   final FocusNode _confirmPasswordFocusNode = FocusNode();

//   // String _selectedRole = 'user';
//   bool _isLoading = false;
//   String? _error;
//   bool _passwordVisible = false;
//   bool _confirmPasswordVisible = false;

//   // Validators
//   String? validateEmail(String? value) {
//     if (value == null || value.isEmpty) return 'Email is required';
//     if (value.length > 254) return 'Email is too long';
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
//     return null;
//   }

//   String? validatePhone(String? value) {
//     if (value == null || value.isEmpty) return 'Phone number is required';
//     final phoneRegex = RegExp(r'^[6-9]\d{9}$');
//     if (!phoneRegex.hasMatch(value)) return 'Enter a valid Indian phone number';
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) return 'Password is required';
//     if (value.length < 6) return 'Password must be at least 6 characters';
//     return null;
//   }

//   String? validateConfirmPassword(String? value) {
//     if (value != _passwordController.text) return 'Passwords do not match';
//     return null;
//   }

//   void _submitForm() {
//     if (_formKey.currentState!.validate()) {
//       // All validations passed, proceed with registration or submission
//       print('Form is valid');
//     } else {
//       print('Form has errors');
//     }
//   }

//   Future<void> _signup() async {
//     final email = _emailController.text.trim().toLowerCase();
//     final password = _passwordController.text;
//     final confirmPassword = _confirmPasswordController.text;
//     final phone = _phoneController.text.trim();

//     if (email.isEmpty || password.isEmpty || phone.isEmpty) {
//       setState(() {
//         _error = 'Please fill in all fields';
//       });
//       return;
//     }

//     if (password != confirmPassword) {
//       setState(() {
//         _error = 'Passwords do not match';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       //  Check for duplicate phone number
//       final phoneCheck = await FirebaseFirestore.instance
//           .collection('users')
//           .where('phone', isEqualTo: phone)
//           .limit(1)
//           .get();

//       if (phoneCheck.docs.isNotEmpty) {
//         setState(() {
//           _error = 'This phone number is already registered';
//           _isLoading = false;
//         });
//         return;
//       }

//       //  Create user with Firebase Auth
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       //  Store user info in Firestore
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user!.uid)
//           .set({
//         'email': email,
//         'phone': phone,
//         'role': "user",
//         'isActive': true,
//         'isSubscribed': false,
//         'freeDownloadUsed': false,
//         'subscriptionPlan': '',
//         'subscriptionExpiry': null,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'An error occurred during sign up';

//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'This email is already registered';
//       } else if (e.code == 'weak-password') {
//         errorMessage = 'The password is too weak';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Please enter a valid email address';
//       }

//       setState(() {
//         _error = errorMessage;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final colorScheme = Theme.of(context).colorScheme;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: LoadingOverlay(
//         isLoading: _isLoading,
//         child: SafeArea(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: SizedBox(
//                 height: size.height - 40, // Account for SafeArea
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const Spacer(flex: 1),
//                     // App logo or icon here
//                     SizedBox(
//                         height: 200,
//                         width: 200,
//                         child: Lottie.asset('assets/animations/reg.json')),
//                     const SizedBox(height: 24),
//                     // const SizedBox(height: 24),
//                     Text(
//                       'Create Account',
//                       style: TextStyle(
//                         fontSize: 28,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Sign up to get started',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.black,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 40),

//                     // Email field
//                     TextFormField(
//                       focusNode: _emailFocusNode,
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         // labelText: 'Email',
//                         hintText: 'Enter your email',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.green, width: 2),
//                         ),
//                         prefixIcon:
//                             Icon(Icons.email_outlined, color: Colors.green),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         contentPadding:
//                             const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       keyboardType: TextInputType.emailAddress,
//                       textInputAction: TextInputAction.next,
//                       validator: validateEmail,
//                       onFieldSubmitted: (_) =>
//                           FocusScope.of(context).requestFocus(_phoneFocusNode),
//                     ),
//                     const SizedBox(height: 16),

//                     TextFormField(
//                       focusNode: _phoneFocusNode,
//                       controller: _phoneController,
//                       inputFormatters: [
//                         FilteringTextInputFormatter.digitsOnly,
//                         LengthLimitingTextInputFormatter(10),
//                       ],
//                       decoration: InputDecoration(
//                         // labelText: 'Phone Number',
//                         hintText: 'Enter your phone number',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.green, width: 2),
//                         ),
//                         prefixIcon:
//                             Icon(Icons.phone_outlined, color: Colors.green),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         contentPadding:
//                             const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       keyboardType: TextInputType.phone,
//                       textInputAction: TextInputAction.next,
//                       validator: validatePhone,
//                       onFieldSubmitted: (_) => FocusScope.of(context)
//                           .requestFocus(_passwordFocusNode),
//                     ),
//                     const SizedBox(height: 16),

//                     // Password field
//                     TextFormField(
//                       focusNode: _passwordFocusNode,
//                       controller: _passwordController,
//                       decoration: InputDecoration(
//                         // labelText: 'Password',
//                         hintText: 'Create a password',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.green, width: 2),
//                         ),
//                         prefixIcon:
//                             Icon(Icons.lock_outline, color: Colors.green),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _passwordVisible
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                             color: Colors.grey[600],
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _passwordVisible = !_passwordVisible;
//                             });
//                           },
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         contentPadding:
//                             const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       obscureText: !_passwordVisible,
//                       textInputAction: TextInputAction.next,
//                       validator: validatePassword,
//                       onFieldSubmitted: (_) => FocusScope.of(context)
//                           .requestFocus(_confirmPasswordFocusNode),
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       focusNode: _confirmPasswordFocusNode,
//                       controller: _confirmPasswordController,
//                       decoration: InputDecoration(
//                         // labelText: 'Confirm Password',
//                         hintText: 'Confirm your password',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.green, width: 2),
//                         ),
//                         prefixIcon:
//                             Icon(Icons.lock_outline, color: Colors.green),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _confirmPasswordVisible
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                             color: Colors.grey[600],
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _confirmPasswordVisible =
//                                   !_confirmPasswordVisible;
//                             });
//                           },
//                         ),
//                         filled: true,
//                         fillColor: Colors.grey[50],
//                         contentPadding:
//                             const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       obscureText: !_confirmPasswordVisible,
//                       validator: validateConfirmPassword,
//                     ),
//                     const SizedBox(height: 16),

//                     if (_error != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 16),
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.red[50],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.red[200]!),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(Icons.error_outline, color: Colors.red[700]),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   _error!,
//                                   style: TextStyle(color: Colors.red[700]),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 24),

//                     // Sign Up button
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _signup,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 2,
//                       ),
//                       child: const Text(
//                         'Create Account',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Login link
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'Already have an account? ',
//                           style: TextStyle(
//                             color: Colors.black,
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () =>
//                               Navigator.pushNamed(context, '/login'),
//                           child: Text(
//                             'Login',
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(flex: 2),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _emailFocusNode.dispose();
//     _phoneFocusNode.dispose();
//     _passwordFocusNode.dispose();
//     _confirmPasswordFocusNode.dispose();
//     super.dispose();
//   }
// }
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    as flutterSecureStorage;
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _error;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Validators
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (value.length > 254) return 'Email is too long';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter a valid Indian phone number';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() {
        _error = 'Please fill in all fields';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _error = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check for duplicate phone number
      final phoneCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isNotEmpty) {
        setState(() {
          _error = 'This phone number is already registered';
          _isLoading = false;
        });
        return;
      }

      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user info in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'phone': phone,
        'role': "user",
        'isActive': true,
        'isSubscribed': false,
        'freeDownloadUsed': false,
        'subscriptionPlan': '',
        'subscriptionExpiry': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign up';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address';
      }

      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isLoggedIn': false,
          'deviceId': '',
        });
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              child: Column(
                children: <Widget>[
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/background.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 30,
                          width: 80,
                          height: 200,
                          child: FadeInUp(
                            duration: Duration(seconds: 1),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/light-1.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 140,
                          width: 80,
                          height: 150,
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1200),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/light-2.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          top: 40,
                          width: 80,
                          height: 150,
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1300),
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/clock.png'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          child: FadeInUp(
                            duration: Duration(milliseconds: 1600),
                            child: Container(
                              margin: EdgeInsets.only(top: 50),
                              child: Center(
                                child: Text(
                                  "Sign Up",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          FadeInUp(
                            duration: Duration(milliseconds: 1800),
                            child: Column(
                              children: <Widget>[
                                // Email TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_phoneFocusNode);
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Email",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: validateEmail,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Phone TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_passwordFocusNode);
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Phone number",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: validatePhone,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Password TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    focusNode: _passwordFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context).requestFocus(
                                          _confirmPasswordFocusNode);
                                    },
                                    obscureText: !_passwordVisible,
                                    decoration: InputDecoration(
                                      hintText: "Password",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: validatePassword,
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Confirm Password TextField
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    focusNode: _confirmPasswordFocusNode,
                                    textInputAction: TextInputAction.done,
                                    obscureText: !_confirmPasswordVisible,
                                    decoration: InputDecoration(
                                      hintText: "Confirm Password",
                                      hintStyle:
                                          TextStyle(color: Colors.grey[700]),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color.fromRGBO(
                                              143, 148, 251, 0.5),
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromRGBO(143, 148, 251, 1),
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _confirmPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _confirmPasswordVisible =
                                                !_confirmPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: validateConfirmPassword,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: FadeInUp(
                                duration: Duration(milliseconds: 1800),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style:
                                              TextStyle(color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 30),
                          FadeInUp(
                            duration: Duration(milliseconds: 1900),
                            child: GestureDetector(
                              onTap: _isLoading ? null : _signup,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF00A19A),
                                      Color(0x9900A19A),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          FadeInUp(
                            duration: Duration(milliseconds: 2100),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: Color.fromRGBO(143, 148, 251, 1),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset('assets/animations/empty_gallery.json'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
