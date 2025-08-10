import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KullaniciIletisim extends StatefulWidget {
  @override
  _KullaniciIletisimState createState() => _KullaniciIletisimState();
}

class _KullaniciIletisimState extends State<KullaniciIletisim> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isSending = false;
  bool _isEditing = false;
  List<DocumentSnapshot> _userBuses = [];
  String? _selectedBusId;
  String? _selectedBusNo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserBuses();
  }

  Future<void> _loadUserBuses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('rezervasyonlar')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final busIds = querySnapshot.docs.map((doc) => doc['otobusId'] as String).toSet();

        final buses = await _firestore
            .collection('otobusler')
            .where(FieldPath.documentId, whereIn: busIds.toList())
            .get();

        setState(() {
          _userBuses = buses.docs;
          if (_userBuses.isNotEmpty) {
            _selectedBusId = _userBuses.first.id;
            _selectedBusNo = _userBuses.first['otobusNo'] as String?;
          }
        });
      }
    } catch (e) {
      print('Error loading user buses: $e');
    }
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc.data()?['name'] ?? '';
          _phoneController.text = userDoc.data()?['phone'] ?? '';
          _addressController.text = userDoc.data()?['address'] ?? '';
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'email': user.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bilgileriniz güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen bir otobüs seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Get bus admin info
      final busDoc = await _firestore.collection('otobusler').doc(_selectedBusId).get();
      final adminId = busDoc['adminId'] as String?;
      if (adminId == null) throw Exception('Otobüs admin bilgisi bulunamadı');

      await _firestore.collection('messages').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': _nameController.text,
        'userPhone': _phoneController.text,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'busId': _selectedBusId,
        'busNo': _selectedBusNo,
        'adminId': adminId,
        'type': 'user_to_admin',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesajınız gönderildi!'),
          backgroundColor: Colors.green,
        ),
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildBusSelector() {
    if (_userBuses.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Text(
          'Rezervasyon yaptığınız herhangi bir otobüs bulunamadı',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mesaj Gönderilecek Otobüs',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBusId,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _userBuses.map((bus) {
              final busNo = bus['otobusNo'] as String? ?? 'Belirtilmemiş';
              final plaka = bus['plaka'] as String? ?? 'Belirtilmemiş';
              return DropdownMenuItem<String>(
                value: bus.id,
                child: Text('$busNo - $plaka'),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                final selectedBus = _userBuses.firstWhere((bus) => bus.id == newValue);
                setState(() {
                  _selectedBusId = newValue;
                  _selectedBusNo = selectedBus['otobusNo'] as String?;
                });
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Lütfen bir otobüs seçin';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'İletişim Bilgileri',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),

                // Email (غير قابل للتعديل)
                _buildContactInfo(
                  Icons.email,
                  'Email',
                  user?.email ?? 'Giriş yapılmamış',
                  isEditable: false,
                ),

                // الاسم (قابل للتعديل)
                _buildEditableContactInfo(
                  Icons.person,
                  'Ad Soyad',
                  _nameController,
                ),

                // الهاتف (قابل للتعديل)
                _buildEditableContactInfo(
                  Icons.phone,
                  'Telefon',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                ),

                // العنوان (قابل للتعديل)
                _buildEditableContactInfo(
                  Icons.location_on,
                  'Adres',
                  _addressController,
                  maxLines: 2,
                ),

                // زر التعديل/حفظ
                if (_isEditing)
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _saveUserData,
                      child: _isSending
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Bilgileri Kaydet'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: Text('Bilgileri Düzenle'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue[800],
                      ),
                    ),
                  ),

                // قسم إرسال الرسالة
                Text(
                  'Bize Ulaşın',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),

                // Otobüs seçici
                _buildBusSelector(),

                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Mesajınız',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen mesajınızı yazın';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendMessage,
                  child: _isSending
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Mesaj Gönder'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String title, String value, {bool isEditable = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
          if (isEditable && _isEditing)
            IconButton(
              icon: Icon(Icons.edit, size: 20),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildEditableContactInfo(
      IconData icon,
      String title,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                _isEditing
                    ? TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bu alan zorunludur';
                    }
                    return null;
                  },
                )
                    : Text(controller.text.isEmpty ? 'Belirtilmemiş' : controller.text),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}