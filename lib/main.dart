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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
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
  VoidCallback? onAdminTap,
}) {
  return AppBar(
    title: Text(title),
    actions: [
      Consumer<RoleProvider>(
        builder: (context, provider, child) {
          if (kDebugMode) {
            print("Current roles: ${provider.roles}");
          }
          if (provider.roles['admin'] == true && onAdminTap != null) {
            return IconButton(
              onPressed: onAdminTap,
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Admin Dashboard',
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
        onOpenAdminDashboard: _openAdminDashboard,
      ),
      TripsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
        onOpenAdminDashboard: _openAdminDashboard,
      ),
      GroupsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
        onOpenAdminDashboard: _openAdminDashboard,
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({
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
  State<ExplorePage> createState() =>
      _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {

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
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> pickImage() async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
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

                    // ===== TITLE =====
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text("Environment: ${data['environmentType'] ?? '-'}"),

                    const SizedBox(height: 20),

                    // ===== RATING STARS =====
                    const Text("Rate this place:",
                        style: TextStyle(fontWeight: FontWeight.bold)),

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

                    // ===== COMMENT FIELD =====
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Write your comment...",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: pickImage,
                      child: const Text("Add Image (Optional)"),
                    ),

                    if (selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.memory(
                          selectedImageBytes!,
                          height: 120,
                        ),
                      ),

                    const SizedBox(height: 15),

                    // ===== SUBMIT REVIEW =====
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

                    // ===== REVIEWS LIST =====
                    const Text("Reviews:",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),

                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('places')
                          .doc(placeId)
                          .collection('reviews')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final reviews = snapshot.data!.docs;

                        if (reviews.isEmpty) {
                          return const Text("No reviews yet.");
                        }

                        return Column(
                          children: reviews.map((doc) {
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
                                    if (review['imageBase64'] != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Image.memory(
                                          base64Decode(
                                              review['imageBase64']),
                                          height: 100,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
          onAdminTap: widget.onOpenAdminDashboard,
        ),
        Expanded(
          flex: 2,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('places')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                _logFirestoreReadError('places', snapshot.error);
              }
              final docs = snapshot.data?.docs ?? [];
              final approvedMarkers = docs.map((doc) {
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
              }).whereType<Marker>().toList();

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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.kashta',
                  ),
                  if (allMarkers.isNotEmpty) MarkerLayer(markers: allMarkers),
                ],
              );
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Text(widget.tr.t('explore_hint')),
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
    required this.onOpenAdminDashboard,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenAdminDashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: tr,
        isArabic: isArabic,
        title: tr.t('trips'),
        onToggleLanguage: onToggleLanguage,
        onAdminTap: onOpenAdminDashboard,
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
            if (error is FirebaseException && error.code == 'permission-denied') {
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
            return Center(
              child: Text(tr.t('load_error')),
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
    required this.onOpenAdminDashboard,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenAdminDashboard;

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
        onAdminTap: widget.onOpenAdminDashboard,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            _logFirestoreReadError('groups', error);
            if (error is FirebaseException && error.code == 'permission-denied') {
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
            return Center(child: Text(widget.tr.t('groups_page')));
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
          final canCreate = provider.roles['groupOrganizer'] == true ||
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
                  builder: (_) => AddGroupPage(
                    tr: widget.tr,
                    groupService: _groupService,
                  ),
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
  const AddGroupPage({
    super.key,
    required this.tr,
    required this.groupService,
  });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.tr.t('fill_all_fields'))),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.tr.t('save_failed'))),
        );
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
  @override
  Widget build(BuildContext context) {
    final isAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    return Scaffold(
      appBar: appBarWithLanguage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        title: widget.tr.t('profile'),
        onToggleLanguage: widget.onToggleLanguage,
        onAdminTap: widget.onOpenAdminDashboard,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAnonymous
                  ? widget.tr.t('guest_account')
                  : widget.tr.t('signed_in_account'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: Text(widget.tr.t('sign_out')),
            ),
          ],
        ),
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
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
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
              if (error is FirebaseException && error.code == 'permission-denied') {
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
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
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
            if (error is FirebaseException && error.code == 'permission-denied') {
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
    'permission_denied': 'Permission denied',
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
    'permission_denied':
        '\u0644\u0627 \u062a\u0645\u0644\u0643 \u0635\u0644\u0627\u062d\u064a\u0629 \u0644\u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621',
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
