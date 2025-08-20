import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/auth_screen.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/add_debt_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_app/screens/user_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  if(kIsWeb){
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['apiKey']!,
        authDomain: dotenv.env['authDomain']!,
        projectId: dotenv.env['projectId']!,
        storageBucket: dotenv.env['storageBucket']!,
        messagingSenderId: dotenv.env['messagingSenderId']!,
        appId: dotenv.env['appId']!,
        measurementId: dotenv.env['measurementId']!,
      ),
    );
  print('Firebase initialized successfully');
  }
  else{
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bordim Money',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7C4DFF), // light purple
          secondary: Color(0xFF2196F3), // blue
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/add-debt': (_) => const AddDebtScreen(),
        '/user-screen': (_) => const UserScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
