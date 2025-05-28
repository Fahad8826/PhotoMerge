import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context); // Use theme for consistent styling

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view notifications.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00A19A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0, // Flat app bar
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style:
                    theme.textTheme.bodyLarge?.copyWith(color: Colors.red[400]),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16), // Add padding for better spacing
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No Title';
              final message = data['message'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final isRead = data['read'] == true;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isRead
                        ? Colors.grey[200]!
                        : theme.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        isRead ? Colors.grey[300] : theme.primaryColor,
                    child: Icon(
                      isRead ? Icons.notifications : Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  trailing: timestamp != null
                      ? Text(
                          DateFormat('d MMM yyyy')
                              .format(timestamp), // Better date format
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        )
                      : null,
                  onTap: () {
                    // Optional: Mark notification as read
                    if (!isRead) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('notifications')
                          .doc(docs[index].id)
                          .update({'read': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
