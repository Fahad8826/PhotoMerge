import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photomerge/Admin/user/user_details.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart'; // Add this import
import 'dart:io';

class UserListPage extends StatefulWidget {
  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void _refreshUserList() {
    setState(() {});
  }

  Future<void> _setUserStatus(String docId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'isActive': newStatus,
      });
    } catch (e) {
      print('Error setting user status: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserProfile(String docId) async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(docId)
          .get();

      if (profileDoc.exists) {
        return profileDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
    return null;
  }

  bool isProfileComplete(
      Map<String, dynamic> data, List<String> requiredFields) {
    for (String field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  // NEW: Get all users data method
  Future<List<Map<String, dynamic>>> _getAllUsersData() async {
    // Fetch all users
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final users = usersSnapshot.docs.where((doc) {
      final data = doc.data();
      return data['role'] != 'admin'; // Exclude admins
    }).toList();

    if (users.isEmpty) {
      return [];
    }

    // Fetch profile data for all users
    final userDataWithProfiles = <Map<String, dynamic>>[];
    for (var userDoc in users) {
      final userData = userDoc.data();
      final docId = userDoc.id;
      final profileData = await _getUserProfile(docId);
      userDataWithProfiles.add({
        'docId': docId,
        'userData': userData,
        'profileData': profileData,
      });
    }

    // Sort by full name (firstName + lastName)
    userDataWithProfiles.sort((a, b) {
      final profileA = a['profileData'] as Map<String, dynamic>?;
      final profileB = b['profileData'] as Map<String, dynamic>?;
      final fullNameA =
          '${profileA?['firstName'] ?? ''} ${profileA?['lastName'] ?? ''}'
              .trim();
      final fullNameB =
          '${profileB?['firstName'] ?? ''} ${profileB?['lastName'] ?? ''}'
              .trim();
      return fullNameA.compareTo(fullNameB);
    });

    return userDataWithProfiles;
  }

  // NEW: Generate Excel file
  Future<File> _generateExcelFile(List<Map<String, dynamic>> usersData) async {
    final excel = Excel.createExcel();
    final sheet = excel['All Users Data'];

    // Set column widths
    sheet.setColumnWidth(0, 25); // Name
    sheet.setColumnWidth(1, 15); // Phone
    sheet.setColumnWidth(2, 30); // Email
    sheet.setColumnWidth(3, 25); // Company
    sheet.setColumnWidth(4, 20); // Designation
    sheet.setColumnWidth(5, 15); // District
    sheet.setColumnWidth(6, 15); // Branch
    sheet.setColumnWidth(7, 20); // Subscription Plan
    sheet.setColumnWidth(8, 15); // Price
    sheet.setColumnWidth(9, 10); // Status

    // Add header row
    final headers = [
      'Name',
      'Phone Number',
      'Email',
      'Company Name',
      'Designation',
      'District',
      'Branch',
      'Subscription Plan',
      'Subscription Price',
      'Status'
    ];

    for (int i = 0; i < headers.length; i++) {
      var cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.blue200,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int rowIndex = 0; rowIndex < usersData.length; rowIndex++) {
      final user = usersData[rowIndex];
      final userData = user['userData'] as Map<String, dynamic>;
      final profileData = user['profileData'] as Map<String, dynamic>?;

      // Prepare data
      final fullName = profileData != null
          ? '${profileData['firstName'] ?? 'N/A'} ${profileData['lastName'] ?? 'N/A'}'
              .trim()
          : 'N/A';
      final phoneNumber = profileData?['phone']?.toString() ?? 'N/A';
      final email = userData['email']?.toString() ?? 'N/A';
      final companyName = profileData?['companyName']?.toString() ?? 'N/A';
      final designation = profileData?['designation']?.toString() ?? 'N/A';
      final district = profileData?['district']?.toString() ?? 'N/A';
      final branch = profileData?['branch']?.toString() ?? 'N/A';
      final subscriptionPlan =
          userData['subscriptionPlan']?.toString() ?? 'N/A';
      final subscriptionPrice =
          userData['subscriptionPrice']?.toString() ?? 'N/A';
      final status = (userData['isActive'] ?? true) ? 'Active' : 'Inactive';

      final rowData = [
        fullName,
        phoneNumber,
        email,
        companyName,
        designation,
        district,
        branch,
        subscriptionPlan,
        subscriptionPrice,
        status
      ];

      for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex, rowIndex: rowIndex + 1));
        cell.value = TextCellValue(rowData[colIndex]);

        // Color code status column
        if (colIndex == 9) {
          // Status column
          cell.cellStyle = CellStyle(
            backgroundColorHex:
                status == 'Active' ? ExcelColor.green200 : ExcelColor.red200,
          );
        }
      }
    }

    // Add summary row
    final summaryRow = usersData.length + 2;
    var summaryCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow));
    summaryCell.value = TextCellValue('Total Users: ${usersData.length}');
    summaryCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.grey100,
    );

    // Add generation timestamp
    final timestampRow = summaryRow + 1;
    var timestampCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: timestampRow));
    timestampCell.value = TextCellValue(
        'Generated on: ${DateTime.now().toString().split('.')[0]}');
    timestampCell.cellStyle = CellStyle(
      italic: true,
      fontSize: 10,
    );

    // Save file
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File(
        '${outputDir.path}/all_users_data_${DateTime.now().millisecondsSinceEpoch}.xlsx');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  // UPDATED: Download PDF method
  Future<void> _downloadAllUsersDataAsPDF() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      final usersData = await _getAllUsersData();

      if (usersData.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found to download.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'All Users Data',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              ...usersData.map((user) {
                final userData = user['userData'] as Map<String, dynamic>;
                final profileData =
                    user['profileData'] as Map<String, dynamic>?;

                final fullName = profileData != null
                    ? '${profileData['firstName'] ?? 'N/A'} ${profileData['lastName'] ?? 'N/A'}'
                        .trim()
                    : 'N/A';

                final phoneNumber = profileData?['phone']?.toString() ?? 'N/A';
                final email = userData['email']?.toString() ?? 'N/A';
                final companyName =
                    profileData?['companyName']?.toString() ?? 'N/A';
                final designation =
                    profileData?['designation']?.toString() ?? 'N/A';
                final district = profileData?['district']?.toString() ?? 'N/A';
                final branch = profileData?['branch']?.toString() ?? 'N/A';
                final subscriptionPlan =
                    userData['subscriptionPlan']?.toString() ?? 'N/A';
                final subscriptionPrice =
                    userData['subscriptionPrice']?.toString() ?? 'N/A';
                final status =
                    (userData['isActive'] ?? true) ? 'Active' : 'Inactive';

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Name: $fullName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Phone Number: $phoneNumber'),
                    pw.Text('Email: $email'),
                    pw.Text('Company Name: $companyName'),
                    pw.Text('Designation: $designation'),
                    pw.Text('District: $district'),
                    pw.Text('Branch: $branch'),
                    pw.Text('Subscription Plan: $subscriptionPlan'),
                    pw.Text('Subscription Price: $subscriptionPrice'),
                    pw.Text('Status: $status'),
                    pw.Divider(),
                    pw.SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ];
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final file = File(
          '${outputDir.path}/all_users_data_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PDF Generated'),
          content: Text(
              'PDF has been saved to app documents directory. Would you like to open it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open PDF: ${result.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Open'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Error downloading users data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW: Download Excel method
  Future<void> _downloadAllUsersDataAsExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating Excel...'),
          ],
        ),
      ),
    );

    try {
      final usersData = await _getAllUsersData();

      if (usersData.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found to download.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final file = await _generateExcelFile(usersData);
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Excel Generated'),
          content: Text(
              'Excel file has been saved to app documents directory. Would you like to open it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open Excel: ${result.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Open'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Error generating Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW: Share Excel method
  Future<void> _shareAllUsersDataAsExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Preparing Excel for sharing...'),
          ],
        ),
      ),
    );

    try {
      final usersData = await _getAllUsersData();

      if (usersData.isEmpty) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No users found to share.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final file = await _generateExcelFile(usersData);
      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'All Users Data Report',
        subject:
            'Users Data Export - ${DateTime.now().toString().split(' ')[0]}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel file prepared for sharing'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      print('Error sharing Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing Excel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NEW: Show export options
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Export All Users Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text('Download as PDF'),
                subtitle: Text('Save PDF to device storage'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAllUsersDataAsPDF();
                },
              ),
              ListTile(
                leading: Icon(Icons.table_chart, color: Colors.green),
                title: Text('Download as Excel'),
                subtitle: Text('Save Excel spreadsheet to device storage'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadAllUsersDataAsExcel();
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.blue),
                title: Text('Share Excel'),
                subtitle: Text('Share Excel file via email or messaging apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAllUsersDataAsExcel();
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
        centerTitle: true,
        backgroundColor: Color(0xFF00B6B0),
        title: Text(
          'All Users',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshUserList,
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _showExportOptions,
            tooltip: 'Export all users data',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email, phone, or first name',
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
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final users = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['role'] != 'admin'; // Exclude admins
                }).toList();

                if (users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final docId = userDoc.id;
                    final email = userData['email'] ?? 'No email';
                    final role = userData['role'] ?? 'No role';
                    final isActive = userData['isActive'] ?? true;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _getUserProfile(docId),
                      builder: (context, profileSnapshot) {
                        final profileData = profileSnapshot.data;
                        final firstName =
                            profileData?['firstName']?.toString() ?? '';
                        final phone = profileData?['phone']?.toString() ?? '';

                        // Filter logic
                        if (_searchQuery.isNotEmpty) {
                          final query = _searchQuery;
                          final matches = email.toLowerCase().contains(query) ||
                              phone.toLowerCase().contains(query) ||
                              firstName.toLowerCase().contains(query);
                          if (!matches) return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profileData != null && firstName.isNotEmpty
                                        ? '$firstName (${email})'
                                        : email,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('Role: $role'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: isActive,
                                  activeColor: Colors.green,
                                  onChanged: (newValue) =>
                                      _setUserStatus(docId, newValue),
                                ),
                              ],
                            ),
                            onTap: () async {
                              if (profileData == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('No user profile data found.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailsPage(
                                    profileData: profileData,
                                    userData: userData,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
