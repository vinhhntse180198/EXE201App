import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../config/app_flags.dart';
import '../../config/yume_perf.dart';
import '../../config/yume_colors.dart';
import '../../core/mock/mock_data.dart';
import '../../core/session/app_session.dart';
import '../../services/api_client.dart';
import '../../services/google_auth_service.dart';
import '../../utils/post_login_nav.dart';
import '../../widgets/auth/auth_hero_panel.dart';
import '../../widgets/auth/yume_auth_field.dart';
import '../../widgets/yume/yume_brand_mark.dart';
import '../../widgets/yume/yume_sakura_background.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.previewOnly = false});

  final bool previewOnly;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    AppSession.instance.applyAuth(MockData.auth);
    if (widget.previewOnly) {
      Navigator.of(context).pop();
      return;
    }
    navigatePostLogin(context, MockData.auth);
  }

  Future<void> _loginGoogle() async {
    if (widget.previewOnly || designMode) {
      _enterApp();
      return;
    }
    if (!isGoogleSignInConfigured) {
      setState(() => _error = 'Chưa cấu hình GOOGLE_SERVER_CLIENT_ID.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final idToken = await GoogleAuthService().signInAndGetIdToken();
      if (idToken == null) return;
      final auth = await AppSession.instance.auth.loginWithGoogleIdToken(idToken);
      AppSession.instance.applyAuth(auth);
      if (!mounted) return;
      navigatePostLogin(context, auth);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginPassword() async {
    if (widget.previewOnly || designMode) {
      _enterApp();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = await AppSession.instance.auth.login(
        usernameOrEmail: _emailController.text,
        password: _passwordController.text,
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
    final formCard = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YumeColors.border.withValues(alpha: 0.35)),
        boxShadow: yumeLiteUi
            ? null
            : [
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
              'Chào mừng trở lại',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: YumeColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhập email và mật khẩu để đăng nhập.',
              textAlign: TextAlign.center,
              style: TextStyle(color: YumeColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            YumeAuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'ban@email.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 14),
            YumeAuthField(
              controller: _passwordController,
              label: 'Mật khẩu',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.previewOnly
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
                        ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _loginPassword,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_loading ? 'Đang xử lý...' : 'Đăng nhập'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading || widget.previewOnly ? null : _loginGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Đăng nhập Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.previewOnly
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                      ),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );

    final scroll = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            if (widget.previewOnly)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            if (!yumeLiteUi)
              const AuthHeroPanel(
                compact: true,
                imageAsset: 'assets/images/hero-japan.png',
                title: 'YumeGo-Ji',
                subtitle: 'Học tiếng Nhật qua bài học, game và chat.',
              )
            else
              const AuthHeroPanel(
                compact: true,
                title: 'YumeGo-Ji',
                subtitle: 'Học tiếng Nhật qua bài học, game và chat.',
              ),
            const SizedBox(height: 20),
            RepaintBoundary(child: formCard),
          ],
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFFBFE),
      body: yumeLiteUi ? scroll : YumeSakuraBackground(child: scroll),
    );
  }
}
