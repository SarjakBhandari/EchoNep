import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:echonep/core/providers/role_provider.dart';
import 'package:echonep/core/providers/theme_provider.dart';
import 'package:echonep/core/theme/app_theme.dart';
import 'package:echonep/features/home/home_screen.dart';
import 'package:echonep/features/role_select/role_select_screen.dart';
import 'package:echonep/features/splash/splash_screen.dart';

class TranslatorApp extends ConsumerWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleProvider);
    final themeMode = ref.watch(themeModeProvider);

    final Widget activeScreen = roleState.when(
      loading: () => const SplashScreen(key: ValueKey('splash')),
      error: (error, stackTrace) => SplashScreen(
        key: const ValueKey('splash-error'),
        message: error.toString(),
      ),
      data: (role) {
        if (role == null) {
          return const RoleSelectScreen(key: ValueKey('role-select'));
        }
        return HomeScreen(key: const ValueKey('home'), role: role);
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECHONEP',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: activeScreen,
      ),
    );
  }
}
