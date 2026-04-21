import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/role_provider.dart';
import 'pending_places_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, pendingSnapshot) {
            if (pendingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (pendingSnapshot.hasError) {
              final error = pendingSnapshot.error;
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                return const Center(child: Text('Permission denied'));
              }
              return const Center(
                child: Text('Failed to load moderation dashboard'),
              );
            }

            final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: const Text('Pending Places'),
                subtitle: Text('$pendingCount waiting for review'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PendingPlacesPage(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
