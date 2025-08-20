import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return '이메일을 입력하세요';
    if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.trim().isEmpty) return '비밀번호를 입력하세요';
    if (v.trim().length < 6) return '비밀번호는 6자 이상';
    return null;
  }

  String _mapCode(String code) {
    switch (code) {
      case 'email-already-in-use': return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':        return '이메일 형식이 올바르지 않습니다.';
      case 'user-not-found':
      case 'wrong-password':       return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'weak-password':        return '더 강한 비밀번호를 사용하세요(6자 이상).';
      case 'too-many-requests':    return '요청이 너무 많습니다. 잠시 후 다시 시도하세요.';
      default:                     return '인증 오류: $code';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_busy) return;

    setState(() { _busy = true; _error = null; });

    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text.trim(),
        );
      }
      // 성공 시 main.dart의 AuthGate가 자동으로 홈 화면으로 보냄
    } on FirebaseAuthException catch (e) {
      final msg = _mapCode(e.code);
      setState(() => _error = msg);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _error = '알 수 없는 오류: $e');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('알 수 없는 오류: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_busy) return;
    final email = _email.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (email.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('비밀번호 재설정: 이메일을 먼저 입력하세요')));
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('재설정 메일을 보냈습니다.')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('메일 전송 실패: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? '회원가입' : '로그인')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _email,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      decoration: const InputDecoration(labelText: '이메일'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_isSignUp ? '회원가입' : '로그인'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () {
                        setState(() { _isSignUp = !_isSignUp; _error = null; });
                      },
                      child: Text(_isSignUp ? '이미 계정이 있으신가요? 로그인' : '처음이신가요? 회원가입'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _resetPassword,
                      child: const Text('비밀번호 재설정 메일 보내기'),
                    ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
