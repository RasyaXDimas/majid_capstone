import 'package:capstone/widgets/drawerGuest.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalPageGuest extends StatefulWidget {
  const JadwalPageGuest({super.key});

  @override
  State<JadwalPageGuest> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPageGuest>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State variables untuk menyimpan data dari Firestore
  List<Map<String, dynamic>> jadwalKajian = [];
  List<Map<String, dynamic>> jadwalImam = [];
  bool isLoadingKajian = true;
  bool isLoadingImam = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchJadwalKajian();
    _fetchJadwalImam();
  }

  // Fungsi untuk mengambil data jadwal kajian dari Firestore
  Future<void> _fetchJadwalKajian() async {
    try {
      setState(() {
        isLoadingKajian = true;
      });

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('kajian')
          .orderBy('tanggal', descending: false)
          .get();

      List<Map<String, dynamic>> kajianList = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Konversi Timestamp ke String yang readable
        String formattedDate = '';
        if (data['tanggal'] != null) {
          Timestamp timestamp = data['tanggal'];
          DateTime dateTime = timestamp.toDate();
          
          // Format tanggal sesuai dengan format yang diinginkan
          List<String> days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
          List<String> months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                                'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
          
          String dayName = days[dateTime.weekday % 7];
          String monthName = months[dateTime.month];
          
          formattedDate = '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
        }

        kajianList.add({
          'id': doc.id,
          'judul': data['judul'] ?? '',
          'hariTanggal': formattedDate,
          'waktu': _formatWaktu(data['tanggal']),
          'ustadz': data['ustadz'] ?? '',
          'rawTimestamp': data['tanggal'],
        });
      }

      setState(() {
        jadwalKajian = kajianList;
        isLoadingKajian = false;
      });
    } catch (e) {
      print('Error fetching kajian data: $e');
      setState(() {
        isLoadingKajian = false;
      });
    }
  }

  // Fungsi untuk mengambil data jadwal imam dari Firestore
  Future<void> _fetchJadwalImam() async {
    try {
      setState(() {
        isLoadingImam = true;
      });

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('jadwalImam')
          .get();

      List<Map<String, dynamic>> imamList = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        imamList.add({
          'id': doc.id,
          'sholat': data['jadwalSholat'] ?? '',
          'waktu': data['waktu'] ?? '',
          'ustadz': data['ustadz'] ?? '',
        });
      }

      // Urutkan berdasarkan urutan sholat
      List<String> urutanSholat = ['sholat subuh', 'sholat dhuhr', 'sholat asr', 'sholat maghrib', 'sholat isya'];
      imamList.sort((a, b) {
        int indexA = urutanSholat.indexWhere((sholat) => 
            a['sholat'].toString().toLowerCase().contains(sholat.split(' ')[1]));
        int indexB = urutanSholat.indexWhere((sholat) => 
            b['sholat'].toString().toLowerCase().contains(sholat.split(' ')[1]));
        
        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;
        
        return indexA.compareTo(indexB);
      });

      setState(() {
        jadwalImam = imamList;
        isLoadingImam = false;
      });
    } catch (e) {
      print('Error fetching imam data: $e');
      setState(() {
        isLoadingImam = false;
      });
    }
  }

  // Fungsi helper untuk format waktu dari Timestamp
  String _formatWaktu(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    DateTime dateTime = timestamp.toDate();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute - ${(dateTime.hour + 1).toString().padLeft(2, '0')}:$minute';
  }

  // Fungsi untuk refresh data
  Future<void> _refreshData() async {
    await Future.wait([
      _fetchJadwalKajian(),
      _fetchJadwalImam(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const GuestDrawer(selectedMenu: 'Kajian & Imam'),
        backgroundColor: const Color(0xffF4F4F4),
        appBar: AppBar(
          backgroundColor: const Color(0xff348E9C),
          title: const Text('Masjid Al-Waraq'),
          centerTitle: true,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Jadwal Kajian & Imam',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: Color(0xff348E9C),
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Color(0xff348E9C),
                  tabs: const [
                    Tab(text: 'Jadwal Kajian'),
                    Tab(text: 'Jadwal Imam'),
                  ],
                  labelStyle: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Jadwal Kajian
                      isLoadingKajian
                          ? const Center(child: CircularProgressIndicator())
                          : jadwalKajian.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada jadwal kajian tersedia',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: jadwalKajian.length,
                                  itemBuilder: (context, index) {
                                    final item = jadwalKajian[index];
                                    return _buildCard(
                                      title: item['judul'] ?? '',
                                      subtitle:
                                          '${item['hariTanggal']}\n${item['waktu']}\n${item['ustadz']}',
                                      data: item,
                                    );
                                  },
                                ),
                      // Tab Jadwal Imam
                      isLoadingImam
                          ? const Center(child: CircularProgressIndicator())
                          : jadwalImam.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Tidak ada jadwal imam tersedia',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: jadwalImam.length,
                                  itemBuilder: (context, index) {
                                    final item = jadwalImam[index];
                                    return _buildCard(
                                      title: item['sholat'] ?? '',
                                      subtitle: '${item['waktu']}\n${item['ustadz']}',
                                      data: item,
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Map<String, dynamic> data,
  }) {
    return Card(
      // Menambahkan padding di sekitar card
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Mempertahankan sudut melengkung
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        // Menambahkan padding di dalam card
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul dengan ukuran font lebih besar
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle dengan ukuran font yang lebih besar
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}