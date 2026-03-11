import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

enum NfcStatus { idle, scanning, success, error }

class NfcReadScreen extends StatefulWidget {
  const NfcReadScreen({super.key});

  @override
  State<NfcReadScreen> createState() => _NfcReadScreenState();
}

class _NfcReadScreenState extends State<NfcReadScreen> {
  NfcStatus _status = NfcStatus.idle;
  String _statusMessage =
      'Appuyez sur le bouton puis approchez votre carte NFC';
  List<_NdefEntry> _records = [];
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
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

  Future<void> _startReadSession() async {
    setState(() {
      _status = NfcStatus.scanning;
      _statusMessage = 'Approchez votre carte NFC…';
      _records = [];
    });

    try {
      // 1. Détecter le tag
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Approchez votre carte NFC',
      );

      // 2. Vérifier NDEF
      if (tag.ndefAvailable != true) {
        _setStatus(NfcStatus.error, 'Ce tag ne contient pas de données NDEF');
        return;
      }

      // 3. Lire les records NDEF
      final rawRecords = await FlutterNfcKit.readNDEFRecords(cached: false);

      if (rawRecords.isEmpty) {
        _setStatus(NfcStatus.error, 'Aucun enregistrement trouvé sur ce tag');
        return;
      }

      // 4. Décoder chaque record
      final entries = <_NdefEntry>[];
      for (final record in rawRecords) {
        entries.add(_decodeRecord(record));
      }

      setState(() {
        _status = NfcStatus.success;
        _statusMessage = '✅ ${entries.length} enregistrement(s) lu(s)';
        _records = entries;
      });
    } catch (e) {
      _setStatus(NfcStatus.error, 'Erreur : $e');
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Lecture terminée !');
    }
  }

  _NdefEntry _decodeRecord(ndef.NDEFRecord record) {
    if (record is ndef.TextRecord) {
      return _NdefEntry(
        type: 'Texte',
        icon: Icons.text_fields,
        value: record.text ?? '',
        language: record.language,
      );
    } else if (record is ndef.UriRecord) {
      return _NdefEntry(
        type: 'URI',
        icon: Icons.link,
        value: record.uri?.toString() ?? '',
      );
    } else if (record is ndef.MimeRecord) {
      return _NdefEntry(
        type: 'MIME (${record.decodedType})',
        icon: Icons.insert_drive_file,
        value: String.fromCharCodes(record.payload ?? []),
      );
    } else {
      return _NdefEntry(
        type: 'Inconnu (TNF: ${record.tnf})',
        icon: Icons.help_outline,
        value: record.payload != null
            ? record.payload!
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(' ')
            : '',
      );
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
      _statusMessage = 'Appuyez sur le bouton puis approchez votre carte NFC';
      _records = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecture NFC'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildReadButton(),
            if (_records.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildRecordsList(),
            ],
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
          if (_status == NfcStatus.scanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildRecordsList() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contenu de la carte',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = _records[index];
                return Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: Icon(entry.icon, color: Colors.indigo),
                    title: Text(
                      entry.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: SelectableText(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    isThreeLine: entry.value.length > 40,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadButton() {
    final isScanning = _status == NfcStatus.scanning;

    return FilledButton.icon(
      onPressed: (_nfcAvailable && !isScanning) ? _startReadSession : null,
      icon: isScanning
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.nfc),
      label: Text(isScanning ? 'Lecture en cours…' : 'Lire la carte NFC'),
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

// ─── Modèle interne pour l'affichage ─────────────────────────────────────────
class _NdefEntry {
  final String type;
  final IconData icon;
  final String value;
  final String? language;

  const _NdefEntry({
    required this.type,
    required this.icon,
    required this.value,
    this.language,
  });
}
