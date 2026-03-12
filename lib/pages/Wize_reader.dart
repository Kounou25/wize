import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import '../interactions/models/voyage.dart';
import '../interactions/services/voyageService.dart';
import 'package:audioplayers/audioplayers.dart';

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

  final player = AudioPlayer();

  void playSound() async {
    await player.play(AssetSource('assets/tons/beep.mp3'));
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

      final entries = <_NdefEntry>[];
      String? phoneNumber;

      for (final record in rawRecords) {
        final entry = _decodeRecord(record);
        entries.add(entry);

        if (record is ndef.TextRecord) {
          phoneNumber ??= record.text;
        }
      }

      setState(() {
        _records = entries;
      });

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final service = VoyageService();
        final voyages = await service.getVoyages(phoneNumber);

        if (voyages.isNotEmpty) {
          _setStatus(
            NfcStatus.success,
            'Voyage(s) trouvé(s) pour $phoneNumber',
          );
          setState(() {
            for (var voyage in voyages) {
              _records.add(
                _NdefEntry(
                  type: 'Voyage',
                  icon: Icons.directions_bus,
                  value:
                      'Nom: ${voyage.nomClient}\nDépart: ${voyage.villeDep}\nArrivée: ${voyage.villeArr}\nDate: ${voyage.dateDep.toLocal()}\nPlaces: ${voyage.nbrPlace}\nPrix: ${voyage.totalPrice}\nStatus: ${voyage.status}',
                  voyage: voyage, // ⭐ très important
                ),
              );
            }
          });

          playSound();
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
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final entry = _records[index];
                if (entry.type == 'Voyage' && entry.voyage != null) {
                  return _VoyageTicketCard(voyage: entry.voyage!);
                }
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

// ─── Modèle interne ───────────────────────────────────────────────────────────
class _NdefEntry {
  final String type;
  final IconData icon;
  final String value;
  final String? language;
  final Voyage? voyage;

  const _NdefEntry({
    required this.type,
    required this.icon,
    required this.value,
    this.language,
    this.voyage,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// ── Billet moderne — flat, propre, aéré ───────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class _VoyageTicketCard extends StatelessWidget {
  final Voyage voyage;
  const _VoyageTicketCard({required this.voyage});

  // Palette minimaliste
  static const _accent = Color(0xFF2563EB); // bleu vif unique
  static const _ink = Color(0xFF111827); // presque noir
  static const _sub = Color(0xFF6B7280); // gris secondaire
  static const _border = Color(0xFFE5E7EB); // bordure douce
  static const _bgLight = Color(0xFFF9FAFB); // fond section basse

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        // Ombre très légère, juste pour décoller du fond
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTop(),
          _buildRoute(),
          _buildSeparator(),
          _buildBottom(),
        ],
      ),
    );
  }

  // ── Bandeau supérieur : passager + statut ─────────────────────────────────
  Widget _buildTop() {
    final statusColor = _resolveStatusColor(voyage.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône bus dans un carré accent
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Passager
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PASSAGER',
                  style: TextStyle(
                    fontSize: 9,
                    color: _sub,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  voyage.nomClient,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              voyage.status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Itinéraire central ────────────────────────────────────────────────────
  Widget _buildRoute() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Départ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DÉPART',
                  style: TextStyle(
                    fontSize: 9,
                    color: _sub,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voyage.villeDep,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatTime(voyage.dateDep.toLocal()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),

          // Flèche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _circleDot(),
                    Container(width: 20, height: 1, color: _border),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: _accent, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: _accent,
                        size: 14,
                      ),
                    ),
                    Container(width: 20, height: 1, color: _border),
                    _circleDot(filled: true),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'DIRECT',
                  style: TextStyle(
                    fontSize: 8,
                    color: _sub,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // Arrivée
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ARRIVÉE',
                  style: TextStyle(
                    fontSize: 9,
                    color: _sub,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voyage.villeArr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(voyage.dateDep.toLocal()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _sub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleDot({bool filled = false}) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? _accent : Colors.white,
      border: Border.all(color: _accent, width: 1.5),
    ),
  );

  // ── Séparateur avec encoches ──────────────────────────────────────────────
  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Encoche gauche
          Transform.translate(
            offset: const Offset(-1, 0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: _border, width: 1.5),
              ),
            ),
          ),
          // Ligne tiretée
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) {
                const dw = 4.0, ds = 4.0;
                final n = (c.maxWidth / (dw + ds)).floor();
                return Row(
                  children: List.generate(
                    n,
                    (_) => Container(
                      width: dw,
                      height: 1,
                      margin: const EdgeInsets.only(right: ds),
                      color: _border,
                    ),
                  ),
                );
              },
            ),
          ),
          // Encoche droite
          Transform.translate(
            offset: const Offset(1, 0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: _border, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section basse : 3 infos en ligne ─────────────────────────────────────
  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Row(
        children: [
          _BottomInfo(
            label: 'DATE',
            value: _formatDate(voyage.dateDep.toLocal()),
            icon: Icons.calendar_today_rounded,
          ),
          _dividerV(),
          _BottomInfo(
            label: 'PLACES',
            value: '${voyage.nbrPlace} place${voyage.nbrPlace > 1 ? 's' : ''}',
            icon: Icons.event_seat_rounded,
          ),
          _dividerV(),
          _BottomInfo(
            label: 'PRIX TOTAL',
            value: '${voyage.totalPrice} F',
            icon: Icons.receipt_rounded,
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _dividerV() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: _border,
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _resolveStatusColor(String s) => switch (s.toLowerCase()) {
    'confirmé' || 'confirmed' || 'actif' => const Color(0xFF16A34A),
    'annulé' || 'cancelled' => const Color(0xFFDC2626),
    'en attente' || 'pending' => const Color(0xFFD97706),
    _ => const Color(0xFF6B7280),
  };

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
}

// ── Cellule d'info basse ──────────────────────────────────────────────────────
class _BottomInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);

  const _BottomInfo({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: highlight ? _accent : _sub),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: _sub,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? _accent : _ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
