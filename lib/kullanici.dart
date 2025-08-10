import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'kullanicianasayfa.dart';
import 'kullaniciotobusler.dart';
import 'kullanicirota.dart';
import 'kullaniciiletisim.dart';
import 'kullaniciogrencibilgileri.dart';

class Kullanici extends StatefulWidget {
  const Kullanici({super.key});

  @override
  State<Kullanici> createState() => _KullaniciState();
}

class _KullaniciState extends State<Kullanici> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    KullaniciAnasayfa(),
    KullaniciOtobusler(),
    KullaniciRota(),
    KullaniciIletisim(),
    KullaniciOgrenciBilgileri(), // الصفحة الجديدة
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kullanıcı Paneli"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Anasayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Otobüsler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Rota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_support),
            label: 'İletişim',
          ),
          BottomNavigationBarItem( // العنصر الجديد
            icon: Icon(Icons.school),
            label: 'Öğrencilerim',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onPressed: () => logout(context),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}