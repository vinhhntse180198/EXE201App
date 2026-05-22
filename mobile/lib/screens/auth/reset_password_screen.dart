import 'package:flutter/material.dart';

import '../../core/session/app_session.dart';
import '../../services/api_client.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) _token.text = widget.initialToken!;
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.length < 6) {
      setState(() => _error = 'Mật khẩu tối thiểu 6 ký tự.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (_token.text.trim().isEmpty) {
      setState(() => _error = 'Nhập mã token từ email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppSession.instance.auth.resetPassword(
        token: _token.text.trim(),
        newPassword: _password.text,
      );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text('Đổi mật khẩu thành công!'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                child: const Text('Đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _token,
              decoration: const InputDecoration(labelText: 'Token (từ email / dev link)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Đang lưu...' : 'Lưu mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }
}
