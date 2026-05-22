import 'package:flutter/material.dart';

import '../../config/yume_colors.dart';
import '../../core/session/app_session.dart';
import '../../services/api_client.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/auth/auth_hero_panel.dart';
import '../../widgets/auth/yume_auth_field.dart';
import '../../widgets/yume/yume_brand_mark.dart';
import '../../widgets/yume/yume_sakura_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = await AppSession.instance.auth.register(
        username: _username.text,
        email: _email.text,
        password: _password.text,
      );
      AppSession.instance.applyAuth(auth);
      if (!mounted) return;
      navigatePostLogin(context, auth);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối API. Bật backend (:5056).');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YumeSakuraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                const AuthHeroPanel(
                  compact: true,
                  imageAsset: 'assets/images/auth-register.png',
                  title: 'Bắt đầu\nhành trình',
                  subtitle: 'Tạo tài khoản miễn phí — làm placement test sau khi đăng ký.',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: YumeColors.border.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: YumeBrandMark(size: 44)),
                        const SizedBox(height: 16),
                        const Text(
                          'Tạo tài khoản',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: YumeColors.ink),
                        ),
                        const SizedBox(height: 20),
                        YumeAuthField(
                          controller: _username,
                          label: 'Username',
                          hint: 'yume_learner',
                          icon: Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 14),
                        YumeAuthField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || !v.contains('@') ? 'Email không hợp lệ' : null,
                        ),
                        const SizedBox(height: 14),
                        YumeAuthField(
                          controller: _password,
                          label: 'Mật khẩu',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => v == null || v.length < 6 ? 'Tối thiểu 6 ký tự' : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Đăng ký'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Đã có tài khoản? Đăng nhập'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
