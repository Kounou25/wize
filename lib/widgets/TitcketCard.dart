import 'package:flutter/material.dart';
import '../interactions/models/voyage.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ── Billet moderne — flat, propre, aéré ───────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class VoyageTicketCard extends StatelessWidget {
  final Voyage voyage;
  const VoyageTicketCard({super.key, required this.voyage});

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _bgLight = Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
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
          _buildBaggageHint(),
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

  // ── Hint bagages ──────────────────────────────────────────────────────────
  Widget _buildBaggageHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.04),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 13, color: _accent),
          SizedBox(width: 5),
          Text(
            'Appuyez pour ajouter des bagages',
            style: TextStyle(
              fontSize: 11,
              color: _accent,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
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
