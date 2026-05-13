import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/utils/localization.dart';
import 'pending_places_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.tr});

  final Tr tr;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return Scaffold(body: Center(child: Text(tr.t('access_denied'))));
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr.t('admin_dashboard'))),
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
                return Center(child: Text(tr.t('permission_denied')));
              }
              return Center(
                child: Text(tr.t('failed_load_moderation_dashboard')),
              );
            }

            final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(tr.t('pending_places')),
                subtitle: Text('$pendingCount ${tr.t('waiting_for_review')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PendingPlacesPage(tr: tr),
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
