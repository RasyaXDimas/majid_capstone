import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTambahJadwalPressed() {
    if (_tabController.index == 0) {
      // Tab 0 = Jadwal Kajian
      _showTambahJadwalDialog(context);
    } else {
      // Tab 1 = Jadwal Imam
      _showTambahJadwalImamDialog(context);
    }
  }

  void _onEditJadwalPressed(Map<String, String> data) {
  if (_tabController.index == 0) {
    _showEditJadwalKajianDialog(context, data);
  } else {
    _showEditJadwalImamDialog(context, data);
  }
}


  List<Map<String, String>> jadwalKajian = const [
    {
      'judul': 'Memahami Surah Al-Kahfi',
      'hariTanggal': 'Senin, 15 Mei 2025',
      'waktu': '18:30 - 19:30',
      'ustadz': 'Ustadz Abdullah',
    },
    {
      'judul': 'Pentingnya Shalat',
      'hariTanggal': 'Jumat, 19 Mei 2025',
      'waktu': '20:00 - 21:00',
      'ustadz': 'Ustadz Mahmud',
    },
    {
      'judul': 'Kisah Para Nabi',
      'hariTanggal': 'Minggu, 21 Mei 2025',
      'waktu': '10:00 - 11:30',
      'ustadz': 'Ustadz Ibrahim',
    },
    {
      'judul': 'Fiqih Puasa',
      'hariTanggal': 'Rabu, 24 Mei 2025',
      'waktu': '19:30 - 20:30',
      'ustadz': 'Ustadz Muhammad',
    },
  ];

  List<Map<String, String>> jadwalImam = const [
    {
      'sholat': 'Sholat Subuh',
      'waktu': '04:30 AM',
      'ustadz': 'Ustadz Abdullah',
    },
    {
      'sholat': 'Sholat Dhuhr',
      'waktu': '12:30 PM',
      'ustadz': 'Ustadz Mahmud',
    },
    {
      'sholat': 'Sholat Asr',
      'waktu': '03:45 PM',
      'ustadz': 'Ustadz Ibrahim',
    },
    {
      'sholat': 'Sholat Magrib',
      'waktu': '06:15 PM',
      'ustadz': 'Ustadz Muhammad',
    },
    {
      'sholat': 'Sholat Isya',
      'waktu': '07:45 PM',
      'ustadz': 'Ustadz Muhammad',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const DashboardDrawer(selectedMenu: 'Kajian & Imam'),
        appBar: AppBar(
          backgroundColor: const Color(0xff348E9C),
          title: const Text('Masjid Al-Waraq'),
          centerTitle: true,
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
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jadwal Kajian & Imam',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _onTambahJadwalPressed();
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Jadwal'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff348E9C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1),
                    )),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: Color(0xff348E9C),
                unselectedLabelColor: Colors.black54,
                indicatorColor: Color(0xff348E9C),
                tabs: const [
                  Tab(text: 'Jadwal Kajian'),
                  Tab(text: 'Jadwal Imam'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ListView.builder(
                      itemCount: jadwalKajian.length,
                      itemBuilder: (context, index) {
                        final item = jadwalKajian[index];
                        return _buildCard(
                          title: item['judul']!,
                          subtitle:
                              '${item['hariTanggal']}\n${item['waktu']}\n${item['ustadz']}',
                          data: item,
                        );
                      },
                    ),
                    ListView.builder(
                      itemCount: jadwalImam.length,
                      itemBuilder: (context, index) {
                        final item = jadwalImam[index];
                        return _buildCard(
                          title: item['sholat']!,
                          subtitle: '${item['waktu']}\n${item['ustadz']}',
                          data: item,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Map<String, String> data,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                _onEditJadwalPressed(data);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(context, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTambahJadwalDialog(BuildContext context) {
    final TextEditingController judulController = TextEditingController();
    final TextEditingController ustadzController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Jadwal Kajian'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Judul Kajian'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: judulController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Memahami Surah Al-Kahfi',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        hintText: 'dd/mm/yy',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: selectedDate == null
                            ? ''
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu',
                        hintText: '--:--',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: selectedTime == null
                            ? ''
                            : selectedTime!.format(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nama Imam/Ustadz'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: ustadzController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Ustadz Abdullah',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lakukan validasi atau simpan data di sini
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff348E9C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showTambahJadwalImamDialog(BuildContext context) {
    final TextEditingController sholatController = TextEditingController();
    final TextEditingController ustadzController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Jadwal Imam'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Judul Kajian'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: sholatController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Sholat Shubuh',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu',
                        hintText: '--:--',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: selectedTime == null
                            ? ''
                            : selectedTime!.format(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Nama Imam/Ustadz'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: ustadzController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Ustadz Abdullah',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lakukan validasi atau simpan data di sini
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff348E9C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditJadwalKajianDialog(
      BuildContext context, Map<String, String> jadwalKajian) {
    final TextEditingController judulController =
        TextEditingController(text: jadwalKajian['judul']);
    final TextEditingController tanggalController =
        TextEditingController(text: jadwalKajian['hariTanggal']);
    final TextEditingController waktuController =
        TextEditingController(text: jadwalKajian['waktu']);
    final TextEditingController imamController =
        TextEditingController(text: jadwalKajian['ustadz']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Jadwal Kajian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Kajian',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tanggalController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                    hintText: 'dd/mm/yyyy',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waktuController,
                  decoration: const InputDecoration(
                    labelText: 'Waktu',
                    hintText: '--:--',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imamController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Imam/Ustadz',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simpan logika update data di sini
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('${jadwalKajian['judul']} berhasil diperbarui'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff348E9C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditJadwalImamDialog(
      BuildContext context, Map<String, String> jadwalImam) {
    final TextEditingController sholatController =
        TextEditingController(text: jadwalImam['sholat']);
    final TextEditingController waktuController =
        TextEditingController(text: jadwalImam['waktu']);
    final TextEditingController imamController =
        TextEditingController(text: jadwalImam['ustadz']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Jadwal Kajian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sholatController,
                  decoration: const InputDecoration(
                    labelText: 'Waktu Solat',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waktuController,
                  decoration: const InputDecoration(
                    labelText: 'Waktu',
                    hintText: '--:--',
                    suffixIcon: Icon(Icons.access_time),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imamController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Imam/Ustadz',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simpan logika update data di sini
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${jadwalImam['solat']} berhasil diperbarui'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff348E9C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
                'Apakah anda yakin ingin menghapus kajian ini?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '${item['judul']})',
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
                  jadwalKajian = List.from(jadwalKajian);
                  jadwalKajian.removeWhere(
                      (element) => element['judul'] == item['judul']);
                });
                // Close the dialog
                Navigator.of(context).pop();

                // Show a snackbar to indicate successful deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['judul']} berhasil dihapus'),
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
}
