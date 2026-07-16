import 'package:cloud_firestore/cloud_firestore.dart';

import 'entry_model.dart';

/// CRUD access to `users/{uid}/entries`, ordered by `createdAt` descending.
///
/// All Firestore access for entries goes through here — no queries in widgets.
class EntriesRepository {
  EntriesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _db.collection('users').doc(uid).collection('entries');

  /// Live list of the user's entries, newest first.
  Stream<List<Entry>> watchEntries(String uid) {
    return _entries(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Entry.fromFirestore).toList());
  }

  /// Creates a new entry and returns its generated id.
  Future<String> addEntry(String uid, Entry entry) async {
    final data = entry.toContentMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _entries(uid).add(data);
    return ref.id;
  }

  /// Updates an existing entry (touches `updatedAt`, leaves `createdAt`).
  Future<void> updateEntry(String uid, Entry entry) async {
    final data = entry.toContentMap()
      ..['updatedAt'] = FieldValue.serverTimestamp();
    await _entries(uid).doc(entry.id).update(data);
  }

  Future<void> deleteEntry(String uid, String entryId) async {
    await _entries(uid).doc(entryId).delete();
  }
}
