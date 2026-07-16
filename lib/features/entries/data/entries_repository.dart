import 'package:cloud_firestore/cloud_firestore.dart';

import 'entry_model.dart';

class EntriesRepository {
  EntriesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _db.collection('users').doc(uid).collection('entries');

  Stream<List<Entry>> watchEntries(String uid) {
    return _entries(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Entry.fromFirestore).toList());
  }

  Future<String> addEntry(String uid, Entry entry) async {
    final data = entry.toContentMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _entries(uid).add(data);
    return ref.id;
  }

  Future<void> updateEntry(String uid, Entry entry) async {
    final data = entry.toContentMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _entries(uid).doc(entry.id).update(data);
  }

  Future<void> deleteEntry(String uid, String entryId) async {
    await _entries(uid).doc(entryId).delete();
  }
}
