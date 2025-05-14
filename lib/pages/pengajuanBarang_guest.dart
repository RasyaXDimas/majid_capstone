import 'package:capstone/widgets/drawerGuest.dart';
import 'package:flutter/material.dart';

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

  PeminjamanItem({
    required this.id,
    required this.name,
    required this.borrower,
    required this.requestDate,
    required this.status,
    this.isReturned = false, // Default is not returned
  });
}

// Main Page
class PengajuanBarangPage extends StatefulWidget {
  const PengajuanBarangPage({super.key});

  @override
  State<PengajuanBarangPage> createState() => _PengajuanBarangPageState();
}

class _PengajuanBarangPageState extends State<PengajuanBarangPage> {
  // Sample data
  final List<PeminjamanItem> _allItems = [
    PeminjamanItem(
      id: 'BRW-2025-001',
      name: 'Portable Speaker',
      borrower: 'Ahmad',
      requestDate: '15 Mei 2025',
      status: 'Tertunda',
    ),
    PeminjamanItem(
      id: 'BRW-2025-002',
      name: 'Projektor',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Disetujui',
    ),
    PeminjamanItem(
      id: 'BRW-2025-003',
      name: 'Kursi Kayu',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Ditolak',
    ),
    PeminjamanItem(
      id: 'BRW-2025-004',
      name: 'Tempat Alquran',
      borrower: 'Umar',
      requestDate: '14 Mei 2025',
      status: 'Tertunda',
    ),
  ];

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Tertunda', 'Disetujui', 'Ditolak'];

  // Filter items based on selected filter
  List<PeminjamanItem> get _filteredItems {
    if (_selectedFilter == 'Semua') {
      return _allItems;
    } else {
      return _allItems.where((item) => item.status == _selectedFilter).toList();
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ItemCard(
                  key: Key(item.id), // Use the item's ID as the key
                  item: item,
                  onReturnConfirmed: () {
                    // Need to call setState to refresh the list when an item is returned
                    setState(() {
                      // Item will be updated inside the ItemCard widget
                    });
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
    if (widget.item.isReturned) {
      return Colors.blue;
    }
    
    switch (widget.item.status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Tertunda':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color get _cardColor {
    if (widget.item.isReturned) {
      return Colors.blue.shade50;
    }
    
    switch (widget.item.status) {
      case 'Disetujui':
        return Colors.green.shade50;
      case 'Ditolak':
        return Colors.red.shade50;
      case 'Tertunda':
        return Colors.amber.shade50;
      default:
        return Colors.white;
    }
  }

  IconData get _statusIcon {
    if (widget.item.isReturned) {
      return Icons.assignment_returned;
    }
    
    switch (widget.item.status) {
      case 'Disetujui':
        return Icons.check_circle;
      case 'Ditolak':
        return Icons.cancel;
      case 'Tertunda':
        return Icons.access_time;
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
                        widget.item.isReturned 
                            ? 'Barang Sudah Dikembalikan' 
                            : widget.item.status,
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
            
            // Return confirmation button (only for approved items that haven't been returned)
            if (widget.item.status == 'Disetujui' && !widget.item.isReturned)
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
                              'Apakah Anda yakin ingin mengembalikan ${widget.item.name}?',
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
                                  
                                  // Update the item status
                                  setState(() {
                                    widget.item.isReturned = true;
                                  });
                                  
                                  // Notify parent to refresh the list
                                  widget.onReturnConfirmed();
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${widget.item.name} telah dikembalikan!'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Konfirmasi',
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
                            'Konfirmasi\nPengembalian',
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