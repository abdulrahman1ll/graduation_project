import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'core/config/firebase_options.dart';
import 'features/groups/groups.dart' as chat;
import 'app/app_shell.dart';

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
