import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KullaniciOtobusler extends StatefulWidget {
  @override
  _KullaniciOtobuslerState createState() => _KullaniciOtobuslerState();
}

class _KullaniciOtobuslerState extends State<KullaniciOtobusler> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _otobuslerStream;

  // Location variables
  double? _latitude;
  double? _longitude;
  String? _address;
  final TextEditingController _locationController = TextEditingController();

  // Filter variables
  String? _selectedSehir;
  String? _selectedIlce;
  final List<String> _sehirler = ['Tümü', 'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Isparta'];
  final Map<String, List<String>> _sehirIlceleri = {
    'İstanbul': ['Tümü', 'Beşiktaş', 'Kadıköy', 'Şişli', 'Fatih'],
    'Ankara': ['Tümü', 'Çankaya', 'Keçiören', 'Yenimahalle', 'Altındağ'],
    'İzmir': ['Tümü', 'Konak', 'Karşıyaka', 'Bornova', 'Buca'],
    'Bursa': ['Tümü', 'Osmangazi', 'Yıldırım', 'Nilüfer', 'Gemlik'],
    'Antalya': ['Tümü', 'Muratpaşa', 'Konyaaltı', 'Kepez', 'Alanya'],
    'Isparta': ['Tümü', 'Merkez', 'Yalvaç', 'Eğirdir', 'Şarkikaraağaç'],
  };

  // Form controllers
  final TextEditingController _ogrenciAdiController = TextEditingController();
  final TextEditingController _ogrenciNoController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Map variables
  late GoogleMapController _mapController;
  final LatLng _initialPosition = const LatLng(41.0082, 28.9784); // Istanbul center
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _filterOtobusler(null, null);
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konum alınamadı: $e')),
      );
    }
  }

  void _filterOtobusler(String? sehir, String? ilce) {
    setState(() {
      _selectedSehir = sehir;
      _selectedIlce = ilce;

      if (sehir == null || sehir == 'Tümü') {
        _otobuslerStream = _firestore.collection('otobusler').snapshots();
      } else {
        if (ilce == null || ilce == 'Tümü') {
          _otobuslerStream = _firestore
              .collection('otobusler')
              .where('sehir', isEqualTo: sehir)
              .snapshots();
        } else {
          _otobuslerStream = _firestore
              .collection('otobusler')
              .where('sehir', isEqualTo: sehir)
              .where('ilce', isEqualTo: ilce)
              .snapshots();
        }
      }
    });
  }

  Future<void> _rezervasyonYap(DocumentSnapshot otobus) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rezervasyon yapmak için giriş yapmalısınız')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final otobusRef = otobus.reference;
    final kapasite = otobus['kapasite'] as int? ?? 0;

    if (kapasite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Üzgünüz, bu otobüs dolu')),
      );
      return;
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final freshOtobus = await transaction.get(otobusRef);
        final currentKapasite = freshOtobus['kapasite'] as int? ?? 0;

        if (currentKapasite <= 0) {
          throw Exception('Otobüs dolu');
        }

        transaction.update(otobusRef, {'kapasite': currentKapasite - 1});

        await _firestore.collection('rezervasyonlar').add({
          'userId': user.uid,
          'userEmail': user.email,
          'otobusId': otobus.id,
          'otobusNo': otobus['otobusNo'] ?? 'Belirtilmemiş',
          'plaka': otobus['plaka'] ?? 'Belirtilmemiş',
          'ogrenciAdi': _ogrenciAdiController.text,
          'ogrenciNo': _ogrenciNoController.text,
          'telefon': _telefonController.text,
          'location': _latitude != null && _longitude != null
              ? GeoPoint(_latitude!, _longitude!)
              : null,
          'locationText': _locationController.text,
          'rezervasyonTarihi': FieldValue.serverTimestamp(),
          'durum': 'onaylandı',
          'sehir': otobus['sehir'] ?? 'Belirtilmemiş',
          'ilce': otobus['ilce'] ?? 'Belirtilmemiş',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rezervasyon başarılı!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rezervasyon başarısız: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _latitude != null && _longitude != null
                            ? LatLng(_latitude!, _longitude!)
                            : _initialPosition,
                        zoom: 14.0,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onTap: (LatLng latLng) {
                        setState(() {
                          _latitude = latLng.latitude;
                          _longitude = latLng.longitude;
                          _markers.clear();
                          _markers.add(
                            Marker(
                              markerId: MarkerId('selected-location'),
                              position: latLng,
                            ),
                          );
                        });
                      },
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_latitude != null && _longitude != null) {
                                _locationController.text =
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
                                Navigator.pop(context);
                              }
                            },
                            child: Text('Konumu Seç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
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
    );
  }

  void _showRezervasyonForm(DocumentSnapshot otobus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Koltuk Rezervasyon Formu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // Location field with auto-fill and map selection
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Konum (Enlem, Boylam)',
                          border: OutlineInputBorder(),
                          hintText: 'Örnek: 41.0082, 28.9784',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen konum bilgisini girin';
                          }
                          return null;
                        },
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.location_on, color: Colors.blue),
                      onPressed: _getCurrentLocation,
                      tooltip: 'Mevcut konumu kullan',
                    ),
                    IconButton(
                      icon: Icon(Icons.map, color: Colors.green),
                      onPressed: _showMapPicker,
                      tooltip: 'Haritadan seç',
                    ),
                  ],
                ),
                SizedBox(height: 15),

                TextFormField(
                  controller: _ogrenciAdiController,
                  decoration: InputDecoration(
                    labelText: 'Öğrenci Adı Soyadı',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bu alan zorunludur';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _ogrenciNoController,
                  decoration: InputDecoration(
                    labelText: 'Öğrenci Numarası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bu alan zorunludur';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _telefonController,
                  decoration: InputDecoration(
                    labelText: 'Telefon Numarası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bu alan zorunludur';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _rezervasyonYap(otobus),
                  child: Text('Rezervasyon Yap'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Otobüs Listesi'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSehir,
                  decoration: InputDecoration(
                    labelText: 'Şehir Seçiniz',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _sehirler.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'Tümü' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    _filterOtobusler(newValue, null);
                    _selectedIlce = null;
                  },
                ),
                SizedBox(height: 10),
                if (_selectedSehir != null && _selectedSehir != 'Tümü')
                  DropdownButtonFormField<String>(
                    value: _selectedIlce,
                    decoration: InputDecoration(
                      labelText: 'İlçe Seçiniz',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _sehirIlceleri[_selectedSehir]?.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Tümü' ? null : value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      _filterOtobusler(_selectedSehir, newValue);
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _otobuslerStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata oluştu: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedSehir == null
                          ? 'Kayıtlı otobüs bulunamadı'
                          : _selectedIlce == null
                          ? '${_selectedSehir} şehrinde otobüs bulunamadı'
                          : '${_selectedSehir} - ${_selectedIlce} bölgesinde otobüs bulunamadı',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var otobus = snapshot.data!.docs[index];
                    return _buildOtobusCard(otobus);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtobusCard(DocumentSnapshot otobus) {
    final kapasite = otobus['kapasite'] as int? ?? 0;
    final otobusNo = otobus['otobusNo'] as String? ?? 'Belirtilmemiş';
    final plaka = otobus['plaka'] as String? ?? 'Belirtilmemiş';
    final model = otobus['model'] as String? ?? 'Belirtilmemiş';
    final soforAdi = otobus['soforAdi'] as String? ?? 'Belirtilmemiş';
    final sehir = otobus['sehir'] as String? ?? 'Belirtilmemiş';
    final ilce = otobus['ilce'] as String? ?? 'Belirtilmemiş';
    final imageUrl = otobus['imageUrl'] as String?;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      child: Column(
        children: [
          // صورة الباص
          Container(
            height: 150,
            width: double.infinity,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Icon(Icons.error, color: Colors.red),
              ),
            )
                : Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(Icons.directions_bus, size: 50, color: Colors.grey),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.directions_bus, size: 40, color: Colors.blue),
            title: Text(
              '$otobusNo - $plaka',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Text('Model: $model'),
                Text('Şoför: $soforAdi'),
                Text('Kalan Kapasite: $kapasite kişi'),
                Text('Şehir: $sehir'),
                Text('İlçe: $ilce'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 10, left: 10, right: 10),
            child: ElevatedButton(
              onPressed: kapasite > 0
                  ? () => _showRezervasyonForm(otobus)
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
                backgroundColor: kapasite > 0 ? Colors.blue : Colors.grey,
              ),
              child: Text(
                kapasite > 0 ? 'Koltuk Rezerve Et' : 'Dolu',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ogrenciAdiController.dispose();
    _ogrenciNoController.dispose();
    _telefonController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}