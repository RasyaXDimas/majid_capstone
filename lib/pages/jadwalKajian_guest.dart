import 'package:capstone/widgets/drawerGuest.dart';
import 'package:flutter/material.dart';

class JadwalPageGuest extends StatefulWidget {
  const JadwalPageGuest({super.key});

  @override
  State<JadwalPageGuest> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPageGuest>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }


  List<Map<String, String>> jadwalKajian = const [
    {
      'judul': 'Memahami Surah Al-Kahfi',
      'hariTanggal': 'Senin, 15 Mei 2025',
      'waktu': '18:30 - 19:30',
      'ustadz': 'Ustadz Abdullah',
    },
    {
      'judul': 'Pentingnya Shalat',
      'hariTanggal': 'Jumat, 19 Mei 2025',
      'waktu': '20:00 - 21:00',
      'ustadz': 'Ustadz Mahmud',
    },
    {
      'judul': 'Kisah Para Nabi',
      'hariTanggal': 'Minggu, 21 Mei 2025',
      'waktu': '10:00 - 11:30',
      'ustadz': 'Ustadz Ibrahim',
    },
    {
      'judul': 'Fiqih Puasa',
      'hariTanggal': 'Rabu, 24 Mei 2025',
      'waktu': '19:30 - 20:30',
      'ustadz': 'Ustadz Muhammad',
    },
  ];

  List<Map<String, String>> jadwalImam = const [
    {
      'sholat': 'Sholat Subuh',
      'waktu': '04:30 AM',
      'ustadz': 'Ustadz Abdullah',
    },
    {
      'sholat': 'Sholat Dhuhr',
      'waktu': '12:30 PM',
      'ustadz': 'Ustadz Mahmud',
    },
    {
      'sholat': 'Sholat Asr',
      'waktu': '03:45 PM',
      'ustadz': 'Ustadz Ibrahim',
    },
    {
      'sholat': 'Sholat Magrib',
      'waktu': '06:15 PM',
      'ustadz': 'Ustadz Muhammad',
    },
    {
      'sholat': 'Sholat Isya',
      'waktu': '07:45 PM',
      'ustadz': 'Ustadz Muhammad',
    },
  ];

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
                  Scaffold.of(context)
                      .openDrawer(); // Ini sekarang akan bekerja
                },
              );
            },
          ),
        ),
        body: Padding(
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
                ],labelStyle: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.builder(
                      itemCount: jadwalKajian.length,
                      itemBuilder: (context, index) {
                        final item = jadwalKajian[index];
                        return _buildCard(
                          title: item['judul']!,
                          subtitle:
                              '${item['hariTanggal']}\n${item['waktu']}\n${item['ustadz']}',
                          data: item,
                        );
                      },
                    ),
                    ListView.builder(
                      itemCount: jadwalImam.length,
                      itemBuilder: (context, index) {
                        final item = jadwalImam[index];
                        return _buildCard(
                          title: item['sholat']!,
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
    );
  }

  Widget _buildCard({
  required String title,
  required String subtitle,
  required Map<String, String> data,
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
