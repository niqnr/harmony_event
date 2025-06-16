import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harmony_event/main.dart';
import 'package:harmony_event/registration_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmony_event/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool isStudentSelected = true; // default Student
  bool _isPasswordVisible = false;

  Future<void> _saveLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
  }

  void _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Ambil data user dari database
      final uid = userCredential.user?.uid;
      if (uid != null) {
        final userRef = FirebaseDatabase.instance.ref('user').child(uid);
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final status = data['status'];
          // Validasi status sesuai pilihan login
          if ((isStudentSelected && status == 'student') || (!isStudentSelected && status == 'ormawa')) {
            await _saveLoginStatus();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
            return;
          } else {
            // Status tidak sesuai
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akun ini terdaftar sebagai \\${status == 'student' ? 'Student' : 'Ormawa'}. Silakan login sesuai tipe akun.'),
                backgroundColor: Colors.redAccent,
              ),
            );
            await FirebaseAuth.instance.signOut();
            await _clearLoginStatus();
            return;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data akun tidak ditemukan di database.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        await FirebaseAuth.instance.signOut();
        await _clearLoginStatus();
        return;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login gagal. Silakan coba lagi.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Tidak ada pengguna dengan email tersebut.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: \\${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6CB6FF), Color(0xFF3B5BFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset('assets/image/1.jpeg', width: 90, height: 90, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF222B45),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isStudentSelected = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isStudentSelected ? const Color(0xFF3B5BFF) : Colors.white,
                                border: Border.all(color: const Color(0xFF3B5BFF)),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Student",
                                  style: TextStyle(
                                    color: isStudentSelected ? Colors.white : const Color(0xFF3B5BFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                isStudentSelected = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isStudentSelected ? const Color(0xFF3B5BFF) : Colors.white,
                                border: Border.all(color: const Color(0xFF3B5BFF)),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Ormawa",
                                  style: TextStyle(
                                    color: !isStudentSelected ? Colors.white : const Color(0xFF3B5BFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B5BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationPage()),
                        );
                      },
                      child: const Text(
                        'Daftar Akun Baru',
                        style: TextStyle(
                          color: Color(0xFF2D5BFF),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
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