import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

//  @override
//   State<InventoryPage> createState() => _InventoryPageState();
// }

// class _InventoryPageState extends State<InventoryPage> {
//   // Gunakan GlobalKey untuk Scaffold
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
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
        'id': 'INV001',
        'category': 'Furniture',
        'status': 'Tersedia',
      },
    ];

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
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Barang'),
                  style: ElevatedButton.styleFrom(
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
                  FilterChip(
                    label: const Text('Semua'),
                    selected: true,
                    onSelected: (_) {}, // Tambahkan ini
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Perlengkapan Audio'),
                    selected: false,
                    onSelected: (_) {}, // Tambahkan ini
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Furniture'),
                    selected: false,
                    onSelected: (_) {}, // Tambahkan ini
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = inventoryItems[index];
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['name'],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Icon(Icons.qr_code, color: Colors.purple)
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
                              _buildTag(item['category'], Colors.grey.shade300,
                                  Colors.black),
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
}
