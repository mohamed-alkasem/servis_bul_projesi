import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AdminOtobusDuzelt extends StatefulWidget {
  const AdminOtobusDuzelt({super.key});

  @override
  _AdminOtobusDuzeltState createState() => _AdminOtobusDuzeltState();
}

class _AdminOtobusDuzeltState extends State<AdminOtobusDuzelt> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late Stream<QuerySnapshot> _otobuslerStream;

  @override
  void initState() {
    super.initState();
    _loadOtobusler();
  }

  void _loadOtobusler() {
    _otobuslerStream = _firestore
        .collection('otobusler')
        .where('adminId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otobüs Düzenle'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _otobuslerStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Kayıtlı otobüs bulunamadı'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final otobus = snapshot.data!.docs[index];
              return _buildOtobusCard(otobus);
            },
          );
        },
      ),
    );
  }

  Widget _buildOtobusCard(DocumentSnapshot otobus) {
    final data = otobus.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] as String?;

    // Log the image URL for debugging
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('Image URL for otobus ${data['otobusNo']}: $imageUrl');
    } else {
      debugPrint('No image URL for otobus ${data['otobusNo']}');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: Column(
        children: [
          // Resim bölümü
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[200],
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus, size: 50, color: Colors.grey),
                    SizedBox(height: 5),
                    Text(
                      'Görüntü yüklenemedi: $error',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 50, color: Colors.grey),
                  SizedBox(height: 5),
                  Text(
                    'Görüntü yok',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Bilgiler bölümü
          ListTile(
            leading: Icon(Icons.directions_bus, size: 40, color: Colors.blue),
            title: Text(
              '${data['otobusNo']} - ${data['plaka']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Model: ${data['model']}'),
                Text('Şoför: ${data['soforAdi']}'),
                Text('Kapasite: ${data['kapasite']} kişi'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(otobus),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(otobus),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(DocumentSnapshot otobus) async {
    final data = otobus.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] as String?;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Otobüsü Sil'),
        content: Text('${data['otobusNo']} plakalı otobüsü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Resmi storage'dan sil (varsa)
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            debugPrint('Resim silme hatası: $e');
          }
        }

        // Firestore'dan sil
        await otobus.reference.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Otobüs başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Silme hatası: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showEditDialog(DocumentSnapshot otobus) {
    final data = otobus.data() as Map<String, dynamic>;
    final formKey = GlobalKey<FormState>();

    TextEditingController otobusNoController = TextEditingController(text: data['otobusNo']);
    TextEditingController plakaController = TextEditingController(text: data['plaka']);
    TextEditingController modelController = TextEditingController(text: data['model']);
    TextEditingController soforAdiController = TextEditingController(text: data['soforAdi']);
    TextEditingController kapasiteController = TextEditingController(text: data['kapasite'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Otobüs Bilgilerini Düzenle'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: otobusNoController,
                  decoration: InputDecoration(labelText: 'Otobüs No'),
                  validator: (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                ),
                TextFormField(
                  controller: plakaController,
                  decoration: InputDecoration(labelText: 'Plaka'),
                  validator: (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                ),
                TextFormField(
                  controller: modelController,
                  decoration: InputDecoration(labelText: 'Model'),
                ),
                TextFormField(
                  controller: soforAdiController,
                  decoration: InputDecoration(labelText: 'Şoför Adı'),
                ),
                TextFormField(
                  controller: kapasiteController,
                  decoration: InputDecoration(labelText: 'Kapasite'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await otobus.reference.update({
                    'otobusNo': otobusNoController.text,
                    'plaka': plakaController.text,
                    'model': modelController.text,
                    'soforAdi': soforAdiController.text,
                    'kapasite': int.tryParse(kapasiteController.text) ?? data['kapasite'],
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Otobüs bilgileri güncellendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Güncelleme hatası: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}