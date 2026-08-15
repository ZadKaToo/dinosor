import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/app_toast.dart';
import 'main_layout_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = _isSignUp
          ? await AuthService.register(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await AuthService.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

      if (!mounted) return;

      context.read<AppState>().setSession(user: result.user, token: result.token);

      showAppToast(
        context,
        _isSignUp ? 'สมัครสมาชิกสำเร็จ ยินดีต้อนรับ!' : 'เข้าสู่ระบบสำเร็จ',
        type: ToastType.success,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppToast(context, e.message, type: ToastType.error);
    } catch (_) {
      if (!mounted) return;
      showAppToast(context, 'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: state.bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(state),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: state.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: state.borderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp ? 'สร้างบัญชีใหม่' : 'เข้าสู่ระบบ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(
                              color: state.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSignUp
                                ? 'สมัครสมาชิกเพื่อเริ่มเส้นทางสาย IT ของคุณ'
                                : 'ยินดีต้อนรับกลับ ไปต่อกันเลย',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.prompt(color: state.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 24),
                          if (_isSignUp) ...[
                            _buildLabel(state, 'ชื่อ-นามสกุล'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              state: state,
                              controller: _fullNameController,
                              hint: 'เช่น สมชาย ใจดี',
                              icon: Icons.person_outline,
                              validator: (v) {
                                if (!_isSignUp) return null;
                                if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อ-นามสกุล';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildLabel(state, 'อีเมล'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            state: state,
                            controller: _emailController,
                            hint: 'you@example.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
                              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                              if (!ok) return 'รูปแบบอีเมลไม่ถูกต้อง';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildLabel(state, 'รหัสผ่าน'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            state: state,
                            controller: _passwordController,
                            hint: 'อย่างน้อย 6 ตัวอักษร',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: state.textMuted,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            onSubmitted: (_) => _submit(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                              if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildSubmitButton(state),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildToggleModeRow(state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(AppState state) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.laptop, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 26),
            children: [
              TextSpan(text: 'Learn', style: TextStyle(color: state.textPrimary)),
              const TextSpan(text: 'Pro', style: TextStyle(color: Color(0xFF10B981))),
            ],
          ),
        ),
        Text('IT Career Platform', style: GoogleFonts.prompt(color: state.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildLabel(AppState state, String text) {
    return Text(text, style: GoogleFonts.prompt(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required AppState state,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.prompt(color: state.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.prompt(color: state.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: state.textMuted, size: 18),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: state.cardAltColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: state.borderColorSoft)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: state.borderColorSoft)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: state.accentColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF87171))),
        errorStyle: GoogleFonts.prompt(color: const Color(0xFFF87171), fontSize: 11),
      ),
    );
  }

  Widget _buildSubmitButton(AppState state) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: state.accentColor.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Text(_isSignUp ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ', style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildToggleModeRow(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isSignUp ? 'มีบัญชีอยู่แล้ว?' : 'ยังไม่มีบัญชี?', style: GoogleFonts.prompt(color: state.textMuted, fontSize: 13)),
        TextButton(
          onPressed: _isLoading ? null : _toggleMode,
          child: Text(
            _isSignUp ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
            style: GoogleFonts.prompt(color: state.accentColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
