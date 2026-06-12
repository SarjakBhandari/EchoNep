import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

class SessionStore {
  static const _storageKey = 'selected_user_role';

  static Future<UserRole?> loadRole() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_storageKey);
    if (value == null) {
      return null;
    }
    return value == UserRole.tourist.name ? UserRole.tourist : UserRole.trader;
  }
}
