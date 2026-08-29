import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
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

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted && userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DelegateDashboard(email: userCredential.user!.email!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تسجيل الدخول: " + e.toString() + "')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('بوابة المحافظين'), backgroundColor: AppColors.cardBackground),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, size: 64, color: AppColors.primaryOrange),
                const SizedBox(height: 16),
                const Text('تسجيل الدخول', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('خاص بمحافظي ومراقبي المباريات فقط', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('دخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}