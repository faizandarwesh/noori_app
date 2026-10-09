import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Tiny key-value store. Everything stays on the device.
abstract class LocalStore {
  Object? read(String key);
  Future<void> write(String key, Object? value);
}

class HiveStore implements LocalStore {
  HiveStore._(this._box);

  static const _boxName = 'noori';

  static Future<HiveStore> open() async {
    await Hive.initFlutter();
    return HiveStore._(await Hive.openBox<Object?>(_boxName));
  }

  final Box<Object?> _box;

  @override
  Object? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, Object? value) => _box.put(key, value);
}

/// For tests and previews.
class MemoryStore implements LocalStore {
  MemoryStore([Map<String, Object?>? initial]) : _data = {...?initial};

  final Map<String, Object?> _data;

  @override
  Object? read(String key) => _data[key];

  @override
  Future<void> write(String key, Object? value) async => _data[key] = value;
}

/// Overridden in main() with the opened [HiveStore].
final localStoreProvider = Provider<LocalStore>((ref) => MemoryStore());
