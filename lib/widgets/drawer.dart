import 'package:flutter/material.dart';
import '../pages/admin_dashboard.dart';
import '../pages/InventoryPage.dart';

class DashboardDrawer extends StatelessWidget {
  final String selectedMenu;

  const DashboardDrawer({super.key, required this.selectedMenu});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide.none),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const Spacer(),
                InkWell(
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop(); // Menutup drawer
                    },
                  ),
                )
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Dashboard',
            isActive: selectedMenu == 'Dashboard',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.inventory_2,
            title: 'Inventaris',
            isActive: selectedMenu == 'Inventaris',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_month,
            title: 'Kajian & Imam',
            isActive: selectedMenu == 'Kajian & Imam',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.assignment_return,
            title: 'Peminjaman Barang',
            isActive: selectedMenu == 'Peminjaman Barang',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.volunteer_activism,
            title: 'Donasi',
            isActive: selectedMenu == 'Donasi',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.group,
            title: 'Kelola Admin',
            isActive: selectedMenu == 'Kelola Admin',
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                  color: Colors.red, fontSize: 20, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              // Aksi logout
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isActive = false,
  }) {
    return ListTile(
      tileColor: isActive ? Colors.teal.shade100 : null,
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 20),
      ),
      onTap: () {
        // Navigasi sesuai title atau id menu
        Navigator.pop(context); // Tutup drawer dulu

        if (title == 'Dashboard' && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (title == 'Inventaris' && !isActive) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InventoryPage()),
          );
        } else if (title == 'Kajian & Imam' && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (title == 'Peminjaman Barang' && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (title == 'Donasi' && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (title == 'Kelola Admin' && !isActive) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        }
      },
    );
  }
}
