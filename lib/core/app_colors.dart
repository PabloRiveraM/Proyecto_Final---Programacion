// lib/core/app_colors.dart
// Paleta oficial del proyecto — extraída de main.dart
// Todos los módulos deben importar este archivo para mantener coherencia visual.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // No instanciable

  // === COLORES BASE ===
  static const Color primary    = Colors.black;          // Negro formal
  static const Color background = Colors.white;          // Fondo general
  static const Color surface    = Color(0xFFF5F5F5);     // Tarjetas / contenedores
  static const Color secondary  = Color(0xFF455A64);     // blueGrey shade700
  static const Color error      = Color(0xFFC62828);     // red shade700

  // === TEXTO ===
  static const Color textPrimary   = Colors.black;
  static const Color textSecondary = Color(0xFF607D8B);  // blueGrey shade600
  static const Color textOnDark    = Colors.white;
  static const Color textDisabled  = Color(0xFFBDBDBD);

  // === BORDES Y DIVISORES ===
  static const Color border    = Color(0xFFE0E0E0);
  static const Color divider   = Color(0xFFEEEEEE);

  // === ESTADOS ===
  static const Color success  = Color(0xFF2E7D32); // verde oscuro
  static const Color warning  = Color(0xFFF57F17); // ámbar oscuro
}
