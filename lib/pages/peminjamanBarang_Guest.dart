import 'package:capstone/widgets/drawer.dart';
import 'package:capstone/widgets/drawerGuest.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
      home: const PeminjamanBarangPage(),
    );
  }



}


// Model for lending items
class PeminjamanItem {
  final String id;
  final String name;
  final String borrower;
  String status;
  final String description;
  final DateTime availableDate;

  PeminjamanItem({
    required this.id,
    required this.name,
    required this.borrower,
    required this.status,
    required this.description,
    required this.availableDate,
  });
}

// Main Page
class PeminjamanBarangPage extends StatefulWidget {
  const PeminjamanBarangPage({super.key});

  @override
  State<PeminjamanBarangPage> createState() => _PeminjamanBarangPageState();
}

class _PeminjamanBarangPageState extends State<PeminjamanBarangPage> {
  // Sample data
  final List<PeminjamanItem> _allItems = [
    PeminjamanItem(
      id: 'BRW-2025-001',
      name: 'Portable Speaker',
      borrower: 'Ahmad',
      status: 'Tersedia',
      description: 'Digunakan untuk acara pengajian',
      availableDate: DateTime(2025, 5, 15),
    ),
    PeminjamanItem(
      id: 'BRW-2025-002',
      name: 'Projektor',
      borrower: 'Umar',
      status: 'Sedang dipinjam',
      description: 'Digunakan untuk acara kajian Jumat',
      availableDate: DateTime(2025, 5, 15),
    ),
    PeminjamanItem(
      id: 'BRW-2025-003',
      name: 'Kursi Kayu',
      borrower: 'Umar',
      status: 'Tersedia',
      description: 'Diperlukan untuk acara keluarga',
      availableDate: DateTime(2025, 5, 15),
    ),
    PeminjamanItem(
      id: 'BRW-2025-004',
      name: 'Tempat Alquran',
      borrower: 'Umar',
      status: 'Tersedia',
      description: 'Diperlukan untuk kelas mengaji',
      availableDate: DateTime(2025, 5, 15),
    ),
  ];

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

  // Show borrowing form
  void _showBorrowingForm(BuildContext context, PeminjamanItem item) {
    showDialog(
      context: context,
      builder: (context) => BorrowingFormDialog(
        item: item,
        onSubmit: (name, date, description, idCard) {
          // Here you would typically send this to a backend
          // For now, we'll just change the status to demonstrate
          _changeStatus(item.id, 'Sedang dipinjam');
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Change item status
  void _changeStatus(String id, String newStatus) {
    setState(() {
      for (var item in _allItems) {
        if (item.id == id) {
          item.status = newStatus;
          break;
        }
      }
    });
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
            color: const Color(0xff348E9C),
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              'Peminjaman Barang',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Item List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allItems.length,
              itemBuilder: (context, index) {
                final item = _allItems[index];
                return ItemCard(
                  item: item,
                  onViewDetail: () => _showItemDetail(context, item),
                  onBorrow: item.status == 'Tersedia'
                      ? () => _showBorrowingForm(context, item)
                      : null,
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
  final VoidCallback? onBorrow;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onViewDetail,
    this.onBorrow,
  }) : super(key: key);

  Color get _statusColor {
    switch (item.status) {
      case 'Tersedia':
        return Colors.green;
      case 'Sedang dipinjam':
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
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 16),
                const SizedBox(width: 8),
                Text(
                  item.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Available date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Jadwal Tersedia: ${DateFormat('dd MMM yyyy').format(item.availableDate)}',
                  style: const TextStyle(
                    fontSize: 14,
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
                child: const Text(
                  'Pinjam',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
                _detailRow('ID Tiket', Icons.description, item.id),
                const SizedBox(height: 16),
                _detailRow('Nama Barang', Icons.inventory, item.name),
                const SizedBox(height: 16),
                _borrowerRow(context, item.borrower),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _borrowerRow(BuildContext context, String borrower) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peminjam',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                borrower[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              borrower,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
      case 'Sedang dipinjam':
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

// Borrowing Form Dialog
class BorrowingFormDialog extends StatefulWidget {
  final PeminjamanItem item;
  final Function(String name, DateTime date, String description, String idCard) onSubmit;

  const BorrowingFormDialog({
    Key? key,
    required this.item,
    required this.onSubmit,
  }) : super(key: key);

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
                      initialValue: widget.item.name,
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

                    // Upload KTP
                    const Text(
                      'Upload KTP',
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
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
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
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(8),
                                      ),
                                    ),
                                    child: IconButton(
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
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Klik untuk memilih dari galeri atau kamera',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff348E9C),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_idCardImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harap upload foto KTP terlebih dahulu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setState(() {
                          _isLoading = true;
                        });
                        
                        // Simulate network delay for uploading image
                        Future.delayed(const Duration(seconds: 1), () {
                          setState(() {
                            _isLoading = false;
                          });
                          
                          widget.onSubmit(
                            _nameController.text,
                            _selectedDate,
                            _descriptionController.text,
                            _idCardImage!.path,
                          );
                        });
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Pinjam',
                            style: TextStyle(color: Colors.white),
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

  // Method to show image picker options
  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
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
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xff348E9C),
                    child: Icon(Icons.camera_alt, color: Colors.white),
                  ),
                  title: const Text('Ambil Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xff348E9C),
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Method to get image from camera or gallery
  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? selectedImage = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (selectedImage != null) {
        setState(() {
          _idCardImage = selectedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}