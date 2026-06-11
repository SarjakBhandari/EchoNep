import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:echonep/core/providers/role_provider.dart';
import 'package:echonep/features/home/home_screen.dart';
import 'package:echonep/features/role_select/role_select_screen.dart';
import 'package:echonep/features/splash/splash_screen.dart';

class TranslatorApp extends ConsumerWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECHONEP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E99)),
        useMaterial3: true,
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          bodyLarge: GoogleFonts.manrope(),
          bodyMedium: GoogleFonts.manrope(),
        ),
      ),
      home: roleState.when(
        loading: () => const SplashScreen(),
        error: (error, stackTrace) => SplashScreen(message: error.toString()),
        data: (role) {
          if (role == null) {
            return const RoleSelectScreen();
          }
          return HomeScreen(role: role);
        },
      ),
    );
  }
}
