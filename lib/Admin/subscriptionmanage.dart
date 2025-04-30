import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSubscriptionPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subscriptions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;
              final email = userData['email'] ?? 'No email';
              final isSubscribed = userData['isSubscribed'] ?? false;
              final subscriptionPlan = userData['subscriptionPlan'] ?? 'None';
              final subscriptionExpiry =
                  userData['subscriptionExpiry'] as Timestamp?;

              return ListTile(
                title: Text(email),
                subtitle: Text(
                  'Plan: $subscriptionPlan\n'
                  'Subscribed: ${isSubscribed ? 'Yes' : 'No'}\n'
                  'Expiry: ${subscriptionExpiry?.toDate().toString() ?? 'N/A'}',
                ),
                trailing: isSubscribed
                    ? TextButton(
                        onPressed: () => _revokeSubscription(context, userId),
                        child: const Text('Revoke'),
                      )
                    : TextButton(
                        onPressed: () => _approveSubscription(context, userId),
                        child: const Text('Approve'),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  void _approveSubscription(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Subscription'),
        content: const Text('Select a subscription plan for this user:'),
        actions: [
          ListTile(
            title: const Text('Basic Plan - 30 days'),
            onTap: () async {
              await _firestore.collection('users').doc(userId).update({
                'isSubscribed': true,
                'subscriptionPlan': 'Basic',
                'subscriptionExpiry': Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 30)),
                ),
                'lastSubscriptionUpdate': Timestamp.now(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription approved')),
              );
            },
          ),
          ListTile(
            title: const Text('Premium Plan - 1 yaer'),
            onTap: () async {
              await _firestore.collection('users').doc(userId).update({
                'isSubscribed': true,
                'subscriptionPlan': 'Premium',
                'subscriptionExpiry': Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 365)),
                ),
                'lastSubscriptionUpdate': Timestamp.now(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Subscription approved')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _revokeSubscription(BuildContext context, String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isSubscribed': false,
      'subscriptionPlan': '',
      'subscriptionExpiry': null,
      'lastSubscriptionUpdate': Timestamp.now(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription revoked')),
    );
  }
}
