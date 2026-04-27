import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/localization.dart';

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
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.42).clamp(300.0, 380.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE2),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHero(context, tr, heroHeight),
              Transform.translate(
                offset: const Offset(0, -34),
                child: _buildAuthCard(context, tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, Tr tr, double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/444.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8F4E24),
                    Color(0xFFD38A48),
                    Color(0xFFF4C88F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2D1A10).withValues(alpha: 0.62),
                  const Color(0xFF9B5628).withValues(alpha: 0.28),
                  const Color(0xFFF8EFE2).withValues(alpha: 0.94),
                ],
                stops: const [0.0, 0.55, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 58),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: widget.isArabic
                      ? Alignment.topLeft
                      : Alignment.topRight,
                  child: TextButton(
                    onPressed: widget.onToggleLanguage,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                      ),
                    ),
                    child: Text(
                      widget.isArabic ? 'EN' : 'AR',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  tr.t('welcome_title'),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    tr.t('welcome_subtitle'),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, Tr tr) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE9D7BF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6F421D).withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr.t('sign_in'),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Color(0xFF2F2118),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr.t('welcome_subtitle'),
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: Color(0xFF7B6653),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          _authTextField(
            controller: _emailController,
            hintText: tr.t('email'),
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _authTextField(
            controller: _passwordController,
            hintText: tr.t('password'),
            icon: Icons.lock_outline_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4A23),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF8B4A23).withValues(alpha: 0.48),
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(tr.t('sign_in')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _signUpWithEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B3922),
                    side: const BorderSide(color: Color(0xFFD9BE9C)),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(tr.t('sign_up')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _secondaryAuthButton(
            onPressed: _loading ? null : _signInWithGoogle,
            icon: Icons.g_mobiledata_rounded,
            label: tr.t('continue_google'),
          ),
          const SizedBox(height: 10),
          _secondaryAuthButton(
            onPressed: _loading ? null : _signInWithPhone,
            icon: Icons.phone_rounded,
            label: tr.t('sign_in_phone'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _loading ? null : _signInAnonymously,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B4A23),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(tr.t('continue_guest')),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Color(0xFF8B4A23),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _authTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9C8672),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9B6B43)),
        filled: true,
        fillColor: const Color(0xFFF8EFE4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE8D7C0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFB6783F), width: 1.4),
        ),
      ),
    );
  }

  Widget _secondaryAuthButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5B3922),
        backgroundColor: Colors.white.withValues(alpha: 0.62),
        side: const BorderSide(color: Color(0xFFE1CCB2)),
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
        'activityPreference': 'camping',
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
