import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/kashta_colors.dart';
import '../../../core/utils/localization.dart';
import '../../../core/widgets/language_app_bar.dart';
import '../../../widgets/kashta_background.dart';
import '../../safety/ui/safety_checkin_page.dart';
import 'favorites_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
    required this.onOpenAdminDashboard,
    required this.onOpenPlace,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenAdminDashboard;
  final void Function({
    required String placeId,
    required double lat,
    required double lng,
    required bool openDetailsOnLoad,
  }) onOpenPlace;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        imagePath: 'assets/tripPic.png',
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
                leading: const Icon(Icons.star_border),
                title: Text(widget.tr.t('favorites')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openFavorites,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.health_and_safety_outlined,
                  color: KashtaColors.primary,
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
                    color: KashtaColors.primary,
                  ),
                  title: Text(widget.tr.t('admin_dashboard')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onOpenAdminDashboard,
                ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.mail_outline,
                  color: KashtaColors.primary,
                ),
                title: const Text('Contact Us'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openContactUs,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: KashtaColors.softOrange,
                ),
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

  void _openContactUs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ContactUsPage(),
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

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          tr: widget.tr,
          isArabic: widget.isArabic,
          onToggleLanguage: widget.onToggleLanguage,
          onOpenPlace: widget.onOpenPlace,
        ),
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'abdulrahma55124@gmail.com',
  );

  Future<void> _sendEmail(BuildContext context) async {
    try {
      final launched = await launchUrl(
        _emailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) {
        return;
      }
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
      ),
      body: KashtaBackground(
        imagePath: 'assets/tripPic.png',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For questions, feedback, or reporting issues, you can contact the Kashta team through email.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'abdulrahma55124@gmail.com',
                      style: TextStyle(
                        color: KashtaColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _sendEmail(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: KashtaColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Send Email'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

