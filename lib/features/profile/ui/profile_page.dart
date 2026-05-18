import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../../../widgets/kashta_background.dart';
import '../../safety/ui/safety_checkin_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
    required this.onOpenAdminDashboard,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenAdminDashboard;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showComingSoon(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    final provider = context.watch<RoleProvider>();
    final isAdmin = provider.roles['admin'] == true;
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('profile'),
        onToggleLanguage: widget.onToggleLanguage,
      ),
      body: KashtaBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(
                isAnonymous
                    ? widget.tr.t('guest_account')
                    : widget.tr.t('signed_in_account'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(widget.tr.t('edit_profile')),
                onTap: () => _showComingSoon(widget.tr.t('coming_soon')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.hiking_outlined),
                title: Text(widget.tr.t('my_trips')),
                onTap: () => _showComingSoon(widget.tr.t('coming_soon')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.star_border),
                title: Text(widget.tr.t('favorites')),
                onTap: () => _showComingSoon(widget.tr.t('coming_soon')),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.orange,
                ),
                title: Text(widget.tr.t('safety_checkin_title')),
                subtitle: Text(widget.tr.t('safety_checkin_profile_subtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openSafetyCheckin,
              ),
            ),
            if (isAdmin)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.shield_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(widget.tr.t('admin_dashboard')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onOpenAdminDashboard,
                ),
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(widget.tr.t('sign_out')),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSafetyCheckin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SafetyCheckinPage(
          tr: widget.tr,
          isArabic: widget.isArabic,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
    );
  }
}



