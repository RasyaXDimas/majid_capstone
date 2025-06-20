import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:capstone/data/model.dart'; // model.dart is not directly used for Log display here
import 'package:intl/intl.dart';

class LogInventarisPage extends StatefulWidget {
  const LogInventarisPage({super.key});

  @override
  State<LogInventarisPage> createState() => _LogInventarisPageState();
}

class _LogInventarisPageState extends State<LogInventarisPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String selectedFilter = 'Semua'; // This filters by 'action' type

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  List<QueryDocumentSnapshot> getFilteredLogs(List<QueryDocumentSnapshot> logs) {
    return logs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Filter berdasarkan tipe aksi (Tambah, Edit, Hapus, Status)
      final actionMatch = selectedFilter == 'Semua' || data['action'] == selectedFilter;
      
      // Filter berdasarkan kata kunci pencarian (itemName, adminName, itemId)
      final searchMatch = _searchQuery.isEmpty ||
          (data['itemName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (data['adminName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (data['itemId']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (data['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false); // Added description to search
      
      return actionMatch && searchMatch;
    }).toList();
  }

  IconData getActionIcon(String action) {
    switch (action) {
      case 'Tambah':
        return Icons.add_circle_outline;
      case 'Edit':
        return Icons.edit_note_outlined;
      case 'Hapus':
        return Icons.delete_outline;
      case 'Status':
        return Icons.published_with_changes_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color getActionColor(String action) {
    switch (action) {
      case 'Tambah':
        return Colors.green.shade700;
      case 'Edit':
        return Colors.blue.shade700;
      case 'Hapus':
        return Colors.red.shade700;
      case 'Status':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff348E9C),
        title: const Text(
          'Log Riwayat Inventaris',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari log (item, admin, ID, deskripsi)...',
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
            
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Tambah'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Edit'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hapus'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Status'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Log List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('LogInventaris') // Changed collection name
                    .orderBy('timestamp', descending: true)
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
                            Icons.history_toggle_off_outlined, // Changed icon
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tidak ada log aktivitas.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allLogs = snapshot.data!.docs;
                  final filteredLogs = getFilteredLogs(allLogs);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Counter
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _searchQuery.isNotEmpty || selectedFilter != 'Semua'
                              ? 'Menampilkan ${filteredLogs.length} dari ${allLogs.length} entri log'
                              : 'Total ${allLogs.length} entri log',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      
                      // Log Items
                      Expanded(
                        child: filteredLogs.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                     Icon(
                                      Icons.search_off_outlined,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height:10),
                                    Text(
                                      'Tidak ada log yang cocok dengan filter atau pencarian Anda.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredLogs.length,
                                itemBuilder: (context, index) {
                                  final doc = filteredLogs[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                                  final action = data['action']?.toString() ?? 'Info';
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                                    elevation: 1.5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Action Icon
                                          Container(
                                            padding: const EdgeInsets.all(10), // Increased padding
                                            decoration: BoxDecoration(
                                              color: getActionColor(action).withOpacity(0.12), // Adjusted opacity
                                              borderRadius: BorderRadius.circular(10), // More rounded
                                            ),
                                            child: Icon(
                                              getActionIcon(action),
                                              color: getActionColor(action),
                                              size: 22, // Slightly larger icon
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          
                                          // Log Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['description'] ?? 'Tidak ada deskripsi.',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600, // Bolder
                                                    fontSize: 14.5, // Slightly larger
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'Item: ${data['itemName'] ?? '-'} (ID: ${data['itemId'] ?? '-'})',
                                                  style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.person_outline, size: 15, color: Colors.grey[600]),
                                                    const SizedBox(width: 5),
                                                    Expanded( // Added Expanded to prevent overflow
                                                      child: Text(
                                                        data['adminName'] ?? 'N/A',
                                                        style: TextStyle(
                                                          color: Colors.grey[700],
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12), // Spacing
                                                    Icon(Icons.access_time_outlined, size: 15, color: Colors.grey[600]),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      timestamp != null 
                                                          ? DateFormat('dd MMM yyyy, HH:mm:ss').format(timestamp)
                                                          : 'N/A',
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedFilter = label;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xff348E9C),
      checkmarkColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: isSelected ? const Color(0xff348E9C) : Colors.grey[400]!)),
    );
  }
}