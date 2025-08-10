import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KullaniciRota extends StatefulWidget {
  @override
  _KullaniciRotaState createState() => _KullaniciRotaState();
}

class _KullaniciRotaState extends State<KullaniciRota> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _otobusler = [];
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _loading = true;
  String _hataMesaji = '';
  LatLng? _rezervasyonKonumu;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    try {
      setState(() {
        _loading = true;
        _hataMesaji = '';
        _otobusler.clear();
      });

      final user = _auth.currentUser;
      if (user == null) throw Exception('Giriş yapılmamış');

      await _rezervasyonBilgileriniGetir(user.uid);
      await _soforKonumlariniGetir();

      setState(() {
        _loading = false;
      });

    } catch (e) {
      setState(() {
        _loading = false;
        _hataMesaji = 'Hata: ${e.toString()}';
      });
    }
  }

  Future<void> _rezervasyonBilgileriniGetir(String userId) async {
    final rezervasyonQuery = await _firestore
        .collection('rezervasyonlar')
        .where('userId', isEqualTo: userId)
        .get();

    if (rezervasyonQuery.docs.isEmpty) {
      throw Exception('Rezervasyon bulunamadı');
    }

    for (var doc in rezervasyonQuery.docs) {
      final data = doc.data();
      final geoPoint = data['location'] as GeoPoint?;

      if (geoPoint != null && data['otobusId'] != null) {
        setState(() {
          _rezervasyonKonumu = LatLng(geoPoint.latitude, geoPoint.longitude);
          _otobusler.add({
            'otobusId': data['otobusId'],
            'otobusNo': data['otobusNo'] ?? 'Belirtilmemiş',
            'plaka': data['plaka'] ?? 'Belirtilmemiş',
            'rezervasyonKonumu': _rezervasyonKonumu,
          });
        });
      }
    }
  }

  Future<void> _soforKonumlariniGetir() async {
    for (var otobus in _otobusler) {
      final otobusId = otobus['otobusId'];

      final adminQuery = await _firestore
          .collection('admin_konumlar')
          .where('otobusId', isEqualTo: otobusId)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        final adminData = adminQuery.docs.first.data();
        final adminLat = adminData['latitude'] as double?;
        final adminLng = adminData['longitude'] as double?;

        if (adminLat != null && adminLng != null) {
          final soforKonumu = LatLng(adminLat, adminLng);
          final distance = _rezervasyonKonumu != null
              ? Geolocator.distanceBetween(
            _rezervasyonKonumu!.latitude,
            _rezervasyonKonumu!.longitude,
            adminLat,
            adminLng,
          ) / 1000
              : null;

          setState(() {
            otobus['soforKonumu'] = soforKonumu;
            otobus['soforAdi'] = adminData['adminAdi'] ?? 'Şoför';
            otobus['mesafe'] = distance;
          });
        }
      }
    }
  }

  void _haritayiGuncelle(int index) {
    if (index >= _otobusler.length) return;

    _markers.clear();
    final otobus = _otobusler[index];

    if (otobus['rezervasyonKonumu'] != null) {
      _markers.add(Marker(
        markerId: MarkerId('rezervasyon'),
        position: otobus['rezervasyonKonumu'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Rezervasyon Konumunuz'),
      ));
    }

    if (otobus['soforKonumu'] != null) {
      _markers.add(Marker(
        markerId: MarkerId('sofor_${otobus['otobusId']}'),
        position: otobus['soforKonumu'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: '${otobus['otobusNo']} - ${otobus['soforAdi']}',
          snippet: 'Mesafe: ${otobus['mesafe']?.toStringAsFixed(2) ?? '--'} km',
        ),
      ));
    }

    if (otobus['rezervasyonKonumu'] != null && otobus['soforKonumu'] != null) {
      _haritayiOrtala(otobus['rezervasyonKonumu'], otobus['soforKonumu']);
    }
  }

  void _haritayiOrtala(LatLng konum1, LatLng konum2) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        min(konum1.latitude, konum2.latitude),
        min(konum1.longitude, konum2.longitude),
      ),
      northeast: LatLng(
        max(konum1.latitude, konum2.latitude),
        max(konum1.longitude, konum2.longitude),
      ),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Otobüs Takip Sistemi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _verileriYukle,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _hataMesaji.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 10),
            Text(
              _hataMesaji,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verileriYukle,
              child: Text('Yenile'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _rezervasyonKonumu ?? LatLng(0, 0),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_otobusler.isNotEmpty) {
                  _haritayiGuncelle(_selectedIndex);
                }
              },
              markers: _markers,
              myLocationEnabled: false,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Rezervasyonlarım',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _otobusler.length,
                    itemBuilder: (context, index) {
                      final otobus = _otobusler[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 3,
                        color: _selectedIndex == index
                            ? Colors.blue[50]
                            : Colors.white,
                        child: ListTile(
                          leading: Icon(Icons.directions_bus,
                              color: Colors.blue),
                          title: Text(
                            'Otobüs: ${otobus['otobusNo']}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plaka: ${otobus['plaka']}'),
                              Text(
                                'Mesafe: ${otobus['mesafe']?.toStringAsFixed(2) ?? '--'} km',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              _haritayiGuncelle(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}