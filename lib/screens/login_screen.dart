import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _error = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _tryLogin() {
    final ok = context.read<AppState>().login(_controller.text);
    if (!ok) {
      setState(() => _error = true);
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1c2128),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38bdf8).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(Icons.sports_esports,
                    size: 64, color: Color(0xFF38bdf8)),
              ),
              const SizedBox(height: 24),
              const Text('ElHarifa PlayStation',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38bdf8))),
              const SizedBox(height: 8),
              Text('أدخل كلمة السر',
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 32),

              // Password field with shake animation
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (ctx, child) => Transform.translate(
                  offset: Offset(
                      _shakeCtrl.isAnimating
                          ? (_shakeCtrl.value < 0.5 ? -_shakeAnim.value : _shakeAnim.value)
                          : 0,
                      0),
                  child: child,
                ),
                child: TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, letterSpacing: 4),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: const Color(0xFF1c2128),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: _error ? Colors.red : const Color(0xFF38bdf8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: _error
                              ? Colors.red
                              : Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFF38bdf8), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    errorText: _error ? 'كلمة السر غلط!' : null,
                  ),
                  onSubmitted: (_) => _tryLogin(),
                  onChanged: (_) => setState(() => _error = false),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _tryLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('دخول', style: TextStyle(fontSize: 18)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF38bdf8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
