// lib/admin_auth_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart'; // Pastikan package ini ada di pubspec.yaml
import 'package:flutter/foundation.dart';

// ... (Class AdminUser tetap sama) ...
class AdminUser {
  final String email;
  final String? name;
  AdminUser({required this.email, this.name});
  @override
  String toString() {
    return 'AdminUser(email: $email, name: $name)';
  }
}


class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;

  // --- UBAH BAGIAN INI ---
  static const String _adminLoggedInKey = 'isAdminLoggedIn'; // SESUAIKAN DENGAN LoginPage
  static const String _adminEmailKey = 'adminEmail';      // SESUAIKAN DENGAN LoginPage
  static const String _adminNameKey = 'adminName';        // SESUAIKAN DENGAN LoginPage
  // --- AKHIR PERUBAHAN KUNCI ---

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<AdminUser?> _adminAuthController = StreamController<AdminUser?>.broadcast();
  Stream<AdminUser?> get adminAuthStateChanges => _adminAuthController.stream;

  AdminAuthService._internal() {
    if (kDebugMode) {
      print('[AdminAuthService] Constructor: Initializing and calling _checkInitialAuthState...');
    }
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    // ... (sisa fungsi _checkInitialAuthState tetap sama, menggunakan konstanta yang sudah diubah di atas) ...
    // Contoh pembacaan akan menjadi:
    // final bool isLoggedIn = prefs.getBool(_adminLoggedInKey) ?? false;
    // final email = prefs.getString(_adminEmailKey);
    // final name = prefs.getString(_adminNameKey);
    // (Tidak perlu mengubah implementasi di sini, hanya konstanta di atas)
    if (kDebugMode) {
      print('[AdminAuthService] _checkInitialAuthState: Starting check...');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool(_adminLoggedInKey) ?? false; // Akan menggunakan 'isAdminLoggedIn'
      if (kDebugMode) {
        print('[AdminAuthService] _checkInitialAuthState: SharedPreferences - isLoggedIn ($isLoggedIn) using key "$_adminLoggedInKey"');
      }

      if (isLoggedIn) {
        final email = prefs.getString(_adminEmailKey); // Akan menggunakan 'adminEmail'
        final name = prefs.getString(_adminNameKey);   // Akan menggunakan 'adminName'
        if (kDebugMode) {
          print('[AdminAuthService] _checkInitialAuthState: SharedPreferences - email ($email) using key "$_adminEmailKey", name ($name) using key "$_adminNameKey"');
        }
        if (email != null) {
          final user = AdminUser(email: email, name: name);
          if (kDebugMode) {
            print('[AdminAuthService] _checkInitialAuthState: User found in prefs. Emitting user: $user');
          }
          _adminAuthController.add(user);
        } else {
          if (kDebugMode) {
            print('[AdminAuthService] _checkInitialAuthState: Inconsistent state (loggedIn but no email). Clearing session and emitting null.');
          }
          await _clearAdminSessionFromPrefs();
          _adminAuthController.add(null);
        }
      } else {
        if (kDebugMode) {
          print('[AdminAuthService] _checkInitialAuthState: Not logged in according to prefs. Emitting null.');
        }
        _adminAuthController.add(null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuthService] _checkInitialAuthState: Error loading auth state: $e. Emitting null.');
      }
      _adminAuthController.add(null);
    }
  }

  // Fungsi signInAdmin ini sebaiknya digunakan untuk menggantikan logika login Admin di LoginPage
  // agar pengelolaan SharedPreferences terpusat.
  Future<bool> signInAdmin(String email, String plainPassword) async {
    if (kDebugMode) {
      print('[AdminAuthService] signInAdmin: Attempting login for $email');
    }
    try {
      // Ini mengasumsikan Anda ingin AdminAuthService yang melakukan query.
      // Jika Anda tetap ingin AdminService.verifyAdminLogin, maka bagian ini perlu disesuaikan.
      final QuerySnapshot adminQuery = await _firestore
          .collection('admins') // Pastikan nama koleksi benar
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        final adminDoc = adminQuery.docs.first;
        final adminData = adminDoc.data() as Map<String, dynamic>;
        final String storedHashedPassword = adminData['password']; // Dari Firestore
        final String? adminName = adminData['name'];             // Dari Firestore
        final String adminEmailFromDb = adminData['email'];        // Dari Firestore

        final bool isPasswordCorrect = BCrypt.checkpw(plainPassword, storedHashedPassword);

        if (isPasswordCorrect) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_adminLoggedInKey, true);       // Menyimpan dengan kunci yang sudah diselaraskan
          await prefs.setString(_adminEmailKey, adminEmailFromDb); // Menyimpan dengan kunci yang sudah diselaraskan
          if (adminName != null) {
            await prefs.setString(_adminNameKey, adminName);   // Menyimpan dengan kunci yang sudah diselaraskan
          } else {
            await prefs.remove(_adminNameKey);
          }
          final user = AdminUser(email: adminEmailFromDb, name: adminName);
          if (kDebugMode) {
            print('[AdminAuthService] signInAdmin: Login successful. Emitting user: $user');
          }
          _adminAuthController.add(user);
          return true;
        }
      }
      if (kDebugMode) {
        print('[AdminAuthService] signInAdmin: Email $email not found or password incorrect.');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('[AdminAuthService] signInAdmin: Error during sign in for $email: $e.');
      }
      return false;
    }
  }


  Future<void> _clearAdminSessionFromPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminLoggedInKey);
      await prefs.remove(_adminEmailKey);
      await prefs.remove(_adminNameKey);
      if (kDebugMode) {
        print('[AdminAuthService] _clearAdminSessionFromPrefs: Cleared admin session from SharedPreferences.');
      }
  }

  Future<void> signOutAdmin() async {
    if (kDebugMode) { print('[AdminAuthService] signOutAdmin: Called.'); }
    await _clearAdminSessionFromPrefs();
    _adminAuthController.add(null);
    if (kDebugMode) { print('[AdminAuthService] signOutAdmin: Emitted null.'); }
  }

  Future<AdminUser?> getCurrentAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(_adminLoggedInKey) ?? false;
    if (kDebugMode) {
       print('[AdminAuthService] getCurrentAdmin: SharedPreferences - isLoggedIn: $isLoggedIn');
    }
    if (isLoggedIn) {
      final email = prefs.getString(_adminEmailKey);
      final name = prefs.getString(_adminNameKey);
      if (email != null) {
        return AdminUser(email: email, name: name);
      }
    }
    return null;
  }

  void dispose() {
    // _adminAuthController.close(); // Umumnya tidak ditutup untuk singleton
  }
}