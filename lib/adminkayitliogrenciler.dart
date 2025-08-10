// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class AdminKayitliOgrenciler extends StatelessWidget {
//   const AdminKayitliOgrenciler({super.key});
//
//   Future<List<String>> _getAdminBuses() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return [];
//
//       final query = await FirebaseFirestore.instance
//           .collection('otobusler')
//           .where('adminId', isEqualTo: user.uid)
//           .get();
//
//       return query.docs.map((doc) => doc.id).toList();
//     } catch (e) {
//       debugPrint('Hata: $e');
//       return [];
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Kayıtlı Öğrenciler'),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: FutureBuilder<List<String>>(
//         future: _getAdminBuses(),
//         builder: (context, busesSnapshot) {
//           if (busesSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (busesSnapshot.hasError) {
//             return Center(child: Text('Hata: ${busesSnapshot.error}'));
//           }
//
//           if (busesSnapshot.data == null || busesSnapshot.data!.isEmpty) {
//             return _buildEmptyState('Eklediğiniz otobüs bulunamadı');
//           }
//
//           final adminBusIds = busesSnapshot.data!;
//           return _buildReservationsList(adminBusIds);
//         },
//       ),
//     );
//   }
//
//   Widget _buildReservationsList(List<String> adminBusIds) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('rezervasyonlar')
//           .where('otobusId', whereIn: adminBusIds)
//           .orderBy('rezervasyonTarihi', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Hata: ${snapshot.error}'));
//         }
//
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final reservations = snapshot.data?.docs ?? [];
//         if (reservations.isEmpty) {
//           return _buildEmptyState('Kayıtlı öğrenci bulunamadı');
//         }
//
//         return ListView.builder(
//           padding: const EdgeInsets.only(top: 12, bottom: 24),
//           itemCount: reservations.length,
//           itemBuilder: (context, index) {
//             return _buildStudentCard(reservations[index], context);
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildStudentCard(DocumentSnapshot doc, BuildContext context) {
//     final data = doc.data() as Map<String, dynamic>;
//     final date = _formatDate(data['rezervasyonTarihi'] as Timestamp?);
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Card(
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => _showStudentDetails(doc, context),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 20,
//                       backgroundColor: Colors.blue[50],
//                       child: Text(
//                         data['ogrenciAdi']?.isNotEmpty == true
//                             ? data['ogrenciAdi'][0].toUpperCase()
//                             : '?',
//                         style: TextStyle(
//                           color: Colors.blue[700],
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             data['ogrenciAdi']?.toString().toUpperCase() ?? 'İSİMSİZ ÖĞRENCİ',
//                             style: const TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             date,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       Icons.chevron_right,
//                       color: Colors.grey[400],
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 _buildInfoItem(Icons.school, 'Öğrenci No:', data['ogrenciko']),
//                 _buildInfoItem(Icons.location_city, 'Şehir:', data['sehir']),
//                 _buildInfoItem(Icons.pin_drop, 'İlçe:', data['ilce']),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoItem(IconData icon, String label, String? value) {
//     if (value == null || value.isEmpty) return const SizedBox.shrink();
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: 18,
//             color: Colors.blueGrey[300],
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.group_off,
//             size: 48,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDate(Timestamp? timestamp) {
//     if (timestamp == null) return 'Tarih belirtilmemiş';
//
//     final date = timestamp.toDate();
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
//
//   void _showStudentDetails(DocumentSnapshot doc, BuildContext context) {
//     final data = doc.data() as Map<String, dynamic>;
//     final date = _formatDate(data['rezervasyonTarihi'] as Timestamp?);
//
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Öğrenci Detayları',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildDetailRow('Ad Soyad:', data['ogrenciAdi'] ?? 'Belirtilmemiş'),
//               _buildDetailRow('Öğrenci No:', data['ogrenciNo'] ?? 'Belirtilmemiş'),
//               _buildDetailRow('Otobüs No:', data['otobusNo'] ?? 'Belirtilmemiş'),
//               _buildDetailRow('Plaka:', data['plaka'] ?? 'Belirtilmemiş'),
//               _buildDetailRow('Rezervasyon Tarihi:', date),
//               if (data['telefon'] != null) _buildDetailRow('Telefon:', data['telefon']),
//               if (data['userEmail'] != null) _buildDetailRow('Email:', data['userEmail']),
//               if (data['sehir'] != null) _buildDetailRow('Şehir:', data['sehir']),
//               if (data['ilce'] != null) _buildDetailRow('İlçe:', data['ilce']),
//               if (data['locationText'] != null) _buildDetailRow('Konum:', data['locationText']),
//               const SizedBox(height: 20),
//               Center(
//                 child: TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('KAPAT'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminKayitliOgrenciler extends StatelessWidget {
  const AdminKayitliOgrenciler({super.key});

  Future<List<String>> _getAdminBuses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final query = await FirebaseFirestore.instance
          .collection('otobusler')
          .where('adminId', isEqualTo: user.uid)
          .get();

      return query.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Hata: $e');
      return [];
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Tarih belirtilmemiş';

    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Kayıtlı Öğrenciler',
        style: TextStyle(fontWeight: FontWeight.w600)),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.blue[700],
    foregroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
    bottom: Radius.circular(16),
    ),
    ) ),
    body: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF5F9FF)],
    ),
    ),
    child: FutureBuilder<List<String>>(
    future: _getAdminBuses(),
    builder: (context, busesSnapshot) {
    if (busesSnapshot.connectionState == ConnectionState.waiting) {
    return Center(
    child: CircularProgressIndicator(
    color: Colors.blue[700],
    strokeWidth: 2.5,
    ),
    );
    }

    if (busesSnapshot.hasError) {
    return Center(
    child: Text('Hata: ${busesSnapshot.error}',
    style: TextStyle(color: Colors.red[700])),
    );
    }

    if (busesSnapshot.data == null || busesSnapshot.data!.isEmpty) {
    return _buildEmptyState('Eklediğiniz otobüs bulunamadı');
    }

    final adminBusIds = busesSnapshot.data!;
    return _buildReservationsList(adminBusIds);
    },
    ),
    ));
  }

  Widget _buildReservationsList(List<String> adminBusIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rezervasyonlar')
          .where('otobusId', whereIn: adminBusIds)
          .orderBy('rezervasyonTarihi', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}',
                style: TextStyle(color: Colors.red[700])),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.blue[700],
              strokeWidth: 2.5,
            ),
          );
        }

        final reservations = snapshot.data?.docs ?? [];
        if (reservations.isEmpty) {
          return _buildEmptyState('Kayıtlı öğrenci bulunamadı');
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            return _buildStudentCard(reservations[index], context);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final date = _formatDate(data['rezervasyonTarihi'] as Timestamp?);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStudentDetails(doc, context),
          splashColor: Colors.blue[50],
          highlightColor: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          data['ogrenciAdi']?.isNotEmpty == true
                              ? data['ogrenciAdi'][0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['ogrenciAdi']?.toString().toUpperCase() ?? 'İSİMSİZ ÖĞRENCİ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[500],
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoItem(Icons.school_outlined, 'Öğrenci No:', data['ogrenciko']),
                _buildInfoItem(Icons.location_city_outlined, 'Şehir:', data['sehir']),
                _buildInfoItem(Icons.pin_drop_outlined, 'İlçe:', data['ilce']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_outlined,
            size: 56,
            color: Colors.blue[200],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final date = _formatDate(data['rezervasyonTarihi'] as Timestamp?);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Öğrenci Detayları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Ad Soyad:', data['ogrenciAdi'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Öğrenci No:', data['ogrenciNo'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Otobüs No:', data['otobusNo'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Plaka:', data['plaka'] ?? 'Belirtilmemiş'),
              _buildDetailRow('Rezervasyon Tarihi:', date),
              if (data['telefon'] != null) _buildDetailRow('Telefon:', data['telefon']),
              if (data['userEmail'] != null) _buildDetailRow('Email:', data['userEmail']),
              if (data['sehir'] != null) _buildDetailRow('Şehir:', data['sehir']),
              if (data['ilce'] != null) _buildDetailRow('İlçe:', data['ilce']),
              if (data['locationText'] != null) _buildDetailRow('Konum:', data['locationText']),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('KAPAT',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}