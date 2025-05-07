import 'package:capstone/widgets/drawer.dart';
import 'package:flutter/material.dart';

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
        // elevatedButtonTheme: ElevatedButtonThemeData(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: const Color(0xff348E9C),
        //   ),
        // ),
        useMaterial3: true,
      ),
      home: const AdminPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Admin {
  final int id;
  String name;
  String email;
  String phone;
  String role;
  String password;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
  });
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final List<Admin> _admins = [
    Admin(
      id: 1,
      name: 'Ahmad Rizky',
      email: 'ahmad.rizky@gmail.com',
      phone: '081234567890',
      role: 'superadmin',
      password: 'password123',
    ),
    Admin(
      id: 2,
      name: 'Budi Santoso',
      email: 'budi.santoso@gmail.com',
      phone: '081234567891',
      role: 'admin',
      password: 'password123',
    ),
    Admin(
      id: 3,
      name: 'Citra Dewi',
      email: 'citra.dewi@gmail.com',
      phone: '081234567892',
      role: 'admin',
      password: 'password123',
    ),
    Admin(
      id: 4,
      name: 'Dian Pratama',
      email: 'dian.pratama@gmail.com',
      phone: '081234567893',
      role: 'admin',
      password: 'password123',
    ),
  ];

  String _searchQuery = '';

  List<Admin> get _filteredAdmins => _admins
      .where((admin) =>
          admin.name.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

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
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
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
              child: ListView.builder(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditAdminDialog(BuildContext context,
      [Admin? admin]) async {
    final isEditing = admin != null;
    final titleText = isEditing ? 'Edit Admin' : 'Tambah Admin';
    final buttonText = isEditing ? 'Simpan Perubahan' : 'Simpan';
    final passwordLabelText =
        isEditing ? 'Password (Biarkan jika tidak diubah)' : 'Password';

    final nameController = TextEditingController(text: admin?.name ?? '');
    final emailController = TextEditingController(text: admin?.email ?? '');
    final phoneController = TextEditingController(text: admin?.phone ?? '');
    final passwordController = TextEditingController();

    String role = admin?.role ?? 'admin';

    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role Admin',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('Superadmin'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      role = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: passwordLabelText,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (!isEditing && (value == null || value.isEmpty)) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (isEditing) {
                  setState(() {
                    admin.name = nameController.text;
                    admin.email = emailController.text;
                    admin.phone = phoneController.text;
                    admin.role = role;
                    if (passwordController.text.isNotEmpty) {
                      admin.password = passwordController.text;
                    }
                  });
                } else {
                  setState(() {
                    _admins.add(
                      Admin(
                        id: _admins.isNotEmpty ? _admins.last.id + 1 : 1,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        role: role,
                        password: passwordController.text,
                      ),
                    );
                  });
                }
                Navigator.of(context).pop();
              }
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Admin admin) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _admins.removeWhere((a) => a.id == admin.id);
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
                Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildRoleChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              admin.email,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              admin.phone,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
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
    final isSuper = admin.role == 'superadmin';
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
          fontSize: 14,
        ),
      ),
    );
  }
}
