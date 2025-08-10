import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'adminanasayfa.dart';
import 'adminotobusekle.dart';
import 'adminotobusduzelt.dart';
import 'adminkonum.dart';
import 'adminmesajlar.dart';
import 'adminkayitliogrenciler.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AdminAnasayfa(),
    AdminOtobusEkle(),
    AdminOtobusDuzelt(),
    AdminKonum(),
    AdminMesajlar(),
    AdminKayitliOgrenciler(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        color: Colors.blue[800],
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 5,
        shadowColor: Colors.blue[900],
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 15,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("ADMIN PANELİ"),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(context),
          icon: Icon(Icons.logout, size: 28),
          tooltip: 'Çıkış Yap',
        )
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[800]!,
            Colors.blue[900]!,
            Colors.blue[900]!,
          ],
        ),
      ),
      child: _pages[_currentIndex],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 26),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus, size: 26),
            label: 'Otobüs Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit, size: 26),
            label: 'Otobüs Düzenle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on, size: 26),
            label: 'Konum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message, size: 26),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 26),
            label: 'Öğrenciler',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.blue[700],
        title: Text(
          'Çıkış Yap',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Uygulamadan çıkmak istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text(
              'İptal',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}