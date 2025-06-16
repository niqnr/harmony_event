import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _currentUserId;
  int _totalLikes = 0;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_currentUserId == null) {
      setState(() { _isLoading = false; });
      return;
    }
    try {
      final userRef = FirebaseDatabase.instance.ref('user').child(_currentUserId!);
      final userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        _userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      }
      setState(() { _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  void _showEditProfileDialog(String currentName, String userStatus, String currentPhotoUrl) async {
    final controller = TextEditingController(text: currentName);
    final isStudent = userStatus == 'student';
    final label = isStudent ? 'Username' : 'Nama Organisasi';
    XFile? pickedFile;
    String? previewPhoto = currentPhotoUrl;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Edit $label & Foto Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final file = await picker.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    pickedFile = file;
                    final bytes = await file.readAsBytes();
                    setStateDialog(() {
                      previewPhoto = base64Encode(bytes);
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: (previewPhoto != null && previewPhoto?.isNotEmpty == true && !(previewPhoto?.startsWith('http') ?? false))
                    ? MemoryImage(base64Decode(previewPhoto!))
                    : (currentPhotoUrl.isNotEmpty ? NetworkImage(currentPhotoUrl) : null) as ImageProvider?,
                  child: const Icon(Icons.camera_alt, size: 28, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: 'Masukkan $label baru'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || _userData == null) return;
                final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
                Map<String, dynamic> updateData = {};
                if (newName.isNotEmpty && newName != currentName) {
                  if (isStudent) {
                    updateData['username'] = newName;
                  } else {
                    updateData['nama_organisasi'] = newName;
                  }
                }
                if (pickedFile != null && previewPhoto != null && previewPhoto != currentPhotoUrl) {
                  updateData['photoUrl'] = previewPhoto;
                }
                if (updateData.isNotEmpty) {
                  await userRef.update(updateData);
                  setState(() {
                    if (updateData.containsKey('username')) _userData!['username'] = newName;
                    if (updateData.containsKey('nama_organisasi')) _userData!['nama_organisasi'] = newName;
                    if (updateData.containsKey('photoUrl')) _userData!['photoUrl'] = previewPhoto;
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diubah!')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_userData == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat data user.')),
      );
    }
    final String status = _userData!['status'] ?? '';
    final String username = _userData!['username'] ?? _userData!['nama_organisasi'] ?? 'User';
    final String photoUrl = _userData!['photoUrl'] ?? 'https://via.placeholder.com/150';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showEditProfileDialog(username, status, photoUrl),
              child: CircleAvatar(
                radius: 60,
                backgroundImage: photoUrl.isNotEmpty && !photoUrl.startsWith('http')
                    ? MemoryImage(base64Decode(photoUrl))
                    : NetworkImage(photoUrl) as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit',
                  onPressed: () => _showEditProfileDialog(username, status, photoUrl),
                ),
              ],
            ),
            if (status == 'ormawa') ...[
              const SizedBox(height: 8),
              Text('Jumlah Like $_totalLikes'),
            ],
          ],
        ),
      ),
    );
  }
} 