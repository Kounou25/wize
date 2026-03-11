import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:flutter/services.dart'; // <- nécessaire pour FilteringTextInputFormatter

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
//       home: const NfcWriteScreen(),
//     );
//   }
// }

enum NfcStatus { idle, scanning, success, error }

class NfcWriteScreen extends StatefulWidget {
  const NfcWriteScreen({super.key});

  @override
  State<NfcWriteScreen> createState() => _NfcWriteScreenState();
}

class _NfcWriteScreenState extends State<NfcWriteScreen> {
  final TextEditingController _textController = TextEditingController();
  NfcStatus _status = NfcStatus.idle;
  String _statusMessage = 'Entrez un texte puis approchez votre carte NFC';
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkNfcAvailability() async {
    final availability = await FlutterNfcKit.nfcAvailability;
    setState(() {
      _nfcAvailable = availability == NFCAvailability.available;
      if (!_nfcAvailable) {
        _status = NfcStatus.error;
        _statusMessage = 'NFC non disponible sur cet appareil';
      }
    });
  }

  Future<void> _startWriteSession() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _status = NfcStatus.error;
        _statusMessage = 'Veuillez entrer un texte à écrire';
      });
      return;
    }

    setState(() {
      _status = NfcStatus.scanning;
      _statusMessage = 'Approchez votre carte NFC…';
    });

    try {
      // 1. Attendre qu'un tag soit détecté
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Approchez votre carte NFC',
      );

      // 2. Vérifier que le tag supporte NDEF
      if (tag.ndefAvailable != true) {
        _setStatus(NfcStatus.error, 'Ce tag ne supporte pas NDEF');
        return;
      }

      if (tag.ndefWritable != true) {
        _setStatus(NfcStatus.error, 'Ce tag est en lecture seule');
        return;
      }

      // 3. Vérifier la capacité
      final record = ndef.TextRecord(text: text, language: 'en');
      // final recordSize = record.toRawNdefRecord().encodedBytes.length;
      // if (tag.ndefCapacity != null && recordSize > tag.ndefCapacity!) {
      //   _setStatus(
      //     NfcStatus.error,
      //     'Texte trop long (${recordSize}B > max ${tag.ndefCapacity}B)',
      //   );
      //   return;
      // }

      // 4. Écrire le record NDEF
      await FlutterNfcKit.writeNDEFRecords([record]);

      _setStatus(NfcStatus.success, ' Écriture réussie sur la carte NFC !');
    } catch (e) {
      _setStatus(NfcStatus.error, 'Erreur : $e');
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Terminé !');
    }
  }

  void _setStatus(NfcStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _statusMessage = message;
    });
  }

  void _reset() {
    setState(() {
      _status = NfcStatus.idle;
      _statusMessage = 'Entrez un texte puis approchez votre carte NFC';
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Écriture NFC'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildTextField(),
            const SizedBox(height: 16),
            _buildWriteButton(),
            if (_status == NfcStatus.success || _status == NfcStatus.error) ...[
              const SizedBox(height: 12),
              _buildResetButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final (color, icon) = switch (_status) {
      NfcStatus.idle => (Colors.grey.shade100, Icons.nfc),
      NfcStatus.scanning => (Colors.blue.shade50, Icons.wifi_tethering),
      NfcStatus.success => (Colors.green.shade50, Icons.check_circle),
      NfcStatus.error => (Colors.red.shade50, Icons.error_outline),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: _iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_statusMessage, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Color get _iconColor => switch (_status) {
    NfcStatus.idle => Colors.grey,
    NfcStatus.scanning => Colors.blue,
    NfcStatus.success => Colors.green,
    NfcStatus.error => Colors.red,
  };

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      enabled: _status != NfcStatus.scanning,
      maxLines: 1, // souvent les champs numériques sont sur une seule ligne
      keyboardType: TextInputType.number, // affiche le clavier numérique
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // n'accepte que les chiffres
      ],
      decoration: InputDecoration(
        labelText: 'ID numérique à écrire',
        hintText: 'Ex: 123456',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _textController.clear,
          tooltip: 'Effacer',
        ),
      ),
    );
  }

  Widget _buildWriteButton() {
    final isScanning = _status == NfcStatus.scanning;

    return FilledButton.icon(
      onPressed: (_nfcAvailable && !isScanning) ? _startWriteSession : null,
      icon: isScanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.edit),
      label: Text(
        isScanning ? 'En attente de la carte…' : 'Écrire sur la carte NFC',
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _reset,
      icon: const Icon(Icons.refresh),
      label: const Text('Recommencer'),
    );
  }
}
