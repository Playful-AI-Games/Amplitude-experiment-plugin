import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/variant.dart';

/// Abstract storage interface
abstract class Storage {
  Future<void> save(String key, String value);
  Future<String?> load(String key);
  Future<void> clear(String key);
  Future<void> clearAll();
}

/// SharedPreferences implementation of Storage
class SharedPreferencesStorage implements Storage {
  static const String _prefix = 'amplitude_experiment_';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> save(String key, String value) async {
    final p = await prefs;
    await p.setString('$_prefix$key', value);
  }

  @override
  Future<String?> load(String key) async {
    final p = await prefs;
    return p.getString('$_prefix$key');
  }

  @override
  Future<void> clear(String key) async {
    final p = await prefs;
    await p.remove('$_prefix$key');
  }

  @override
  Future<void> clearAll() async {
    final p = await prefs;
    final keys = p.getKeys()
        .where((key) => key.startsWith(_prefix))
        .toList();
    for (final key in keys) {
      await p.remove(key);
    }
  }
}

/// Storage specifically for variants
class VariantStorage {
  final Storage _storage;
  final String _storageKey;

  VariantStorage({
    Storage? storage,
    String? storageKey,
  })  : _storage = storage ?? SharedPreferencesStorage(),
        _storageKey = storageKey ?? 'variants';

  Future<void> saveVariants(Variants variants) async {
    final Map<String, dynamic> data = {};
    variants.forEach((key, variant) {
      data[key] = variant.toJson();
    });
    await _storage.save(_storageKey, jsonEncode(data));
  }

  Future<Variants> loadVariants() async {
    try {
      final String? data = await _storage.load(_storageKey);
      if (data == null) return {};
      
      final Map<String, dynamic> json = jsonDecode(data);
      final Variants variants = {};
      
      json.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          variants[key] = Variant.fromJson(value);
        }
      });
      
      return variants;
    } catch (e) {
      // If there's an error loading/parsing, return empty variants
      return {};
    }
  }

  Future<void> clearVariants() async {
    await _storage.clear(_storageKey);
  }
}

/// Storage for flag configurations
class FlagStorage {
  final Storage _storage;
  final String _storageKey;

  FlagStorage({
    Storage? storage,
    String? storageKey,
  })  : _storage = storage ?? SharedPreferencesStorage(),
        _storageKey = storageKey ?? 'flags';

  Future<void> saveFlags(String flags) async {
    await _storage.save(_storageKey, flags);
  }

  Future<String?> loadFlags() async {
    return await _storage.load(_storageKey);
  }

  Future<void> clearFlags() async {
    await _storage.clear(_storageKey);
  }
}