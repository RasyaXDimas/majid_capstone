import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Donasiadmin extends StatelessWidget {
  const Donasiadmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waraq',
      theme: ThemeData(
        primaryColor: const Color(0xff348E9C),
        // colorScheme: ColorScheme.fromSeed(
        //   seedColor: const Color(0xFF26A69A),
        //   primary: const Color(0xff348E9C),
        // ),
        appBarTheme: const AppBarTheme(
          backgroundColor: const Color(0xff348E9C),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DonationManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Donation {
  final int id;
  String name;
  int amount;
  DateTime date;
  String method;

  Donation({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.method,
  });
}

class DonationManagementScreen extends StatefulWidget {
  const DonationManagementScreen({super.key});

  @override
  State<DonationManagementScreen> createState() =>
      _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> {
  final List<Donation> _donations = [
    Donation(
      id: 1,
      name: 'Fatima Zahra',
      amount: 500000,
      date: DateTime(2025, 5, 15),
      method: 'Cash',
    ),
    Donation(
      id: 2,
      name: 'Umar Abdullah',
      amount: 1000000,
      date: DateTime(2025, 5, 14),
      method: 'Bank Transfer',
    ),
    Donation(
      id: 3,
      name: 'Ali Ibrahim',
      amount: 750000,
      date: DateTime(2025, 5, 12),
      method: 'Cash',
    ),
    Donation(
      id: 4,
      name: 'Ahmad Hasan',
      amount: 1500000,
      date: DateTime(2025, 5, 10),
      method: 'Bank Transfer',
    ),
    Donation(
      id: 5,
      name: 'Zainab Mahmud',
      amount: 1250000,
      date: DateTime(2025, 5, 8),
      method: 'Bank Transfer',
    ),
  ];

  String _timeFilter = 'Semua Waktu';
  String _paymentFilter = 'Semua Metode Pembayaran';

  // Format number to Indonesian Rupiah
  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id');
    return 'Rp ${formatter.format(amount)}';
  }

  // Format date to Indonesian format
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Format date for form input (DD/MM/YYYY)
  String _formatDateForForm(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Parse date from form format (DD/MM/YYYY)
  DateTime _parseDateFromForm(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
        int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  // Calculate total donations
  int get _totalDonations =>
      _filteredDonations.fold(0, (sum, donation) => sum + donation.amount);

  // Filter donations based on selected filters
  List<Donation> get _filteredDonations {
    return _donations.where((donation) {
      // Time filter
      if (_timeFilter == 'Minggu Ini') {
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        if (donation.date.isBefore(oneWeekAgo)) return false;
      } else if (_timeFilter == 'Bulan Ini') {
        final now = DateTime.now();
        if (donation.date.month != now.month ||
            donation.date.year != now.year) {
          return false;
        }
      }

      // Payment method filter
      if (_paymentFilter != 'Semua Metode Pembayaran' &&
          donation.method != _paymentFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  // Show add donation dialog
  void _showAddDonationDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: '0');
    final dateController =
        TextEditingController(text: _formatDateForForm(DateTime.now()));
    String method = 'Cash';

   showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            // constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tambah Donasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('Nama Donatur'),
                const SizedBox(height: 5),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Jumlah Donasi'),
                const SizedBox(height: 5),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Tanggal Donasi'),
                const SizedBox(height: 5),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Metode Pembayaran'),
                const SizedBox(height: 5),
                TextField(
                  controller: TextEditingController(text: method),
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTap: () {
                    // In a real app, you might want to show a dropdown or another dialog here
                    // For simplicity, we're just toggling between Cash and Bank Transfer
                    method = method == 'Cash' ? 'Bank Transfer' : 'Cash';
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          setState(() {
                            _donations.add(
                              Donation(
                                id: _donations.isNotEmpty ? _donations.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1 : 1,
                                name: nameController.text,
                                amount: int.tryParse(amountController.text) ?? 0,
                                date: _parseDateFromForm(dateController.text),
                                method: method,
                              ),
                            );
                          });
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show edit donation dialog
  void _showEditDonationDialog(Donation donation) {
    final nameController = TextEditingController(text: donation.name);
    final amountController =
        TextEditingController(text: donation.amount.toString());
    final dateController =
        TextEditingController(text: _formatDateForForm(donation.date));
    String method = donation.method;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Donasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Nama Donatur'),
                const SizedBox(height: 5),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Jumlah Donasi'),
                const SizedBox(height: 5),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Tanggal Donasi'),
                const SizedBox(height: 5),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 15),
                const Text('Metode Pembayaran'),
                const SizedBox(height: 5),
                TextField(
                  controller: TextEditingController(text: method),
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTap: () {
                    // In a real app, you might want to show a dropdown or another dialog here
                    method = method == 'Cash' ? 'Bank Transfer' : 'Cash';
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          setState(() {
                            final index = _donations.indexWhere((d) => d.id == donation.id);
                            if (index != -1) {
                              _donations[index].name = nameController.text;
                              _donations[index].amount = int.tryParse(amountController.text) ?? 0;
                              _donations[index].date = _parseDateFromForm(dateController.text);
                              _donations[index].method = method;
                            }
                          });
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmationDialog(Donation donation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Apakah anda yakin ingin menghapus donasi ini?',
              textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatCurrency(donation.amount)} (${donation.name})',
                style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _donations.removeWhere((d) => d.id == donation.id);
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(selectedMenu: 'donasi'),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Masjid Al-Waraq'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manajemen Donasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDonationDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Tambah Donasi',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Donations
            Container(
              padding: const EdgeInsets.all(16),
              width: double.maxFinite,
              decoration: BoxDecoration(
                color: const Color(0xffECFDF5),
                border: Border.all(color: Colors.green.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Donasi Terkumpul',
                    style: TextStyle(
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    _formatCurrency(_totalDonations),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filters
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _timeFilter,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>[
                  'Semua Waktu',
                  'Minggu Ini',
                  'Bulan Ini',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _timeFilter = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _paymentFilter,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>[
                  'Semua Metode Pembayaran',
                  'Cash',
                  'Bank Transfer',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _paymentFilter = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Donations List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredDonations.length,
                itemBuilder: (context, index) {
                  final donation = _filteredDonations[index];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Donation details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatCurrency(donation.amount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(donation.name,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(donation.date),
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.credit_card,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(donation.method,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Action buttons
                          Column(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showEditDonationDialog(donation),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirmationDialog(donation),
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
        ),
      ),
    );
  }
}
