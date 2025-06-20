import 'package:capstone/widgets/drawer.dart';
import 'package:capstone/data/model.dart'; // Import model yang sudah dibuat
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk real-time updates
  Stream<QuerySnapshot>? _kajianStream;
  Stream<QuerySnapshot>? _jadwalImamStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeStreams();
  }

  void _initializeStreams() {
    _kajianStream = _firestore
        .collection('kajian')
        .orderBy('tanggal', descending: false)
        .snapshots();

    _jadwalImamStream = _firestore
        .collection('jadwalImam')
        .orderBy('waktu', descending: false)
        .snapshots();
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

  void _onEditJadwalPressed(dynamic data, String docId) {
    if (_tabController.index == 0) {
      _showEditJadwalKajianDialog(context, data, docId);
    } else {
      _showEditJadwalImamDialog(context, data, docId);
    }
  }

  // Method untuk menambah kajian ke Firestore
  Future<void> _addKajianToFirestore(Kajian kajian) async {
    try {
      await _firestore.collection('kajian').add(kajian.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal kajian berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Method untuk menambah jadwal imam ke Firestore
  Future<void> _addJadwalImamToFirestore(JadwalImam jadwalImam) async {
    try {
      await _firestore.collection('jadwalImam').add(jadwalImam.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal imam berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Method untuk update kajian
  Future<void> _updateKajianInFirestore(String docId, Kajian kajian) async {
    try {
      await _firestore.collection('kajian').doc(docId).update(kajian.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal kajian berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Method untuk update jadwal imam
  Future<void> _updateJadwalImamInFirestore(
      String docId, JadwalImam jadwalImam) async {
    try {
      await _firestore
          .collection('jadwalImam')
          .doc(docId)
          .update(jadwalImam.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal imam berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Method untuk delete dari Firestore
  Future<void> _deleteFromFirestore(
      String collection, String docId, String itemName) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName berhasil dihapus'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const DashboardDrawer(selectedMenu: 'Kajian & Imam'),
        backgroundColor: const Color(0xffF4F4F4),
        appBar: AppBar(
          backgroundColor: const Color(0xff348E9C),
          title: const Text('Masjid Al-Waraq'),
          centerTitle: true,
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
                labelColor: const Color(0xff348E9C),
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xff348E9C),
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
                    // Tab Jadwal Kajian
                    StreamBuilder<QuerySnapshot>(
                      stream: _kajianStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final kajianDocs = snapshot.data?.docs ?? [];

                        if (kajianDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Tidak ada jadwal kajian',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: kajianDocs.length,
                          itemBuilder: (context, index) {
                            final doc = kajianDocs[index];
                            final kajian = Kajian.fromFirestore(doc);
                            return _buildKajianCard(
                              kajian: kajian,
                              docId: doc.id,
                            );
                          },
                        );
                      },
                    ),
                    // Tab Jadwal Imam
                    StreamBuilder<QuerySnapshot>(
                      stream: _jadwalImamStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final jadwalImamDocs = snapshot.data?.docs ?? [];

                        if (jadwalImamDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Tidak ada jadwal imam',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: jadwalImamDocs.length,
                          itemBuilder: (context, index) {
                            final doc = jadwalImamDocs[index];
                            final jadwalImam = JadwalImam.fromFirestore(doc);

                            return _buildJadwalImamCard(
                              jadwalImam: jadwalImam,
                              docId: doc.id,
                            );
                          },
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

  Widget _buildKajianCard({
    required Kajian kajian,
    required String docId,
  }) {
    final formattedDate =
        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(kajian.tanggal);
    final formattedTime = DateFormat('HH:mm').format(kajian.tanggal);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        title: Text(kajian.judul,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('$formattedDate - $formattedTime\n${kajian.ustadz}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                _onEditJadwalPressed(kajian, docId);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(
                    context, kajian.judul, 'kajian', docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalImamCard({
    required JadwalImam jadwalImam,
    required String docId,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        title: Text(jadwalImam.jadwalSholat,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('${jadwalImam.waktu}\n${jadwalImam.ustadz}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                _onEditJadwalPressed(jadwalImam, docId);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(
                    context, jadwalImam.jadwalSholat, 'jadwalImam', docId);
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
                            : DateFormat('dd/MM/yyyy').format(selectedDate!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu',
                        hintText: 'HH:mm',
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
                            : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
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
                // Validasi input
                if (judulController.text.isEmpty ||
                    ustadzController.text.isEmpty ||
                    selectedDate == null ||
                    selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi semua field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Gabungkan tanggal dan waktu
                final combinedDateTime = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                // Buat objek Kajian
                final kajian = Kajian(
                  judul: judulController.text.trim(),
                  tanggal: combinedDateTime,
                  ustadz: ustadzController.text.trim(), 
                  id: '',
                );

                // Simpan ke Firestore
                _addKajianToFirestore(kajian);
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
    final TextEditingController waktuController = TextEditingController();

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
                    const Text('Waktu Sholat'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: sholatController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: Sholat Subuh',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Waktu'),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: waktuController,
                        decoration: const InputDecoration(
                            hintText: 'Contoh: 04:30 AM',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8)),
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
                // Validasi input
                if (sholatController.text.isEmpty ||
                    waktuController.text.isEmpty ||
                    ustadzController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi semua field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Buat objek JadwalImam
                final jadwalImam = JadwalImam(
                  jadwalSholat: sholatController.text.trim(),
                  ustadz: ustadzController.text.trim(),
                  waktu: waktuController.text.trim(), id: '',
                );

                // Simpan ke Firestore
                _addJadwalImamToFirestore(jadwalImam);
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
      BuildContext context, Kajian kajian, String docId) {
    final TextEditingController judulController =
        TextEditingController(text: kajian.judul);
    final TextEditingController ustadzController =
        TextEditingController(text: kajian.ustadz);
    DateTime selectedDate = kajian.tanggal;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(kajian.tanggal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Jadwal Kajian'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        hintText: 'dd/mm/yyyy',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
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
                        text: DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Waktu',
                        hintText: 'HH:mm',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text: '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ustadzController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Imam/Ustadz',
                      ),
                    ),
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
                // Validasi input
                if (judulController.text.isEmpty ||
                    ustadzController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi semua field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Gabungkan tanggal dan waktu
                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                // Buat objek Kajian yang sudah diupdate
                final updatedKajian = Kajian(
                  judul: judulController.text.trim(),
                  tanggal: combinedDateTime,
                  ustadz: ustadzController.text.trim(), 
                  id: '',
                );

                // Update di Firestore
                _updateKajianInFirestore(docId, updatedKajian);
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

  void _showEditJadwalImamDialog(
      BuildContext context, JadwalImam jadwalImam, String docId) {
    final TextEditingController sholatController =
        TextEditingController(text: jadwalImam.jadwalSholat);
    final TextEditingController waktuController =
        TextEditingController(text: jadwalImam.waktu);
    final TextEditingController ustadzController =
        TextEditingController(text: jadwalImam.ustadz);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Jadwal Imam'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sholatController,
                  decoration: const InputDecoration(
                    labelText: 'Waktu Sholat',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: waktuController,
                  decoration: const InputDecoration(
                    labelText: 'Waktu',
                    hintText: '--:--',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ustadzController,
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
                // Validasi input
                if (sholatController.text.isEmpty ||
                    waktuController.text.isEmpty ||
                    ustadzController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi semua field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Buat objek JadwalImam yang sudah diupdate
                final updatedJadwalImam = JadwalImam(
                  jadwalSholat: sholatController.text.trim(),
                  ustadz: ustadzController.text.trim(),
                  waktu: waktuController.text.trim(), id: '',
                );

                // Update di Firestore
                _updateJadwalImamInFirestore(docId, updatedJadwalImam);
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

  void _showDeleteConfirmationDialog(
      BuildContext context, String itemName, String collection, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus "$itemName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteFromFirestore(collection, docId, itemName);
                Navigator.pop(context);
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