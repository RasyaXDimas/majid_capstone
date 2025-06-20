import 'package:capstone/widgets/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:capstone/firebase_service.dart'; // Assuming firebase_service.dart is not strictly needed for this page or is part of general setup
import 'package:capstone/data/model.dart';
import 'package:capstone/pages/log_inventaris.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Tambahkan import ini

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String selectedCategoryFilter = 'Semua';
  String selectedStatusFilter = 'Semua';
  String selectedCategory = 'Semua';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _currentAdminName = 'Memuat nama admin...';

  // Method to fetch admin name by email
  Future<void> _fetchCurrentAdminName(String adminEmail) async {
    if (adminEmail.isNotEmpty) {
      try {
        QuerySnapshot adminQuery = await _firestore
            .collection('admins')
            .where('email', isEqualTo: adminEmail)
            .limit(1)
            .get();

        if (mounted) {
          if (adminQuery.docs.isNotEmpty) {
            final adminDoc = adminQuery.docs.first;
            final adminData = adminDoc.data() as Map<String, dynamic>;
            setState(() {
              _currentAdminName = adminData['name'] ?? 'Admin Tanpa Nama';
            });
            print(
                "Nama admin berhasil diambil dari Firestore: $_currentAdminName (berdasarkan email: $adminEmail)");
          } else {
            setState(() {
              _currentAdminName =
                  'Admin Tidak Ditemukan di Firestore (Email: $adminEmail)';
            });
            print(
                "Admin tidak ditemukan di Firestore untuk email: $adminEmail");
          }
        }
      } catch (e) {
        print('Error fetching admin name by email: $e');
        if (mounted) {
          setState(() {
            _currentAdminName = 'Gagal Memuat Nama dari Firestore';
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _currentAdminName = 'Email Admin Tidak Disediakan untuk Pencarian';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAdminDataFromPrefsOrAuth();
  }

  Future<void> _loadAdminDataFromPrefsOrAuth() async {
    if (!mounted) return; // Pastikan widget masih ada di tree

    final prefs = await SharedPreferences.getInstance();
    bool isAdminLoggedInViaPrefs = prefs.getBool('isAdminLoggedIn') ?? false;
    String? adminEmailFromPrefs = prefs.getString('adminEmail');
    // String? adminNameFromPrefs = prefs.getString('adminName'); // Bisa juga diambil jika diperlukan langsung

    print(
        "SharedPreferences: isAdminLoggedIn: $isAdminLoggedInViaPrefs, adminEmail: $adminEmailFromPrefs");

    if (isAdminLoggedInViaPrefs &&
        adminEmailFromPrefs != null &&
        adminEmailFromPrefs.isNotEmpty) {
      print("Menggunakan email dari SharedPreferences: $adminEmailFromPrefs");
      // Jika login via AdminService (Firestore check) dan data ada di SharedPreferences
      await _fetchCurrentAdminName(adminEmailFromPrefs);
    } else if (adminEmailFromPrefs == null || adminEmailFromPrefs.isEmpty) {
      setState(() {
        _currentAdminName =
            'Sesi admin tidak ditemukan. Silakan login kembali.';
      });
      print("Email admin tidak ditemukan di SharedPreferences.");
    }
  }

  // Fungsi untuk mengambil data barang dari Firestore
  Future<List<Barang>> barangInventaris() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('barangInventris')
          .get(); // Note: collection name is 'barangInventris'

      List<Barang> barangList = snapshot.docs.map((doc) {
        return Barang.fromFirestore(doc);
      }).toList();

      return barangList;
    } catch (e) {
      print('Error fetching barang: $e');
      return [];
    }
  }

  // Updated _addLog function to accept adminName (already good)
  Future<void> _addLog(String action, String itemName, String itemId,
      String adminName, String description) async {
    try {
      await FirebaseFirestore.instance.collection('LogInventaris').add({
        'action': action,
        'itemName': itemName,
        'itemId': itemId,
        'adminName':
            _currentAdminName, // This will now use the name fetched by email
        'timestamp': Timestamp.now(),
        'description': description,
      });
    } catch (e) {
      print('Error adding log: $e');
    }
  }

  // Fungsi untuk menambah inventaris baru
  Future<void> tambahInventarisBaru(String name, String category, String status,
      String kondisi, String adminName) async {
    try {
      final inventaris =
          FirebaseFirestore.instance.collection('barangInventris');

      final snapshot =
          await inventaris.orderBy('id', descending: true).limit(1).get();

      int lastNumber = 0;
      if (snapshot.docs.isNotEmpty) {
        String lastId = snapshot.docs.first['id'];
        try {
          lastNumber = int.parse(lastId.replaceAll('INV', ''));
        } catch (e) {
          print("Error parsing lastId $lastId: $e");
          // Handle cases where ID might not be in the expected format
          // For example, query for the highest numeric part if format varies
        }
      }

      int newNumber = lastNumber + 1;
      String newId = 'INV${newNumber.toString().padLeft(3, '0')}';

      await inventaris.doc(newId).set({
        'id': newId,
        'name': name,
        'category': category,
        'status': status,
        'kondisi': kondisi,
      });

      await _addLog(
          'Tambah',
          name,
          newId,
          adminName, // adminName is _currentAdminName
          'Barang baru ditambahkan ke inventaris');
    } catch (e) {
      throw Exception('Gagal menambahkan barang: $e');
    }
  }

  // Fungsi untuk mengupdate inventaris
  Future<void> updateInventaris(String docId, String name, String category,
      String status, String kondisi, String adminName) async {
    try {
      final oldDoc =
          await _firestore.collection('barangInventris').doc(docId).get();
      final oldData = oldDoc.data() as Map<String, dynamic>;

      await _firestore.collection('barangInventris').doc(docId).update({
        'name': name,
        'category': category,
        'status': status,
        'kondisi': kondisi,
      });

      String description = '';

// oldData['name'], oldData['category'], oldData['status'], oldData['kondisi'] are the old values
// name, category, status, kondisi are the new values

// Case 1: All four fields (name, category, status, kondisi) changed
      if (oldData['name'] != name &&
          oldData['category'] != category &&
          oldData['status'] != status &&
          oldData['kondisi'] != kondisi) {
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name", Kategori diubah dari "${oldData['category']}" menjadi "$category", Status diubah menjadi \'$status\', dan Kondisi diubah menjadi \'$kondisi\'';
      }
// Cases 2: Three fields changed
      else if (oldData['name'] != name &&
          oldData['category'] != category &&
          oldData['status'] != status) {
        // kondisi remains the same
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name", Kategori diubah dari "${oldData['category']}" menjadi "$category", dan Status diubah menjadi \'$status\'';
      } else if (oldData['name'] != name &&
          oldData['category'] != category &&
          oldData['kondisi'] != kondisi) {
        // status remains the same
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name", Kategori diubah dari "${oldData['category']}" menjadi "$category", dan Kondisi diubah menjadi \'$kondisi\'';
      } else if (oldData['name'] != name &&
          oldData['status'] != status &&
          oldData['kondisi'] != kondisi) {
        // category remains the same
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name", Status diubah menjadi \'$status\', dan Kondisi diubah menjadi \'$kondisi\'';
      } else if (oldData['category'] != category &&
          oldData['status'] != status &&
          oldData['kondisi'] != kondisi) {
        // name remains the same
        description =
            'Kategori diubah dari "${oldData['category']}" menjadi "$category", Status diubah menjadi \'$status\', dan Kondisi diubah menjadi \'$kondisi\'';
      }
// Cases 3: Two fields changed (original combinations + new ones involving kondisi)
      else if (oldData['name'] != name && oldData['category'] != category) {
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name" dan Kategori diubah dari "${oldData['category']}" menjadi "$category"';
      } else if (oldData['name'] != name && oldData['status'] != status) {
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name" dan Status diubah menjadi \'$status\'';
      } else if (oldData['name'] != name && oldData['kondisi'] != kondisi) {
        // New: name and kondisi changed
        description =
            'Nama diubah dari "${oldData['name']}" menjadi "$name" dan Kondisi diubah menjadi \'$kondisi\'';
      } else if (oldData['category'] != category &&
          oldData['status'] != status) {
        description =
            'Kategori diubah dari "${oldData['category']}" menjadi "$category" dan Status diubah menjadi \'$status\'';
      } else if (oldData['category'] != category &&
          oldData['kondisi'] != kondisi) {
        // New: category and kondisi changed
        description =
            'Kategori diubah dari "${oldData['category']}" menjadi "$category" dan Kondisi diubah menjadi \'$kondisi\'';
      } else if (oldData['status'] != status && oldData['kondisi'] != kondisi) {
        // New: status and kondisi changed
        description =
            'Status diubah menjadi \'$status\' dan Kondisi diubah menjadi \'$kondisi\'';
      }
// Cases 4: Only one field changed
      else if (oldData['name'] != name) {
        description = 'Nama diubah dari "${oldData['name']}" menjadi "$name"';
      } else if (oldData['category'] != category) {
        description =
            'Kategori diubah dari "${oldData['category']}" menjadi "$category"';
      } else if (oldData['status'] != status) {
        description =
            'Status barang \'${name}\' (${oldData['id']}) dirubah menjadi \'$status\'';
      } else if (oldData['kondisi'] != kondisi) {
        // New: only kondisi changed
        description =
            'Kondisi barang \'${name}\' (${oldData['id']}) dirubah menjadi \'$kondisi\'';
      }
// Case 5: No fields changed (or changes not covered above, though this structure aims to be exhaustive)
      else {
        description =
            'Data barang \'${name}\' (${oldData['id']}) diperbarui tanpa perubahan terdeteksi';
      }

      await _addLog(
          oldData['status'] != status ? 'Status' : 'Edit',
          name,
          oldData['id'],
          adminName,
          description); // adminName is _currentAdminName
    } catch (e) {
      throw Exception('Gagal mengupdate barang: $e');
    }
  }

  // Fungsi untuk menghapus inventaris
  Future<void> deleteInventaris(String docId, String adminName) async {
    try {
      final doc =
          await _firestore.collection('barangInventris').doc(docId).get();
      final data = doc.data() as Map<String, dynamic>;

      await _firestore.collection('barangInventris').doc(docId).delete();

      await _addLog(
          'Hapus',
          data['name'],
          data['id'],
          adminName, // adminName is _currentAdminName
          'Barang dihapus dari inventaris');
    } catch (e) {
      throw Exception('Gagal menghapus barang: $e');
    }
  }

  // Fungsi untuk memfilter data berdasarkan kriteria
  List<QueryDocumentSnapshot> getFilteredItems(
      List<QueryDocumentSnapshot> items) {
    return items.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final categoryMatch = selectedCategoryFilter == 'Semua' ||
          data['category'] == selectedCategoryFilter;

      final statusMatch = selectedStatusFilter == 'Semua' ||
          data['status'] == selectedStatusFilter;

      final searchMatch = _searchQuery.isEmpty ||
          data['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          data['id']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          data['category']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return categoryMatch && statusMatch && searchMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(selectedMenu: 'Inventaris'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogInventarisPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Inventaris',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari barang...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // setState(() { // _onSearchChanged handles this
                          //   _searchQuery = '';
                          // });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    _showFilterDialog(context);
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddItemDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Barang'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xff348E9C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Perlengkapan Audio'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Furniture'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Visual Audio'),
                  // Add other categories as needed or fetch dynamically
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('barangInventris')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tidak ada data barang.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allItems = snapshot.data!.docs;
                  final filteredItems = getFilteredItems(allItems);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Ditemukan ${filteredItems.length} item untuk "$_searchQuery"'
                                  : 'Menampilkan ${filteredItems.length} item',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Tidak ditemukan hasil untuk "$_searchQuery"'
                                          : 'Tidak ada item yang sesuai filter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_searchQuery.isNotEmpty ||
                                        selectedCategoryFilter != 'Semua' ||
                                        selectedStatusFilter != 'Semua')
                                      Text(
                                        'Cobalah kata kunci lain atau ubah filter',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    if (_searchQuery.isNotEmpty ||
                                        selectedCategoryFilter != 'Semua' ||
                                        selectedStatusFilter != 'Semua')
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            selectedCategory = 'Semua';
                                            selectedCategoryFilter = 'Semua';
                                            selectedStatusFilter = 'Semua';
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text(
                                            'Reset Filter & Pencarian'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff348E9C),
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredItems[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name = data['name'] ?? 'Tanpa nama';
                                  final id = data['id'] ?? '-';
                                  final category = data['category'] ?? '-';
                                  final status = data['status'] ?? '-';
                                  final kondisi = data['kondisi'] ?? '-';

                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      _showEditItemDialog(
                                                          context, doc);
                                                    },
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      _showDeleteConfirmationDialog(
                                                          context, doc);
                                                    },
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              "Fitur QR Code belum diimplementasikan."),
                                                          backgroundColor:
                                                              Colors
                                                                  .orangeAccent,
                                                        ),
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.qr_code,
                                                      color: Colors.purple,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: $id',
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _buildTag(
                                                  category,
                                                  Colors.grey.shade300,
                                                  Colors.black),
                                              const SizedBox(width: 8),
                                              _buildTag(
                                                status,
                                                status.toLowerCase() ==
                                                        'tersedia'
                                                    ? Colors.green.shade100
                                                    : (status.toLowerCase() ==
                                                            'dipinjam'
                                                        ? Colors.amber.shade100
                                                        : Colors.red.shade100),
                                                status.toLowerCase() ==
                                                        'tersedia'
                                                    ? Colors.green
                                                    : (status.toLowerCase() ==
                                                            'dipinjam'
                                                        ? Colors.orange
                                                        : Colors.red),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildTag(
                                                kondisi,
                                                kondisi.toLowerCase() ==
                                                        'baik'
                                                    ? Colors.green.shade100
                                                    : (kondisi.toLowerCase() ==
                                                            'baru'
                                                        ? Colors.blue.shade100
                                                        : Colors.red.shade100),
                                                kondisi.toLowerCase() ==
                                                        'baik'
                                                    ? Colors.green
                                                    : (kondisi.toLowerCase() ==
                                                            'baru'
                                                        ? Colors.blue
                                                        : Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: textColor),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: selectedCategory == label,
      selectedColor: const Color(0xff348E9C).withOpacity(0.3),
      checkmarkColor: const Color(0xff348E9C),
      onSelected: (_) {
        setState(() {
          selectedCategory = label;
          selectedCategoryFilter = label; // This applies the filter immediately
        });
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    String dialogSelectedCategoryFilter = selectedCategoryFilter;
    String dialogSelectedStatusFilter = selectedStatusFilter;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Barang'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kategori'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: dialogSelectedCategoryFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                      DropdownMenuItem(
                          value: 'Perlengkapan Audio',
                          child: Text('Perlengkapan Audio')),
                      DropdownMenuItem(
                          value: 'Furniture', child: Text('Furniture')),
                      DropdownMenuItem(
                          value: 'Visual Audio', child: Text('Visual Audio')),
                      // Add other categories as needed
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedCategoryFilter = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Status'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: dialogSelectedStatusFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                      DropdownMenuItem(
                          value: 'Tersedia', child: Text('Tersedia')),
                      DropdownMenuItem(
                          value: 'Dipinjam', child: Text('Dipinjam')),
                      DropdownMenuItem(
                          value: 'Tidak Tersedia',
                          child: Text('Tidak Tersedia')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogSelectedStatusFilter = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // No need for setDialogState here as we are applying directly to main state
                    setState(() {
                      selectedCategoryFilter = 'Semua';
                      selectedStatusFilter = 'Semua';
                      selectedCategory =
                          'Semua'; // Also reset the visual chip selection
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategoryFilter = dialogSelectedCategoryFilter;
                      selectedStatusFilter = dialogSelectedStatusFilter;
                      // Update the visual chip selection based on the chosen category filter
                      if (dialogSelectedCategoryFilter != 'Semua' &&
                          ['Perlengkapan Audio', 'Furniture', 'Visual Audio']
                              .contains(dialogSelectedCategoryFilter)) {
                        // Add other valid categories to this list
                        selectedCategory = dialogSelectedCategoryFilter;
                      } else {
                        selectedCategory = 'Semua';
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff348E9C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCategoryDialog = 'Perlengkapan Audio'; // Default category
    String selectedStatusDialog = 'Tersedia';
    String selectedKondisiDialog = 'Baru'; // Default status

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tambah Barang Baru'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Barang'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Kategori'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryDialog,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Perlengkapan Audio',
                          child: Text('Perlengkapan Audio'),
                        ),
                        DropdownMenuItem(
                          value: 'Furniture',
                          child: Text('Furniture'),
                        ),
                        DropdownMenuItem(
                          value: 'Visual Audio',
                          child: Text('Visual Audio'),
                        ),
                        DropdownMenuItem(
                          value: 'Lainnya', // Added Lainnya
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategoryDialog = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Status'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedStatusDialog,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tersedia',
                          child: Text('Tersedia'),
                        ),
                        DropdownMenuItem(
                          value: 'Dipinjam',
                          child: Text('Dipinjam'),
                        ),
                        DropdownMenuItem(
                          value: 'Tidak Tersedia',
                          child: Text('Tidak Tersedia'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatusDialog = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Kondisi Barang'),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedKondisiDialog,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Baru',
                          child: Text('Baru'),
                        ),
                        DropdownMenuItem(
                          value: 'Baik',
                          child: Text('Baik'),
                        ),
                        DropdownMenuItem(
                          value: 'Rusak',
                          child: Text('Rusak'),
                        ),
                        DropdownMenuItem(
                          value: 'Hilang',
                          child: Text('Hilang'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKondisiDialog = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff348E9C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Nama barang tidak boleh kosong"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    try {
                      // _currentAdminName is fetched in initState and updated by _fetchCurrentAdminName
                      await tambahInventarisBaru(
                          name,
                          selectedCategoryDialog,
                          selectedStatusDialog,
                          selectedKondisiDialog,
                          _currentAdminName);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Barang berhasil ditambahkan"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gagal menambahkan barang: $e"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditItemDialog(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    String selectedCategoryDialog =
        data['category'] ?? 'Lainnya'; // Default if null
    String selectedStatusDialog =
        data['status'] ?? 'Tersedia'; // Default if null
    String selectedKondisiDialog = data['kondisi'] ?? 'Baru';

    // Ensure selectedCategoryDialog is a valid option
    const validCategories = [
      'Perlengkapan Audio',
      'Furniture',
      'Visual Audio',
      'Lainnya'
    ];
    if (!validCategories.contains(selectedCategoryDialog)) {
      selectedCategoryDialog = 'Lainnya';
    }
    const validStatuses = ['Tersedia', 'Dipinjam', 'Tidak Tersedia'];
    if (!validStatuses.contains(selectedStatusDialog)) {
      selectedStatusDialog = 'Tersedia';
    }
    const validKondisi = ['Baru', 'Baik', 'Rusak', 'Hilang'];
    if (!validKondisi.contains(selectedKondisiDialog)) {
      selectedKondisiDialog = 'Baru';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.8, // Adjusted max height
                ),
                child: SingleChildScrollView(
                  // Ensure content is scrollable
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Barang',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('ID'),
                        const SizedBox(height: 8),
                        TextField(
                          readOnly: true,
                          controller:
                              TextEditingController(text: data['id'] ?? 'N/A'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Nama Barang'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              // Consistent border
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .hintColor), // Default border
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .primaryColor, // Highlight on focus
                                  width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Kategori'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedCategoryDialog,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8, // Adjusted for Dropdown
                            ),
                          ),
                          items: validCategories.map((String category) {
                            // Use the validCategories list
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedCategoryDialog = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Status'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedStatusDialog,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8, // Adjusted for Dropdown
                            ),
                          ),
                          items: validStatuses.map((String status) {
                            // Use validStatuses list
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedStatusDialog = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Kondisi'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedKondisiDialog,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8, // Adjusted for Dropdown
                            ),
                          ),
                          items: validKondisi.map((String kondisi) {
                            // Use validStatuses list
                            return DropdownMenuItem<String>(
                              value: kondisi,
                              child: Text(kondisi),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedKondisiDialog = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.black54),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final name = nameController.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Nama barang tidak boleh kosong"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await updateInventaris(
                                      doc.id,
                                      name,
                                      selectedCategoryDialog,
                                      selectedStatusDialog,
                                      selectedKondisiDialog,
                                      _currentAdminName); // Use fetched admin name
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Barang berhasil diupdate"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("Gagal mengupdate barang: $e"),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff348E9C),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Simpan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Barang Tanpa Nama';
    final id = data['id'] ?? 'N/A';
    final category = data['category'] ?? 'N/A';
    final status = data['status'] ?? 'N/A';
    final kondisi = data['kondisi'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Konfirmasi Hapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah Anda yakin ingin menghapus barang ini?'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: $id',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Nama: $name'),
                    Text('Kategori: $category'),
                    Text('Status: $status'),
                    Text('Kondisi: $kondisi')
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await deleteInventaris(
                      doc.id, _currentAdminName); // Use fetched admin name
                  Navigator.of(context).pop(); // Close confirmation dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Barang berhasil dihapus"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Close confirmation dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus barang: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
