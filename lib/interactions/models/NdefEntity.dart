import 'package:flutter/material.dart';
import 'voyage.dart';

/// Modèle interne représentant un enregistrement NDEF décodé.
class NdefEntry {
  final String type;
  final IconData icon;
  final String value;
  final String? language;
  final Voyage? voyage;

  const NdefEntry({
    required this.type,
    required this.icon,
    required this.value,
    this.language,
    this.voyage,
  });
}
