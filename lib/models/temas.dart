// 🎨 Modo Pilsen
import 'package:flutter/material.dart';

final ThemeData temaPilsen = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: Colors.orange[200],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.orange[100],
    foregroundColor: Colors.brown[700],
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  iconTheme: const IconThemeData(color: Colors.grey),
);

// 🎨 Modo IPA
final ThemeData temaIPA = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5EEDC),
  primaryColor: const Color(0xFF9E7A3F),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFDCB581),
    foregroundColor: Color(0xFF3C3C3C),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFF3C3C3C)),
  ),
  iconTheme: const IconThemeData(color: Color(0xFFC2A968)),
);

// 🎨 Modo Stout
final ThemeData temaStout = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.grey[900],
  primaryColor: Colors.brown[800],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.brown[900],
    foregroundColor: Colors.grey[300],
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.grey),
  ),
  iconTheme: const IconThemeData(color: Colors.grey),
);