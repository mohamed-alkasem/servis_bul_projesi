import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AdminKonum extends StatefulWidget {
  @override
  _AdminKonumState createState() => _AdminKonumState();
}

class _AdminKonumState extends State<AdminKonum> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  Position? _adminKonumu;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _ogrenciMesafeleri = [];
  bool _loading = true;
  Timer? _konumTimer;
  String? _otobusId;
  List<String> _adminOtobusIds = [];

  @override
  void initState() {
    super.initState();
    _adminBilgileriniGetir().then((_) {
      _baslat();
      _konumTimer =
          Timer.periodic(Duration(seconds: 10), (_) => _konumuGuncelle());
    });
  }

  Future<void> _adminBilgileriniGetir() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("Hata: Kullanıcı oturumu açık değil.");
      return;
    }

    try {
      QuerySnapshot otobusler = await _firestore
          .collection('otobusler')
          .where('adminId', isEqualTo: user.uid)
          .get();

      if (otobusler.docs.isNotEmpty) {
        setState(() {
          _adminOtobusIds = otobusler.docs.map((doc) => doc.id).toList();
          _otobusId = _adminOtobusIds.first;
        });
        debugPrint("Admin otobüsleri alındı: $_adminOtobusIds");
      } else {
        debugPrint("Adminin yönettiği otobüs bulunamadı");
        _hataGoster("Yönettiğiniz otobüs bulunamadı");
      }
    } catch (e) {
      debugPrint("Admin bilgileri alınırken hata: $e");
      _hataGoster("Admin bilgileri alınamadı: $e");
    }
  }

  Future<void> _baslat() async {
    await _konumuGuncelle();
    _ogrencileriGetir();
  }

  Future<void> _konumuGuncelle() async {
    try {
      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
        if (izin == LocationPermission.denied ||
            izin == LocationPermission.deniedForever) {
          _hataGoster("Konum izni gerekli.");
          debugPrint("Hata: Konum izni reddedildi.");
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition();
      debugPrint("Konum alındı: ${pos.latitude}, ${pos.longitude}");

      final user = _auth.currentUser;
      if (user != null && _otobusId != null) {
        try {
          // Otobüs bilgilerini de ekleyerek kaydet
          DocumentSnapshot otobusDoc =
              await _firestore.collection('otobusler').doc(_otobusId).get();

          await _firestore.collection("admin_konumlar").doc(_otobusId).set({
            "otobusId": _otobusId, // Bu satır eklendi
            "numara": _otobusId,
            "plaka": otobusDoc['plaka'] ?? 'Belirtilmemiş',
            "model": otobusDoc['model'] ?? 'Belirtilmemiş',
            "adminId": user.uid,
            "adminAdi": user.displayName ?? 'Admin',
            "latitude": pos.latitude,
            "longitude": pos.longitude,
            "updatedAt": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          debugPrint("Konum Firestore'a kaydedildi: $_otobusId");
        } catch (e) {
          debugPrint("Firestore'a kaydetme hatası: $e");
          _hataGoster("Konum kaydedilemedi: $e");
        }
      }

      setState(() {
        _adminKonumu = pos;
        _loading = false;
        _guncelleMarkerlar();
        _haritayiOrtala();
      });
    } catch (e) {
      debugPrint("Konum alınırken hata: $e");
      _hataGoster("Konum alınamadı: $e");
    }
  }

  void _ogrencileriGetir() {
    if (_adminOtobusIds.isEmpty) return;

    _firestore
        .collection("rezervasyonlar")
        .where("otobusId", whereIn: _adminOtobusIds)
        .where("location", isNotEqualTo: null)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      Set<Marker> yeniMarkerlar = {..._markers};
      yeniMarkerlar.removeWhere((m) => m.markerId.value.startsWith("ogrenci_"));
      List<Map<String, dynamic>> mesafeler = [];

      for (var doc in snapshot.docs) {
        final geoPoint = doc["location"] as GeoPoint?;
        if (geoPoint == null) continue;

        final LatLng konum = LatLng(geoPoint.latitude, geoPoint.longitude);
        yeniMarkerlar.add(Marker(
          markerId: MarkerId("ogrenci_${doc.id}"),
          position: konum,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: doc["ogrenciAdi"] ?? "Öğrenci",
            snippet: "Otobüs: ${doc["otobusNo"] ?? "Yok"}",
          ),
        ));

        if (_adminKonumu != null) {
          final mesafe = Geolocator.distanceBetween(
                _adminKonumu!.latitude,
                _adminKonumu!.longitude,
                konum.latitude,
                konum.longitude,
              ) /
              1000;

          mesafeler.add({
            "ogrenciAdi": doc["ogrenciAdi"] ?? "Öğrenci",
            "mesafe": mesafe.toStringAsFixed(2),
            "otobusNo": doc["otobusNo"] ?? "Yok",
            "otobusId": doc["otobusId"] ?? "Yok",
          });
        }
      }

      setState(() {
        _markers = yeniMarkerlar;
        _ogrenciMesafeleri = mesafeler;
      });
    });
  }

  void _guncelleMarkerlar() {
    if (_adminKonumu == null) return;

    final Marker adminMarker = Marker(
      markerId: MarkerId("admin_konum"),
      position: LatLng(_adminKonumu!.latitude, _adminKonumu!.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: "Admin Konumu (${_otobusId ?? ''})"),
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "admin_konum");
      _markers.add(adminMarker);
    });
  }

  void _haritayiOrtala() {
    if (_mapController != null && _adminKonumu != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(_adminKonumu!.latitude, _adminKonumu!.longitude), 14),
      );
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _konumTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Konum Takip (${_otobusId ?? ''})"),
        actions: [
          IconButton(
            onPressed: _haritayiOrtala,
            icon: Icon(Icons.my_location),
            tooltip: 'Konumuma Git',
          ),
          if (_adminOtobusIds.length > 1)
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  _otobusId = value;
                  _ogrencileriGetir();
                });
              },
              itemBuilder: (BuildContext context) {
                return _adminOtobusIds.map((String otobusId) {
                  return PopupMenuItem<String>(
                    value: otobusId,
                    child: Text(otobusId),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: _loading || _adminKonumu == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          _adminKonumu!.latitude, _adminKonumu!.longitude),
                      zoom: 14,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _markers,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: _ogrenciMesafeleri.length,
                    itemBuilder: (context, index) {
                      final item = _ogrenciMesafeleri[index];
                      return Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.blueAccent),
                          title: Text(item["ogrenciAdi"]),
                          subtitle: Text(
                              "Otobüs: ${item["otobusNo"]} (${item["otobusId"]})"),
                          trailing: Text("${item["mesafe"]} km",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
