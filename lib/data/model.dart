import 'package:cloud_firestore/cloud_firestore.dart';

class Barang {
  final String id;
  final String nama;
  final List<String> kategori;
  final String status;

  Barang(
      {required this.id,
      required this.nama,
      required this.kategori,
      required this.status});

  factory Barang.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Barang(
        id: doc.id,
        nama: data['name'] ?? '',
        kategori: (data['category'] is List)
            ? List<String>.from(data['category'])
            : [],
        status: data['status'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'nama': nama, 'kategori': kategori, 'status': status};
  }
}

class Kajian {
  final String id; // Firestore Document ID
  final String judul;
  final DateTime tanggal;
  final String ustadz;

  Kajian({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.ustadz,
  });

  // Factory method untuk mengambil dari Firestore
  factory Kajian.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Kajian(
      id: doc.id,
      judul: data['judul'] ?? '',
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      ustadz: data['ustadz'] ?? '',
    );
  }

  // Untuk mengubah kembali menjadi Map saat menambah ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'tanggal': Timestamp.fromDate(tanggal),
      'ustadz': ustadz,
    };
  }
}

class JadwalImam {
  final String id;
  final String jadwalSholat;
  final String ustadz;
  final String waktu; // format waktu: "HH:mm" (misal: "05:30")

  JadwalImam({
    required this.id,
    required this.jadwalSholat,
    required this.ustadz,
    required this.waktu,
  });

  // Factory method untuk konversi dari Firestore
  factory JadwalImam.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return JadwalImam(
      id: doc.id,
      jadwalSholat: data['jadwalSholat'] ?? '',
      ustadz: data['ustadz'] ?? '',
      waktu: data['waktu'] ?? '',
    );
  }

  // Konversi ke Map (untuk menambahkan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'jadwalSholat': jadwalSholat,
      'ustadz': ustadz,
      'waktu': waktu,
    };
  }
}

class PeminjamanItem {
  final String id;
  final String name;
  final String borrower;
  final String requestDate; // This is the formatted string for display
  String status;
  final String description;
  final String ticketId;
  final DateTime? tanggalPengajuan; // Actual DateTime object
  final DateTime? tanggalDisetujui;
  final DateTime? tanggalPengembalian;
  final String ktpImageUrl;

  PeminjamanItem(
      {required this.id,
      required this.name,
      required this.borrower,
      required this.requestDate,
      required this.status,
      required this.description,
      required this.ticketId,
      this.tanggalPengajuan,
      this.tanggalDisetujui,
      this.tanggalPengembalian,
      required this.ktpImageUrl});

  // Factory constructor to create PeminjamanItem from Firestore document
  factory PeminjamanItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PeminjamanItem(
        id: data['idBarang'] ?? '',
        name: data['namaBarang'] ?? '',
        borrower: data['peminjam'] ?? '',
        // Use the public formatDate for the display string
        requestDate: formatDate(data['tanggalPengajuan'] as Timestamp?),
        // Use the public mapFirestoreStatus for the display status
        status: mapFirestoreStatus(data['status'] ?? 'Tertunda'),
        description: data['keterangan'] ?? '',
        ticketId: data['ticketId'] ?? '',
        tanggalPengajuan: (data['tanggalPengajuan'] as Timestamp?)?.toDate(),
        tanggalDisetujui: (data['tanggalDisetujui'] as Timestamp?)?.toDate(),
        tanggalPengembalian:
            (data['tanggalPengembalian'] as Timestamp?)?.toDate(),
        ktpImageUrl: data['ktpImageUrl'] ?? '');
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'idBarang': id,
      'namaBarang': name,
      'peminjam': borrower,
      // Use the public mapToFirestoreStatus to save the correct status value
      'status': mapToFirestoreStatus(status),
      'keterangan': description,
      'ticketId': ticketId,
      'tanggalPengajuan': tanggalPengajuan != null
          ? Timestamp.fromDate(tanggalPengajuan!)
          : null,
      'tanggalDisetujui': tanggalDisetujui != null
          ? Timestamp.fromDate(tanggalDisetujui!)
          : null,
      'tanggalPengembalian': tanggalPengembalian != null
          ? Timestamp.fromDate(tanggalPengembalian!)
          : null,
      'ktpImageUrl': ktpImageUrl
    };
  }

  // Helper method to format date - NOW PUBLIC
  static String formatDate(Timestamp? timestamp) {
    //
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  // Map Firestore status to display status - NOW PUBLIC
  static String mapFirestoreStatus(String firestoreStatus) {
    //
    switch (firestoreStatus.toLowerCase()) {
      case 'tertunda':
        return 'Tertunda';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'menunggu konfirmasi pengembalian':
        return 'Menunggu Konfirmasi Pengembalian';
      default:
        return 'Tertunda'; // Default to Tertunda if status is unrecognized
    }
  }

  // Map display status to Firestore status - NOW PUBLIC
  static String mapToFirestoreStatus(String displayStatus) {
    //
    switch (displayStatus) {
      case 'Tertunda':
        return 'tertunda';
      case 'Disetujui':
        return 'disetujui';
      case 'Ditolak':
        return 'ditolak';
      case 'Dikembalikan':
        return 'dikembalikan';
      case 'menunggu konfirmasi pengembalian':
        return 'Menunggu Konfirmasi Pengembalian';
      default:
        return 'tertunda'; // Default to tertunda if status is unrecognized
    }
  }
}

// Model for inventory items
class BarangInventaris {
  final String id;
  final String name;
  final String category;
  final String status;
  final String kondisi;

  BarangInventaris({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.kondisi,
  });

  factory BarangInventaris.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return BarangInventaris(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'tersedia',
      kondisi: data['kondisi'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'kondisi': kondisi,
    };
  }

  // Helper method to check if item can be borrowed
  bool get canBeBorrowed => status.toLowerCase() == 'tersedia';

  // Helper method to get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'tersedia':
        return 'Tersedia';
      case 'dipinjam':
        return 'Dipinjam';
      case 'tidak tersedia':
        return 'Tidak Tersedia';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'tersedia':
        return 'green';
      case 'Dipinjam':
        return 'orange';
      case 'tidak tersedia':
        return 'red';
      default:
        return 'grey';
    }
  }
}

class Donation {
  final String id;
  String name;
  int amount;
  DateTime tanggal;
  String method;

  Donation({
    required this.id,
    required this.name,
    required this.amount,
    required this.tanggal,
    required this.method,
  });

  // Convert from Firestore DocumentSnapshot
  factory Donation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      name: data['name'] ?? '',
      amount: data['amount'] ?? 0,
      tanggal: (data['tanggal'] as Timestamp).toDate(),
      method: data['method'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'tanggal': Timestamp.fromDate(tanggal),
      'method': method,
    };
  }

  // Convert from Map (for compatibility with existing code if needed)
  factory Donation.fromMap(Map<String, dynamic> map, String id) {
    return Donation(
      id: id,
      name: map['name'] ?? '',
      amount: map['amount'] ?? 0,
      tanggal: map['tanggal'] is Timestamp
          ? (map['tanggal'] as Timestamp).toDate()
          : DateTime.parse(map['tanggal']),
      method: map['method'] ?? '',
    );
  }

  // Create a copy with updated fields
  Donation copyWith({
    String? id,
    String? name,
    int? amount,
    DateTime? tanggal,
    String? method,
  }) {
    return Donation(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      tanggal: tanggal ?? this.tanggal,
      method: method ?? this.method,
    );
  }
}

class Admin {
  final String id;
  String name;
  String email;
  String phone;
  String role;
  String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor untuk membuat Admin dari Firestore DocumentSnapshot
  factory Admin.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Admin(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'admin',
      password: data['password'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Factory constructor untuk membuat Admin dari Map
  factory Admin.fromMap(Map<String, dynamic> map, String id) {
    return Admin(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: (map['role'] ?? 'admin').toString(), // Ensure it's a string
      password: map['password'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Method untuk convert ke Map untuk Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'password': password,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Method untuk update admin (tidak mengubah createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'password': password,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Copy with method untuk membuat salinan dengan perubahan
  Admin copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Admin(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Admin{id: $id, name: $name, email: $email, phone: $phone, role: $role}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Admin && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
