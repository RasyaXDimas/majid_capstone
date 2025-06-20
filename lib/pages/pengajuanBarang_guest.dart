import 'package:capstone/widgets/drawerGuest.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Extension untuk capitalize string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class PengajuanbarangGuest extends StatelessWidget {
  const PengajuanbarangGuest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waraq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff348E9C),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xff348E9C),
          secondary: const Color(0xff348E9C),
        ),
      ),
      home: const PengajuanBarangPage(),
    );
  }
}

// Model for lending items
class PeminjamanItem {
  final String id;
  final String name;
  final String borrower;
  final String requestDate;
  String status; // Changed to non-final to allow status updates
  bool isReturned; // Added property to track return status
  final String documentId; // Added to track Firestore document ID

  PeminjamanItem({
    required this.id,
    required this.name,
    required this.borrower,
    required this.requestDate,
    required this.status,
    this.isReturned = false, // Default is not returned
    required this.documentId,
  });

  // Factory constructor to create PeminjamanItem from Firestore document
  factory PeminjamanItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Format tanggal dari Firestore timestamp
    String formattedDate = '';
    if (data['tanggalPengajuan'] != null) {
      if (data['tanggalPengajuan'] is Timestamp) {
        DateTime date = (data['tanggalPengajuan'] as Timestamp).toDate();
        formattedDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
      } else {
        formattedDate = data['tanggalPengajuan'].toString();
      }
    }
    
    // Tentukan status pengembalian berdasarkan status dan tanggal pengembalian
    bool isReturned = false;
    String currentStatus = data['status']?.toString().toLowerCase() ?? '';
    
    // Jika status adalah 'dikembalikan', maka item sudah dikembalikan
    if (currentStatus == 'dikembalikan') {
      isReturned = true;
    }
    // Jika ada tanggal pengembalian tapi status belum 'dikembalikan', 
    // berarti sedang menunggu konfirmasi
    else if (data['tanggalPengembalian'] != null && data['tanggalPengembalian'] != 'null') {
      isReturned = false; // Belum benar-benar dikembalikan, masih menunggu konfirmasi admin
    }
    
    return PeminjamanItem(
      id: data['ticketId'] ?? data['idBarang'] ?? '',
      name: data['namaBarang'] ?? '',
      borrower: data['peminjam'] ?? '',
      requestDate: formattedDate,
      status: data['status'] ?? '',
      isReturned: isReturned,
      documentId: doc.id,
    );
  }
  
  // Helper method untuk mengubah angka bulan ke nama bulan
  static String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  // Method to convert PeminjamanItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ticketId': id,
      'namaBarang': name,
      'peminjam': borrower,
      'tanggalPengajuan': requestDate,
      'status': status,
      'tanggalPengembalian': isReturned ? Timestamp.now() : null,
    };
  }
}

// Main Page
class PengajuanBarangPage extends StatefulWidget {
  const PengajuanBarangPage({super.key});

  @override
  State<PengajuanBarangPage> createState() => _PengajuanBarangPageState();
}

class _PengajuanBarangPageState extends State<PengajuanBarangPage> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // List to store items from Firestore
  List<PeminjamanItem> _allItems = [];
  bool _isLoading = true;

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'tertunda', 'disetujui', 'ditolak', 'menunggu konfirmasi pengembalian', 'dikembalikan'];

  @override
  void initState() {
    super.initState();
    _fetchPeminjamanData();
  }

  // Fetch data from Firestore
  Future<void> _fetchPeminjamanData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot snapshot = await _firestore.collection('peminjaman').get();
      
      List<PeminjamanItem> items = snapshot.docs.map((doc) {
        return PeminjamanItem.fromFirestore(doc);
      }).toList();

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update item return status in Firestore
  Future<void> _updateReturnStatus(PeminjamanItem item) async {
    try {
      // Update di Firestore dengan status "Menunggu Konfirmasi Pengembalian"
      await _firestore.collection('peminjaman').doc(item.documentId).update({
        'tanggalPengembalian': Timestamp.now(),
        'status': 'Menunggu Konfirmasi Pengembalian',
      });
      
      // Update local state
      setState(() {
        item.status = 'Menunggu Konfirmasi Pengembalian';
        // Jangan set isReturned = true karena belum dikonfirmasi admin
        item.isReturned = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengembalian ${item.name} telah diajukan! Menunggu konfirmasi admin.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error updating return status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan pengembalian: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Filter items based on selected filter
  List<PeminjamanItem> get _filteredItems {
    if (_selectedFilter == 'Semua') {
      return _allItems;
    } else {
      return _allItems.where((item) => 
        item.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const GuestDrawer(selectedMenu: 'Pengajuan Barang'),
      appBar: AppBar(
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
        title: const Text('Masjid Al-Waraq'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPeminjamanData,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Peminjaman Barang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: _selectedFilter == filter,
                    label: Text(filter == 'Semua' ? filter : filter.capitalize()),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Theme.of(context).primaryColor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: _selectedFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Item List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _fetchPeminjamanData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Muat Ulang'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPeminjamanData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ItemCard(
                              key: Key(item.documentId), // Use document ID as key
                              item: item,
                              onReturnConfirmed: () => _updateReturnStatus(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// Item Card Widget
class ItemCard extends StatefulWidget {
  final PeminjamanItem item;
  final VoidCallback onReturnConfirmed;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onReturnConfirmed,
  }) : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  Color get _statusColor {
    String status = widget.item.status.toLowerCase();
    
    switch (status) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'tertunda':
        return Colors.orange;
      case 'menunggu konfirmasi pengembalian':
        return Colors.purple;
      case 'dikembalikan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color get _cardColor {
    String status = widget.item.status.toLowerCase();
    
    switch (status) {
      case 'disetujui':
        return Colors.green.shade50;
      case 'ditolak':
        return Colors.red.shade50;
      case 'tertunda':
        return Colors.amber.shade50;
      case 'menunggu konfirmasi pengembalian':
        return Colors.purple.shade50;
      case 'dikembalikan':
        return Colors.blue.shade50;
      default:
        return Colors.white;
    }
  }

  IconData get _statusIcon {
    String status = widget.item.status.toLowerCase();
    
    switch (status) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      case 'tertunda':
        return Icons.access_time;
      case 'menunggu konfirmasi pengembalian':
        return Icons.pending_actions;
      case 'dikembalikan':
        return Icons.assignment_returned;
      default:
        return Icons.help;
    }
  }

  String get _displayStatus {
    String status = widget.item.status.toLowerCase();
    
    switch (status) {
      case 'menunggu konfirmasi pengembalian':
        return 'Menunggu Konfirmasi Pengembalian';
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return widget.item.status.capitalize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content column - takes most of the space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.item.borrower,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Permohonan: ${widget.item.requestDate}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(_statusIcon, size: 16, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(
                        _displayStatus,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID Tiket: ${widget.item.id}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Return confirmation button (only for approved items that haven't been returned or are waiting for confirmation)
            if (widget.item.status.toLowerCase() == 'disetujui')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 35
                        ),
                      ),
                      onPressed: () {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi Pengembalian'),
                            content: Text(
                              'Apakah Anda yakin ingin mengajukan pengembalian ${widget.item.name}?\n\nStatus akan berubah menjadi "Menunggu Konfirmasi Pengembalian" dan menunggu admin untuk mengonfirmasi.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  // Close the dialog
                                  Navigator.pop(context);
                                  
                                  // Call the callback to update Firestore
                                  widget.onReturnConfirmed();
                                },
                                child: const Text(
                                  'Ajukan Pengembalian',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Column(
                        children: [
                          Icon(
                            Icons.assignment_return,
                            color: Colors.white,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ajukan\nPengembalian',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}