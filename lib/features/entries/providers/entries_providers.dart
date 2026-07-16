import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/entries_repository.dart';
import '../data/entry_model.dart';

final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final entriesRepositoryProvider = Provider<EntriesRepository>((ref) {
  return EntriesRepository(ref.watch(firestoreProvider));
});

final entriesStreamProvider = StreamProvider.autoDispose<List<Entry>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const <Entry>[]);
  return ref.watch(entriesRepositoryProvider).watchEntries(uid);
});
