import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const KashtaApp());
}

enum AppLanguage { en, ar }

class KashtaApp extends StatefulWidget {
  const KashtaApp({super.key});

  @override
  State<KashtaApp> createState() => _KashtaAppState();
}

class _KashtaAppState extends State<KashtaApp> {
  AppLanguage _lang = AppLanguage.en;

  void _toggleLanguage() {
    setState(() {
      _lang = _lang == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr(_lang);
    final isArabic = _lang == AppLanguage.ar;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AuthGate(
          tr: tr,
          isArabic: isArabic,
          onToggleLanguage: _toggleLanguage,
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

        return MainScreen(
          tr: tr,
          isArabic: isArabic,
          onToggleLanguage: onToggleLanguage,
        );
      },
    );
  }
}

PreferredSizeWidget appBarWithLanguage({
  required Tr tr,
  required bool isArabic,
  required String title,
  required VoidCallback onToggleLanguage,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      TextButton(
        onPressed: onToggleLanguage,
        child: Text(
          isArabic ? 'EN' : 'AR',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/444.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF7D7AF), Color(0xFFE1C39B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.32)),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: widget.isArabic
                      ? Alignment.topLeft
                      : Alignment.topRight,
                  child: TextButton(
                    onPressed: widget.onToggleLanguage,
                    child: Text(widget.isArabic ? 'EN' : 'AR'),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.t('welcome_title'),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr.t('welcome_subtitle'),
                        textAlign: TextAlign.start,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textAlign: widget.isArabic
                            ? TextAlign.right
                            : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: tr.t('email'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textAlign: widget.isArabic
                            ? TextAlign.right
                            : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: tr.t('password'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(tr.t('sign_in')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _loading ? null : _signUpWithEmail,
                              child: Text(tr.t('sign_up')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: Text(tr.t('continue_google')),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _signInWithPhone,
                        icon: const Icon(Icons.phone),
                        label: Text(tr.t('sign_in_phone')),
                      ),
                      TextButton(
                        onPressed: _loading ? null : _signInAnonymously,
                        child: Text(tr.t('continue_guest')),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack(widget.tr.t('email_password_required'));
      return;
    }

    await _authRun(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );
    });
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _snack(widget.tr.t('email_password_required'));
      return;
    }

    await _authRun(() async {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
    });
  }

  Future<void> _signInWithGoogle() async {
    await _authRun(() async {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        return;
      }

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    });
  }

  Future<void> _signInWithPhone() async {
    final phone = await _askInput(
      title: widget.tr.t('phone_number'),
      controller: _phoneController,
      hint: widget.tr.t('phone_hint'),
      keyboardType: TextInputType.phone,
    );
    if (phone == null || phone.trim().isEmpty) {
      return;
    }

    await _authRun(() async {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone.trim(),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (e) {
          _snack('${widget.tr.t('phone_failed')}: ${e.message ?? e.code}');
        },
        codeSent: (verificationId, _) async {
          final codeController = TextEditingController();
          final sms = await _askInput(
            title: widget.tr.t('sms_code'),
            controller: codeController,
            hint: widget.tr.t('sms_hint'),
            keyboardType: TextInputType.number,
          );
          codeController.dispose();
          if (sms == null || sms.trim().isEmpty) {
            return;
          }
          final credential = PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: sms.trim(),
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    });
  }

  Future<void> _signInAnonymously() async {
    await _authRun(() async {
      await FirebaseAuth.instance.signInAnonymously();
    });
  }

  Future<String?> _askInput({
    required String title,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.tr.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(widget.tr.t('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _authRun(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExplorePage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      TripsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      GroupsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      ProfilePage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: widget.tr.t('explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.hiking),
            label: widget.tr.t('trips'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: widget.tr.t('groups'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.tr.t('profile'),
          ),
        ],
      ),
    );
  }
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({
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
    return Column(
      children: [
        appBarWithLanguage(
          tr: tr,
          isArabic: isArabic,
          title: tr.t('explore'),
          onToggleLanguage: onToggleLanguage,
        ),
        Expanded(
          flex: 2,
          child: FlutterMap(
            options: MapOptions(
  initialCenter: const LatLng(21.4858, 39.1925),
  initialZoom: 11,
  onTap: (tapPosition, point) {
    print("Lat: ${point.latitude}");
    print("Lng: ${point.longitude}");
  },
),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kashta',
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Text(tr.t('explore_hint')),
          ),
        ),
      ],
    );
  }
}

class TripsPage extends StatelessWidget {
  const TripsPage({
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
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('trips'),
        onToggleLanguage: onToggleLanguage,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('${tr.t('load_error')}\n${snapshot.error}'),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(tr.t('no_trips')));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  title: Text((data['title'] ?? '').toString()),
                  subtitle: Text((data['description'] ?? '').toString()),
                  trailing: Text(
                    '${tr.t('members')} ${(data['peopleCount'] ?? 0)}',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTripPage(tr: tr, isArabic: isArabic),
            ),
          );
        },
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr.t('new_trip')),
      ),
    );
  }
}

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key, required this.tr, required this.isArabic});

  final Tr tr;
  final bool isArabic;

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController();
  final _locationUrlController = TextEditingController();
  DateTime? _tripDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _peopleController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.tr;
    return Scaffold(
      appBar: AppBar(title: Text(tr.t('add_trip'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: tr.t('trip_name')),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: tr.t('description')),
            ),
            TextFormField(
              controller: _peopleController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr.t('people_count')),
            ),
            TextFormField(
              controller: _locationUrlController,
              decoration: InputDecoration(labelText: tr.t('location_url')),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _pickDate,
              child: Text(
                _tripDate == null
                    ? tr.t('choose_trip_date')
                    : _formatDate(_tripDate!),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(tr.t('save_trip')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _tripDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() => _tripDate = selected);
    }
  }

  Future<void> _save() async {
    final tr = widget.tr;
    final count = int.tryParse(_peopleController.text.trim());
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        count == null ||
        count <= 0 ||
        _locationUrlController.text.trim().isEmpty ||
        _tripDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.t('fill_all_fields'))));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('trips').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'peopleCount': count,
        'locationUrl': _locationUrlController.text.trim(),
        'tripDate': Timestamp.fromDate(_tripDate!),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${tr.t('save_failed')}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDate(DateTime value) {
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '${value.year}/$m/$d';
  }
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({
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
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('groups'),
        onToggleLanguage: onToggleLanguage,
      ),
      body: Center(child: Text(tr.t('groups_page'))),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
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
    final isAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('profile'),
        onToggleLanguage: onToggleLanguage,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAnonymous ? tr.t('guest_account') : tr.t('signed_in_account'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: Text(tr.t('sign_out')),
            ),
          ],
        ),
      ),
    );
  }
}

class Tr {
  Tr(this.language);

  final AppLanguage language;

  static const _en = {
    'welcome_title': 'Welcome to Kashta',
    'welcome_subtitle': 'Discover places, plan trips, and share adventures.',
    'email': 'Email',
    'password': 'Password',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'continue_google': 'Continue with Google',
    'sign_in_phone': 'Sign in with phone number',
    'continue_guest': 'Continue as Guest',
    'email_password_required': 'Email and password are required',
    'phone_number': 'Phone Number',
    'phone_hint': '+9665XXXXXXXX',
    'phone_failed': 'Phone sign-in failed',
    'sms_code': 'SMS Code',
    'sms_hint': 'Enter OTP',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'explore': 'Explore',
    'trips': 'Trips',
    'groups': 'Groups',
    'profile': 'Profile',
    'explore_hint': 'Place details will appear here.',
    'load_error': 'Failed to load trips',
    'no_trips': 'No trips yet. Add a new trip.',
    'new_trip': 'New Trip',
    'members': 'Members',
    'add_trip': 'Add Trip',
    'trip_name': 'Trip Name',
    'description': 'Description',
    'people_count': 'People Count',
    'location_url': 'Location URL',
    'choose_trip_date': 'Choose trip date',
    'save_trip': 'Save Trip',
    'fill_all_fields': 'Fill all fields correctly',
    'save_failed': 'Failed to save trip',
    'groups_page': 'Groups page',
    'guest_account': 'Guest account',
    'signed_in_account': 'Signed in account',
    'sign_out': 'Sign Out',
  };

  static const _ar = {
    'welcome_title':
        '\u0623\u0647\u0644\u064b\u0627 \u0628\u0643 \u0641\u064a \u0643\u0634\u0646\u0629',
    'welcome_subtitle':
        '\u0627\u0643\u062a\u0634\u0641 \u0627\u0644\u0623\u0645\u0627\u0643\u0646\u060c \u062e\u0637\u0637 \u0631\u062d\u0644\u0627\u062a\u0643\u060c \u0648\u0634\u0627\u0631\u0643 \u0627\u0644\u0645\u063a\u0627\u0645\u0631\u0627\u062a.',
    'email':
        '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
    'password': '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
    'sign_in': '\u062a\u0633\u062c\u064a\u0644 \u062f\u062e\u0648\u0644',
    'sign_up': '\u0625\u0646\u0634\u0627\u0621 \u062d\u0633\u0627\u0628',
    'continue_google':
        '\u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629 \u0639\u0628\u0631 Google',
    'sign_in_phone':
        '\u0627\u0644\u062f\u062e\u0648\u0644 \u0628\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'continue_guest':
        '\u0627\u0644\u062f\u062e\u0648\u0644 \u0643\u0636\u064a\u0641',
    'email_password_required':
        '\u0627\u0644\u0628\u0631\u064a\u062f \u0648\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0645\u0637\u0644\u0648\u0628\u0627\u0646',
    'phone_number': '\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'phone_hint': '+9665XXXXXXXX',
    'phone_failed':
        '\u0641\u0634\u0644 \u062a\u0633\u062c\u064a\u0644 \u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'sms_code': '\u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642',
    'sms_hint': '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0645\u0632',
    'cancel': '\u0625\u0644\u063a\u0627\u0621',
    'confirm': '\u062a\u0623\u0643\u064a\u062f',
    'explore': '\u0627\u0633\u062a\u0643\u0634\u0627\u0641',
    'trips': '\u0631\u062d\u0644\u0627\u062a',
    'groups': '\u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0627\u062a',
    'profile': '\u0645\u0644\u0641\u064a',
    'explore_hint':
        '\u0647\u0646\u0627 \u062a\u0638\u0647\u0631 \u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u0623\u0645\u0627\u0643\u0646.',
    'load_error':
        '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0631\u062d\u0644\u0627\u062a',
    'no_trips':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u062d\u0644\u0627\u062a \u062d\u0627\u0644\u064a\u0627\u064b\u060c \u0623\u0636\u0641 \u0631\u062d\u0644\u0629 \u062c\u062f\u064a\u062f\u0629.',
    'new_trip': '\u0631\u062d\u0644\u0629 \u062c\u062f\u064a\u062f\u0629',
    'members': '\u0623\u0639\u0636\u0627\u0621',
    'add_trip': '\u0625\u0636\u0627\u0641\u0629 \u0631\u062d\u0644\u0629',
    'trip_name': '\u0627\u0633\u0645 \u0627\u0644\u0631\u062d\u0644\u0629',
    'description': '\u0648\u0635\u0641',
    'people_count':
        '\u0639\u062f\u062f \u0627\u0644\u0623\u0634\u062e\u0627\u0635',
    'location_url':
        '\u0631\u0627\u0628\u0637 \u0627\u0644\u0645\u0648\u0642\u0639',
    'choose_trip_date':
        '\u0627\u062e\u062a\u0631 \u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0631\u062d\u0644\u0629',
    'save_trip': '\u062d\u0641\u0638 \u0627\u0644\u0631\u062d\u0644\u0629',
    'fill_all_fields':
        '\u0627\u0645\u0644\u0623 \u062c\u0645\u064a\u0639 \u0627\u0644\u062d\u0642\u0648\u0644 \u0628\u0634\u0643\u0644 \u0635\u062d\u064a\u062d',
    'save_failed':
        '\u0641\u0634\u0644 \u062d\u0641\u0638 \u0627\u0644\u0631\u062d\u0644\u0629',
    'groups_page':
        '\u0635\u0641\u062d\u0629 \u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0627\u062a',
    'guest_account': '\u062d\u0633\u0627\u0628 \u0636\u064a\u0641',
    'signed_in_account': '\u062d\u0633\u0627\u0628 \u0645\u0633\u062c\u0644',
    'sign_out': '\u062a\u0633\u062c\u064a\u0644 \u062e\u0631\u0648\u062c',
  };

  String t(String key) {
    final map = language == AppLanguage.en ? _en : _ar;
    return map[key] ?? key;
  }
}
