import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/warehouse_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 웹은 세션 영속성 끄기(페이지 새로고침/재실행 시 자동 로그아웃)
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
  }

  // ✅ 앱을 새로 시작할 때마다 무조건 로그아웃(가장 확실한 방식)
  await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '창고 관리 앱',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

// ✅ 콜드 스타트 때 한 번 더 확실히 로그아웃
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _signedOutOnce = false;

  @override
  void initState() {
    super.initState();

    // 프레임 이후 비동기로 1회 강제 로그아웃 (2차 방어선)
    Future.microtask(() async {
      if (!_signedOutOnce) {
        _signedOutOnce = true;
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasData) {
          return const WarehouseScreen();    // 로그인됨
        }
        return const LoginScreen();     // 미로그인
      },
    );
  }
}
