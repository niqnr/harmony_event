import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        title: const Text('Harmony Event', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari event...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('item').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('Belum ada event'));
                }
                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                var items = data.entries
                    .where((e) => _searchQuery.isEmpty || (e.value['nama']?.toString().toLowerCase().contains(_searchQuery) ?? false))
                    .toList();
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada event yang ditemukan untuk "$_searchQuery"'
                          : 'Belum ada event',
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final event = items[idx].value;
                    final eventKey = items[idx].key;
                    return ListTile(
                      title: Text(event['nama'] ?? ''),
                      subtitle: Text(event['kategori'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailEventPage(event: event, eventKey: eventKey),
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
  }
} 