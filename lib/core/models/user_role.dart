import 'package:flutter/material.dart';

enum UserRole { tourist, trader }

extension UserRoleX on UserRole {
  String get direction => this == UserRole.tourist ? 'en_np' : 'np_en';
  String get label => this == UserRole.tourist ? 'Tourist' : 'Trader';
  String get subtitle =>
      this == UserRole.tourist ? 'English -> Nepali' : 'Nepali -> English';
  String get prompt =>
      this == UserRole.tourist ? 'Speak English' : 'Speak Nepali in Devanagari';
  String get outputLabel =>
      this == UserRole.tourist ? 'Nepali output' : 'English output';
  String get chipLabel =>
      this == UserRole.tourist ? 'Tourist mode' : 'Trader mode';
  IconData get icon => this == UserRole.tourist ? Icons.public : Icons.store;
}
