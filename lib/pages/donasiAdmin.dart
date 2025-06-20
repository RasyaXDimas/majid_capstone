import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:capstone/data/model.dart';
import 'package:capstone/donasi_services.dart';

class Donasiadmin extends StatelessWidget {
  const Donasiadmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waraq',
      theme: ThemeData(
        primaryColor: const Color(0xff348E9C),
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

class DonationManagementScreen extends StatefulWidget {
  const DonationManagementScreen({super.key});

  @override
  State<DonationManagementScreen> createState() =>
      _DonationManagementScreenState();
}

class _DonationManagementScreenState extends State<DonationManagementScreen> {
  String _timeFilter = 'Semua Waktu';
  String _paymentFilter = 'Semua Metode Pembayaran';
  bool _isLoading = false;

  // Format number to Indonesian Rupiah
  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'id');
    return 'Rp ${formatter.format(amount)}';
  }

  // Format date to Indonesian format
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
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

  // Calculate total donations from filtered list
  int _calculateTotal(List<Donation> donations) {
    return donations.fold(0, (sum, donation) => sum + donation.amount);
  }

  // Filter donations based on selected filters
  List<Donation> _filterDonations(List<Donation> donations) {
    return donations.where((donation) {
      // Time filter
      if (_timeFilter == 'Minggu Ini') {
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        if (donation.tanggal.isBefore(oneWeekAgo)) return false;
      } else if (_timeFilter == 'Bulan Ini') {
        final now = DateTime.now();
        if (donation.tanggal.month != now.month ||
            donation.tanggal.year != now.year) {
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              child: Container(
                width: double.maxFinite,
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
                    GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          method = method == 'Cash' ? 'Bank Transfer' : 'Cash';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(method),
                      ),
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
                          onPressed: _isLoading ? null : () async {
                            if (nameController.text.isNotEmpty && 
                                amountController.text.isNotEmpty) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final donation = Donation(
                                  id: '', // Will be generated by Firestore
                                  name: nameController.text,
                                  amount: int.tryParse(amountController.text) ?? 0,
                                  tanggal: _parseDateFromForm(dateController.text),
                                  method: method,
                                );

                                await DonationService.addDonation(donation);
                                
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Donasi berhasil ditambahkan'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Simpan', style: TextStyle(color: Colors.white)),
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

  // Show edit donation dialog
  void _showEditDonationDialog(Donation donation) {
    final nameController = TextEditingController(text: donation.name);
    final amountController =
        TextEditingController(text: donation.amount.toString());
    final dateController =
        TextEditingController(text: _formatDateForForm(donation.tanggal));
    String method = donation.method;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          method = method == 'Cash' ? 'Bank Transfer' : 'Cash';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(method),
                      ),
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
                          onPressed: _isLoading ? null : () async {
                            if (nameController.text.isNotEmpty && 
                                amountController.text.isNotEmpty) {
                              setState(() {
                                _isLoading = true;
                              });

                              try {
                                final updatedDonation = donation.copyWith(
                                  name: nameController.text,
                                  amount: int.tryParse(amountController.text) ?? 0,
                                  tanggal: _parseDateFromForm(dateController.text),
                                  method: method,
                                );

                                await DonationService.updateDonation(updatedDonation);
                                
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Donasi berhasil diperbarui'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Simpan', style: TextStyle(color: Colors.white)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });

                try {
                  await DonationService.deleteDonation(donation.id);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Donasi berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Hapus', style: TextStyle(color: Colors.white)),
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
                Scaffold.of(context).openDrawer();
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

            // StreamBuilder for donations
            Expanded(
              child: StreamBuilder<List<Donation>>(
                stream: DonationService.getDonationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allDonations = snapshot.data ?? [];
                  final filteredDonations = _filterDonations(allDonations);
                  final totalDonations = _calculateTotal(filteredDonations);

                  return Column(
                    children: [
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
                              _formatCurrency(totalDonations),
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
                                  const Icon(Icons.payment,
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
                        child: filteredDonations.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.volunteer_activism,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Belum ada donasi',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredDonations.length,
                                itemBuilder: (context, index) {
                                  final donation = filteredDonations[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              donation.method == 'Cash'
                                                  ? Icons.money
                                                  : Icons.account_balance,
                                              color: Theme.of(context).primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          
                                          // Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  donation.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatCurrency(donation.amount),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.green.shade600,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatDate(donation.tanggal),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: donation.method == 'Cash'
                                                            ? Colors.orange.shade100
                                                            : Colors.blue.shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        donation.method,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: donation.method == 'Cash'
                                                              ? Colors.orange.shade700
                                                              : Colors.blue.shade700,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Actions
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showEditDonationDialog(donation);
                                              } else if (value == 'delete') {
                                                _showDeleteConfirmationDialog(donation);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 18, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
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
