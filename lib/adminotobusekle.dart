import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class AdminOtobusEkle extends StatefulWidget {
  @override
  _AdminOtobusEkleState createState() => _AdminOtobusEkleState();
}

class _AdminOtobusEkleState extends State<AdminOtobusEkle> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _otobusEklendi = false;

  final TextEditingController _otobusNoController = TextEditingController();
  final TextEditingController _ilceAdiController = TextEditingController();
  final TextEditingController _kapasiteController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plakaController = TextEditingController();
  final TextEditingController _soforAdiController = TextEditingController();

  String? _selectedSehir;
  String? _selectedIlce;

  final List<String> _sehirler = ['İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana'];
  final Map<String, List<String>> _ilceler = {
    'İstanbul': ['Beşiktaş', 'Kadıköy', 'Şişli', 'Üsküdar', 'Fatih'],
    'Ankara': ['Çankaya', 'Keçiören', 'Yenimahalle', 'Altındağ', 'Mamak'],
    'İzmir': ['Bornova', 'Karşıyaka', 'Konak', 'Buca', 'Bayraklı'],
    'Bursa': ['Osmangazi', 'Yıldırım', 'Nilüfer', 'Gemlik', 'Mustafakemalpaşa'],
    'Antalya': ['Muratpaşa', 'Kepez', 'Konyaaltı', 'Alanya', 'Manavgat'],
    'Adana': ['Seyhan', 'Yüreğir', 'Çukurova', 'Sarıçam', 'Ceyhan'],
  };

  @override
  void initState() {
    super.initState();
    _checkIfOtobusExists();
  }

  Future<void> _checkIfOtobusExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('otobusler')
          .where('adminId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() => _otobusEklendi = true);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _selectedImageBytes = bytes);
        } else {
          setState(() => _selectedImage = File(pickedFile.path));
        }
      }
    } catch (e) {
      print('Resim seçme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken hata oluştu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage() async {
    try {
      if ((kIsWeb && _selectedImageBytes == null) || (!kIsWeb && _selectedImage == null)) {
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('otobus_images')
          .child('${_plakaController.text}_$timestamp.jpg');

      if (kIsWeb) {
        await storageRef.putData(_selectedImageBytes!);
      } else {
        await storageRef.putFile(_selectedImage!);
      }

      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Resim yükleme hatası: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _otobusEklendi) return;

    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        throw Exception('Resim yüklenemedi');
      }

      await FirebaseFirestore.instance.collection('otobusler').add({
        'adminId': user.uid,
        'otobusNo': _otobusNoController.text.trim(),
        'plaka': _plakaController.text.trim(),
        'model': _modelController.text.trim(),
        'soforAdi': _soforAdiController.text.trim(),
        'ilceAdi': _ilceAdiController.text.trim(),
        'ilce': _selectedIlce,
        'sehir': _selectedSehir,
        'kapasite': int.tryParse(_kapasiteController.text.trim()) ?? 0,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _otobusEklendi = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otobüs başarıyla eklendi!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      _resetForm();
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedIlce = null;
      _selectedSehir = null;
      _otobusNoController.clear();
      _ilceAdiController.clear();
      _kapasiteController.clear();
      _modelController.clear();
      _plakaController.clear();
      _soforAdiController.clear();
    });
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.blueGrey[800]),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[600]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.blue[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Bu alan zorunludur';
        }
        if (label == 'Kapasite' && int.tryParse(value) == null) {
          return 'Lütfen geçerli bir sayı girin';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Yeni Otobüs Ekle', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blue[600]))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_otobusEklendi)
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[800]),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Zaten bir otobüs eklediniz. Yalnızca bir otobüs ekleyebilirsiniz.',
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: _otobusEklendi ? 20 : 0),
                      GestureDetector(
                        onTap: _otobusEklendi ? null : _pickImage,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _otobusEklendi ? Colors.grey[300]! : Colors.blue[200]!,
                              width: 2,
                            ),
                          ),
                          child: (_selectedImageBytes == null && _selectedImage == null)
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: _otobusEklendi ? Colors.grey : Colors.blue[400],
                                size: 40,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Otobüs Fotoğrafı Ekle',
                                style: TextStyle(
                                  color: _otobusEklendi ? Colors.grey : Colors.blue[400],
                                ),
                              ),
                            ],
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                : Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField('Otobüs No', _otobusNoController),
                      SizedBox(height: 15),
                      _buildTextField('Plaka', _plakaController),
                      SizedBox(height: 15),
                      _buildTextField('Model', _modelController),
                      SizedBox(height: 15),
                      _buildTextField('Şoför Adı', _soforAdiController),
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueGrey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.blue[50],
                          style: TextStyle(color: Colors.blueGrey[800]),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Şehir Seç',
                            labelStyle: TextStyle(color: Colors.blueGrey[600]),
                          ),
                          value: _selectedSehir,
                          items: _sehirler.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: _otobusEklendi ? null : (newValue) {
                            setState(() {
                              _selectedSehir = newValue;
                              _selectedIlce = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Lütfen bir şehir seçin';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 15),
                      if (_selectedSehir != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blueGrey[200]!),
                          ),
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.blue[50],
                            style: TextStyle(color: Colors.blueGrey[800]),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: 'İlçe Seç',
                              labelStyle: TextStyle(color: Colors.blueGrey[600]),
                            ),
                            value: _selectedIlce,
                            items: _ilceler[_selectedSehir]!.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: _otobusEklendi ? null : (newValue) {
                              setState(() => _selectedIlce = newValue);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Lütfen bir ilçe seçin';
                              }
                              return null;
                            },
                          ),
                        ),
                      SizedBox(height: 15),
                      _buildTextField('Kapasite', _kapasiteController, keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _otobusEklendi ? Colors.grey[400] : Colors.blue[600],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                onPressed: _otobusEklendi ? null : _submitForm,
                child: Text(
                  _otobusEklendi ? 'OTOBÜS EKLENDİ' : 'OTOBÜS EKLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otobusNoController.dispose();
    _ilceAdiController.dispose();
    _kapasiteController.dispose();
    _modelController.dispose();
    _plakaController.dispose();
    _soforAdiController.dispose();
    super.dispose();
  }
}