import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/data/model.dart';

class PeminjamanBarang extends StatelessWidget {
  const PeminjamanBarang({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waraq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF26A69A),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF26A69A),
          secondary: const Color(0xFF26A69A),
        ),
      ),
      home: const PeminjamanBarangPage(),
    );
  }
}

// Main Page
class PeminjamanBarangPage extends StatefulWidget {
  const PeminjamanBarangPage({super.key});

  @override
  State<PeminjamanBarangPage> createState() => _PeminjamanBarangPageState();
}

class _PeminjamanBarangPageState extends State<PeminjamanBarangPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Tertunda',
    'Disetujui',
    'Ditolak',
    'Menunggu Konfirmasi Pengembalian',
    'Dikembalikan'
  ];

  // Stream for real-time data - Fixed to avoid index error
  Stream<List<PeminjamanItem>> _getPeminjamanStream() {
    return _firestore
        .collection('peminjaman')
        .orderBy('tanggalPengajuan', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PeminjamanItem.fromFirestore(doc))
          .toList();
    });
  }

  // Filter items based on selected filter
  List<PeminjamanItem> _filterItems(List<PeminjamanItem> items) {
    if (_selectedFilter == 'Semua') {
      return items;
    } else {
      return items.where((item) => item.status == _selectedFilter).toList();
    }
  }

  // Change item status and update inventory if needed
  Future<void> _changeStatus(String ticketId, String newStatusDisplay) async {
    // newStatusDisplay is 'Disetujui', 'Ditolak', etc.
    try {
      QuerySnapshot peminjamanQuery = await _firestore
          .collection('peminjaman')
          .where('ticketId', isEqualTo: ticketId)
          .limit(1)
          .get();

      if (peminjamanQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Error: Data peminjaman tidak ditemukan untuk ticket ID $ticketId.'),
              backgroundColor: Colors.red));
        }
        return;
      }

      DocumentSnapshot peminjamanDoc = peminjamanQuery.docs.first;
      // Use the PeminjamanItem model for easier and typed field access
      PeminjamanItem currentLoanRequest =
          PeminjamanItem.fromFirestore(peminjamanDoc);
      String idBarang = currentLoanRequest
          .id; // This is idBarang from the peminjaman document

      // --- Start: Basic validation for status transitions ---
      if (newStatusDisplay == 'Disetujui' &&
          currentLoanRequest.status != 'Tertunda') {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Hanya permintaan Tertunda yang dapat Disetujui.'),
              backgroundColor: Colors.orange));
        return;
      }
      if (newStatusDisplay == 'Ditolak' &&
          currentLoanRequest.status != 'Tertunda') {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Hanya permintaan Tertunda yang dapat Ditolak.'),
              backgroundColor: Colors.orange));
        return;
      }
      if (newStatusDisplay == 'Dikembalikan' &&
          currentLoanRequest.status != 'Menunggu Konfirmasi Pengembalian') {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Hanya permintaan Menunggu Konfirmasi Pengembalian yang dapat Dikembalikan.'),
              backgroundColor: Colors.orange));
        return;
      }
      // --- End: Basic validation for status transitions ---

      if (newStatusDisplay == 'Disetujui') {
        // Fetch the inventory item to check its current status
        QuerySnapshot inventoryQuery = await _firestore
            .collection('barangInventris')
            .where('id',
                isEqualTo:
                    idBarang) // 'id' is the field in barangInventris matching idBarang
            .limit(1)
            .get();

        if (inventoryQuery.docs.isEmpty) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Error: Barang inventaris dengan ID "$idBarang" tidak ditemukan.'),
                backgroundColor: Colors.red));
          return;
        }

        DocumentSnapshot inventoryDocSnapshot = inventoryQuery.docs.first;
        // Use BarangInventaris model for typed access
        BarangInventaris inventoryItem =
            BarangInventaris.fromFirestore(inventoryDocSnapshot);

        // Check 1: Is the item currently 'sedang dipinjam'?
        if (inventoryItem.status.toLowerCase() == 'Dipinjam') {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Gagal: Barang ini sudah dipinjam oleh pengguna lain.'),
                backgroundColor: Colors.red));
          return;
        }

        // Check 2: If item is 'tersedia', enforce 1-week cooldown after last return.
        // This applies if an item was returned and a new request for it is being approved.
        if (inventoryItem.status.toLowerCase() == 'tersedia') {
          // Find the latest 'Dikembalikan' loan for this specific item - Fixed query
          QuerySnapshot previousLoansQuery = await _firestore
              .collection('peminjaman')
              .where('idBarang', isEqualTo: idBarang)
              .where('status',
                  isEqualTo: PeminjamanItem.mapToFirestoreStatus(
                      'Dikembalikan')) // 'dikembalikan'
              .get(); // Removed orderBy to avoid index error

          if (previousLoansQuery.docs.isNotEmpty) {
            // Sort manually to get the latest return
            List<PeminjamanItem> previousLoans = previousLoansQuery.docs
                .map((doc) => PeminjamanItem.fromFirestore(doc))
                .where((loan) => loan.tanggalPengembalian != null)
                .toList();

            if (previousLoans.isNotEmpty) {
              // Sort manually by return date
              previousLoans.sort((a, b) =>
                  b.tanggalPengembalian!.compareTo(a.tanggalPengembalian!));

              PeminjamanItem lastReturnedLoan = previousLoans.first;

              // Ensure both dates are available for comparison
              if (lastReturnedLoan.tanggalPengembalian != null &&
                  currentLoanRequest.tanggalPengajuan != null) {
                DateTime lastReturnDate = lastReturnedLoan.tanggalPengembalian!;
                DateTime currentRequestSubmissionDate = currentLoanRequest
                    .tanggalPengajuan!; // Date the current request was made

                // The current request can only be approved if its submission date
                // is at least 7 days after the last actual return date of the item.
                if (currentRequestSubmissionDate
                    .isBefore(lastReturnDate.add(const Duration(days: 7)))) {
                  String formattedLastReturnDate = PeminjamanItem.formatDate(
                      Timestamp.fromDate(lastReturnDate));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Gagal: Barang baru dapat dipinjam 1 minggu setelah tanggal pengembalian terakhir ($formattedLastReturnDate). Pengajuan ini dibuat pada ${PeminjamanItem.formatDate(Timestamp.fromDate(currentRequestSubmissionDate))}.'),
                        backgroundColor: Colors.red,
                        duration: const Duration(
                            seconds: 7), // Longer duration for readability
                      ),
                    );
                  }
                  return;
                }
              }
            }
          }
        }
      }

      // Proceed with status update if all checks pass
      String firestoreStatusPeminjaman =
          PeminjamanItem.mapToFirestoreStatus(newStatusDisplay);
      Map<String, dynamic> updateDataPeminjaman = {
        'status': firestoreStatusPeminjaman
      };

      if (newStatusDisplay == 'Disetujui') {
        updateDataPeminjaman['tanggalDisetujui'] = FieldValue.serverTimestamp();
      } else if (newStatusDisplay == 'Dikembalikan') {
        updateDataPeminjaman['tanggalPengembalian'] =
            FieldValue.serverTimestamp();
      }

      await peminjamanDoc.reference.update(updateDataPeminjaman);

      // Update inventory status in barangInventris collection
      await _updateInventoryStatus(
          idBarang, newStatusDisplay); // Pass the display status

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Status peminjaman berhasil diubah menjadi $newStatusDisplay'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      print('Error in _changeStatus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  // Update inventory status based on peminjaman status
  Future<void> _updateInventoryStatus(
      String idBarang, String peminjamanStatusDisplay) async {
    try {
      String newInventoryStatus;

      switch (peminjamanStatusDisplay) {
        // Compare with display status like 'Disetujui'
        case 'Disetujui':
          newInventoryStatus =
              'Dipinjam'; // Firestore value for barangInventris.status
          break;
        case 'Ditolak':
        case 'Dikembalikan':
          newInventoryStatus =
              'tersedia'; // Firestore value for barangInventris.status
          break;
        case 'Menunggu Konfirmasi Pengembalian':
          newInventoryStatus = 'Menunggu Konfirmasi Pengembalian';
          break;
        default:
          // For 'Tertunda', 'Menunggu Konfirmasi Pengembalian' or other statuses, no change to inventory status is needed from here.
          return;
      }

      // Find and update the inventory item in 'barangInventris'
      // Assumes 'id' is the document ID or a unique field in 'barangInventris'
      QuerySnapshot inventoryQuery = await _firestore
          .collection('barangInventris')
          .where('id',
              isEqualTo: idBarang) // Match the 'id' field in barangInventris
          .limit(1)
          .get();

      if (inventoryQuery.docs.isNotEmpty) {
        await inventoryQuery.docs.first.reference.update({
          'status': newInventoryStatus,
        });
        print('Inventory status for $idBarang updated to $newInventoryStatus');
      } else {
        // This case should ideally not happen if data is consistent.
        print(
            'Peringatan: Barang inventaris dengan ID $idBarang tidak ditemukan untuk pembaruan status.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Peringatan: Data barang di inventaris (ID: $idBarang) tidak ditemukan. Status inventaris mungkin tidak sinkron.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating inventory status for $idBarang: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error memperbarui status inventaris: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show item detail dialog
  void _showItemDetail(BuildContext context, PeminjamanItem item) {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(
        item: item,
        onStatusChange: _changeStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(selectedMenu: 'Peminjaman Barang'),
      appBar: AppBar(
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
        title: const Text('Masjid Al-Waraq'),
        centerTitle: true,
        backgroundColor: const Color(0xff348E9C),
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
                    label: Text(filter),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
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

          // Item List with StreamBuilder
          Expanded(
            child: StreamBuilder<List<PeminjamanItem>>(
              stream: _getPeminjamanStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
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
                          'Belum ada pengajuan peminjaman',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<PeminjamanItem> filteredItems =
                    _filterItems(snapshot.data!);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data untuk filter "$_selectedFilter"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return ItemCard(
                      item: item,
                      onViewDetail: () => _showItemDetail(context, item),
                      onStatusChange: _changeStatus,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Item Card Widget
class ItemCard extends StatelessWidget {
  final PeminjamanItem item;
  final VoidCallback onViewDetail;
  final Function(String, String) onStatusChange;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onViewDetail,
    required this.onStatusChange,
  }) : super(key: key);

  Color get _statusColor {
    switch (item.status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Tertunda':
        return Colors.orange;
      case 'Menunggu Konfirmasi Pengembalian':
        return Colors.purple;
      case 'Dikembalikan':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color get _cardColor {
    switch (item.status) {
      case 'Disetujui':
        return Colors.green.shade50;
      case 'Ditolak':
        return Colors.red.shade50;
      case 'Tertunda':
        return Colors.amber.shade50;
      case 'Menunggu Konfirmasi Pengembalian':
        return Colors.purple.shade50;
      case 'Dikembalikan':
        return Colors.blue.shade50;
      default:
        return Colors.white;
    }
  }

  IconData get _statusIcon {
    switch (item.status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Ditolak':
        return Icons.cancel;
      case 'Tertunda':
        return Icons.access_time;
      case 'Menunggu Konfirmasi Pengembalian':
        return Icons.hourglass_empty;
      case 'Dikembalikan':
        return Icons.replay;
      default:
        return Icons.help;
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
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
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
                        item.borrower,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Permohonan: ${item.requestDate}',
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
                        item.status,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID Tiket: ${item.ticketId}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye),
                  color: Colors.blue,
                  onPressed: onViewDetail,
                ),
                if (item.status == 'Tertunda') ...[
                  IconButton(
                    icon: const Icon(Icons.check_circle),
                    color: Colors.green,
                    onPressed: () => onStatusChange(item.ticketId, 'Disetujui'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    color: Colors.red,
                    onPressed: () => onStatusChange(item.ticketId, 'Ditolak'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Dialog
class DetailDialog extends StatelessWidget {
  final PeminjamanItem item;
  final Function(String, String) onStatusChange;

  const DetailDialog({
    Key? key,
    required this.item,
    required this.onStatusChange,
  }) : super(key: key);

  // Show KTP image in full screen
  void _showKtpImage(BuildContext context, String? ktpImageUrl) {
    if (ktpImageUrl == null || ktpImageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar KTP tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xff348E9C),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dokumen KTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ktpImageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show confirmation dialog for marking item as returned
  void _showReturnConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pengembalian'),
          content: const Text(
              'Apakah Anda yakin untuk menandai barang ini sebagai dikembalikan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close detail dialog
                onStatusChange(item.ticketId, 'Dikembalikan');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Tandai Dikembalikan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Peminjaman',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('ID Tiket', Icons.description, item.ticketId),
                const SizedBox(height: 16),
                _detailRow('Nama Barang', Icons.inventory, item.name),
                const SizedBox(height: 16),
                _borrowerRow(context, item.borrower),
                const SizedBox(height: 16),
                _detailRow('Tanggal Permohonan', Icons.calendar_today,
                    item.requestDate),
                const SizedBox(height: 16),
                _statusChip(item.status),
                const SizedBox(height: 16),
                Text(
                  'Keterangan',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // KTP Document Section
                Text(
                  'Dokumen Identitas',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),

                // KTP Image Container
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: item.ktpImageUrl != null &&
                          item.ktpImageUrl!.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _showKtpImage(context, item.ktpImageUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.ktpImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 120,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Gagal memuat gambar',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tidak ada dokumen KTP',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                if (item.ktpImageUrl != null && item.ktpImageUrl!.isNotEmpty)
                  Text(
                    'Ketuk untuk melihat lebih detail',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (item.status == 'Tertunda') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onStatusChange(item.ticketId, 'Disetujui');
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Setujui'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onStatusChange(item.ticketId, 'Ditolak');
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Tolak'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (item.status ==
                    'Menunggu Konfirmasi Pengembalian') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReturnConfirmation(context),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Tandai Dikembalikan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _borrowerRow(BuildContext context, String borrower) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.person, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peminjam',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                borrower,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color statusColor;
    Color backgroundColor;
    IconData statusIcon;

    switch (status) {
      case 'Disetujui':
        statusColor = Colors.green;
        backgroundColor = Colors.green.shade50;
        statusIcon = Icons.check_circle;
        break;
      case 'Ditolak':
        statusColor = Colors.red;
        backgroundColor = Colors.red.shade50;
        statusIcon = Icons.cancel;
        break;
      case 'Tertunda':
        statusColor = Colors.orange;
        backgroundColor = Colors.orange.shade50;
        statusIcon = Icons.access_time;
        break;
      case 'Menunggu Konfirmasi Pengembalian':
        statusColor = Colors.purple;
        backgroundColor = Colors.purple.shade50;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'Dikembalikan':
        statusColor = Colors.blue;
        backgroundColor = Colors.blue.shade50;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        backgroundColor = Colors.grey.shade50;
        statusIcon = Icons.help;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
