// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_cropper/image_cropper.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';


// Future<File?> cropImage(File? imageFile) async {
//   var _croppedFile = await ImageCropper().cropImage(
//     sourcePath: imageFile!.path,
//     aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
//     uiSettings: [
//       AndroidUiSettings(
//         toolbarColor: Color(0xFF2564AF),
//         toolbarWidgetColor: Colors.white,
//         initAspectRatio: CropAspectRatioPreset.original,
//         lockAspectRatio: false,
//       ),
//     ],
//   );

//   return _croppedFile != null ? File(_croppedFile.path) : null;
// }


//  Future<File?> compress({
//   required File image,
//   int quality = 80,
//   int minWidth = 800,
//   int minHeight = 600,
// }) async {
//   final dir = await getTemporaryDirectory();
//   final targetPath = path.join(dir.path, 'compressed_${path.basename(image.path)}');

//   final result = await FlutterImageCompress.compressAndGetFile(
//     image.absolute.path,
//     targetPath,
//     quality: quality,
//     minWidth: minWidth,
//     minHeight: minHeight,
//   );
//   return result != null ? File(result.path) : null;
// }
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<File?> cropImage(File? imageFile) async {
  if (imageFile == null) return null;
  
  try {
    var croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarColor:  Color(0xFF00A19A),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: false,
          cropGridStrokeWidth: 2,
          cropFrameStrokeWidth: 3,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  } catch (e) {
    print('Error cropping image: $e');
    return null;
  }
}

Future<File?> compress({
  required File image,
  int quality = 80,
  int minWidth = 800,
  int minHeight = 600,
}) async {
  try {
    // Check if the input file exists
    if (!await image.exists()) {
      print('Input image file does not exist');
      return null;
    }

    print('Original file size: ${await image.length()} bytes');
    
    final dir = await getTemporaryDirectory();
    
    // Generate a unique filename to avoid conflicts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    final extension = path.extension(image.path);
    final targetPath = path.join(dir.path, 'compressed_${timestamp}_${random}$extension');

    print('Compressing to: $targetPath');

    final result = await FlutterImageCompress.compressAndGetFile(
      image.absolute.path,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg, // Explicitly set format
    );

    if (result != null) {
      final compressedFile = File(result.path);
      print('Compressed file size: ${await compressedFile.length()} bytes');
      return compressedFile;
    } else {
      print('Compression failed - result is null');
      return null;
    }
  } catch (e) {
    print('Error compressing image: $e');
    return null;
  }
}

// Alternative compression method using XFile
Future<File?> compressAlternative({
  required File image,
  int quality = 80,
  int minWidth = 800,
  int minHeight = 600,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = path.join(dir.path, 'compressed_$timestamp.jpg');

    final result = await FlutterImageCompress.compressWithFile(
      image.absolute.path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      final compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(result);
      return compressedFile;
    }
    return null;
  } catch (e) {
    print('Error in alternative compression: $e');
    return null;
  }
}