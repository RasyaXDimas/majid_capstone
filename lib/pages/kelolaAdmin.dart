import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:capstone/data/model.dart';
import 'package:capstone/admin_service.dart';

class Kelolaadmin extends StatelessWidget {
  const Kelolaadmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Al-Waraq',
      theme: ThemeData(
        primaryColor: const Color(0xff348E9C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff348E9C),
        ),
        useMaterial3: true,
      ),
      home: const AdminPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Admin> _admins = [];
  List<Admin> _filteredAdmins = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Admin> admins = await AdminService.getAllAdmins();
      setState(() {
        _admins = admins;
        _filteredAdmins = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data admin: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterAdmins(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAdmins = _admins;
      } else {
        _filteredAdmins = _admins
            .where((admin) =>
                admin.name.toLowerCase().contains(query.toLowerCase()) ||
                admin.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DashboardDrawer(selectedMenu: 'kelola admin'),
      appBar: AppBar(
        title: const Text(
          'Masjid Al-Waraq',
          style: TextStyle(color: Colors.white),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAdmins,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari admin...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filterAdmins,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Tambah Admin',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xff348E9C),
                ),
                onPressed: () => _showAddEditAdminDialog(context),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildAdminList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAdmins,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredAdmins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada data admin'
                  : 'Tidak ditemukan admin dengan kata kunci "$_searchQuery"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredAdmins.length,
      itemBuilder: (context, index) {
        final admin = _filteredAdmins[index];
        return AdminCard(
          admin: admin,
          onEdit: () => _showAddEditAdminDialog(context, admin),
          onDelete: admin.role == 'superadmin'
              ? null
              : () => _showDeleteConfirmationDialog(context, admin),
        );
      },
    );
  }

  Future<void> _showAddEditAdminDialog(BuildContext context,
      [Admin? admin]) async {
    final isEditing = admin != null;
    final titleText = isEditing ? 'Edit Admin' : 'Tambah Admin';
    final buttonText = isEditing ? 'Simpan Perubahan' : 'Simpan';
    final passwordLabelText =
        isEditing ? 'Password (Biarkan kosong jika tidak diubah)' : 'Password';

    final nameController = TextEditingController(text: admin?.name ?? '');
    final emailController = TextEditingController(text: admin?.email ?? '');
    final phoneController = TextEditingController(text: admin?.phone ?? '');
    final passwordController = TextEditingController();

    // Role tetap sama untuk edit, atau 'admin' untuk tambah baru
    String role = admin?.role ?? 'admin';
    bool isLoading = false;
    bool _obscurePassword = true;

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(titleText),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person),
                    ),
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      if (value.trim().length < 2) {
                        return 'Nama minimal 2 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      if (value.trim().length < 10) {
                        return 'Nomor telepon minimal 10 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Info role untuk admin baru
                  if (!isEditing) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Admin baru akan dibuat dengan role Admin',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Info role untuk edit (hanya jika superadmin)
                  if (isEditing && admin!.role == 'superadmin') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.purple.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Role Superadmin tidak dapat diubah',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: passwordLabelText,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    validator: (value) {
                      if (!isEditing && (value == null || value.isEmpty)) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Kosongkan password jika tidak ingin mengubah password',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          if (isEditing) {
                            // Update admin
                            // Cek apakah password diubah
                            bool passwordChanged = passwordController.text.isNotEmpty;
                            
                            Admin updatedAdmin = admin!.copyWith(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              role: role, // Tetap menggunakan role yang sama
                              updatedAt: DateTime.now(),
                              // Jika password tidak diubah, gunakan password lama
                              password: passwordChanged ? passwordController.text : admin.password,
                            );

                            // Panggil updateAdmin dengan parameter updatePassword
                            await AdminService.updateAdmin(
                              admin.id, 
                              updatedAdmin, 
                              updatePassword: passwordChanged
                            );
                          } else {
                            // Tambah admin baru - otomatis role 'admin'
                            Admin newAdmin = Admin(
                              id: '', // ID akan diset oleh Firestore
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              role: 'admin', // Selalu admin untuk penambahan baru
                              password: passwordController.text, // Password akan di-hash di AdminService
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            await AdminService.addAdmin(newAdmin);
                          }

                          // Tutup dialog SEBELUM menampilkan snackbar
                          Navigator.of(dialogContext).pop();

                          // Refresh data
                          _loadAdmins();

                          // Tampilkan snackbar sukses
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEditing
                                    ? 'Admin berhasil diperbarui'
                                    : 'Admin berhasil ditambahkan'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      }
                    },
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Admin admin) async {
    bool isLoading = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text('Apakah anda yakin ingin menghapus admin ini?'),
              const SizedBox(height: 8),
              Text(
                admin.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                admin.email,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        await AdminService.deleteAdmin(admin.id);

                        // Tutup dialog SEBELUM menampilkan snackbar
                        Navigator.of(dialogContext).pop();

                        // Refresh data
                        _loadAdmins();

                        // Tampilkan snackbar sukses
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Admin berhasil dihapus'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final Admin admin;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const AdminCard({
    Key? key,
    required this.admin,
    required this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    admin.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRoleChip(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    admin.email,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  admin.phone ?? '-',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dibuat: ${_formatDate(admin.createdAt)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            if (admin.updatedAt != null) ...[
              Text(
                'Diupdate: ${_formatDate(admin.updatedAt!)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(width: 8),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip() {
    final isSuper = admin.role.toLowerCase() == 'superadmin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSuper ? const Color(0xFFBF94E4) : const Color(0xFFC7F9CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isSuper ? 'Superadmin' : 'Admin',
        style: TextStyle(
          color: isSuper ? Colors.white : const Color(0xFF28a745),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}