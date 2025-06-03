import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Controller untuk Student
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentEmailController = TextEditingController();
  final TextEditingController _studentPasswordController = TextEditingController();
  final TextEditingController _studentConfirmPasswordController = TextEditingController();

  // Controller untuk Ormawa
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _orgEmailController = TextEditingController();
  final TextEditingController _orgContactController = TextEditingController();
  final TextEditingController _orgSKController = TextEditingController();
  final TextEditingController _orgPasswordController = TextEditingController();
  String? _orgCategory;
  String? _orgCustomCategory;

  bool isStudentSelected = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentEmailController.dispose();
    _studentPasswordController.dispose();
    _studentConfirmPasswordController.dispose();
    _orgNameController.dispose();
    _orgEmailController.dispose();
    _orgContactController.dispose();
    _orgSKController.dispose();
    _orgPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _register() async {
    try {
      if (isStudentSelected) {
        // Validasi student
        if (_studentNameController.text.isEmpty ||
            _studentEmailController.text.isEmpty ||
            _studentPasswordController.text.isEmpty ||
            _studentConfirmPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua field wajib diisi.'), backgroundColor: Colors.redAccent),
          );
          return;
        }
        if (_studentPasswordController.text != _studentConfirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password dan konfirmasi password tidak sama.'), backgroundColor: Colors.redAccent),
          );
          return;
  }
        // Register Student
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _studentEmailController.text,
          password: _studentPasswordController.text,
      );
      if (userCredential.user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('user').child(userCredential.user!.uid);
        await userRef.set({
            'email': _studentEmailController.text,
            'username': _studentNameController.text,
            'status': 'student',
            'createdAt': DateTime.now().toIso8601String(),
        });
      }
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan masuk.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        // Validasi ormawa
        if (_orgNameController.text.isEmpty ||
            _orgEmailController.text.isEmpty ||
            _orgPasswordController.text.isEmpty ||
            _orgContactController.text.isEmpty ||
            _orgSKController.text.isEmpty ||
            _orgCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua field wajib diisi.'), backgroundColor: Colors.redAccent),
      );
          return;
        }
        if (_orgCategory == 'Lainnya' && (_orgCustomCategory == null || _orgCustomCategory!.isEmpty)) {
       ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan isi kategori organisasi.'), backgroundColor: Colors.redAccent),
        );
          return;
  }
        // Register Ormawa
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _orgEmailController.text,
          password: _orgPasswordController.text,
      );
       if (userCredential.user != null) {
        DatabaseReference userRef = FirebaseDatabase.instance.ref('user').child(userCredential.user!.uid);
        await userRef.set({
            'email': _orgEmailController.text,
            'nama_organisasi': _orgNameController.text,
            'kontak_person': _orgContactController.text,
            'sk_terbaru': _orgSKController.text,
            'kategori': _orgCategory == 'Lainnya' ? _orgCustomCategory : _orgCategory ?? '',
            'status': 'ormawa',
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi Ormawa berhasil! Silakan masuk.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registrasi gagal. Silakan coba lagi.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Akun dengan email ini sudah ada.';
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
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Daftar', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 32),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStudentSelected ? 'Pendaftaran akun Mahasiswa' : 'Pendaftaran akun ORMAWA',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isStudentSelected
                                  ? 'Untuk mendaftar sebagai mahasiswa, harap lengkapi data yang dibutuhkan di bawah ini.'
                                  : 'Untuk mendaftar sebagai organisasi mahasiswa, harap lengkapi data yang dibutuhkan di bawah ini.',
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                            Row(
                              children: [
                                Text(
                                  isStudentSelected
                                    ? 'Ingin daftar sebagai Ormawa? '
                                    : 'Ingin daftar sebagai Mahasiswa? ',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isStudentSelected = !isStudentSelected;
                                    });
                                    // Scroll ke atas agar user langsung lihat form baru
                                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    isStudentSelected ? 'Daftar Ormawa' : 'Daftar Mahasiswa',
                                    style: const TextStyle(
                                      color: Color(0xFF2D5BFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                      ),
                    ),
                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isStudentSelected) ...[
                    _buildInput(_studentNameController, 'Nama Mahasiswa'),
                    const SizedBox(height: 16),
                    _buildInput(_studentEmailController, 'Email'),
                    const SizedBox(height: 16),
                    _buildInput(_studentPasswordController, 'Kata Sandi', isPassword: true),
                    const SizedBox(height: 16),
                    _buildInput(_studentConfirmPasswordController, 'Konfirmasi Kata Sandi', isPassword: true),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5BFF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                  'Daftar',
                  style: TextStyle(
                          color: Colors.white,
                    fontWeight: FontWeight.bold,
                          fontSize: 16,
                  ),
                ),
                    ),
                  ),
                  ] else ...[
                    _buildInput(_orgNameController, 'Nama Organisasi'),
                    const SizedBox(height: 16),
                    _buildInput(_orgEmailController, 'Email'),
                    const SizedBox(height: 16),
                    _buildInput(_orgPasswordController, 'Kata Sandi', isPassword: true),
                    const SizedBox(height: 16),
                    _buildInput(_orgContactController, 'Kontak Person'),
                    const SizedBox(height: 16),
                    _buildInput(_orgSKController, 'Masukan SK terbaru Organisasi'),
                    const SizedBox(height: 16),
                    _buildDropdownKategori(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B5BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Validasi akun',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                 TextButton(
                  onPressed: () {
                      Navigator.pop(context);
                  },
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                  const SizedBox(height: 20),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownKategori() {
    final kategoriList = [
      'BEM', 'UKM', 'Himpunan', 'Komunitas', 'Lainnya'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _orgCategory,
              hint: const Text('Kategori Organisasi'),
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              items: kategoriList.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _orgCategory = val;
                  if (val != 'Lainnya') _orgCustomCategory = null;
                });
              },
            ),
          ),
        ),
        if (_orgCategory == 'Lainnya')
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextField(
              onChanged: (val) => _orgCustomCategory = val,
              decoration: InputDecoration(
                hintText: 'Tulis kategori organisasi',
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 