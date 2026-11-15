import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';

/// Halaman Masuk & Daftar akun KuliahKu.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailC = TextEditingController();
  final _loginPasswordC = TextEditingController();

  final _regEmailC = TextEditingController();
  final _regPasswordC = TextEditingController();
  final _regFullNameC = TextEditingController();
  final _regProgramC = TextEditingController();
  final _regSemesterC = TextEditingController(text: '1');
  final _regNimC = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailC.dispose();
    _loginPasswordC.dispose();
    _regEmailC.dispose();
    _regPasswordC.dispose();
    _regFullNameC.dispose();
    _regProgramC.dispose();
    _regSemesterC.dispose();
    _regNimC.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final auth = AppScope.authOf(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.login(_loginEmailC.text, _loginPasswordC.text);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Login berhasil! Selamat datang kembali.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    final auth = AppScope.authOf(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.register(
        email: _regEmailC.text,
        password: _regPasswordC.text,
        fullName: _regFullNameC.text,
        programStudi: _regProgramC.text,
        semester: _regSemesterC.text,
        nim: _regNimC.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Selamat datang di KuliahKu.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'KuliahKu',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola jadwal dan tugas kuliahmu dengan mudah',
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/KuliahkuBanner.png',
                      height: 165,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 140,
                        width: double.infinity,
                        color: scheme.primaryContainer,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.school_rounded,
                          size: 56,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tab Switcher Masuk / Daftar
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AuthTabButton(
                                    label: 'Masuk',
                                    selected: _tabController.index == 0,
                                    onTap: () => _tabController.animateTo(0),
                                  ),
                                ),
                                Expanded(
                                  child: _AuthTabButton(
                                    label: 'Daftar',
                                    selected: _tabController.index == 1,
                                    onTap: () => _tabController.animateTo(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (_tabController.index == 0)
                            _buildLoginForm(scheme)
                          else
                            _buildRegisterForm(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(ColorScheme scheme) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailC,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'email@universitas.ac.id',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordC,
            obscureText: _obscureLogin,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureLogin ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitLogin,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Masuk'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _loginEmailC.text = 'test@test.com';
                _loginPasswordC.text = 'password';
              },
              icon: Icon(Icons.person_search_outlined, size: 18, color: scheme.onSurfaceVariant),
              label: Text(
                'Isi akun demo (test@test.com)',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regEmailC,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'email@universitas.ac.id',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regPasswordC,
            obscureText: _obscureReg,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureReg ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscureReg = !_obscureReg),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regFullNameC,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'Nama lengkap mahasiswa',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => Validators.notEmpty(v, 'Nama lengkap diperlukan'),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _regProgramC,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Program Studi',
                    hintText: 'Informatika',
                  ),
                  validator: (v) => Validators.notEmpty(v, 'Program studi diperlukan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _regSemesterC,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: '1–14',
                  ),
                  validator: Validators.semester,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _regNimC,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitRegister(),
            decoration: const InputDecoration(
              labelText: 'NIM (Opsional)',
              hintText: 'Nomor Induk Mahasiswa',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: Validators.nim,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitRegister,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Daftar & Masuk'),
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 16,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
