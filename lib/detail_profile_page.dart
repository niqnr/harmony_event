import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:harmony_event/main.dart';

class DetailProfilePage extends StatefulWidget {
  final String uploaderUid;
  const DetailProfilePage({Key? key, required this.uploaderUid}) : super(key: key);

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> {
  int _totalLikes = 0;

  Future<int> _fetchTotalLikes() async {
    final eventsRef = FirebaseDatabase.instance.ref('item');
    final eventsSnapshot = await eventsRef.orderByChild('uploaderUid').equalTo(widget.uploaderUid).get();
    int likes = 0;
    if (eventsSnapshot.exists) {
      final eventsData = Map<String, dynamic>.from(eventsSnapshot.value as Map);
      eventsData.forEach((key, value) {
        likes += (value['likes'] ?? 0) as int;
      });
    }
    return likes;
  }

  @override
  void initState() {
    super.initState();
    _fetchTotalLikes().then((val) {
      setState(() {
        _totalLikes = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Profil')),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.ref('user/${widget.uploaderUid}').get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Akun tidak ditemukan'));
          final user = snapshot.data!.value as Map;
          final photoUrl = user['photoUrl'] ?? 'https://via.placeholder.com/150';
          final username = user['username'] ?? user['nama_organisasi'] ?? 'User';
          final email = user['email'] ?? '';
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Jumlah Like $_totalLikes',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Event yang diupload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                SizedBox(
                  height: 400,
                  child: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance.ref('item').orderByChild('uploaderUid').equalTo(widget.uploaderUid).onValue,
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data?.snapshot.value == null) {
                        return const Center(child: Text('Belum ada event'));
                      }
                      final data = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
                      final items = data.entries.toList();
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final event = items[idx].value;
                          final imageUrl = event['imageUrl'];
                          Widget imageWidget;
                          const double thumbnailSize = 60.0;
                          if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                            try {
                              imageWidget = Image.memory(
                                base64Decode(imageUrl),
                                width: thumbnailSize,
                                height: thumbnailSize,
                                fit: BoxFit.cover,
                              );
                            } catch (e) {
                              imageWidget = Image.network(
                                'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                                width: thumbnailSize,
                                height: thumbnailSize,
                                fit: BoxFit.cover,
                              );
                            }
                          } else {
                            imageWidget = Image.network(
                              (imageUrl != null && imageUrl.isNotEmpty)
                                  ? imageUrl
                                  : 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
                              width: thumbnailSize,
                              height: thumbnailSize,
                              fit: BoxFit.cover,
                            );
                          }
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageWidget,
                            ),
                            title: Text(event['nama'] ?? ''),
                            subtitle: Text(event['kategori'] ?? ''),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailEventPage(event: event, eventKey: items[idx].key),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 