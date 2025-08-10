import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class AdminAnasayfa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildStatsRow(context),
            SizedBox(height: 24),
            _buildRecentReservations(),
            SizedBox(height: 24),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş Geldiniz, Yönetici',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Okul Servis Otobüs Yönetim Paneli',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.directions_bus,
          value: '12',
          label: 'Aktif Otobüs',
          color: Colors.blue,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.people,
          value: '346',
          label: 'Kayıtlı Öğrenci',
          color: Colors.green,
        ),
        SizedBox(width: 16),
        _buildStatCard(
          icon: Icons.today,
          value: '28',
          label: 'Bugünkü Rezervasyon',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Son Rezervasyonlar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildReservationItem(
                studentName: 'Ahmet Yılmaz',
                busNo: '34 ABC 456',
                time: '07:30 - 08:15',
                status: 'Aktif',
                statusColor: Colors.green,
              ),
              Divider(height: 1),
              _buildReservationItem(
                studentName: 'Ayşe Kaya',
                busNo: '34 DEF 789',
                time: '08:00 - 08:45',
                status: 'Tamamlandı',
                statusColor: Colors.blue,
              ),
              Divider(height: 1),
              _buildReservationItem(
                studentName: 'Mehmet Demir',
                busNo: '34 GHI 123',
                time: '07:45 - 08:30',
                status: 'İptal Edildi',
                statusColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationItem({
    required String studentName,
    required String busNo,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: Colors.blue[700]),
      ),
      title: Text(
        studentName,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Otobüs: $busNo'),
          Text('Saat: $time'),
        ],
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(color: statusColor),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildQuickActionCard(
              icon: Icons.add,
              title: 'Yeni Otobüs Ekle',
              color: Colors.blue,
              onTap: () {},
            ),
            _buildQuickActionCard(
              icon: Icons.edit,
              title: 'Otobüs Düzenle',
              color: Colors.green,
              onTap: () {},
            ),
            _buildQuickActionCard(
              icon: Icons.notifications,
              title: 'Duyuru Gönder',
              color: Colors.orange,
              onTap: () {},
            ),
            _buildQuickActionCard(
              icon: Icons.bar_chart,
              title: 'Raporları Görüntüle',
              color: Colors.purple,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}