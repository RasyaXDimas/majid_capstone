import 'package:capstone/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';
// Tambahkan dependency ini

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late StreamSubscription<User?> _authSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data variables
  int totalBarang = 0;
  int barangDipinjam = 0;
  int totalKajianBulanIni = 0;
  double totalDonasi = 0.0;
  List<Map<String, dynamic>> recentNotifications = [];
  List<Map<String, dynamic>> todayKajian = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _setupAuthListener();
    _fetchAllData();
  }

  Future<bool> loginAdmin(String email, String password) async {
    final firestore = FirebaseFirestore.instance;

    final querySnapshot = await firestore
        .collection('admins')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) return false;

    final adminDoc = querySnapshot.docs.first;
    final storedHashedPassword = adminDoc['password'];

    final bool isValid = BCrypt.checkpw(password, storedHashedPassword);
    if (!isValid) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminId', adminDoc.id);
    return true;
  }

  // MODIFIED: Check both Firebase Auth and custom auth state
  void _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isLoggedInFirestore = prefs.getBool('isAdminLoggedIn') ?? false;

    // Jika tidak ada Firebase user DAN tidak ada session Firestore
    if (user == null && !isLoggedInFirestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToSignIn();
      });
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('adminId');
  }

  // MODIFIED: Setup auth listener that considers both auth methods
  void _setupAuthListener() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null && mounted) {
        // Check if user is logged in via Firestore
        final prefs = await SharedPreferences.getInstance();
        final isLoggedInFirestore = prefs.getBool('isAdminLoggedIn') ?? false;

        // Only navigate to sign in if both auth methods are null/false
        if (!isLoggedInFirestore) {
          _navigateToSignIn();
        }
      }
    });
  }

  void _navigateToSignIn() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  // Method untuk logout yang membersihkan semua session
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdminLoggedIn');
    await prefs.remove('adminEmail');
    await prefs.remove('adminName');

    // Juga logout dari Firebase Auth jika ada
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    if (mounted) {
      _navigateToSignIn();
    }
  }

  // Fetch all data from Firestore
  Future<void> _fetchAllData() async {
    try {
      setState(() {
        isLoading = true;
      });

      await Future.wait([
        _fetchBarangInventris(),
        _fetchPeminjaman(),
        _fetchKajian(),
        _fetchDonasi(),
        _fetchKajianHariIni(),
      ]);

      _generateNotifications();
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fetch Barang Inventris
  Future<void> _fetchBarangInventris() async {
    try {
      final snapshot = await _firestore.collection('barangInventris').get();
      setState(() {
        totalBarang = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching barang inventris: $e');
    }
  }

  // Fetch Peminjaman
  Future<void> _fetchPeminjaman() async {
    try {
      final snapshot = await _firestore
          .collection('barangInventris')
          .where('status', isEqualTo: 'Dipinjam')
          .get();
      if (mounted) {
        setState(() {
          barangDipinjam = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error fetching barang dipinjam from inventaris: $e');
      if (mounted) {
        setState(() {
          barangDipinjam = 0;
        });
      }
    }
  }

  // Fetch Kajian (this month)
  Future<void> _fetchKajian() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection('kajian')
          .where('tanggal',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      setState(() {
        totalKajianBulanIni = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching kajian: $e');
    }
  }

  // Fetch Donasi
  Future<void> _fetchDonasi() async {
    try {
      final snapshot = await _firestore.collection('donasi').get();
      double total = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['amount'] != null) {
          total += (data['amount'] as num).toDouble();
        }
      }

      setState(() {
        totalDonasi = total;
      });
    } catch (e) {
      print('Error fetching donasi: $e');
    }
  }

  // Fetch Kajian for today
  Future<void> _fetchKajianHariIni() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('kajian')
          .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('tanggal', isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy('tanggal')
          .get();

      List<Map<String, dynamic>> kajianList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        kajianList.add({
          'time': _formatTime(data['tanggal'] as Timestamp),
          'judul': data['judul'] ?? 'Kajian',
          'ustadz': data['ustadz'] ?? 'Ustadz',
        });
      }

      setState(() {
        todayKajian = kajianList;
      });
    } catch (e) {
      print('Error fetching kajian hari ini: $e');
    }
  }

  // Generate notifications based on data
  void _generateNotifications() {
    List<Map<String, dynamic>> notifications = [];

    if (barangDipinjam > 0) {
      notifications.add({
        'title': 'Barang Dipinjam',
        'subtitle':
            '$barangDipinjam barang sedang dipinjam\nPeriksa status peminjaman',
        'color': Colors.orange.shade50,
        'icon': Icons.warning_amber_rounded,
        'iconColor': Colors.orange,
      });
    }

    if (totalDonasi > 0) {
      notifications.add({
        'title': 'Total Donasi Terkumpul',
        'subtitle':
            'Rp ${_formatCurrency(totalDonasi)}\nDonasi dari para jamaah',
        'color': Colors.green.shade50,
        'icon': Icons.check_circle,
        'iconColor': Colors.green,
      });
    }

    if (totalKajianBulanIni > 0) {
      notifications.add({
        'title': 'Kajian Bulan Ini',
        'subtitle':
            '$totalKajianBulanIni kajian telah terjadwal\nPastikan persiapan sudah lengkap',
        'color': Colors.blue.shade50,
        'icon': Icons.book,
        'iconColor': Colors.blue,
      });
    }

    setState(() {
      recentNotifications = notifications;
    });
  }

  String _formatTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}JT';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        drawer: const DashboardDrawer(selectedMenu: 'dashboard'),
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff348E9C),
          title: const Text(
            'Masjid Al-Waraq',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          // TAMBAHKAN: Logout button di AppBar
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
        body:
            _buildDashboardContent(), // SIMPLIFIED: Remove StreamBuilder wrapper
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff348E9C)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    title: 'Total\nBarang',
                    value: totalBarang.toString(),
                    color: Colors.teal.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.book,
                    title: 'Kajian\nBulan Ini',
                    value: totalKajianBulanIni.toString(),
                    color: Colors.purple.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.volunteer_activism,
                    title: 'Donasi\nTerkumpul',
                    value: 'Rp ${_formatCurrency(totalDonasi)}',
                    color: Colors.orange.shade50,
                  ),
                  _buildDashboardItem(
                    icon: Icons.shopping_basket,
                    title: 'Barang\nDipinjam',
                    value: barangDipinjam.toString(),
                    color: Colors.blue.shade50,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Notifikasi Terkini'),
            const SizedBox(height: 12),
            if (recentNotifications.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada notifikasi terbaru',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentNotifications
                  .map((notification) => _buildNotificationItem(
                        title: notification['title'],
                        subtitle: notification['subtitle'],
                        color: notification['color'],
                        icon: notification['icon'],
                        iconColor: notification['iconColor'],
                      )),
            const SizedBox(height: 24),
            _buildSectionTitle('Jadwal Kajian Hari Ini'),
            const SizedBox(height: 12),
            if (todayKajian.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada jadwal kajian hari ini',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...todayKajian.map((kajian) => _buildKajianItem(
                    time: kajian['time'],
                    judul: kajian['judul'],
                    ustadz: kajian['ustadz'],
                  )),
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
          const SizedBox(width: 8),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
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

  Widget _buildKajianItem({
    required String time,
    required String judul,
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
          const Icon(Icons.school, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(judul),
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
