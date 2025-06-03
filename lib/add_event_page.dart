import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AddEventPage extends StatefulWidget {
  // ... (existing code)
}

class _AddEventPageState extends State<AddEventPage> {
  // ... (existing code)

  Future<void> _addEvent() async {
    try {
      // ... (existing code)
      final eventRef = FirebaseDatabase.instance.ref('item').push();
      await eventRef.set({
        'name': _nameController.text,
        'date': _selectedDate.toIso8601String(),
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'imageUrl': _imageUrl,
        'uploaderId': FirebaseAuth.instance.currentUser?.uid,
        'uploaderName': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Add notification with eventId
      final notificationRef = FirebaseDatabase.instance.ref('notifikasi').push();
      await notificationRef.set({
        'title': 'Event Baru',
        'message': '${_nameController.text} telah ditambahkan ke dalam daftar event',
        'eventId': eventRef.key,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // ... (existing code)
    } catch (e) {
      // ... (existing code)
    }
  }

  // ... (rest of the existing code)
} 