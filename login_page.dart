// ============================================================
// login_page.dart
// "หน้าบ้าน" (UI) หน้า Login ธีมย้อนยุคไดโนเสาร์ 🦕🦖
// เชื่อมต่อกับ auth_service.dart ซึ่งเป็นหลังบ้าน
// ============================================================

import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService(); // เชื่อมกับหลังบ้านตรงนี้

  bool _obscurePassword = true;
  bool _isLoading = false;

  // สีธีมยุคดึกดำบรรพ์: เขียวป่าดิบ, น้ำตาลดิน, ส้มอำพัน (สีฟอสซิล)
  static const Color _jungleDark = Color(0xFF1B3A2B);
  static const Color _jungleMid = Color(0xFF2F5233);
  static const Color _amber = Color(0xFFE8A33D);
  static const Color _bone = Color(0xFFF3E5C8);
  static const Color _rustBrown = Color(0xFF6B3E26);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.success ? _jungleMid : Colors.red.shade800,
        content: Text(
          result.success
              ? '${result.message}\n🦴 ยินดีต้อนรับ ${result.user?.displayName} (${result.user?.rank})'
              : result.message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );

    if (result.success) {
      // TODO: ไปยังหน้าถัดไปหลัง Login สำเร็จ เช่น
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_jungleDark, _jungleMid, _rustBrown],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildLoginCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _amber.withOpacity(0.15),
            border: Border.all(color: _amber, width: 2),
          ),
          child: const Center(
            child: Text('🦖', style: TextStyle(fontSize: 48)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'dainosao',
          style: TextStyle(
            color: _amber,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.4),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'SKILL UP',
          style: TextStyle(
            color: _bone.withOpacity(0.85),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bone.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _amber.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _usernameController,
            label: 'ชื่อนักสำรวจฟอสซิล',
            icon: Icons.person_outline,
            obscure: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'รหัสผ่านลับ',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _bone.withOpacity(0.6),
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: _jungleDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(_jungleDark),
                      ),
                    )
                  : const Text(
                      'ออกสำรวจ 🦴',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // TODO: ลิงก์ไปหน้าลืมรหัสผ่าน หรือหน้าสมัครสมาชิก
            },
            child: Text(
              'ลืมรหัสผ่าน / สมัครสมาชิกใหม่',
              style: TextStyle(color: _bone.withOpacity(0.7), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _bone),
      cursorColor: _amber,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _bone.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: _amber),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _amber, width: 1.5),
        ),
      ),
    );
  }
}
