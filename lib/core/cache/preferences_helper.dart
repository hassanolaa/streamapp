import 'package:get_storage/get_storage.dart';

class PreferencesHelper {
  static final GetStorage _box = GetStorage();

  static Future<void> saveString(String key, String value) async =>
    await _box.write(key, value);

  static String? getString(String key) => _box.read<String>(key);

  static Future<void> saveBool(String key, bool value) async =>
    await _box.write(key, value);

  static bool? getBool(String key) => _box.read<bool>(key);

  static Future<void> remove(String key) async => await _box.remove(key);

  static Future<void> clear() async => await _box.erase();
}
