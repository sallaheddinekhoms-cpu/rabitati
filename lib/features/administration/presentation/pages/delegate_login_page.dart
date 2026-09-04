import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../delegate/delegate_dashboard.dart';

class DelegateLoginPage extends StatefulWidget {
  const DelegateLoginPage({super.key});

  @override
  State<DelegateLoginPage> createState() => _DelegateLoginPageState();
}

class _DelegateLoginPageState extends State<DelegateLoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted && userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DelegateDashboard(email: userCredential.user!.email!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: تأكد من صحة البريد وكلمة المرور'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1F15) : const Color(0xFFF1F8F4),
      body: Stack(
        children: [
          // ── الخلفية: تدرج ورسومات ──────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF0F261B), const Color(0xFF08140E)]
                      : [const Color(0xFFEAF5EE), const Color(0xFFF4FAF6)],
                ),
              ),
            ),
          ),

          // كرة قدم خفيفة كعلامة مائية في الخلفية
          Positioned(
            top: -40,
            left: -40,
            child: Opacity(
              opacity: isDark ? 0.05 : 0.12,
              child: const Icon(
                Icons.sports_soccer,
                size: 260,
                color: Color(0xFF1B7A36),
              ),
            ),
          ),

          // أمواج خضراء في أسفل الصفحة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 120),
              painter: _BottomWavePainter(isDark: isDark),
            ),
          ),

          // ── المحتوى ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // الشريط العلوي المخصص
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B7A36), size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'بوابة المحافظين',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B7A36),
                        ),
                      ),
                      const SizedBox(width: 48), // لموازنة زر الرجوع
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF162E22) : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(56),
                            bottom: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B7A36).withOpacity(isDark ? 0.25 : 0.12),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── الشعار: درع ثلاثي الأبعاد أخضر ─────────
                            _buildShieldIcon(),
                            const SizedBox(height: 24),

                            // ── العنوان ─────────────────────────────
                            Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A3326),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'خاص بمحافظي و مراقبي المباريات فقط',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── حقل البريد الإلكتروني ───────────────
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F2419) : const Color(0xFFF9FBFA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF274D38) : const Color(0xFFD6E8DE),
                                ),
                              ),
                              child: TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'البريد الإلكتروني',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF1B7A36),
                                    size: 22,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── حقل كلمة المرور ─────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F2419) : const Color(0xFFF9FBFA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF274D38) : const Color(0xFFD6E8DE),
                                ),
                              ),
                              child: TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'كلمة المرور',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF1B7A36),
                                    size: 22,
                                  ),
                                  prefixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── زر الدخول الأخضر ─────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1B7A36), Color(0xFF2EB85C)],
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1B7A36).withOpacity(0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            'دخول',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // خطوط إشعاعية حول الدرع
        Positioned(
          left: 4,
          top: 30,
          child: Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 14,
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 30,
          child: Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 14,
          child: Transform.rotate(
            angle: 0.5,
            child: Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),

        // الدرع الأخضر
        CustomPaint(
          size: const Size(88, 100),
          painter: _ShieldPainter(),
        ),
      ],
    );
  }
}

// ── رسم الدرع الأخضر 3D ─────────────────────────────────────
class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // مسار الدرع بالكامل
    final path = Path();
    path.moveTo(width * 0.5, 0);
    path.lineTo(width * 0.95, height * 0.16);
    path.cubicTo(
      width * 0.95, height * 0.65,
      width * 0.5, height * 0.92,
      width * 0.5, height,
    );
    path.cubicTo(
      width * 0.5, height * 0.92,
      width * 0.05, height * 0.65,
      width * 0.05, height * 0.16,
    );
    path.close();

    // ظل الدرع
    canvas.drawShadow(path, const Color(0xFF1B7A36).withOpacity(0.4), 10, true);

    // النصف الأيسر (أفتح)
    final leftPath = Path();
    leftPath.moveTo(width * 0.5, 0);
    leftPath.lineTo(width * 0.05, height * 0.16);
    leftPath.cubicTo(
      width * 0.05, height * 0.65,
      width * 0.5, height * 0.92,
      width * 0.5, height,
    );
    leftPath.close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38A169), Color(0xFF276749)],
      ).createShader(Rect.fromLTWH(0, 0, width * 0.5, height));

    canvas.drawPath(leftPath, leftPaint);

    // النصف الأيمن (أغمق ليعطي عمق 3D)
    final rightPath = Path();
    rightPath.moveTo(width * 0.5, 0);
    rightPath.lineTo(width * 0.95, height * 0.16);
    rightPath.cubicTo(
      width * 0.95, height * 0.65,
      width * 0.5, height * 0.92,
      width * 0.5, height,
    );
    rightPath.close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF22543D), Color(0xFF1C4532)],
      ).createShader(Rect.fromLTWH(width * 0.5, 0, width * 0.5, height));

    canvas.drawPath(rightPath, rightPaint);

    // إطار الدرع الخارجي
    final strokePaint = Paint()
      ..color = const Color(0xFF68D391)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── رسم الأمواج السفلية ─────────────────────────────────────
class _BottomWavePainter extends CustomPainter {
  final bool isDark;
  _BottomWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // الموجة الخلفية
    final backPath = Path();
    backPath.moveTo(0, h * 0.4);
    backPath.quadraticBezierTo(w * 0.35, h * 0.1, w * 0.7, h * 0.6);
    backPath.quadraticBezierTo(w * 0.85, h * 0.85, w, h * 0.5);
    backPath.lineTo(w, h);
    backPath.lineTo(0, h);
    backPath.close();

    final backPaint = Paint()
      ..color = isDark ? const Color(0xFF133824).withOpacity(0.6) : const Color(0xFF81C784).withOpacity(0.5);
    canvas.drawPath(backPath, backPaint);

    // الموجة الأمامية
    final frontPath = Path();
    frontPath.moveTo(0, h * 0.7);
    frontPath.quadraticBezierTo(w * 0.3, h, w * 0.65, h * 0.5);
    frontPath.quadraticBezierTo(w * 0.85, h * 0.2, w, h * 0.4);
    frontPath.lineTo(w, h);
    frontPath.lineTo(0, h);
    frontPath.close();

    final frontPaint = Paint()
      ..color = isDark ? const Color(0xFF0E2B1C) : const Color(0xFF388E3C);
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
