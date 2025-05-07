import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';

// Main App
void main() {
  runApp(const MasjidApp());
}

class MasjidApp extends StatelessWidget {
  const MasjidApp({Key? key}) : super(key: key);

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
  final String requestDate;
  String status;
  final String description;

  PeminjamanItem({
    required this.id,
    required this.name,
    required this.borrower,
    required this.requestDate,
    required this.status,
    required this.description,
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
      requestDate: '15 Mei 2025',
      status: 'Tertunda',
      description: 'Digunakan untuk acara pengajian',
    ),
    PeminjamanItem(
      id: 'BRW-2025-002',
      name: 'Projektor',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Disetujui',
      description: 'Digunakan untuk acara kajian Jumat',
    ),
    PeminjamanItem(
      id: 'BRW-2025-003',
      name: 'Kursi Kayu',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Ditolak',
      description: 'Diperlukan untuk acara keluarga',
    ),
    PeminjamanItem(
      id: 'BRW-2025-004',
      name: 'Tempat Alquran',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Dikembalikan',
      description: 'Diperlukan untuk kelas mengaji',
    ),
  ];

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tertunda', 'Disetujui', 'Ditolak', 'Dikembalikan'];
  
  // Filter items based on selected filter
  List<PeminjamanItem> get _filteredItems {
    if (_selectedFilter == 'Semua') {
      return _allItems;
    } else {
      return _allItems.where((item) => item.status == _selectedFilter).toList();
    }
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
                  Scaffold.of(context)
                      .openDrawer(); // Ini sekarang akan bekerja
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

          // Item List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ItemCard(
                  item: item,
                  onViewDetail: () => _showItemDetail(context, item),
                  onStatusChange: _changeStatus,
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
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
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
                    'ID Tiket: ${item.id}',
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
                    onPressed: () => onStatusChange(item.id, 'Disetujui'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    color: Colors.red,
                    onPressed: () => onStatusChange(item.id, 'Ditolak'),
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
                _detailRow('Tanggal Permohonan', Icons.calendar_today, item.requestDate),
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
                if (item.status == 'Disetujui')
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff348E9C),
                    ),
                    onPressed: () {
                      onStatusChange(item.id, 'Dikembalikan');
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Tandai Kembalikan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
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
      case 'Disetujui':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        iconData = Icons.check_circle;
        break;
      case 'Ditolak':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        iconData = Icons.cancel;
        break;
      case 'Tertunda':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        iconData = Icons.access_time;
        break;
      case 'Dikembalikan':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        iconData = Icons.replay;
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

