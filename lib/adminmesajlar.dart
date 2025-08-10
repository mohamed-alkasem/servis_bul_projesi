import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminMesajlar extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _maskEmail(String email) {
    if (email.isEmpty) return 'Anonim';
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];
    final maskedUsername = username.length > 2
        ? '${username.substring(0, 2)}${'*' * (username.length - 2)}'
        : '${'*' * username.length}';

    return '$maskedUsername@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final currentAdminId = _auth.currentUser?.uid;

    if (currentAdminId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Gelen Mesajlar')),
        body: Center(child: Text('Lütfen giriş yapınız')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gelen Mesajlar'),
        backgroundColor: Colors.blue[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages')
            .where('adminId', isEqualTo: currentAdminId) // Sadece bu admin'e gelen mesajlar
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Gelen mesaj bulunamadı'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final message = snapshot.data!.docs[index];
              final data = message.data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                margin: EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  title: Text(
                    data['message'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text(
                        'Gönderen: ${_maskEmail(data['userEmail'] ?? 'Anonim')}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Otobüs: ${data['busNo'] ?? 'Belirtilmemiş'}',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    data['isRead'] == true ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: data['isRead'] == true ? Colors.green : Colors.red,
                  ),
                  onTap: () {
                    _showMessageDetail(context, message);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMessageDetail(BuildContext context, DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;

    // İşaretleme okundu olarak
    if (data['isRead'] != true) {
      message.reference.update({'isRead': true});
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mesaj Detayı'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data['message'],
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Divider(),
              Text(
                'Gönderen: ${_maskEmail(data['userEmail'] ?? 'Anonim')}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Ad Soyad: ${data['userName'] ?? 'Belirtilmemiş'}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Telefon: ${data['userPhone'] ?? 'Belirtilmemiş'}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Otobüs: ${data['busNo'] ?? 'Belirtilmemiş'}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format((data['timestamp'] as Timestamp).toDate())}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Kapat'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}