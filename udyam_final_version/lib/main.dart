import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// By default Flutter only lets touch/stylus drag scrollable widgets (like
/// our photo PageView) -- a mouse drag on web/desktop is ignored, which is
/// why swiping the photo carousel can feel "stuck" when testing in Chrome
/// or on a desktop build. This adds mouse + trackpad as valid drag devices
/// everywhere in the app.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

// TODO: once you're ready to connect to Supabase, this file is where
// Supabase.initialize(url: ..., anonKey: ...) needs to run, before runApp().
// At that point main() needs to become:
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_ANON_KEY');
//   runApp(const MyApp());
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://atfoaqjuhggabqxcpywy.supabase.co',
    publishableKey: 'sb_publishable_Heqhi_8sHsCaohibtZS_MQ_zR9Mh-2W',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndianHandmade',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      theme: ThemeData(primarySwatch: Colors.deepOrange, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
