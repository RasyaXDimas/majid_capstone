import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/data/model.dart';

class DonationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'donasi';

  // Get donations stream
  static Stream<List<Donation>> getDonationsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donation.fromFirestore(doc))
            .toList());
  }

  // Add donation
  static Future<void> addDonation(Donation donation) async {
    try {
      await _firestore.collection(_collectionName).add(donation.toFirestore());
    } catch (e) {
      throw Exception('Failed to add donation: $e');
    }
  }

  // Update donation
  static Future<void> updateDonation(Donation donation) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(donation.id)
          .update(donation.toFirestore());
    } catch (e) {
      throw Exception('Failed to update donation: $e');
    }
  }

  // Delete donation
  static Future<void> deleteDonation(String donationId) async {
    try {
      await _firestore.collection(_collectionName).doc(donationId).delete();
    } catch (e) {
      throw Exception('Failed to delete donation: $e');
    }
  }

  // Get filtered donations
  static Stream<List<Donation>> getFilteredDonationsStream({
    String? timeFilter,
    String? paymentFilter,
  }) {
    Query query = _firestore.collection(_collectionName);

    // Apply time filter
    if (timeFilter == 'Minggu Ini') {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      query = query.where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo));
    } else if (timeFilter == 'Bulan Ini') {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      query = query
          .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
    }

    // Apply payment method filter
    if (paymentFilter != null && paymentFilter != 'Semua Metode Pembayaran') {
      query = query.where('method', isEqualTo: paymentFilter);
    }

    return query
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Donation.fromFirestore(doc))
            .toList());
  }
}