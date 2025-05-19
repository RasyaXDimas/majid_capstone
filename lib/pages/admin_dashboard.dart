import 'package:capstone/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/drawer.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    // Cek apakah user sudah login, kalau belum arahkan ke SignInPage
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(selectedMenu: 'dashboard'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff348E9C),
        title: const Text('Masjid Al-Waraq'),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Ini sekarang akan bekerja
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                children: [
                  _buildDashboardItem(
                    icon: Icons.inventory,
                    title: 'Total Barang',
                    value: '125',
                    color: Colors.teal.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.book,
                    title: 'Jumlah Kajian\nBulan Ini',
                    value: '14',
                    color: Colors.purple.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.volunteer_activism,
                    title: 'Donasi Terkumpul',
                    value: 'Rp 5JT',
                    color: Colors.orange.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.shopping_basket,
                    title: 'Barang Dipinjam',
                    value: '15',
                    color: Colors.blue.shade50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Notifikasi Terkini'),
            const SizedBox(height: 12),
            _buildNotificationItem(
              title: 'Permohonan Peminjaman Baru',
              subtitle: 'Ahmad ingin melakukan peminjaman\n10 menit yang lalu',
              color: Colors.orange.shade50,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
            ),
            _buildNotificationItem(
              title: 'Pengembalian Barang Terlewat',
              subtitle: 'Speaker belum dikembalikan oleh Umar\n2 jam yang lalu',
              color: Colors.red.shade50,
              icon: Icons.error,
              iconColor: Colors.red,
            ),
            _buildNotificationItem(
              title: 'Donasi Baru',
              subtitle: 'Fatimah melakukan donasi Rp 500.000\n1 hari yang lalu',
              color: Colors.green.shade50,
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Jadwal Kajian Hari Ini'),
            const SizedBox(height: 12),
            _buildScheduleItem(
              time: '05:30 - 06:30',
              topic: 'Sholat Subuh dan Bacaan Al Quran Pagi',
              ustadz: 'Ustadz Abdullah',
            ),
            _buildScheduleItem(
              time: '18:30 - 19:30',
              topic: 'Memahami Surah Al-Kahfi',
              ustadz: 'Ustadz Mahmud',
            ),
            _buildScheduleItem(
              time: '20:00 - 21:00',
              topic: 'Sholat Subuh dan Bacaan Al Quran Pagi',
              ustadz: 'Ustadz Ibrahim',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 35, color: Colors.teal),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String topic,
    required String ustadz,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(topic),
                const SizedBox(height: 2),
                Text(
                  ustadz,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
