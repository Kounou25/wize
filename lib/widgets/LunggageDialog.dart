import 'package:flutter/material.dart';
import '../interactions/models/voyage.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ── Popup sélection bagages ────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

class BaggageDialog extends StatefulWidget {
  final Voyage voyage;
  const BaggageDialog({super.key, required this.voyage});

  @override
  State<BaggageDialog> createState() => _BaggageDialogState();
}

class _BaggageDialogState extends State<BaggageDialog> {
  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  int _cabine = 0;
  int _soute = 0;
  int _special = 0;

  void _increment(int type) => setState(() {
    if (type == 0) _cabine++;
    if (type == 1) _soute++;
    if (type == 2) _special++;
  });

  void _decrement(int type) => setState(() {
    if (type == 0 && _cabine > 0) _cabine--;
    if (type == 1 && _soute > 0) _soute--;
    if (type == 2 && _special > 0) _special--;
  });

  int get _total => _cabine + _soute + _special;

  void _validate() {
    // TODO: envoyer les données au service
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bagages enregistrés : $_cabine cabine · $_soute soute · $_special spécial',
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Text(
              '${widget.voyage.villeDep} → ${widget.voyage.villeArr}',
              style: const TextStyle(
                fontSize: 13,
                color: _sub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: _border),
            const SizedBox(height: 24),
            _BaggageRow(
              icon: Icons.backpack_rounded,
              label: 'Bagage cabine',
              sublabel: 'Petit bagage à main',
              count: _cabine,
              onIncrement: () => _increment(0),
              onDecrement: () => _decrement(0),
            ),
            const SizedBox(height: 16),
            _BaggageRow(
              icon: Icons.luggage_rounded,
              label: 'Bagage soute',
              sublabel: 'Valise enregistrée',
              count: _soute,
              onIncrement: () => _increment(1),
              onDecrement: () => _decrement(1),
            ),
            const SizedBox(height: 16),
            _BaggageRow(
              icon: Icons.sports_rounded,
              label: 'Bagage spécial',
              sublabel: 'Vélo, surf, équipement…',
              count: _special,
              onIncrement: () => _increment(2),
              onDecrement: () => _decrement(2),
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: _border),
            const SizedBox(height: 16),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.luggage_rounded, color: _accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BAGAGES',
                style: TextStyle(
                  fontSize: 9,
                  color: _sub,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.voyage.nomClient,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 16, color: _sub),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 9,
                color: _sub,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$_total bagage${_total > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _total > 0 ? _validate : null,
          style: FilledButton.styleFrom(
            backgroundColor: _accent,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'Valider',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

// ── Ligne d'un type de bagage ─────────────────────────────────────────────────

class _BaggageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  const _BaggageRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = count > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? _accent.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _accent.withOpacity(0.30) : _border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive ? _accent : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isActive ? Colors.white : _sub, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _accent : _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: const TextStyle(fontSize: 11, color: _sub),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _CounterButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
                enabled: count > 0,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: SizedBox(
                  key: ValueKey(count),
                  width: 32,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isActive ? _accent : _sub,
                    ),
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                enabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bouton +/− ────────────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  static const _accent = Color(0xFF2563EB);
  static const _border = Color(0xFFE5E7EB);

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? _accent.withOpacity(0.40) : _border,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? _accent : Colors.grey.shade400,
        ),
      ),
    );
  }
}
