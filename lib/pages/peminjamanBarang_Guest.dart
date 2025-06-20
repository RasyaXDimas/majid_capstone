import 'package:capstone/widgets/drawerGuest.dart';
import 'package:capstone/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class PeminjamanbarangGuest extends StatelessWidget {
  const PeminjamanbarangGuest({super.key});

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
      home: const PeminjamanBarangGuest(),
    );
  }
}

// Main Page
class PeminjamanBarangGuest extends StatefulWidget {
  const PeminjamanBarangGuest({super.key});

  @override
  State<PeminjamanBarangGuest> createState() => _PeminjamanBarangGuestState();
}

class _PeminjamanBarangGuestState extends State<PeminjamanBarangGuest> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _barangList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBarangInventris();
  }

  // Fetch data from barangInventris collection
  Future<void> _fetchBarangInventris() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot snapshot = await _firestore.collection('barangInventris').get();
      
      List<Map<String, dynamic>> barangList = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        barangList.add({
          'id': data['id'] ?? '',
          'name': data['name'] ?? '',
          'category': data['category'] ?? '',
          'status': data['status'] ?? '',
          'docId': doc.id,
        });
      }

      setState(() {
        _barangList = barangList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show item detail dialog
  void _showItemDetail(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => DetailDialog(item: item),
    );
  }

  // Show borrowing form
  void _showBorrowingForm(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => BorrowingFormDialog(
        item: item,
        onSubmit: _submitPeminjamanRequest,
      ),
    );
  }

  // Submit peminjaman request to Firestore with Supabase KTP URL
  // UPDATED: No longer changes barang status immediately
Future<void> _submitPeminjamanRequest(
  Map<String, dynamic> item,
  String borrowerName,
  DateTime borrowDate,
  String description,
  String ktpImagePath,
) async {
  BuildContext? dialogContext;
  
  try {
    // Show loading dialog dan simpan context
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Mengupload foto KTP...'),
              ],
            ),
          ),
        );
      },
    );

    print('Starting upload process...');
    print('KTP Image Path: $ktpImagePath');
    
    // Check if file exists before upload
    final ktpFile = File(ktpImagePath);
    if (!await ktpFile.exists()) {
      throw Exception('File KTP tidak ditemukan di path: $ktpImagePath');
    }
    
    print('File exists, size: ${await ktpFile.length()} bytes');

    // Upload KTP image to Supabase
    final ktpImageUrl = await SupabaseService.uploadKtpImage(
      ktpFile,
      borrowerName.replaceAll(' ', '_'),
    );

    print('Upload result: $ktpImageUrl');

    if (ktpImageUrl == null || ktpImageUrl.isEmpty) {
      throw Exception('Gagal mengupload foto KTP. Periksa koneksi internet dan coba lagi.');
    }

    print('Upload successful, saving to Firestore...');

    // Generate ticket ID
    String ticketId = 'BRW-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Create peminjaman document with KTP URL
    // UPDATED: Status remains 'tertunda' and barang status is NOT changed
    await _firestore.collection('peminjaman').add({
      'idBarang': item['id'],
      'namaBarang': item['name'],
      'peminjam': borrowerName,
      'status': 'tertunda', // Remains pending until admin approval
      'keterangan': description,
      'tanggalDisetujui': null, // Will be set when admin approves
      'tanggalPengajuan': Timestamp.fromDate(borrowDate),
      'tanggalPengembalian': null,
      'ticketId': ticketId,
      'ktpImageUrl': ktpImageUrl,
      'ktpFileName': SupabaseService.getFileNameFromUrl(ktpImageUrl),
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // REMOVED: No longer updating barang status to 'Dipinjam' immediately
    // The barang status will remain 'Tersedia' until admin approves the request
    // Admin will handle the status change when approving/rejecting the request

    // Close loading dialog dengan aman
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop();
    }

    // Refresh the data (barang will still show as 'Tersedia')
    await _fetchBarangInventris();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengajuan peminjaman berhasil dikirim!\nTicket ID: $ticketId\nMenunggu persetujuan admin.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }

  } catch (e) {
    print('Error in _submitPeminjamanRequest: $e');
    
    // Close loading dialog dengan aman
    if (dialogContext != null && Navigator.of(dialogContext!).canPop()) {
      Navigator.of(dialogContext!).pop();
    }
    
    // Show detailed error message
    String errorMessage = 'Terjadi kesalahan: ';
    if (e.toString().contains('File KTP tidak ditemukan')) {
      errorMessage = 'File KTP tidak ditemukan. Silakan pilih foto KTP lagi.';
    } else if (e.toString().contains('Gagal mengupload foto KTP')) {
      errorMessage = 'Gagal mengupload foto KTP. Periksa koneksi internet Anda.';
    } else {
      errorMessage += e.toString();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    
    // Re-throw error agar bisa di-handle di _submitForm
    throw e;
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const GuestDrawer(selectedMenu: 'Peminjaman Barang'),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Peminjaman Barang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Item List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _barangList.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada barang tersedia',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchBarangInventris,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _barangList.length,
                          itemBuilder: (context, index) {
                            final item = _barangList[index];
                            return ItemCard(
                              item: item,
                              onViewDetail: () => _showItemDetail(context, item),
                              onBorrow: item['status'] == 'Tersedia'
                                  ? () => _showBorrowingForm(context, item)
                                  : null,
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

// Item Card Widget (unchanged)
class ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onViewDetail;
  final VoidCallback? onBorrow;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onViewDetail,
    this.onBorrow,
  }) : super(key: key);

  Color get _statusColor {
    switch (item['status']) {
      case 'Tersedia':
        return Colors.green;
      case 'Dipinjam':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.amber.shade50,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Name with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Category
            Row(
              children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: 8),
                Text(
                  item['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Status
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 16),
                const SizedBox(width: 8),
                Text(
                  item['status'] ?? '',
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: onBorrow != null 
                      ? const Color(0xFF26A69A)
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onBorrow,
                child: Text(
                  onBorrow != null ? 'Pinjam' : 'Tidak Tersedia',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Detail Dialog (unchanged)
class DetailDialog extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

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
                  'Detail Barang',
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
                _detailRow('ID Barang', Icons.qr_code, item['id'] ?? ''),
                const SizedBox(height: 16),
                _detailRow('Nama Barang', Icons.inventory, item['name'] ?? ''),
                const SizedBox(height: 16),
                _detailRow('Kategori', Icons.category, item['category'] ?? ''),
                const SizedBox(height: 16),
                _statusChip(item['status'] ?? ''),
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, IconData icon, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case 'Tersedia':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle;
        break;
      case 'Dipinjam':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconData = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        iconData = Icons.help;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Updated Borrowing Form Dialog
class BorrowingFormDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>, String, DateTime, String, String) onSubmit;

  const BorrowingFormDialog({
    super.key,
    required this.item,
    required this.onSubmit,
  });

  @override
  State<BorrowingFormDialog> createState() => _BorrowingFormDialogState();
}

class _BorrowingFormDialogState extends State<BorrowingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  XFile? _idCardImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
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
                    'Minta Peminjaman',
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
            ),
            const Divider(height: 1),

            // Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Barang (Pre-filled)
                    const Text(
                      'Nama Barang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: widget.item['name'] ?? '',
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Peminjam
                    const Text(
                      'Peminjam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama peminjam',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama peminjam wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Peminjaman
                    const Text(
                      'Tanggal Peminjaman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2026),
                        );
                        if (picked != null && picked != _selectedDate) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Keterangan Peminjaman
                    const Text(
                      'Keterangan Peminjaman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan keterangan peminjaman',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload KTP - Enhanced with better UI
                    const Text(
                      'Upload KTP *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        _showImagePickerOptions(context);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _idCardImage != null 
                                ? Colors.green.shade300 
                                : Colors.grey.shade300,
                            width: _idCardImage != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: _idCardImage != null 
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                        ),
                        child: _idCardImage != null
                            ? Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_idCardImage!.path),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      iconSize: 20,
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _idCardImage = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Upload foto KTP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap untuk memilih dari galeri atau kamera',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_idCardImage == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '* Wajib upload foto KTP untuk verifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                      ),
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Ajukan', style: TextStyle(color: Colors.white)),
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

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildImagePickerOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF26A69A)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close bottom sheet
    
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _idCardImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengambil gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon upload foto KTP terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi file KTP exists
    final ktpFile = File(_idCardImage!.path);
    if (!await ktpFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File KTP tidak ditemukan. Silakan pilih foto lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSubmit(
        widget.item,
        _nameController.text.trim(),
        _selectedDate,
        _descriptionController.text.trim(),
        _idCardImage!.path,
      );

      // Close dialog only if submission was successful
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is already handled in the parent widget
      // Just reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}