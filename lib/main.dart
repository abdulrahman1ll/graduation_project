import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'providers/role_provider.dart';
import 'services/group_service.dart';
import 'services/place_service.dart';
import 'services/trip_service.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _seedChecklistTemplatesIfEmpty();
  final firebaseOptions = Firebase.app().options;
  debugPrint('PROJECT ID: ${firebaseOptions.projectId}');
  debugPrint('APP ID: ${firebaseOptions.appId}');
  try {
    final packageName = (firebaseOptions as dynamic).androidPackageName;
    debugPrint('PACKAGE: $packageName');
  } catch (_) {
    debugPrint('PACKAGE: unavailable');
  }
  runApp(const KashtaApp());
}

Future<void> _seedChecklistTemplatesIfEmpty() async {
  try {
    final templates = FirebaseFirestore.instance.collection(
      'checklist_templates',
    );
    final existing = await templates.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final defaults = <String, Map<String, String>>{
      'tent': {'name': 'Tent', 'category': 'Camping Gear', 'icon': 'tent'},
      'bbq': {
        'name': 'BBQ Set',
        'category': 'Food & Cooking',
        'icon': 'restaurant',
      },
      'chairs': {'name': 'Chairs', 'category': 'Comfort', 'icon': 'chair'},
      'water': {
        'name': 'Water',
        'category': 'Essentials',
        'icon': 'water_drop',
      },
      'flashlight': {
        'name': 'Flashlight',
        'category': 'Camping Gear',
        'icon': 'flashlight_on',
      },
    };
//fsfds
    final batch = FirebaseFirestore.instance.batch();
    defaults.forEach((docId, data) {
      batch.set(templates.doc(docId), data);
    });
    await batch.commit();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Checklist template seed skipped: $e');
    }
  }
}

IconData _iconFromName(String? iconName) {
  switch (iconName) {
    case 'tent':
      return Icons.terrain;
    case 'restaurant':
      return Icons.restaurant;
    case 'chair':
      return Icons.chair_alt;
    case 'water_drop':
      return Icons.water_drop;
    case 'flashlight_on':
      return Icons.flashlight_on;
    case 'checklist':
      return Icons.checklist;
    default:
      return Icons.checklist;
  }
}

Map<String, int> _categoryTemplateCounts(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> templates,
  Tr tr,
) {
  final counts = <String, int>{};
  for (final doc in templates) {
    final data = doc.data();
    final category = (data['category'] ?? tr.t('other')).toString();
    counts[category] = (counts[category] ?? 0) + 1;
  }
  return counts;
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortChecklistByCompletion(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final aDone = a.data()['done'] == true;
    final bDone = b.data()['done'] == true;
    if (aDone == bDone) {
      return 0;
    }
    return aDone ? 1 : -1;
  });
  return sorted;
}

double _checklistProgressValue({
  required int doneCount,
  required int totalCount,
}) {
  if (totalCount == 0) {
    return 0;
  }
  return doneCount / totalCount;
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

    return ChangeNotifierProvider<RoleProvider>(
      create: (_) => RoleProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
        onOpenAdminDashboard: _openAdminDashboard,
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

  void _openAdminDashboard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
  }
}

Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
  const apiKey = "00d90bb41bd1aa8875aaa0f729a42613";

  final url =
      "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

  print("WEATHER URL:");
  print(url);

  final response = await http.get(Uri.parse(url));

  print("STATUS:");
  print(response.statusCode);

  print("BODY:");
  print(response.body);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    return {
      "temp": data["main"]["temp"],        // temperature
      "weather": data["weather"][0]["main"], // Clouds / Rain / Clear
      "wind": data["wind"]["speed"]        // wind speed
    };
  }

  return null;
}
class ExplorePage extends StatefulWidget {
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
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _showOnlyFavorites = false;
  String? _selectedCategoryChip;
  void _showPlaceDetails(Map<String, dynamic> data, String placeId) {
    
    int selectedRating = 0;
    final commentController = TextEditingController();
    Uint8List? selectedImageBytes;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                Future<void> pickImage() async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );

                  if (image == null) return;

                  final bytes = await image.readAsBytes();

                  setModalState(() {
                    selectedImageBytes = bytes;
                  });
                }

                return SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ===== PLACE TITLE =====
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text("Environment: ${data['environmentType'] ?? '-'}"),

                      

                      const SizedBox(height: 8),

FutureBuilder<Map<String, dynamic>?>(
  future: getWeather(
    (data['lat'] as num).toDouble(),
    (data['lng'] as num).toDouble(),
  ),
  builder: (context, snapshot) {
    print("PLACE DATA:");
print(data);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text("Loading weather...");
    }

    if (!snapshot.hasData) {
      return const Text("Weather unavailable");
    }

    final temp = snapshot.data!["temp"];
final weather = snapshot.data!["weather"];
final wind = snapshot.data!["wind"];

String kashtaCondition = "Good";

if (weather == "Rain" || wind > 8) {
  kashtaCondition = "Bad";
}

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    Row(
      children: [
        const Icon(Icons.thermostat, color: Colors.orange),
        const SizedBox(width: 6),
        Text("${temp.toStringAsFixed(1)} °C"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.cloud, color: Colors.grey),
        const SizedBox(width: 6),
        Text("Weather: $weather"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.air, color: Colors.blue),
        const SizedBox(width: 6),
        Text("Wind: $wind m/s"),
      ],
    ),

    Row(
      children: [
        const Icon(Icons.emoji_nature, color: Colors.green),
        const SizedBox(width: 6),
        Text("Kashta conditions: $kashtaCondition"),
      ],
    ),

  ],
);
  },
),
                      const SizedBox(height: 20),

                      /// ===== RATING =====
                      const Text(
                        "Rate this place",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setModalState(() {
                                selectedRating = index + 1;
                              });
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 10),

                      /// ===== COMMENT =====
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Write your comment...",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// ===== IMAGE PICKER =====
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text("Add Image (Optional)"),
                      ),

                      if (selectedImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.memory(selectedImageBytes!, height: 120),
                        ),

                      const SizedBox(height: 15),

                      /// ===== SUBMIT REVIEW =====
                      ElevatedButton(
                        onPressed: () async {
                          if (selectedRating == 0) return;

                          await FirebaseFirestore.instance
                              .collection('places')
                              .doc(placeId)
                              .collection('reviews')
                              .add({
                                'userId':
                                    FirebaseAuth.instance.currentUser?.uid,
                                'rating': selectedRating,
                                'comment': commentController.text.trim(),
                                'imageBase64': selectedImageBytes == null
                                    ? null
                                    : base64Encode(selectedImageBytes!),
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          Navigator.pop(context);
                        },
                        child: const Text("Submit Review"),
                      ),

                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 10),

                      /// ===== REVIEWS + PHOTOS =====
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('places')
                            .doc(placeId)
                            .collection('reviews')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final reviews = snapshot.data!.docs;

                          double avgRating = 0;
                          if (reviews.isNotEmpty) {
                            final total = reviews.fold<double>(
                              0,
                              (sum, doc) =>
                                  sum +
                                  ((doc.data()
                                          as Map<String, dynamic>)['rating'] ??
                                      0),
                            );
                            avgRating = total / reviews.length;
                          }

                          if (reviews.isEmpty) {
                            return const Text("No reviews yet.");
                          }

                          /// ===== COLLECT IMAGES =====
                          final images = reviews
                              .map(
                                (doc) =>
                                    (doc.data()
                                        as Map<String, dynamic>)['imageBase64'],
                              )
                              .where((e) => e != null && e != '')
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Average rating: ${avgRating.toStringAsFixed(1)} ⭐",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// ===== PHOTOS SECTION =====
                              if (images.isNotEmpty) ...[
                                const Text(
                                  "Photos",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 6,
                                        mainAxisSpacing: 6,
                                      ),
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final img = images[index];

                                    return GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => Dialog(
                                            child: InteractiveViewer(
                                              child: Image.memory(
                                                base64Decode(img),
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(img),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),
                              ],

                              /// ===== REVIEWS =====
                              const Text(
                                "Reviews",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              ...reviews.map((doc) {
                                final review =
                                    doc.data() as Map<String, dynamic>;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(
                                            review['rating'] ?? 0,
                                            (index) => const Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(review['comment'] ?? ''),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  LatLng? selectedPoint;
  final PlaceService _placeService = PlaceService();
  Stream<Set<String>> _favoritePlaceIdsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(<String>{});
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  void _openAddPlaceForm(double lat, double lng) {
    final nameController = TextEditingController();
    String environmentType = 'desert';
    Uint8List? selectedImageBytes;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image == null) {
                return;
              }
              final bytes = await image.readAsBytes();
              setModalState(() {
                selectedImageBytes = bytes;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add New Place'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Place Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: environmentType,
                    items: const [
                      DropdownMenuItem(value: 'desert', child: Text('Desert')),
                      DropdownMenuItem(value: 'nature', child: Text('Nature')),
                      DropdownMenuItem(value: 'beach', child: Text('Beach')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        environmentType = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Environment Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: pickImage,
                    child: const Text('Pick Image (Optional)'),
                  ),
                  const SizedBox(height: 10),
                  if (selectedImageBytes != null)
                    Image.memory(selectedImageBytes!, height: 120),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        _showFirestoreError(
                          sheetContext,
                          FirebaseException(
                            plugin: 'cloud_firestore',
                            code: 'invalid-argument',
                            message: widget.tr.t('fill_all_fields'),
                          ),
                        );
                        return;
                      }

                      try {
                        await _placeService.addPlace(
                          name: nameController.text.trim(),
                          environmentType: environmentType,
                          latitude: lat,
                          longitude: lng,
                          imageBase64: selectedImageBytes == null
                              ? null
                              : base64Encode(selectedImageBytes!),
                        );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      } on FirebaseException catch (e) {
                        if (sheetContext.mounted) {
                          _showFirestoreError(sheetContext, e);
                        }
                      } catch (_) {
                        if (sheetContext.mounted) {
                          _showFirestoreError(
                            sheetContext,
                            FirebaseException(
                              plugin: 'cloud_firestore',
                              code: 'unknown',
                              message: widget.tr.t('save_failed'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Submit'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        appBarWithLanguage(
          tr: widget.tr,
          isArabic: widget.isArabic,
          title: widget.tr.t('explore'),
          onToggleLanguage: widget.onToggleLanguage,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  selected: _showOnlyFavorites,
                  onSelected: (_) {
                    setState(() {
                      _showOnlyFavorites = !_showOnlyFavorites;
                    });
                  },
                  avatar: Icon(
                    _showOnlyFavorites ? Icons.star : Icons.star_border,
                    size: 18,
                    color: _showOnlyFavorites ? Colors.orange : Colors.black54,
                  ),
                  label: Text(widget.tr.t('favorites')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _showOnlyFavorites
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: TextStyle(
                    color: _showOnlyFavorites ? Colors.orange : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'desert',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'desert'
                          ? null
                          : 'desert';
                    });
                  },
                  label: Text(widget.tr.t('desert')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'desert'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'desert'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'beach',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'beach'
                          ? null
                          : 'beach';
                    });
                  },
                  label: Text(widget.tr.t('beach')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'beach'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'beach'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _selectedCategoryChip == 'family',
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryChip = _selectedCategoryChip == 'family'
                          ? null
                          : 'family';
                    });
                  },
                  label: Text(widget.tr.t('family')),
                  selectedColor: Colors.orange.withValues(alpha: 0.16),
                  checkmarkColor: Colors.orange,
                  side: BorderSide(
                    color: _selectedCategoryChip == 'family'
                        ? Colors.orange
                        : Colors.orange.shade200,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _selectedCategoryChip == 'family'
                        ? Colors.orange
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<Set<String>>(
            stream: _favoritePlaceIdsStream(),
            builder: (context, favoritesSnapshot) {
              if (favoritesSnapshot.hasError) {
                _logFirestoreReadError(
                  'users/*/favorites',
                  favoritesSnapshot.error,
                );
              }
              final favoriteIds = favoritesSnapshot.data ?? <String>{};

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('places')
                    .where('status', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    _logFirestoreReadError('places', snapshot.error);
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final visibleDocs = _showOnlyFavorites
                      ? docs
                            .where((doc) => favoriteIds.contains(doc.id))
                            .toList()
                      : docs;
                  final approvedMarkers = visibleDocs
                      .map((doc) {
                        final data = doc.data();
                        final lat = (data['lat'] as num?)?.toDouble();
                        final lng = (data['lng'] as num?)?.toDouble();
                        if (lat == null || lng == null) {
                          return null;
                        }
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () {
                              _showPlaceDetails(data, doc.id);
                            },
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        );
                      })
                      .whereType<Marker>()
                      .toList();

                  final allMarkers = <Marker>[
                    ...approvedMarkers,
                    if (selectedPoint != null)
                      Marker(
                        point: selectedPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                  ];

                  return FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(21.4858, 39.1925),
                      initialZoom: 11,
                      onTap: (tapPosition, point) {
                        setState(() {
                          selectedPoint = point;
                        });
                        _openAddPlaceForm(point.latitude, point.longitude);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.kashta',
                      ),
                      if (allMarkers.isNotEmpty)
                        MarkerLayer(markers: allMarkers),
                    ],
                  );
                },
              );
            },
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
            .where('visibility', isEqualTo: 'public')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            _logFirestoreReadError('trips', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Center(child: Text(tr.t('permission_denied')));
            }
            if (error is FirebaseException) {
              final link = _extractIndexLink(error.message);
              if (link != null) {
                return const Center(
                  child: Text('Trips query requires a Firestore index.'),
                );
              }
            }
            return Center(child: Text(tr.t('load_error')));
          }
          final docs = snapshot.data?.docs ?? [];
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          int upcomingCount = 0;
          int pastCount = 0;
          for (final doc in docs) {
            final data = doc.data();
            final tripDateValue = data['tripDate'];
            if (tripDateValue is! Timestamp) {
              continue;
            }
            final tripDate = tripDateValue.toDate();
            if (tripDate.isBefore(todayStart)) {
              pastCount++;
            } else {
              upcomingCount++;
            }
          }

          if (docs.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TripStatCard(
                          title: tr.t('upcoming'),
                          value: upcomingCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TripStatCard(
                          title: tr.t('past'),
                          value: pastCount,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Center(child: Text(tr.t('no_trips')))),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TripStatCard(
                        title: tr.t('upcoming'),
                        value: upcomingCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TripStatCard(
                        title: tr.t('past'),
                        value: pastCount,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = docs[index].data();
                    return Card(
                      child: ListTile(
                        title: Text((data['title'] ?? '').toString()),
                        subtitle: Text((data['description'] ?? '').toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tr.t('members')} ${(data['peopleCount'] ?? 0)}',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: tr.t('trip_checklist'),
                              icon: const Icon(
                                Icons.checklist,
                                color: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TripChecklistPage(
                                      tr: tr,
                                      tripId: doc.id,
                                      tripTitle: (data['title'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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

class _TripStatCard extends StatelessWidget {
  const _TripStatCard({required this.title, required this.value});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddChecklistItemsPage extends StatelessWidget {
  const AddChecklistItemsPage({
    super.key,
    required this.tr,
    required this.tripId,
  });

  final Tr tr;
  final String tripId;

  Future<void> _addTemplateToTripChecklist(
    BuildContext context,
    String templateId,
    Map<String, dynamic> data,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('checklist')
          .doc(templateId)
          .set({
            'name': (data['name'] ?? '').toString(),
            'category': (data['category'] ?? '').toString(),
            'icon': (data['icon'] ?? 'checklist').toString(),
            'done': false,
            'addedBy': userId ?? 'unknown',
            'assignedTo': null,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('checklist_item_added'))));
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        _showFirestoreError(context, e);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('save_failed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr.t('add_checklist_items'))),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('checklist_templates')
            .snapshots(),
        builder: (context, templatesSnapshot) {
          if (templatesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (templatesSnapshot.hasError) {
            _logFirestoreReadError(
              'checklist_templates',
              templatesSnapshot.error,
            );
            return Center(child: Text(tr.t('load_error')));
          }

          final docs = templatesSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Text(tr.t('no_checklist_templates')));
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .doc(tripId)
                .collection('checklist')
                .snapshots(),
            builder: (context, checklistSnapshot) {
              if (checklistSnapshot.hasError) {
                _logFirestoreReadError(
                  'trips/*/checklist',
                  checklistSnapshot.error,
                );
              }
              final existingIds =
                  checklistSnapshot.data?.docs.map((doc) => doc.id).toSet() ??
                  <String>{};

              final grouped =
                  <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
              for (final doc in docs) {
                final data = doc.data();
                final category = (data['category'] ?? tr.t('other')).toString();
                grouped.putIfAbsent(
                  category,
                  () => <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                );
                grouped[category]!.add(doc);
              }
              final categoryCounts = _categoryTemplateCounts(docs, tr);
              final categories = grouped.keys.toList()..sort();
              for (final category in categories) {
                grouped[category]!.sort((a, b) {
                  final aName = (a.data()['name'] ?? '').toString();
                  final bName = (b.data()['name'] ?? '').toString();
                  return aName.compareTo(bName);
                });
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final items = grouped[category]!;
                  final count = categoryCounts[category] ?? 0;
                  return Card(
                    elevation: 1.2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        '$category ($count)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: items.map((itemDoc) {
                        final data = itemDoc.data();
                        final iconName = (data['icon'] ?? 'checklist')
                            .toString();
                        final name = (data['name'] ?? '').toString();
                        final alreadyAdded = existingIds.contains(itemDoc.id);
                        return ListTile(
                          leading: Icon(
                            _iconFromName(iconName),
                            color: Colors.orange,
                          ),
                          title: Text(name),
                          trailing: alreadyAdded
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr.t('added'),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _addTemplateToTripChecklist(
                                    context,
                                    itemDoc.id,
                                    data,
                                  ),
                                ),
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TripChecklistPage extends StatelessWidget {
  const TripChecklistPage({
    super.key,
    required this.tr,
    required this.tripId,
    required this.tripTitle,
  });

  final Tr tr;
  final String tripId;
  final String tripTitle;

  Future<void> _toggleDone(
    BuildContext context,
    String itemId,
    bool newValue,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .collection('checklist')
          .doc(itemId)
          .update({'done': newValue});
    } on FirebaseException catch (e) {
      if (context.mounted) {
        _showFirestoreError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr.t('trip_checklist')} - $tripTitle'),
        actions: [
          IconButton(
            tooltip: tr.t('add'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddChecklistItemsPage(tr: tr, tripId: tripId),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('trips')
            .doc(tripId)
            .collection('checklist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _logFirestoreReadError('trips/*/checklist', snapshot.error);
            return Center(child: Text(tr.t('load_error')));
          }

          final docs = snapshot.data?.docs ?? [];
          final sortedDocs = _sortChecklistByCompletion(docs);
          final totalItems = sortedDocs.length;
          final doneCount = sortedDocs
              .where((doc) => doc.data()['done'] == true)
              .length;
          final progress = _checklistProgressValue(
            doneCount: doneCount,
            totalCount: totalItems,
          );
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.t('checklist_progress'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('0 / 0 ${tr.t('items_completed')}'),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(
                    value: 0,
                    color: Colors.orange,
                    backgroundColor: Color(0xFFF5F5F5),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(child: Text(tr.t('no_checklist_items'))),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  tr.t('checklist_progress'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$doneCount / $totalItems ${tr.t('items_completed')}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: Colors.orange,
                    backgroundColor: const Color(0xFFF1F1F1),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = sortedDocs[index];
                    final data = doc.data();
                    final done = data['done'] == true;
                    final iconName = (data['icon'] ?? 'checklist').toString();
                    final itemName = (data['name'] ?? '').toString();

                    return Card(
                      elevation: 1.2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: CheckboxListTile(
                        value: done,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          _toggleDone(context, doc.id, value);
                        },
                        activeColor: Colors.orange,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Icon(_iconFromName(iconName), color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                itemName,
                                style: TextStyle(
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr.t('add_from_template')),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddChecklistItemsPage(tr: tr, tripId: tripId),
            ),
          );
        },
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
  final TripService _tripService = TripService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _peopleController = TextEditingController();
  final _locationUrlController = TextEditingController();
  String _visibility = 'public';
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
            DropdownButtonFormField<String>(
              initialValue: _visibility,
              items: const [
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'private', child: Text('Private')),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _visibility = value);
                      }
                    },
              decoration: const InputDecoration(labelText: 'Visibility'),
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
      await _tripService.createTrip(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        peopleCount: count,
        locationUrl: _locationUrlController.text.trim(),
        tripDate: _tripDate!,
        visibility: _visibility,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.t('save_failed'))));
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

class GroupsPage extends StatefulWidget {
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
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final GroupService _groupService = GroupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('groups'),
        onToggleLanguage: widget.onToggleLanguage,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            _logFirestoreReadError('groups', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return Center(child: Text(widget.tr.t('permission_denied')));
            }
            if (error is FirebaseException) {
              final link = _extractIndexLink(error.message);
              if (link != null) {
                return const Center(
                  child: Text('Groups query requires a Firestore index.'),
                );
              }
            }
            return Center(child: Text(widget.tr.t('load_error')));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups, size: 72, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      widget.tr.t('no_groups_yet'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.tr.t('groups_empty_subtitle'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  title: Text((data['name'] ?? '').toString()),
                  subtitle: Text((data['description'] ?? '').toString()),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<RoleProvider>(
        builder: (context, provider, child) {
          final canCreate =
              provider.roles['groupOrganizer'] == true ||
              provider.roles['admin'] == true;
          if (!canCreate) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddGroupPage(tr: widget.tr, groupService: _groupService),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key, required this.tr, required this.groupService});

  final Tr tr;
  final GroupService groupService;

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _saving = false;
  String _visibility = 'public';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Group')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Group Name'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _visibility,
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'private', child: Text('Private')),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _visibility = value);
                    }
                  },
            decoration: const InputDecoration(labelText: 'Visibility'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save Group'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.tr.t('fill_all_fields'))));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        visibility: _visibility,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.tr.t('save_failed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

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
      body: ListView(
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
    );
  }
}

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
              _logFirestoreReadError('places', pendingSnapshot.error);
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

class PendingPlacesPage extends StatefulWidget {
  const PendingPlacesPage({super.key});

  @override
  State<PendingPlacesPage> createState() => _PendingPlacesPageState();
}

class _PendingPlacesPageState extends State<PendingPlacesPage> {
  final PlaceService _placeService = PlaceService();
  final Set<String> _busyIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoleProvider>();
    if (!provider.isAdmin) {
      return const Scaffold(body: Center(child: Text('Access denied')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Places')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
            _logFirestoreReadError('places', error);
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return const Center(child: Text('Permission denied'));
            }
            return const Center(child: Text('Failed to load pending places'));
          }

          final docs = pendingSnapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pending places'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final placeId = doc.id;
              final imageBase64 = data['imageBase64'] as String?;
              final isBusy = _busyIds.contains(placeId);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${(data['environmentType'] ?? '-').toString()}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created by: ${(data['createdBy'] ?? '-').toString()}',
                      ),
                      if (imageBase64 != null && imageBase64.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(imageBase64),
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleApproveReject(
                                      placeId: placeId,
                                      approve: true,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isBusy
                                  ? null
                                  : () => _handleApproveReject(
                                      placeId: placeId,
                                      approve: false,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleApproveReject({
    required String placeId,
    required bool approve,
  }) async {
    setState(() {
      _busyIds.add(placeId);
    });

    try {
      if (approve) {
        await _placeService.approvePlace(placeId);
      } else {
        await _placeService.rejectPlace(placeId);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _showFirestoreError(context, e);
      }
    } catch (_) {
      if (mounted) {
        _showFirestoreError(
          context,
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unknown',
            message: 'Operation failed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyIds.remove(placeId);
        });
      }
    }
  }
}

void _showFirestoreError(BuildContext context, FirebaseException e) {
  String message;
  if (e.code == 'permission-denied') {
    message = 'You do not have permission to perform this action.';
  } else if (e.code == 'unauthenticated') {
    message = 'Please sign in again.';
  } else if (e.code == 'invalid-argument') {
    message = e.message ?? 'Some fields are invalid.';
  } else {
    message = 'Something went wrong. Please try again.';
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _logFirestoreReadError(String collection, Object? error) {
  if (!kDebugMode) {
    return;
  }
  if (error is FirebaseException) {
    debugPrint(
      'Firestore read error [$collection] code=${error.code} message=${error.message}',
    );
    final link = _extractIndexLink(error.message);
    if (link != null) {
      debugPrint('Firestore index link [$collection]: $link');
    }
    return;
  }
  debugPrint('Firestore read error [$collection]: $error');
}

String? _extractIndexLink(String? message) {
  if (message == null) {
    return null;
  }
  final match = RegExp(r'https://\S+').firstMatch(message);
  if (match == null) {
    return null;
  }
  return match.group(0);
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
    'trip_checklist': 'Trip Checklist',
    'add_checklist_items': 'Add Checklist Items',
    'add_items': 'Add Items',
    'add_from_template': 'Add From Template',
    'added': 'Added',
    'checklist_progress': 'Checklist Progress',
    'items_completed': 'items completed',
    'checklist_item_added': 'Checklist item added',
    'no_checklist_items': 'No checklist items yet',
    'no_checklist_templates': 'No checklist templates found',
    'other': 'Other',
    'add': 'Add',
    'members': 'Members',
    'upcoming': 'Upcoming',
    'past': 'Past',
    'add_trip': 'Add Trip',
    'trip_name': 'Trip Name',
    'description': 'Description',
    'people_count': 'People Count',
    'location_url': 'Location URL',
    'choose_trip_date': 'Choose trip date',
    'save_trip': 'Save Trip',
    'fill_all_fields': 'Fill all fields correctly',
    'save_failed': 'Failed to save trip',
    'permission_denied': 'Permission denied',
    'groups_page': 'Groups page',
    'no_groups_yet': 'No groups yet',
    'groups_empty_subtitle':
        'Create a group to start planning your next Kashta',
    'guest_account': 'Guest account',
    'signed_in_account': 'Signed in account',
    'sign_out': 'Sign Out',
    'favorites': 'Favorites',
    'desert': 'Desert',
    'beach': 'Beach',
    'family': 'Family',
    'edit_profile': 'Edit Profile',
    'my_trips': 'My Trips',
    'admin_dashboard': 'Admin Dashboard',
    'coming_soon': 'Coming soon',
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
    'trip_checklist':
        '\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632 \u0644\u0644\u0631\u062d\u0644\u0629',
    'add_checklist_items':
        '\u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0627\u0635\u0631 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'add_items':
        '\u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0627\u0635\u0631',
    'add_from_template':
        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0646 \u0627\u0644\u0642\u0627\u0644\u0628',
    'added': '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u062a\u0647',
    'checklist_progress':
        '\u062a\u0642\u062f\u0645 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'items_completed':
        '\u0639\u0646\u0635\u0631 \u0645\u0643\u062a\u0645\u0644',
    'checklist_item_added':
        '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0635\u0631 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'no_checklist_items':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0646\u0627\u0635\u0631 \u0641\u064a \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0628\u0639\u062f',
    'no_checklist_templates':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0642\u0648\u0627\u0644\u0628 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632',
    'other': '\u0623\u062e\u0631\u0649',
    'add': '\u0625\u0636\u0627\u0641\u0629',
    'members': '\u0623\u0639\u0636\u0627\u0621',
    'upcoming': '\u0627\u0644\u0642\u0627\u062f\u0645\u0629',
    'past': '\u0627\u0644\u0633\u0627\u0628\u0642\u0629',
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
    'permission_denied':
        '\u0644\u0627 \u062a\u0645\u0644\u0643 \u0635\u0644\u0627\u062d\u064a\u0629 \u0644\u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621',
    'groups_page':
        '\u0635\u0641\u062d\u0629 \u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0627\u062a',
    'no_groups_yet':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062c\u0645\u0648\u0639\u0627\u062a \u0628\u0639\u062f',
    'groups_empty_subtitle':
        '\u0623\u0646\u0634\u0626 \u0645\u062c\u0645\u0648\u0639\u0629 \u0644\u0628\u062f\u0621 \u0627\u0644\u062a\u062e\u0637\u064a\u0637 \u0644\u0643\u0634\u062a\u062a\u0643 \u0627\u0644\u0642\u0627\u062f\u0645\u0629',
    'guest_account': '\u062d\u0633\u0627\u0628 \u0636\u064a\u0641',
    'signed_in_account': '\u062d\u0633\u0627\u0628 \u0645\u0633\u062c\u0644',
    'sign_out': '\u062a\u0633\u062c\u064a\u0644 \u062e\u0631\u0648\u062c',
    'favorites': '\u0627\u0644\u0645\u0641\u0636\u0644\u0629',
    'desert': '\u0635\u062d\u0631\u0627\u0621',
    'beach': '\u0634\u0627\u0637\u0626',
    'family': '\u0639\u0627\u0626\u0644\u064a',
    'edit_profile':
        '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0644\u0641',
    'my_trips': '\u0631\u062d\u0644\u0627\u062a\u064a',
    'admin_dashboard':
        '\u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u0634\u0631\u0641',
    'coming_soon': '\u0642\u0631\u064a\u0628\u0627\u064b',
  };

  String t(String key) {
    final map = language == AppLanguage.en ? _en : _ar;
    return map[key] ?? key;
  }
}
