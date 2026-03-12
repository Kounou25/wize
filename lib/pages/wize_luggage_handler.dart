// ──────────────────────────────────────────────────────────────────────────────
// FICHIERS DU PROJET :
//   nfc_read_screen.dart    ← écran principal (ce fichier)
//   voyage_ticket_card.dart ← widget billet
//   baggage_dialog.dart     ← popup bagages
//   ndef_entry.dart         ← modèle interne NdefEntry
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:audioplayers/audioplayers.dart';

import '../interactions/models/voyage.dart';
import '../interactions/services/voyageService.dart';
import '../interactions/models/NdefEntity.dart';
import '../widgets/TitcketCard.dart';
import '../widgets/LunggageDialog.dart';

enum NfcStatus { idle, scanning, success, error }

// ═══════════════════════════════════════════════════════════════════════════════
// ── Écran principal de lecture NFC ────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class NfcReadScreen extends StatefulWidget {
  const NfcReadScreen({super.key});

  @override
  State<NfcReadScreen> createState() => _NfcReadScreenState();
}

class _NfcReadScreenState extends State<NfcReadScreen> {
  NfcStatus _status = NfcStatus.idle;
  String _statusMessage =
      'Appuyez sur le bouton puis approchez votre carte NFC';
  List<NdefEntry> _records = [];
  bool _nfcAvailable = false;

  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  // ── NFC ───────────────────────────────────────────────────────────────────

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
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 20),
        iosAlertMessage: 'Approchez votre carte NFC',
      );

      if (tag.ndefAvailable != true) {
        _setStatus(NfcStatus.error, 'Ce tag ne contient pas de données NDEF');
        return;
      }

      final rawRecords = await FlutterNfcKit.readNDEFRecords(cached: false);

      if (rawRecords.isEmpty) {
        _setStatus(NfcStatus.error, 'Aucun enregistrement trouvé sur ce tag');
        return;
      }

      final entries = <NdefEntry>[];
      String? phoneNumber;

      for (final record in rawRecords) {
        final entry = _decodeRecord(record);
        entries.add(entry);
        if (record is ndef.TextRecord) phoneNumber ??= record.text;
      }

      setState(() => _records = entries);

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final voyages = await VoyageService().getVoyages(phoneNumber);

        if (voyages.isNotEmpty) {
          _setStatus(
            NfcStatus.success,
            'Voyage(s) trouvé(s) pour $phoneNumber',
          );
          setState(() {
            for (final voyage in voyages) {
              _records.add(
                NdefEntry(
                  type: 'Voyage',
                  icon: Icons.directions_bus,
                  value: _voyageSummary(voyage),
                  voyage: voyage,
                ),
              );
            }
          });
          await _player.play(AssetSource('assets/tons/beep.mp3'));
        } else {
          _setStatus(NfcStatus.error, 'Aucun voyage trouvé pour ce numéro');
        }
      } else {
        _setStatus(
          NfcStatus.error,
          'Numéro de téléphone introuvable sur la carte',
        );
      }
    } catch (e) {
      _setStatus(NfcStatus.error, 'Erreur : $e');
    } finally {
      await FlutterNfcKit.finish(iosAlertMessage: 'Lecture terminée !');
    }
  }

  NdefEntry _decodeRecord(ndef.NDEFRecord record) {
    if (record is ndef.TextRecord) {
      return NdefEntry(
        type: 'Texte',
        icon: Icons.text_fields,
        value: record.text ?? '',
        language: record.language,
      );
    } else if (record is ndef.UriRecord) {
      return NdefEntry(
        type: 'URI',
        icon: Icons.link,
        value: record.uri?.toString() ?? '',
      );
    } else if (record is ndef.MimeRecord) {
      return NdefEntry(
        type: 'MIME (${record.decodedType})',
        icon: Icons.insert_drive_file,
        value: String.fromCharCodes(record.payload ?? []),
      );
    } else {
      return NdefEntry(
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

  String _voyageSummary(Voyage v) =>
      'Nom: ${v.nomClient}\nDépart: ${v.villeDep}\nArrivée: ${v.villeArr}\n'
      'Date: ${v.dateDep.toLocal()}\nPlaces: ${v.nbrPlace}\n'
      'Prix: ${v.totalPrice}\nStatus: ${v.status}';

  void _setStatus(NfcStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _statusMessage = message;
    });
  }

  void _reset() => setState(() {
    _status = NfcStatus.idle;
    _statusMessage = 'Appuyez sur le bouton puis approchez votre carte NFC';
    _records = [];
  });

  // ── Popup bagages ─────────────────────────────────────────────────────────

  void _showBaggageDialog(Voyage voyage) {
    showDialog(
      context: context,
      builder: (_) => BaggageDialog(voyage: voyage),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = _records[index];

                // ── Billet cliquable ─────────────────────────────────────
                if (entry.type == 'Voyage' && entry.voyage != null) {
                  return GestureDetector(
                    onTap: () => _showBaggageDialog(entry.voyage!),
                    child: VoyageTicketCard(voyage: entry.voyage!),
                  );
                }

                // ── Enregistrement NDEF générique ────────────────────────
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
