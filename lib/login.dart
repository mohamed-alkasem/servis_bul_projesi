import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kullanici.dart';
import 'admin.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;
  bool _isLoading = false;
  String _userType = 'kullanici';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            // Logo Alanı
            Column(
            children: [
            Image.asset(
              'images/bus.png', // Kendi logo dosyanızı ekleyin
              height: 120,
              width: 120,
            ),
            SizedBox(height: 16),
            Text(
              'Servis Bul Uygulaması',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Güvenli ve Konforlu Ulaşım',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue[600],
              ),
            ),
            ],
          ),
          SizedBox(height: 40),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Kullanıcı Tipi Seçimi
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: Text('Kullanıcı'),
                              value: 'kullanici',
                              groupValue: _userType,
                              onChanged: (value) => setState(() => _userType = value.toString()),
                              activeColor: Colors.blue[800],
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: Text('Admin'),
                              value: 'admin',
                              groupValue: _userType,
                              onChanged: (value) => setState(() => _userType = value.toString()),
                              activeColor: Colors.blue[800],
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                      // Email Alanı
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.blue[800]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[800]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen email adresinizi girin';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Geçerli bir email adresi girin';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16),

                      // Şifre Alanı
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock, color: Colors.blue[800]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility : Icons.visibility_off,
                              color: Colors.blue[800],
                            ),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[800]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),

                      // Giriş Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'GİRİŞ YAP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Kayıt Ol Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hesabınız yok mu?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Register()),
                    );
                  },
                  child: Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. تسجيل الدخول باستخدام Firebase Auth
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. البحث عن المستخدم في Firestore باستخدام البريد الإلكتروني
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _emailController.text.trim())
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          await _auth.signOut();
          throw Exception('Bu email ile kayıtlı kullanıcı bulunamadı');
        }

        // 3. التحقق من صلاحيات المستخدم
        DocumentSnapshot userDoc = userQuery.docs.first;
        String userRole = userDoc.get('rool')?.toString() ?? 'kullanici';

        // 4. التحقق من التطابق بين نوع الدخول المختار ونوع المستخدم الحقيقي
        if ((_userType == 'admin' && userRole != 'Admin') ||
            (_userType == 'kullanici' && userRole == 'Admin')) {
          await _auth.signOut();
          throw Exception('Bu hesap türü ile giriş yapamazsınız');
        }

        // 5. توجيه المستخدم للواجهة المناسبة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => _userType == 'admin' ? Admin() : Kullanici(),
          ),
        );

      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Giriş başarısız: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}