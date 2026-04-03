part of 'app_shell.dart';

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
                        textAlign:
                            widget.isArabic ? TextAlign.right : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: tr.t('email'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textAlign:
                            widget.isArabic ? TextAlign.right : TextAlign.left,
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

  Future<void> _createDefaultUserDocument(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'roles': {
        'regularUser': true,
      },
      'preferences': {
        'placeType': 'desert',
        'distancePreference': 'near',
        'temperaturePreference': 'cool',
      },'preferencesCompleted' :false,
    }, SetOptions(merge: true));
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _snack(widget.tr.t('email_password_required'));
      return;
    }

    await _authRun(() async {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;
      if (user != null) {
        await _createDefaultUserDocument(user);
        if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
      }
    });
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _snack(widget.tr.t('email_password_required'));
      return;
    }

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user;
      if (user != null) {
        await _createDefaultUserDocument(user);
        if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
      }
    } catch (e) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == email) {
        await _createDefaultUserDocument(user);
        if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
        return;
      }

      _snack(e.toString());
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _createDefaultUserDocument(user);
          if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
        }
        return;
      }

      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await _createDefaultUserDocument(user);
        if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
      }
    } catch (e) {
      _snack(e.toString());
    }
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
          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);

          final user = userCredential.user;
          if (user != null) {
            await _createDefaultUserDocument(user);
            if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
          }
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

          final userCredential =
              await FirebaseAuth.instance.signInWithCredential(credential);

          final user = userCredential.user;
          if (user != null) {
            await _createDefaultUserDocument(user);
            if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    });
  }

  Future<void> _signInAnonymously() async {
    await _authRun(() async {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();

      final user = userCredential.user;
      if (user != null) {
        await _createDefaultUserDocument(user);
        if (!mounted) return;
Navigator.pushReplacementNamed(context, '/welcome_preferences');
      }
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
    if (mounted) {
      setState(() => _loading = true);
    }

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