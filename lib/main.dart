import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'chat/chat.dart' as chat;
import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'utils/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firebaseOptions = Firebase.app().options;
  debugPrint('PROJECT ID: ${firebaseOptions.projectId}');
  debugPrint('APP ID: ${firebaseOptions.appId}');
  try {
    final packageName = (firebaseOptions as dynamic).androidPackageName;
    debugPrint('PACKAGE: $packageName');
  } catch (_) {
    debugPrint('PACKAGE: unavailable');
  }

  final deepLinkService = chat.DeepLinkService();
  runApp(KashtaApp(deepLinkService: deepLinkService));
}
