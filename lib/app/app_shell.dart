import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/groups/groups.dart' as chat;
import '../features/auth/ui/auth_page.dart';
import '../features/auth/ui/welcome_preferences_page.dart';
import '../core/theme/kashta_colors.dart';
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
    _deepLinkService.trProvider = () => Tr(_lang);
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
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: KashtaColors.backgroundCream,
          colorScheme: ColorScheme.fromSeed(
            seedColor: KashtaColors.primary,
            primary: KashtaColors.primary,
            secondary: KashtaColors.softOrange,
            tertiary: KashtaColors.softOlive,
            surface: KashtaColors.cardSurface,
            onPrimary: Colors.white,
            onSecondary: KashtaColors.textDark,
            onSurface: KashtaColors.textDark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: KashtaColors.backgroundCream,
            foregroundColor: KashtaColors.textDark,
            surfaceTintColor: Colors.transparent,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: KashtaColors.cardSurface,
            selectedItemColor: KashtaColors.primary,
            unselectedItemColor: KashtaColors.textDark,
          ),
          cardTheme: CardThemeData(
            color: KashtaColors.cardSurface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: KashtaColors.sandBorder),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: KashtaColors.sandBorder,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: KashtaColors.cardSurface,
            prefixIconColor: KashtaColors.primary,
            labelStyle: const TextStyle(color: KashtaColors.textDark),
            hintStyle: TextStyle(
              color: KashtaColors.textDark.withValues(alpha: 0.66),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: KashtaColors.sandBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: KashtaColors.primary,
                width: 1.4,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: KashtaColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: KashtaColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: KashtaColors.primary,
              side: const BorderSide(color: KashtaColors.sandBorder),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: KashtaColors.primary,
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: KashtaColors.cardSurface,
            selectedColor: KashtaColors.primary,
            side: const BorderSide(color: KashtaColors.sandBorder),
            labelStyle: const TextStyle(color: KashtaColors.textDark),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
          ),
          textTheme: ThemeData.light().textTheme.apply(
                bodyColor: KashtaColors.textDark,
                displayColor: KashtaColors.textDark,
              ),
        ),
        routes: {
          '/welcome_preferences': (context) => WelcomePreferencesPage(tr: tr),
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
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnap.data?.data();
            final completed = data?['preferencesCompleted'] == true;

            if (!completed) {
              return WelcomePreferencesPage(tr: tr);
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
