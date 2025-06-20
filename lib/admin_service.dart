import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/data/model.dart';
import 'package:bcrypt/bcrypt.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'admins';

  // Hash password dengan bcrypt + salt
  static String _hashPassword(String password) {
    // Generate salt dan hash password
    String salt = BCrypt.gensalt(logRounds: 12); // 12 rounds untuk keamanan tinggi
    String hashedPassword = BCrypt.hashpw(password, salt);
    return hashedPassword;
  }

  // Verifikasi password
  static bool _verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }

  // Verifikasi login admin
  static Future<Admin?> verifyAdminLogin(String email, String password) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      Admin admin = Admin.fromFirestore(querySnapshot.docs.first);
      
      // Verifikasi password dengan bcrypt
      if (_verifyPassword(password, admin.password)) {
        return admin;
      }
      return null;
    } catch (e) {
      print('Error verifying admin login: $e');
      throw Exception('Gagal verifikasi login: ${e.toString()}');
    }
  }

  // Stream untuk mendapatkan semua admin secara real-time
  static Stream<List<Admin>> getAdminsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Admin.fromFirestore(doc))
            .toList());
  }

  // Mendapatkan semua admin (one-time fetch)
  static Future<List<Admin>> getAllAdmins() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Admin.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting admins: $e');
      return [];
    }
  }

  // Mendapatkan admin berdasarkan ID
  static Future<Admin?> getAdminById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return Admin.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting admin by ID: $e');
      return null;
    }
  }

  // Menambah admin baru dengan password hashing
  static Future<bool> addAdmin(Admin admin) async {
    try {
      // Cek apakah email sudah ada
      bool emailExists = await checkEmailExists(admin.email);
      if (emailExists) {
        throw Exception('Email sudah terdaftar');
      }

      // Hash password sebelum disimpan
      Admin adminWithHashedPassword = Admin(
        id: admin.id,
        name: admin.name,
        email: admin.email,
        password: _hashPassword(admin.password), // Hash password di sini
        role: admin.role,
        createdAt: admin.createdAt,
        updatedAt: DateTime.now(),
        phone: admin.phone,
      );

      // Tambahkan admin ke Firestore
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(adminWithHashedPassword.toMap());

      print('Admin berhasil ditambahkan dengan ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('Error adding admin: $e');
      rethrow;
    }
  }

  // Update admin dengan password hashing (jika password diubah)
  static Future<bool> updateAdmin(String id, Admin admin, {bool updatePassword = false}) async {
    try {
      // Cek apakah email sudah digunakan oleh admin lain
      bool emailExists = await checkEmailExistsForUpdate(id, admin.email);
      if (emailExists) {
        throw Exception('Email sudah digunakan oleh admin lain');
      }

      Map<String, dynamic> updateData = admin.toUpdateMap();
      
      // Jika password perlu diupdate, hash password baru
      if (updatePassword && admin.password.isNotEmpty) {
        updateData['password'] = _hashPassword(admin.password);
      } else {
        // Hapus password dari update data jika tidak perlu diupdate
        updateData.remove('password');
      }

      await _firestore
          .collection(_collection)
          .doc(id)
          .update(updateData);

      print('Admin berhasil diupdate');
      return true;
    } catch (e) {
      print('Error updating admin: $e');
      rethrow;
    }
  }

  // Hapus admin
  static Future<bool> deleteAdmin(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .delete();

      print('Admin berhasil dihapus');
      return true;
    } catch (e) {
      print('Error deleting admin: $e');
      rethrow;
    }
  }

  // Cek apakah email sudah ada
  static Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email exists: $e');
      return false;
    }
  }

  // Cek apakah email sudah digunakan oleh admin lain (untuk update)
  static Future<bool> checkEmailExistsForUpdate(String adminId, String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .get();

      // Filter hasil untuk mengecualikan admin yang sedang diupdate
      return snapshot.docs.any((doc) => doc.id != adminId);
    } catch (e) {
      print('Error checking email exists for update: $e');
      return false;
    }
  }

  // Search admin berdasarkan nama
  static Future<List<Admin>> searchAdminsByName(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllAdmins();
      }

      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .startAt([query.toLowerCase()])
          .endAt([query.toLowerCase() + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => Admin.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching admins: $e');
      return [];
    }
  }

  // Mendapatkan jumlah total admin
  static Future<int> getTotalAdminsCount() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting total admins count: $e');
      return 0;
    }
  }

  // Mendapatkan admin berdasarkan role
  static Future<List<Admin>> getAdminsByRole(String role) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Admin.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting admins by role: $e');
      return [];
    }
  }

  // Change password untuk admin yang sudah ada
  static Future<bool> changeAdminPassword(String adminId, String oldPassword, String newPassword) async {
    try {
      // Ambil data admin
      Admin? admin = await getAdminById(adminId);
      if (admin == null) {
        throw Exception('Admin tidak ditemukan');
      }

      // Verifikasi password lama
      if (!_verifyPassword(oldPassword, admin.password)) {
        throw Exception('Password lama tidak sesuai');
      }

      // Update password dengan hash baru
      await _firestore
          .collection(_collection)
          .doc(adminId)
          .update({
            'password': _hashPassword(newPassword),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Password berhasil diubah');
      return true;
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  // Reset password admin (untuk super admin)
  static Future<bool> resetAdminPassword(String adminId, String newPassword) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(adminId)
          .update({
            'password': _hashPassword(newPassword),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Password berhasil direset');
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  // Mendapatkan current user (untuk authentication check)
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Cek apakah user sudah login
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  
}
