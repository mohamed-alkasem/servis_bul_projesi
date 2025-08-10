
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class KullaniciOgrenciBilgileri extends StatefulWidget {
  @override
  _KullaniciOgrenciBilgileriState createState() => _KullaniciOgrenciBilgileriState();
}

class _KullaniciOgrenciBilgileriState extends State<KullaniciOgrenciBilgileri> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<DocumentSnapshot>> _rezervasyonlarStream;
  bool _isSorted = false;
  LatLng? _selectedLocation;
  String? _locationText;

  // ... (ابق على دوال initState و _loadRezervasyonlar كما هي)
 @override
  void initState() {
    super.initState();
    _loadRezervasyonlar();
  }

  void _loadRezervasyonlar() {
    final user = _auth.currentUser;
    if (user != null) {
      _rezervasyonlarStream = _firestore
          .collection('rezervasyonlar')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((querySnapshot) {
        var docs = querySnapshot.docs;
        if (_isSorted) {
          docs.sort((a, b) {
            var aDate = a.get('rezervasyonTarihi') as Timestamp? ?? Timestamp.now();
            var bDate = b.get('rezervasyonTarihi') as Timestamp? ?? Timestamp.now();
            return bDate.compareTo(aDate);
          });
        }
        return docs;
      });
    } else {
      _rezervasyonlarStream = Stream.value([]);
    }
  }
  Future<void> _updateRezervasyon(BuildContext context, DocumentSnapshot rezervasyon) async {
    final _formKey = GlobalKey<FormState>();
    final _ogrenciAdiController = TextEditingController(text: rezervasyon['ogrenciAdi']);
    final _ogrenciNoController = TextEditingController(text: rezervasyon['ogrenciNo']);
    final _telefonController = TextEditingController(text: rezervasyon['telefon']);
    final _locationController = TextEditingController(text: rezervasyon['locationText'] ?? '');

    // تهيئة الموقع المختار بالبيانات الحالية
    if (rezervasyon['location'] != null) {
      final geoPoint = rezervasyon['location'] as GeoPoint;
      _selectedLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rezervasyonu Güncelle'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _ogrenciAdiController,
                        decoration: InputDecoration(labelText: 'Öğrenci Adı Soyadı'),
                        validator: (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                      ),
                      TextFormField(
                        controller: _ogrenciNoController,
                        decoration: InputDecoration(labelText: 'Öğrenci Numarası'),
                        validator: (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                      ),
                      TextFormField(
                        controller: _telefonController,
                        decoration: InputDecoration(labelText: 'Telefon Numarası'),
                        validator: (value) => value!.isEmpty ? 'Bu alan zorunludur' : null,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 10),
                      Text('Konum Bilgisi:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_locationController.text, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final newLocation = await _showMapPicker(context);
                          if (newLocation != null) {
                            setState(() {
                              _selectedLocation = newLocation;
                              _locationController.text = '${newLocation.latitude.toStringAsFixed(4)}, ${newLocation.longitude.toStringAsFixed(4)}';
                            });
                          }
                        },
                        child: Text('Konumu Değiştir'),
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
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      await _performUpdate(
                        rezervasyon.id,
                        _ogrenciAdiController.text,
                        _ogrenciNoController.text,
                        _telefonController.text,
                        _selectedLocation != null
                            ? GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude)
                            : null,
                        _locationController.text,
                      );
                    }
                  },
                  child: Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<LatLng?> _showMapPicker(BuildContext context) async {
    LatLng? pickedLocation;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Konum Seçin'),
              actions: [
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    Navigator.pop(context, _selectedLocation);
                  },
                ),
              ],
            ),
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? LatLng(39.9334, 32.8597), // Ankara default
                zoom: 12,
              ),
              onTap: (LatLng location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: MarkerId('selected-location'),
                        position: _selectedLocation!,
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        );
      },
    ).then((value) {
      pickedLocation = value;
    });

    return pickedLocation;
  }

  Future<void> _performUpdate(
    String rezervasyonId,
    String ogrenciAdi,
    String ogrenciNo,
    String telefon,
    GeoPoint? location,
    String locationText,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      await _firestore.collection('rezervasyonlar').doc(rezervasyonId).update({
        'ogrenciAdi': ogrenciAdi,
        'ogrenciNo': ogrenciNo,
        'telefon': telefon,
        'location': location,
        'locationText': locationText,
        'guncellemeTarihi': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rezervasyon bilgileri güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme başarısız: ${_getUserFriendlyError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ... (ابق على باقي الدوال كما هي _deleteRezervasyon, _incrementKapasite, _getUserFriendlyError, build, _buildInfoRow)
   Future<void> _deleteRezervasyon(String rezervasyonId) async {
    final currentContext = context;

    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final rezervasyonDoc = await _firestore.collection('rezervasyonlar').doc(rezervasyonId).get();

      if (!rezervasyonDoc.exists) {
        Navigator.of(currentContext).pop();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Rezervasyon bulunamadı!')),
        );
        return;
      }

      final otobusId = rezervasyonDoc['otobusId'] as String?;

      await _firestore.collection('rezervasyonlar').doc(rezervasyonId).delete();

      if (otobusId != null && otobusId.isNotEmpty) {
        await _incrementKapasite(otobusId);
      }

      Navigator.of(currentContext).pop();

      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Rezervasyon iptal edildi. Koltuk iade edildi.'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        setState(() {
          _loadRezervasyonlar();
        });
      }

    } catch (e) {
      Navigator.of(currentContext).pop();
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('İptal işlemi başarısız: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Hata: $e');
    }
  }

  Future<void> _incrementKapasite(String otobusId) async {
    await _firestore.collection('otobusler').doc(otobusId).update({
      'kapasite': FieldValue.increment(1),
      'sonGuncelleme': FieldValue.serverTimestamp(),
    });
  }

  String _getUserFriendlyError(dynamic error) {
    if (error.toString().contains('PERMISSION_DENIED')) {
      return 'Bu işlem için yetkiniz yok!';
    } else if (error.toString().contains('UNAVAILABLE')) {
      return 'Sunucuya ulaşılamıyor. Lütfen internet bağlantınızı kontrol edin.';
    } else if (error.toString().contains('NOT_FOUND')) {
      return 'Kayıt bulunamadı.';
    }
    return 'Teknik bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Öğrenci Rezervasyonlarım'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              setState(() {
                _isSorted = !_isSorted;
                _loadRezervasyonlar();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSorted
                      ? 'Rezervasyonlar yeniden eskiye sıralanıyor'
                      : 'Sıralama kapatıldı'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Sıralamayı Değiştir',
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _rezervasyonlarStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 20),
                  Text(
                    'Veri Yüklenemedi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Rezervasyon bilgileri yüklenirken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadRezervasyonlar,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 60, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Kayıtlı rezervasyon bulunamadı'),
                  SizedBox(height: 10),
                  Text('Otobüsler sayfasından yeni rezervasyon yapabilirsiniz'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var rezervasyon = docs[index];
              var data = rezervasyon.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: Icon(Icons.directions_bus, color: Colors.blue),
                  title: Text(data['ogrenciAdi'] ?? 'İsimsiz'),
                  subtitle: Text('Otobüs: ${data['otobusNo'] ?? 'Bilgi yok'} - ${data['plaka'] ?? 'Bilgi yok'}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Öğrenci No:', data['ogrenciNo']),
                          _buildInfoRow('Telefon:', data['telefon']),
                          _buildInfoRow('Konum:', data['locationText'] ?? 'Belirtilmemiş'),
                          _buildInfoRow('Otobüs:', '${data['otobusNo']} (${data['plaka']})'),
                          _buildInfoRow('Rota:', '${data['sehir']} - ${data['ilce']}'),
                          _buildInfoRow('Durum:', data['durum'] ?? 'Onaylandı'),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _updateRezervasyon(context, rezervasyon),
                                child: Text('Düzenle'),
                              ),
                              SizedBox(width: 10),
                              TextButton(
                                onPressed: () async {
                                  bool confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("İptal Onayı"),
                                      content: Text("Bu rezervasyonu iptal etmek istediğinize emin misiniz?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text("Vazgeç"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text("İptal Et", style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await _deleteRezervasyon(rezervasyon.id);
                                  }
                                },
                                child: Text('İptal Et', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(value?.toString() ?? 'Belirtilmemiş'),
          ),
        ],
      ),
    );
  }
}
