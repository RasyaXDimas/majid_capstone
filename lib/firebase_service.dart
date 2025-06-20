import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone/data/model.dart';

class FirebaseService {
  final CollectionReference barangCollection =
      FirebaseFirestore.instance.collection('barangInventris');

   Future<List<Barang>> fetchBarang() async {
    final snapshot = await barangCollection.get();
    return snapshot.docs.map((doc) => Barang.fromFirestore(doc)).toList();
  }

  Future<void> addBarang(Barang barang) async {
    await barangCollection.add(barang.toMap());
  }

  Future<void> updateBarang(String id, Barang barang) async {
    await barangCollection.doc(id).update(barang.toMap());
  }

  Future<void> deleteBarang(String id) async {
    await barangCollection.doc(id).delete();
  }

  Future<List<Barang>> fetchFilteredBarang(String kategori) async {
    final snapshot = await barangCollection
        .where('kategori', isEqualTo: kategori)
        .get();
    return snapshot.docs.map((doc) => Barang.fromFirestore(doc)).toList();
  }

  
}
