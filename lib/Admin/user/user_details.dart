// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:pdf/widgets.dart' as pw;

// class UserDetailsPage extends StatefulWidget {
//   final Map<String, dynamic> profileData;
//   final Map<String, dynamic> userData;

//   const UserDetailsPage({
//     required this.profileData,
//     required this.userData,
//     Key? key,
//   }) : super(key: key);

//   @override
//   _UserDetailsPageState createState() => _UserDetailsPageState();
// }

// class _UserDetailsPageState extends State<UserDetailsPage> {
//   Future<File> _generatePdf(
//     Map<String, dynamic> userData,
//     Map<String, dynamic> profileData,
//     String userId,
//   ) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Center(
//                 child: pw.Text(
//                   'User Details',
//                   style: pw.TextStyle(
//                     fontSize: 24,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Divider(),
//               pw.SizedBox(height: 20),
//               _buildPdfRow(
//                   'First Name', profileData['firstName'] ?? 'Not provided'),
//               _buildPdfRow(
//                   'Last Name', profileData['lastName'] ?? 'Not provided'),
//               _buildPdfRow('Email', userData['email'] ?? 'Not provided'),
//               _buildPdfRow('Phone', profileData['phone1'] ?? 'Not provided'),
//               _buildPdfRow('Role', userData['role'] ?? 'Not provided'),
//               _buildPdfRow(
//                   'Company', profileData['companyName'] ?? 'Not provided'),
//               _buildPdfRow(
//                   'Designation', profileData['designation'] ?? 'Not provided'),
//               _buildPdfRow(
//                   'Website', profileData['companyWebsite'] ?? 'Not provided'),
//               _buildPdfRow('Created', _formatTimestamp(userData['createdAt'])),
//               pw.SizedBox(height: 30),
//               pw.Text(
//                 'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
//                 style: pw.TextStyle(
//                   fontSize: 10,
//                   fontStyle: pw.FontStyle.italic,
//                   color: PdfColors.grey,
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     final output = await getTemporaryDirectory();
//     final displayName = (profileData['firstName'] ?? 'user').toString().trim();
//     final safeName = displayName.replaceAll(RegExp(r'\s+'), '_');
//     final fileName = '${safeName}_details.pdf';
//     final file = File('${output.path}/$fileName');
//     await file.writeAsBytes(await pdf.save());
//     return file;
//   }

//   String _formatTimestamp(dynamic timestamp) {
//     if (timestamp is Timestamp) {
//       return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
//     }
//     return 'Invalid date';
//   }

//   pw.Widget _buildPdfRow(String title, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 4),
//       child: pw.Row(
//         children: [
//           pw.Container(
//             width: 120,
//             child: pw.Text('$title:',
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//           ),
//           pw.Expanded(child: pw.Text(value)),
//         ],
//       ),
//     );
//   }

//   Future<File> _savePdfToDownloads(File tempFile, String userId) async {
//     try {
//       Directory? downloadsDir;
//       final fileName =
//           'user_${userId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

//       if (Platform.isAndroid) {
//         // Primary approach: Try the standard Downloads directory
//         downloadsDir = Directory('/storage/emulated/0/Download');

//         // Check if directory exists and is accessible
//         if (!await downloadsDir.exists() ||
//             !(await _canWriteToDirectory(downloadsDir))) {
//           // Alternative approach: Use External Storage Directory as fallback
//           downloadsDir = await getExternalStorageDirectory();

//           // If still not accessible, try alternative external directories
//           if (downloadsDir == null ||
//               !(await _canWriteToDirectory(downloadsDir))) {
//             final externalDirs = await getExternalStorageDirectories();
//             if (externalDirs != null && externalDirs.isNotEmpty) {
//               downloadsDir = externalDirs.first;
//             }
//           }
//         }

//         // As last resort, use app's directory
//         if (downloadsDir == null ||
//             !(await _canWriteToDirectory(downloadsDir))) {
//           downloadsDir = await getApplicationDocumentsDirectory();
//         }
//       } else if (Platform.isIOS) {
//         // On iOS, save to app's Documents directory
//         downloadsDir = await getApplicationDocumentsDirectory();
//       } else {
//         // Fallback for other platforms
//         downloadsDir = await getTemporaryDirectory();
//       }

//       // Ensure the directory exists
//       if (!await downloadsDir!.exists()) {
//         await downloadsDir.create(recursive: true);
//       }

//       final finalFile = File(path.join(downloadsDir.path, fileName));

//       // Copy the temp file to the final location
//       return await tempFile.copy(finalFile.path);
//     } catch (e) {
//       print('Error saving PDF to downloads: $e');
//       return tempFile; // Return the original file if the operation fails
//     }
//   }

// // Helper method to check if a directory is writable
//   Future<bool> _canWriteToDirectory(Directory directory) async {
//     try {
//       // Try to create a temporary file in the directory
//       final testFile = File(
//           '${directory.path}/write_test_${DateTime.now().millisecondsSinceEpoch}.tmp');
//       await testFile.writeAsString('test');
//       await testFile.delete();
//       return true;
//     } catch (e) {
//       print('Directory is not writable: ${directory.path}, Error: $e');
//       return false;
//     }
//   }

//   Future<void> _downloadUserDetails(BuildContext context,
//       Map<String, dynamic> userData, String userId) async {
//     // Store the context at the beginning of the function
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     final navigator = Navigator.of(context);

//     try {
//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (dialogContext) => const AlertDialog(
//           content: Row(
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(width: 20),
//               Text("Generating PDF..."),
//             ],
//           ),
//         ),
//       );

//       // Generate PDF
//       final tempPdfFile =
//           await _generatePdf(userData, widget.profileData, userId);

//       // Check Android version for appropriate permission request
//       bool isAndroid13OrAbove = false;
//       if (Platform.isAndroid) {
//         final androidInfo = await DeviceInfoPlugin().androidInfo;
//         isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
//       }

//       // Request appropriate permissions based on platform and version
//       bool permissionGranted = false;

//       if (Platform.isAndroid) {
//         if (isAndroid13OrAbove) {
//           // For Android 13+ (API 33+), we need different permissions
//           final status = await Permission.photos.request();
//           permissionGranted = status.isGranted;
//         } else {
//           // For Android 12 and below
//           final statuses = await [
//             Permission.storage,
//             Permission.manageExternalStorage,
//           ].request();

//           permissionGranted = statuses[Permission.storage]?.isGranted == true ||
//               statuses[Permission.manageExternalStorage]?.isGranted == true;
//         }
//       } else if (Platform.isIOS) {
//         // iOS doesn't need explicit permission for app documents directory
//         permissionGranted = true;
//       }

//       File finalPdfFile;

//       if (permissionGranted) {
//         finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
//         await tempPdfFile.delete();
//         print('PDF saved to: ${finalPdfFile.path}');

//         // Show success message
//         scaffoldMessenger.showSnackBar(
//           SnackBar(
//             content: Text(
//                 'PDF saved successfully to: ${path.basename(finalPdfFile.path)}'),
//             duration: Duration(seconds: 3),
//           ),
//         );
//       } else {
//         finalPdfFile = tempPdfFile;
//         print('Storage permission denied. Using temporary file.');

//         // Show permission denied message
//         scaffoldMessenger.showSnackBar(
//           const SnackBar(
//             content: Text(
//                 'Storage permission denied. PDF will be opened but not saved to Downloads.'),
//             duration: Duration(seconds: 5),
//           ),
//         );
//       }

//       // Dismiss the loading dialog if navigator is still valid
//       if (navigator.canPop()) {
//         navigator.pop();
//       }

//       // Open the PDF file
//       final result = await OpenFile.open(finalPdfFile.path);
//       if (result.type != ResultType.done) {
//         scaffoldMessenger.showSnackBar(
//           SnackBar(content: Text('Error opening PDF: ${result.message}')),
//         );
//       }
//     } catch (e) {
//       print('Error generating or saving PDF: $e');
//       // Dismiss the loading dialog if navigator is still valid
//       if (navigator.canPop()) {
//         navigator.pop();
//       }
//       scaffoldMessenger.showSnackBar(
//         SnackBar(content: Text('Error generating or saving PDF: $e')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'User Details',
//           style: GoogleFonts.oswald(
//             fontSize: 25,
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Color(0xFF00B6B0),
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//           onPressed: () => Navigator.of(context).pop(),
//           icon: Icon(Icons.arrow_back),
//           color: Colors.white,
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildProfileRow('First Name',
//                 widget.profileData['firstName'] ?? 'N/A', Icons.person),
//             SizedBox(height: 15),
//             _buildProfileRow('Last Name',
//                 widget.profileData['lastName'] ?? 'N/A', Icons.person_outline),
//             SizedBox(height: 15),
//             _buildProfileRow('Email', widget.profileData['email'], Icons.email),
//             SizedBox(height: 15),
//             _buildProfileRow(
//                 'Phone', widget.profileData['phone'] ?? 'N/A', Icons.phone),
//             SizedBox(height: 15),
//             _buildProfileRow('Role', widget.userData['role'], Icons.work),
//             SizedBox(height: 15),
//             _buildProfileRow('Company',
//                 widget.profileData['companyName'] ?? 'N/A', Icons.business),
//             SizedBox(height: 15),
//             _buildProfileRow('Designation',
//                 widget.profileData['designation'] ?? 'N/A', Icons.title),
//             SizedBox(height: 15),
//             _buildProfileRow('Website',
//                 widget.profileData['companyWebsite'] ?? 'N/A', Icons.language),
//             SizedBox(height: 40),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   final userId = widget.userData['uid'] ?? 'unknown_user';
//                   _downloadUserDetails(context, widget.userData, userId);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                 ),
//                 child: Text(
//                   "Download",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProfileRow(String label, String value, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: Color(0xFF00B6B0), size: 22),
//               SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   '$label: $value',
//                   style: TextStyle(fontSize: 18, color: Colors.black),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 4), // space before underline
//           Divider(
//             color: Colors.black, // underline color
//             thickness: 1, // thickness of underline
//             height: 1,
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart'; // Add this import for sharing

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Map<String, dynamic> userData;

  const UserDetailsPage({
    required this.profileData,
    required this.userData,
    Key? key,
  }) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  // Existing PDF generation method remains the same
  Future<File> _generatePdf(
    Map<String, dynamic> userData,
    Map<String, dynamic> profileData,
    String userId,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'User Details',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _buildPdfRow(
                  'First Name', profileData['firstName'] ?? 'Not provided'),
              _buildPdfRow(
                  'Last Name', profileData['lastName'] ?? 'Not provided'),
              _buildPdfRow('Email', userData['email'] ?? 'Not provided'),
              _buildPdfRow('Phone', profileData['phone1'] ?? 'Not provided'),
              _buildPdfRow('Role', userData['role'] ?? 'Not provided'),
              _buildPdfRow(
                  'Company', profileData['companyName'] ?? 'Not provided'),
              _buildPdfRow(
                  'Designation', profileData['designation'] ?? 'Not provided'),
              _buildPdfRow(
                  'Website', profileData['companyWebsite'] ?? 'Not provided'),
              _buildPdfRow('Created', _formatTimestamp(userData['createdAt'])),
              pw.SizedBox(height: 30),
              pw.Text(
                'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final displayName = (profileData['firstName'] ?? 'user').toString().trim();
    final safeName = displayName.replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeName}_details.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // NEW: Excel generation method
  Future<File> _generateExcel(
    Map<String, dynamic> userData,
    Map<String, dynamic> profileData,
    String userId,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['User Details'];

    // Set column widths
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 30);

    // Add header
    var headerCell = sheet.cell(CellIndex.indexByString('A1'));
    headerCell.value = TextCellValue('User Details Report');
    headerCell.cellStyle = CellStyle(
      fontSize: 16,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Merge cells for header
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('B1'));

    // Add data rows
    int row = 3; // Start from row 3 to leave space after header

    _addExcelRow(
        sheet, row++, 'First Name', profileData['firstName'] ?? 'Not provided');
    _addExcelRow(
        sheet, row++, 'Last Name', profileData['lastName'] ?? 'Not provided');
    _addExcelRow(sheet, row++, 'Email', userData['email'] ?? 'Not provided');
    _addExcelRow(
        sheet, row++, 'Phone', profileData['phone1'] ?? 'Not provided');
    _addExcelRow(sheet, row++, 'Role', userData['role'] ?? 'Not provided');
    _addExcelRow(
        sheet, row++, 'Company', profileData['companyName'] ?? 'Not provided');
    _addExcelRow(sheet, row++, 'Designation',
        profileData['designation'] ?? 'Not provided');
    _addExcelRow(sheet, row++, 'Website',
        profileData['companyWebsite'] ?? 'Not provided');
    _addExcelRow(
        sheet, row++, 'Created', _formatTimestamp(userData['createdAt']));

    // Add generation timestamp
    row += 2;
    var timestampCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    timestampCell.value = TextCellValue(
        'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    timestampCell.cellStyle = CellStyle(
      fontSize: 10,
      italic: true,
    );

    // Save the Excel file
    final output = await getTemporaryDirectory();
    final displayName = (profileData['firstName'] ?? 'user').toString().trim();
    final safeName = displayName.replaceAll(RegExp(r'\s+'), '_');
    final fileName = '${safeName}_details.xlsx';
    final file = File('${output.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  void _addExcelRow(Sheet sheet, int row, String label, String value) {
    var labelCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    labelCell.value = TextCellValue(label);
    labelCell.cellStyle = CellStyle(bold: true);

    var valueCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    valueCell.value = TextCellValue(value);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
    }
    return 'Invalid date';
  }

  pw.Widget _buildPdfRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text('$title:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  Future<File> _savePdfToDownloads(File tempFile, String userId) async {
    try {
      Directory? downloadsDir;
      final fileName =
          'user_${userId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists() ||
            !(await _canWriteToDirectory(downloadsDir))) {
          downloadsDir = await getExternalStorageDirectory();

          if (downloadsDir == null ||
              !(await _canWriteToDirectory(downloadsDir))) {
            final externalDirs = await getExternalStorageDirectories();
            if (externalDirs != null && externalDirs.isNotEmpty) {
              downloadsDir = externalDirs.first;
            }
          }
        }

        if (downloadsDir == null ||
            !(await _canWriteToDirectory(downloadsDir))) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getTemporaryDirectory();
      }

      if (!await downloadsDir!.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final finalFile = File(path.join(downloadsDir.path, fileName));
      return await tempFile.copy(finalFile.path);
    } catch (e) {
      print('Error saving PDF to downloads: $e');
      return tempFile;
    }
  }

  // NEW: Save Excel to downloads
  Future<File> _saveExcelToDownloads(File tempFile, String userId) async {
    try {
      Directory? downloadsDir;
      final fileName =
          'user_${userId}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';

      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists() ||
            !(await _canWriteToDirectory(downloadsDir))) {
          downloadsDir = await getExternalStorageDirectory();

          if (downloadsDir == null ||
              !(await _canWriteToDirectory(downloadsDir))) {
            final externalDirs = await getExternalStorageDirectories();
            if (externalDirs != null && externalDirs.isNotEmpty) {
              downloadsDir = externalDirs.first;
            }
          }
        }

        if (downloadsDir == null ||
            !(await _canWriteToDirectory(downloadsDir))) {
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getTemporaryDirectory();
      }

      if (!await downloadsDir!.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final finalFile = File(path.join(downloadsDir.path, fileName));
      return await tempFile.copy(finalFile.path);
    } catch (e) {
      print('Error saving Excel to downloads: $e');
      return tempFile;
    }
  }

  Future<bool> _canWriteToDirectory(Directory directory) async {
    try {
      final testFile = File(
          '${directory.path}/write_test_${DateTime.now().millisecondsSinceEpoch}.tmp');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      print('Directory is not writable: ${directory.path}, Error: $e');
      return false;
    }
  }

  Future<void> _downloadUserDetails(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating PDF..."),
            ],
          ),
        ),
      );

      final tempPdfFile =
          await _generatePdf(userData, widget.profileData, userId);

      bool isAndroid13OrAbove = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
      }

      bool permissionGranted = false;

      if (Platform.isAndroid) {
        if (isAndroid13OrAbove) {
          final status = await Permission.photos.request();
          permissionGranted = status.isGranted;
        } else {
          final statuses = await [
            Permission.storage,
            Permission.manageExternalStorage,
          ].request();

          permissionGranted = statuses[Permission.storage]?.isGranted == true ||
              statuses[Permission.manageExternalStorage]?.isGranted == true;
        }
      } else if (Platform.isIOS) {
        permissionGranted = true;
      }

      File finalPdfFile;

      if (permissionGranted) {
        finalPdfFile = await _savePdfToDownloads(tempPdfFile, userId);
        await tempPdfFile.delete();
        print('PDF saved to: ${finalPdfFile.path}');

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'PDF saved successfully to: ${path.basename(finalPdfFile.path)}'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        finalPdfFile = tempPdfFile;
        print('Storage permission denied. Using temporary file.');

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Storage permission denied. PDF will be opened but not saved to Downloads.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      if (navigator.canPop()) {
        navigator.pop();
      }

      final result = await OpenFile.open(finalPdfFile.path);
      if (result.type != ResultType.done) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error opening PDF: ${result.message}')),
        );
      }
    } catch (e) {
      print('Error generating or saving PDF: $e');
      if (navigator.canPop()) {
        navigator.pop();
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating or saving PDF: $e')),
      );
    }
  }

  // NEW: Download Excel method
  Future<void> _downloadExcelDetails(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Generating Excel..."),
            ],
          ),
        ),
      );

      final tempExcelFile =
          await _generateExcel(userData, widget.profileData, userId);

      bool isAndroid13OrAbove = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        isAndroid13OrAbove = androidInfo.version.sdkInt >= 33;
      }

      bool permissionGranted = false;

      if (Platform.isAndroid) {
        if (isAndroid13OrAbove) {
          final status = await Permission.photos.request();
          permissionGranted = status.isGranted;
        } else {
          final statuses = await [
            Permission.storage,
            Permission.manageExternalStorage,
          ].request();

          permissionGranted = statuses[Permission.storage]?.isGranted == true ||
              statuses[Permission.manageExternalStorage]?.isGranted == true;
        }
      } else if (Platform.isIOS) {
        permissionGranted = true;
      }

      File finalExcelFile;

      if (permissionGranted) {
        finalExcelFile = await _saveExcelToDownloads(tempExcelFile, userId);
        await tempExcelFile.delete();
        print('Excel saved to: ${finalExcelFile.path}');

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                'Excel saved successfully to: ${path.basename(finalExcelFile.path)}'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        finalExcelFile = tempExcelFile;
        print('Storage permission denied. Using temporary file.');

        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Storage permission denied. Excel will be opened but not saved to Downloads.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      if (navigator.canPop()) {
        navigator.pop();
      }

      final result = await OpenFile.open(finalExcelFile.path);
      if (result.type != ResultType.done) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error opening Excel: ${result.message}')),
        );
      }
    } catch (e) {
      print('Error generating or saving Excel: $e');
      if (navigator.canPop()) {
        navigator.pop();
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error generating or saving Excel: $e')),
      );
    }
  }

  // NEW: Share Excel method
  Future<void> _shareExcelDetails(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Preparing Excel for sharing..."),
            ],
          ),
        ),
      );

      final excelFile =
          await _generateExcel(userData, widget.profileData, userId);

      Navigator.of(context).pop(); // Close loading dialog

      await Share.shareXFiles(
        [XFile(excelFile.path)],
        text: 'User Details Excel Report',
        subject:
            'User Details - ${widget.profileData['firstName'] ?? 'User'} ${widget.profileData['lastName'] ?? ''}',
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Excel file prepared for sharing'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error sharing Excel: $e');
      Navigator.of(context).pop(); // Close loading dialog if still open
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sharing Excel: $e')),
      );
    }
  }

  // NEW: Show export options dialog
  void _showExportOptions(BuildContext context) {
    final userId = widget.userData['uid'] ?? 'unknown_user';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Export Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Download as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadUserDetails(context, widget.userData, userId);
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text('Download as Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadExcelDetails(context, widget.userData, userId);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.blue),
                title: Text('Share Excel'),
                onTap: () {
                  Navigator.pop(context);
                  _shareExcelDetails(context, widget.userData, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Details',
          style: GoogleFonts.oswald(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF00B6B0),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('First Name',
                widget.profileData['firstName'] ?? 'N/A', Icons.person),
            SizedBox(height: 15),
            _buildProfileRow('Last Name',
                widget.profileData['lastName'] ?? 'N/A', Icons.person_outline),
            SizedBox(height: 15),
            _buildProfileRow('Email', widget.profileData['email'], Icons.email),
            SizedBox(height: 15),
            _buildProfileRow(
                'Phone', widget.profileData['phone'] ?? 'N/A', Icons.phone),
            SizedBox(height: 15),
            _buildProfileRow('Role', widget.userData['role'], Icons.work),
            SizedBox(height: 15),
            _buildProfileRow('Company',
                widget.profileData['companyName'] ?? 'N/A', Icons.business),
            SizedBox(height: 15),
            _buildProfileRow('Designation',
                widget.profileData['designation'] ?? 'N/A', Icons.title),
            SizedBox(height: 15),
            _buildProfileRow('Website',
                widget.profileData['companyWebsite'] ?? 'N/A', Icons.language),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showExportOptions(context),
                icon: Icon(Icons.download, color: Colors.white),
                label: Text(
                  "Export Data",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF00B6B0), size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$label: $value',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Divider(
            color: Colors.black,
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }
}
