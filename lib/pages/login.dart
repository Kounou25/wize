import 'package:flutter/material.dart';
import 'package:wize_writter/pages/Wize_reader.dart';
import '../interactions/services/authService.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _authService = AuthService();

  bool _obscurePwd = true;
  bool _isLoading = false;
  String? _authError; // message d'erreur renvoyé par le serveur

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _bg = Color(0xFFF9FAFB);
  static const _white = Color(0xFFFFFFFF);
  static const _error = Color(0xFFDC2626);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _masterCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _lineFade;

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: .92, end: 1).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _lineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _masterCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        );
    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _masterCtrl.dispose();
    super.dispose();
  }

  // ── Soumission ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _authError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = await _authService.login(
        login: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
      );

      final token = auth.accessToken;
      final role = auth.user.role;

      if (!mounted) return;

      // ✅ Afficher un petit message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecté avec succès !'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (role == "agent") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => NfcReadScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() => _authError = e.message);
    } catch (_) {
      setState(() => _authError = 'Problème de connexion. Réessayez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(.04),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: const _WizeLogo(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Ligne déco
                      FadeTransition(
                        opacity: _lineFade,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 3,
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(.3),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _lineFade,
                        child: const Text(
                          'CONNEXION',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _sub,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Formulaire
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WizeField(
                                  controller: _emailCtrl,
                                  label: 'Adresse e-mail',
                                  hint: 'vous@exemple.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Champ requis';
                                    if (!v.contains('@'))
                                      return 'E-mail invalide';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 22),

                                _WizeField(
                                  controller: _pwdCtrl,
                                  label: 'Mot de passe',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePwd,
                                  onToggle: () => setState(
                                    () => _obscurePwd = !_obscurePwd,
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Requis'
                                      : null,
                                ),
                                const SizedBox(height: 14),

                                // ── Bandeau d'erreur serveur ───────────────
                                if (_authError != null)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _error.withOpacity(.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _error.withOpacity(.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: _error,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _authError!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: _error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Mot de passe oublié
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _accent,
                                        letterSpacing: .1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                _WizeButton(
                                  loading: _isLoading,
                                  onTap: _isLoading ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Logotype WIZE
// ─────────────────────────────────────────────────────────────────────────────
class _WizeLogo extends StatelessWidget {
  const _WizeLogo();

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 10, bottom: 6),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'WIZ',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  height: 1,
                  letterSpacing: -2.5,
                ),
              ),
              TextSpan(
                text: 'E',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _accent,
                  height: 1,
                  letterSpacing: -2.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Champ de saisie — champs agrandis
// ─────────────────────────────────────────────────────────────────────────────
class _WizeField extends StatefulWidget {
  const _WizeField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.onToggle,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;

  @override
  State<_WizeField> createState() => _WizeFieldState();
}

class _WizeFieldState extends State<_WizeField> {
  bool _focused = false;

  static const _accent = Color(0xFF2563EB);
  static const _ink = Color(0xFF111827);
  static const _sub = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _bg = Color(0xFFF9FAFB);
  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: _focused ? _accent : _sub,
          ),
          child: Text(widget.label.toUpperCase()),
        ),
        const SizedBox(height: 10),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _focused ? _white : _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _focused ? _accent : _border,
                width: _focused ? 1.5 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: _accent.withOpacity(.10),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscure,
              cursorColor: _accent,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: _sub.withOpacity(.4), fontSize: 14),
                prefixIcon: Icon(
                  widget.icon,
                  size: 20,
                  color: _focused ? _accent : _sub,
                ),
                suffixIcon: widget.onToggle != null
                    ? GestureDetector(
                        onTap: widget.onToggle,
                        child: Icon(
                          widget.obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: _sub,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20, // ← hauteur augmentée ici
                ),
                errorStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bouton WIZE
// ─────────────────────────────────────────────────────────────────────────────
class _WizeButton extends StatefulWidget {
  const _WizeButton({this.onTap, this.loading = false});

  final VoidCallback? onTap;
  final bool loading;

  @override
  State<_WizeButton> createState() => _WizeButtonState();
}

class _WizeButtonState extends State<_WizeButton> {
  bool _pressed = false;

  static const _accent = Color(0xFF2563EB);
  static const _accentPress = Color(0xFF1D4ED8);
  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _pressed ? _accentPress : _accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: _accent.withOpacity(.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: widget.loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _white,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Se connecter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _white,
                      letterSpacing: .2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: _white, size: 18),
                ],
              ),
      ),
    );
  }
}
