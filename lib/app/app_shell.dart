import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/groups/groups.dart' as chat;
import '../features/auth/ui/auth_page.dart';
import '../features/auth/ui/welcome_preferences_page.dart';
import '../core/utils/localization.dart';
import '../core/models/app_language.dart';
import '../core/providers/role_provider.dart';
import 'main_screen.dart';

class KashtaApp extends StatefulWidget {
  const KashtaApp({
    super.key,
    this.deepLinkService,
  });

  final chat.DeepLinkService? deepLinkService;

  @override
  State<KashtaApp> createState() => _KashtaAppState();
}

class _KashtaAppState extends State<KashtaApp> {
  AppLanguage _lang = AppLanguage.en;
  late final chat.DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _deepLinkService = widget.deepLinkService ?? chat.DeepLinkService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _deepLinkService.init(context);
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _lang = _lang == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr(_lang);
    final isArabic = _lang == AppLanguage.ar;

    return ChangeNotifierProvider<RoleProvider>(
      create: (_) => RoleProvider(),
      child: MaterialApp(
        navigatorKey: _deepLinkService.navigatorKey,
        debugShowCheckedModeBanner: false,
        routes: {
    '/welcome_preferences': (context) => const WelcomePreferencesPage(),
    
  },
        home: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AuthGate(
            tr: tr,
            isArabic: isArabic,
            onToggleLanguage: _toggleLanguage,
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

       if (snapshot.data == null) {
  return AuthPage(
    tr: tr,
    isArabic: isArabic,
    onToggleLanguage: onToggleLanguage,
  );
}

final user = snapshot.data;

return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
  builder: (context, userSnap) {
    if (userSnap.connectionState == ConnectionState.waiting) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = userSnap.data?.data();
    final completed = data?['preferencesCompleted'] == true;

    if (!completed) {
      return const WelcomePreferencesPage();
    }

    return MainScreen(
      tr: tr,
      isArabic: isArabic,
      onToggleLanguage: onToggleLanguage,
    );
  },
);
      },
    );
  }
}

