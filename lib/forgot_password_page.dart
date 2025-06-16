import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    setState(() { _isLoading = true; });
    final input = _usernameController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email wajib diisi!'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
      return;
    }
    try {
      final userRef = FirebaseDatabase.instance.ref('user');
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final users = Map<String, dynamic>.from(snapshot.value as Map);
        String? userKey;
        String? email;
        users.forEach((key, value) {
          if (input.contains('@')) {
            if (value['email'] == input) {
              userKey = key;
              email = value['email'];
            }
          } else {
            if (value['username'] == input || value['nama_organisasi'] == input) {
              userKey = key;
              email = value['email'];
            }
          }
        });
        if (userKey != null && email != null) {
          // Kirim email reset password jika input adalah email
          if (input.contains('@')) {
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link reset password sudah dikirim ke email!'), backgroundColor: Colors.green),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mengirim email reset password: $e'), backgroundColor: Colors.redAccent),
              );
            }
          } else {
            // Jika input username, update password di database saja
            await userRef.child(userKey!).update({'password': 'newPassword'});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password di database berhasil diubah!'), backgroundColor: Colors.green),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username atau email tidak ditemukan!'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: $e'), backgroundColor: Colors.redAccent),
      );
    }
    setState(() { _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5BFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 