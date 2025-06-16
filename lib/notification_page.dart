import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:harmony_event/main.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref('notifikasi');

  void _navigateToEventDetail(String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailEventPage(eventKey: eventId, event: const {}),
      ),
    );
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
        title: const Text('Notifikasi', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _notificationsRef.orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Tidak ada notifikasi'));
          }

          final notifications = Map<String, dynamic>.from(
            (snapshot.data!.snapshot.value as Map<dynamic, dynamic>)
                .map((key, value) => MapEntry(key.toString(), value)),
          );

          final sortedNotifications = notifications.entries.toList()
            ..sort((a, b) => (b.value['timestamp'] as int)
                .compareTo(a.value['timestamp'] as int));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedNotifications.length,
            itemBuilder: (context, index) {
              final notification = sortedNotifications[index].value;
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                notification['timestamp'] as int,
              );
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm')
                  .format(timestamp);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    if (notification['eventId'] != null) {
                      _navigateToEventDetail(notification['eventId']);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6CB6FF).withOpacity(0.1),
                      child: const Icon(
                        Icons.event,
                        color: Color(0xFF6CB6FF),
                      ),
                    ),
                    title: Text(
                      notification['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] as String,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 