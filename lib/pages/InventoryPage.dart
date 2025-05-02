import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String selectedCategoryFilter = 'Semua';
  String selectedStatusFilter = 'Semua';
  String selectedCategory = 'Semua';
// Controller untuk textfield pencarian
  final TextEditingController _searchController = TextEditingController();
// Kata kunci pencarian
  String _searchQuery = '';

  final List<Map<String, dynamic>> inventoryItems = [
    {
      'name': 'Projektor',
      'id': 'INV001',
      'category': 'Visual Audio',
      'status': 'Tersedia',
    },
    {
      'name': 'Kursi Kayu',
      'id': 'INV002',
      'category': 'Furniture',
      'status': 'Dipinjam',
    },
    {
      'name': 'Tempat Alquran',
      'id': 'INV003',
      'category': 'Furniture',
      'status': 'Tersedia',
    },
    {
      'name': 'Portable Speaker',
      'id': 'INV004',
      'category': 'Perlengkapan Audio',
      'status': 'Dipinjam',
    },
    {
      'name': 'Sajadah',
      'id': 'INV005',
      'category': 'Furniture',
      'status': 'Tersedia',
    },
  ];

//   List<Map<String, dynamic>> _getFilteredItems() {
//   return inventoryItems.where((item) {
//     // Filter by category
//     final categoryMatch = selectedCategoryFilter == 'Semua' || 
//                          item['category'] == selectedCategoryFilter;
    
//     // Filter by status
//     final statusMatch = selectedStatusFilter == 'Semua' || 
//                        item['status'] == selectedStatusFilter;
    
//     // Filter by search query
//     final searchMatch = _searchQuery.isEmpty ||
//         item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
//         item['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
//         item['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    
//     // Item must match all active filters
//     return categoryMatch && statusMatch && searchMatch;
//   }).toList();
// }

  @override
  void initState() {
    super.initState();
    // Tambahkan listener ke controller untuk mendeteksi perubahan
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final filteredItems = _getFilteredItems();
    // final filteredItems = selectedCategory == 'Semua'
    //     ? inventoryItems
    //     : inventoryItems
    //         .where((item) => item['category'] == selectedCategory)
    //         .toList();

    final filteredItems = inventoryItems.where((item) {
      // Filter berdasarkan kategori
      final categoryMatch =
          selectedCategory == 'Semua' || item['category'] == selectedCategory;
      final statusMatch = 
          selectedStatusFilter == 'Semua' || item['status'] == selectedStatusFilter;
      // Filter berdasarkan kata kunci pencarian
      final searchMatch = _searchQuery.isEmpty ||
          item['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['id']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['category']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      // Item harus memenuhi kedua kriteria filter
      return categoryMatch && searchMatch && statusMatch;
    }).toList();

    return Scaffold(
      // key: _scaffoldKey,
      drawer: const DashboardDrawer(selectedMenu: 'Inventaris'),
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
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          // Hapus text dan reset pencarian
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
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
                ],
              ),
            ),
            // Indikator hasil pencarian - menampilkan jumlah item yang ditemukan
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
            // const SizedBox(height: 2),
            Expanded(
              // UI Kosong - tampilkan saat tidak ada hasil pencarian
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
                                : 'Tidak ada item yang tersedia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'Cobalah kata kunci lain atau hapus filter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (_searchQuery.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  selectedCategory = 'Semua';
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Pencarian'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff348E9C),
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['name'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            _showEditItemDialog(context, item);
                                          },
                                          child: const Icon(Icons.edit,
                                              color: Colors.blue),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            _showDeleteConfirmationDialog(
                                                context, item);
                                          },
                                          child: const Icon(Icons.delete,
                                              color: Colors.red),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        const Icon(Icons.qr_code,
                                            color: Colors.purple)
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('ID: ${item['id']}',
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildTag(item['category'],
                                        Colors.grey.shade300, Colors.black),
                                    const SizedBox(width: 8),
                                    _buildTag(
                                      item['status'],
                                      item['status'] == 'Tersedia'
                                          ? Colors.green.shade100
                                          : Colors.amber.shade100,
                                      item['status'] == 'Tersedia'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
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
      onSelected: (_) {
        setState(() {
          selectedCategory = label;
        });
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final _nameController = TextEditingController();
    String selectedCategory = 'Perlengkapan Audio';
    String selectedStatus = 'Tersedia';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                // Padding(padding: EdgeInsets.symmetric(vertical: 5),

                SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    )),
                const SizedBox(height: 12),
                const Text('Kategori'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(
                        value: 'Perlengkapan Audio',
                        child: Text('Perlengkapan Audio')),
                    DropdownMenuItem(
                        value: 'Furniture', child: Text('Furniture')),
                    DropdownMenuItem(
                        value: 'Visual Audio', child: Text('Visual Audio')),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
                const SizedBox(height: 12),
                const Text('Status'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(
                        value: 'Tersedia', child: Text('Tersedia')),
                    DropdownMenuItem(
                        value: 'Dipinjam', child: Text('Dipinjam')),
                  ],
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff348E9C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
              onPressed: () {
                // Simpan logika
                final newItem = {
                  'name': _nameController.text,
                  'id': 'INVXXX',
                  'category': selectedCategory,
                  'status': selectedStatus,
                };
                print(newItem); // Simpan ke list jika perlu
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog edit item
  void _showEditItemDialog(BuildContext context, Map<String, dynamic> item) {
    // Controller untuk nama barang
    final TextEditingController nameController =
        TextEditingController(text: item['name']);
    // Nilai awal untuk dropdown
    String selectedCategory = item['category'];
    String selectedStatus = item['status'];

    showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7, // Prevent overflow
          ),
          child: SingleChildScrollView( // Make dialog scrollable to prevent overflow
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ID (read-only)
                  const Text('ID'),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: item['id']),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nama Barang
                  const Text('Nama Barang'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Kategori
                  const Text('Kategori'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Visual Audio', child: Text('Audio Visual')),
                      DropdownMenuItem(
                          value: 'Perlengkapan Audio',
                          child: Text('Perlengkapan Audio')),
                      DropdownMenuItem(
                          value: 'Furniture', child: Text('Furniture')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        selectedCategory = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Status
                  const Text('Status'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Tersedia', child: Text('Tersedia')),
                      DropdownMenuItem(
                          value: 'Dipinjam', child: Text('Dipinjam')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        selectedStatus = value;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Tombol aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Update item dengan nilai baru
                          setState(() {
                            // Temukan index item dalam daftar inventaris
                            final index = inventoryItems
                                .indexWhere((e) => e['id'] == item['id']);
                            if (index != -1) {
                              inventoryItems[index]['name'] = nameController.text;
                              inventoryItems[index]['category'] =
                                  selectedCategory;
                              inventoryItems[index]['status'] = selectedStatus;
                            }
                          });
                          Navigator.of(context).pop();

                          // Show a snackbar to indicate successful update
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item['name']} berhasil diperbarui'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
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
}

  void _showDeleteConfirmationDialog(
      BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Konfirmasi Hapus'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                'Apakah anda yakin ingin menghapus barang ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${item['name']} (${item['id']})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete the item from the inventory list
                setState(() {
                  inventoryItems
                      .removeWhere((element) => element['id'] == item['id']);
                });
                // Close the dialog
                Navigator.of(context).pop();

                // Show a snackbar to indicate successful deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['name']} berhasil dihapus'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
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

  void _showFilterDialog(BuildContext context) {
  // Store the current filter values to restore if canceled
  String tempCategoryFilter = selectedCategoryFilter;
  String tempStatusFilter = selectedStatusFilter;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Barang',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Reset to previous values if dialog is closed
                          tempCategoryFilter = selectedCategoryFilter;
                          tempStatusFilter = selectedStatusFilter;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Filter
                  const Text(
                    'Kategori',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: tempCategoryFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: const [
                            DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem(
                              value: 'Audio Visual',
                              child: Text('Audio Visual'),
                            ),
                            DropdownMenuItem(
                              value: 'Perlengkapan Audio',
                              child: Text('Perlengkapan Audio'),
                            ),
                            DropdownMenuItem(
                              value: 'Furniture',
                              child: Text('Furniture'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                tempCategoryFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButton<String>(
                          value: tempStatusFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: const [
                            DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem(
                              value: 'Tersedia',
                              child: Text('Tersedia'),
                            ),
                            DropdownMenuItem(
                              value: 'Dipinjam',
                              child: Text('Dipinjam'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setDialogState(() {
                                tempStatusFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Batal Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      // Terapkan Button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategoryFilter = tempCategoryFilter;
                            selectedStatusFilter = tempStatusFilter;
                            // Also update the chip filter to match the category filter
                            selectedCategory = tempCategoryFilter;
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
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}
