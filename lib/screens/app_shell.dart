import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../chat/chat.dart' as chat;
import '../models/app_language.dart';
import '../providers/role_provider.dart';
import '../services/place_service.dart';
import '../services/trip_service.dart';
import '../services/weather_service.dart';
import '../utils/checklist_utils.dart';
import '../utils/firestore_utils.dart';
import '../utils/localization.dart';
import '../widgets/language_app_bar.dart';
import 'welcome_preferences_page.dart';



part 'auth_page.dart';
part 'main_screen.dart';
part 'explore_page.dart';
part 'trips_page.dart';
part 'groups_page.dart';
part 'profile_page.dart';

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

