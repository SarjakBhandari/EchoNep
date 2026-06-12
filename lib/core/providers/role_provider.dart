import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';

class RoleNotifier extends StateNotifier<AsyncValue<UserRole?>> {
  RoleNotifier() : super(const AsyncLoading()) {
    _loadRole();
  }

  static const _storageKey = 'selected_user_role';

  Future<void> _loadRole() async {
    final preferences = await SharedPreferences.getInstance();
    final savedRole = preferences.getString(_storageKey);
    if (savedRole == null) {
      state = const AsyncData(null);
      return;
    }

    state = AsyncData(
      savedRole == UserRole.tourist.name ? UserRole.tourist : UserRole.trader,
    );
  }

  Future<void> setRole(UserRole role) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, role.name);
    state = AsyncData(role);
  }

  Future<void> clearRole() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    state = const AsyncData(null);
  }
}

final roleProvider = StateNotifierProvider<RoleNotifier, AsyncValue<UserRole?>>(
  (ref) {
    return RoleNotifier();
  },
);
