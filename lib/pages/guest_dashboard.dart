import 'package:capstone/pages/jadwalKajian_guest.dart';
import 'package:capstone/pages/pengajuanBarang_guest.dart';
import 'package:capstone/widgets/drawerGuest.dart';
import 'package:capstone/data/model.dart' as Models;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestDashboard extends StatelessWidget {
  const GuestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waqar',
      theme: ThemeData(
        primaryColor: const Color(0xff348E9C),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xff348E9C),
          secondary: const Color(0xFF2A9D8F),
        ),
      ),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const GuestDrawer(selectedMenu: 'Dashboard'),
      appBar: AppBar(
        title: const Text(
          'Masjid Al-Waqar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff348E9C),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Ini sekarang akan bekerja
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),
              // Peminjaman Barang Card
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('peminjaman')
                    .where('status', isEqualTo: 'disetujui')
                    .snapshots(),
                builder: (context, snapshot) {
                  int approvedCount = 0;
                  if (snapshot.hasData) {
                    // Convert documents to PeminjamanItem objects and count approved ones
                    final peminjamanList = snapshot.data!.docs
                        .map((doc) => Models.PeminjamanItem.fromFirestore(doc))
                        .where((item) => item.status == 'Disetujui')
                        .toList();
                    approvedCount = peminjamanList.length;
                  }
                  
                  return _buildDashboardCard(
                    context,
                    title: 'Peminjaman Barang',
                    subtitle: 'Disetujui : $approvedCount',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PengajuanbarangGuest()),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Jadwal Kajian Card
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('kajian')
                    .orderBy('tanggal', descending: false)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  String scheduleInfo = 'Tidak ada jadwal';
                  
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    // Convert document to Kajian object using the model
                    final kajian = Models.Kajian.fromFirestore(snapshot.data!.docs.first);
                    
                    // Format tanggal dan waktu menggunakan data dari model
                    var date = kajian.tanggal;
                    var dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
                    var monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                    
                    var dayName = dayNames[date.weekday % 7];
                    var day = date.day;
                    var month = monthNames[date.month - 1];
                    var year = date.year;
                    var hour = date.hour.toString().padLeft(2, '0');
                    var minute = date.minute.toString().padLeft(2, '0');
                    
                    scheduleInfo = '$dayName, $day $month $year\n$hour:$minute - Ustadz ${kajian.ustadz}\n${kajian.judul}';
                  }
                  
                  return _buildDashboardCard(
                    context,
                    title: 'Jadwal Kajian',
                    subtitle: scheduleInfo,
                    icon: Icons.calendar_today,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const JadwalPageGuest()));
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Pengumuman Card
              _buildDashboardCard(
                context,
                title: 'Pengumuman',
                subtitle: '',
                icon: Icons.campaign,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}