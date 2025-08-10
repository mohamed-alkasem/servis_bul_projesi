import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:servisbul/register.dart';
import 'login.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBkvnl38hBKe7KUbbhh94Nr0Nl1eUfiYz4",
      appId: "1:121471218727:android:7fbbd4620f8f89c3e4ca02",
      projectId: "servisbul-b1b1b",
      messagingSenderId: "121471218727",
      storageBucket: 'gs://servisbul-b1b1b.firebasestorage.app', // تأكد من وجود هذا

    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue[900],
      ),
      home: LoginPage(),
    );
  }
}
