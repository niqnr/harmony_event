import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:harmony_event/login_page.dart';
import 'package:harmony_event/profile_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:harmony_event/registration_page.dart';
import 'package:flutter/foundation.dart';
import 'package:harmony_event/notification_page.dart';
import 'package:harmony_event/detail_profile_page.dart';

final String _defaultImage = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80';

class AddEventPage extends StatefulWidget {
  const AddEventPage({Key? key}) : super(key: key);

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _tingkatLainController = TextEditingController();
  final TextEditingController _partisipanController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;
  bool _isLoading = false;

  File? _selectedImage;
  String? _base64Image;

  final List<String> _categories = [
    'Lomba', 'Recruitment', 'Seminar', 'Workshop', 'Konser', 'Pameran', 'Kegiatan Mahasiswa', 'Lainnya'
  ];

  final List<String> _randomImages = [
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=400&q=80',
    'https://images.unsplash.com/photo-1465101178521-c1a9136a3b99?auto=format&fit=crop&w=400&q=80',
  ];

  bool _isPaid = false;

  String? _selectedTingkat;
  final List<String> _tingkatList = [
    'Internasional', 'Nasional', 'Lembaga', 'Fakultas', 'Jurusan', 'Lain-lain'
  ];

  String getRandomImage([int? seed]) {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    return _randomImages[rand.nextInt(_randomImages.length)];
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _tingkatLainController.dispose();
    _partisipanController.dispose();
    super.dispose();
  }

  String _unformatHarga(String formatted) {
    return formatted.replaceAll('.', '');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: now, end: now),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
        if (!kIsWeb) {
          _selectedImage = File(pickedFile.path);
        } else {
          _selectedImage = null;
        }
      });
    } else {
      setState(() {
        _selectedImage = null;
        _base64Image = null;
      });
    }
  }

  Future<void> _postEvent() async {
    setState(() { _isLoading = true; });
    // Basic validation
    if (_namaController.text.isEmpty || _selectedDateRange == null || _selectedCategory == null || _deskripsiController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field yang wajib diisi.'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
      return;
    }

    if (_isPaid && _hargaController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan harga event.'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk memposting event.'), backgroundColor: Colors.redAccent),
      );
      setState(() { _isLoading = false; });
      return;
    }

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('item').push();
      await ref.set({
        'nama': _namaController.text,
        'waktuMulai': _selectedDateRange!.start.toIso8601String(),
        'waktuSelesai': _selectedDateRange!.end.toIso8601String(),
        'kategori': _selectedCategory ?? '',
        'deskripsi': _deskripsiController.text,
        'createdAt': DateTime.now().toIso8601String(),
        'imageUrl': _base64Image ?? '',
        'isPaid': _isPaid,
        'harga': _isPaid ? _unformatHarga(_hargaController.text) : null,
        'tingkat': _selectedTingkat == 'Lain-lain' ? _tingkatLainController.text : _selectedTingkat,
        'partisipan': _partisipanController.text,
        'uploaderUid': user.uid,
      });
      // Tambahkan notifikasi event baru
      final notificationRef = FirebaseDatabase.instance.ref('notifikasi').push();
      await notificationRef.set({
        'title': 'Event Baru',
        'message': '${_namaController.text} telah ditambahkan ke dalam daftar event',
        'eventId': ref.key,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil diposting!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal posting event: \\${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tambah Kegiatan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _pickImage,
                  child: _base64Image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(_base64Image!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.image, size: 80, color: Colors.black45),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Klik gambar untuk memilih foto',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _buildInput(_namaController, 'Nama Event'),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildInput(_deskripsiController, 'Deskripsi', maxLines: 3),
                const SizedBox(height: 16),
                // Tingkat Event
                _buildTingkatDropdown(),
                if (_selectedTingkat == 'Lain-lain')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: _buildInput(_tingkatLainController, 'Masukkan tingkat event'),
                  ),
                const SizedBox(height: 16),
                // Partisipan
                _buildInput(_partisipanController, 'Partisipan (misal: Mahasiswa FTK Semester 2-6)'),
                const SizedBox(height: 16),
                // Opsi Gratis/Berbayar
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Gratis'),
                        value: false,
                        groupValue: _isPaid,
                        onChanged: (val) {
                          setState(() {
                            _isPaid = val ?? false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Berbayar'),
                        value: true,
                        groupValue: _isPaid,
                        onChanged: (val) {
                          setState(() {
                            _isPaid = val ?? false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_isPaid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildInput(
                      _hargaController,
                      'Harga (contoh: 50.000)',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _postEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Posting',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {int maxLines = 1, List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _selectedDateRange != null
              ? '${_formatTanggal(_selectedDateRange!.start.toIso8601String())} - ${_formatTanggal(_selectedDateRange!.end.toIso8601String())}'
              : 'Waktu Event (Range Tanggal)',
          style: TextStyle(
            color: _selectedDateRange != null ? Colors.black : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          hint: const Text('Kategori'),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: _categories.map((cat) => DropdownMenuItem(
            value: cat,
            child: Text(cat),
          )).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTingkatDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTingkat,
          hint: const Text('Tingkat Event'),
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          items: _tingkatList.map((tingkat) => DropdownMenuItem(
            value: tingkat,
            child: Text(tingkat),
          )).toList(),
          onChanged: (val) {
            setState(() {
              _selectedTingkat = val;
            });
          },
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp(loggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harmony Event',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: loggedIn ? const HomePage() : const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0;
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> categories = [
    'Terbaru', 'Lomba', 'Seminar', 'Konser', 'Pameran'
  ];

  String? _username;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref().child('user').child(user.uid);
      final snapshot = await ref.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _username = data['username'] ?? data['nama_organisasi'] ?? 'User';
          _photoUrl = data['photoUrl'];
        });
      }
    }
  }

  Widget _buildHomePageContent() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DatabaseEvent>(
      stream: user != null ? FirebaseDatabase.instance.ref('user').child(user.uid).onValue : null,
      builder: (context, snapshot) {
        String username = 'User';
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          username = data['username'] ?? data['nama_organisasi'] ?? 'User';
          photoUrl = data['photoUrl'];
        }
        // Extract the header and search bar as they don't depend on category
        final headerSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 18),
                Row(
              crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')
                      ? MemoryImage(base64Decode(photoUrl))
                      : NetworkImage(photoUrl ?? 'https://via.placeholder.com/150') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hallo, $username!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Yuk cek kegiatan terkini',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 28),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                  child: TextField(
                  controller: _searchController,
                    decoration: InputDecoration(
                    hintText: 'Cari event...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
              height: 44,
              width: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  // Trigger search
                  setState(() {
                    _searchQuery = _searchController.text.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            // HAPUS BAGIAN INI:
            // Container(
            //   height: 44,
            //   width: 44,
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: IconButton(
            //     icon: const Icon(Icons.menu_rounded),
            //     onPressed: () {},
            //   ),
            // ),
            ],
            ),
            const SizedBox(height: 18),
      ],
    );

        // The category list and the event list based on category selection
        final categoryAndFilteredList = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // KATEGORI
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final selected = idx == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = idx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF3B5BFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF3B5BFF), width: 2),
                          ),
                          child: Text(
                            categories[idx],
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF3B5BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _sectionTitle(categories[_selectedCategory]),
                const SizedBox(height: 8),
            // Tampilkan event terbaru jika kategori 'Terbaru' dipilih, jika tidak filter kategori
            _selectedCategory == 0
              ? _eventList(sortBy: 'createdAt')
              : _eventList(kategori: categories[_selectedCategory]),
                const SizedBox(height: 24),
          ],
        );

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerSection,
                categoryAndFilteredList,
                // Use the new widget for the most liked section
                const MostLikedEventsSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: _selectedNavIndex == 0
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: _buildHomePageContent(),
              )
            : _selectedNavIndex == 2
                ? const ProfilePage()
                : Container(), // Placeholder for other pages
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) async { // Make onTap async to await user status check and dialog result
          if (index == 1) { // Add Event button
            final user = FirebaseAuth.instance.currentUser;
            String? userStatus;
            if (user != null) {
               final userRef = FirebaseDatabase.instance.ref().child('user').child(user.uid);
               final snapshot = await userRef.get();
               if (snapshot.exists) {
                 final data = Map<String, dynamic>.from(snapshot.value as Map);
                 userStatus = data['status'];
               }
            }

            if (userStatus == 'ormawa') {
              // Allow Ormawa to add events
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventPage()),
              );
            } else { // Student or not logged in (shouldn't happen if loggedIn check in MyApp works, but good to be safe)
              // Show warning and offer to register as Ormawa
              final bool? registerAsOrmawa = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Akses Dibatasi'),
                    content: const Text('Hanya akun Ormawa yang dapat menambah event. Apakah Anda ingin mendaftar sebagai akun Ormawa?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // User cancels
                        child: const Text('Tidak'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true), // User confirms
                        child: const Text('Ya, Daftar Ormawa'),
                      ),
                    ],
                  );
                },
              );

              if (registerAsOrmawa == true) {
                // Navigate to RegistrationPage, maybe pass a flag to pre-select Ormawa
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const RegistrationPage()), // TODO: Pass a flag to RegistrationPage to select Ormawa
                 );
              }
               // If user cancels dialog or chooses not to register, stay on current page
            }
          } else { // Other navigation items (Home, Profile)
          setState(() {
            _selectedNavIndex = index;
          });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded, size: 36),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        selectedItemColor: Color(0xFF2D5BFF),
        unselectedItemColor: Colors.black54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: () {
            Navigator.push(
              // ignore: use_build_context_synchronously
              context,
              MaterialPageRoute(builder: (context) => const AllEventsPage()),
            );
          },
          child: const Text('Lihat Semuanya', style: TextStyle(color: Color(0xFF2D5BFF))),
        ),
      ],
    );
  }

  Widget _eventList({String? kategori, String? sortBy}) {
    return EventList(
      kategori: kategori,
      sortBy: sortBy,
                isFullWidth: false,
      searchQuery: _searchQuery,
    );
  }
}

String _formatTanggal(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')} ${_bulan(date.month)} ${date.year}';
}

String _bulan(int month) {
  const bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return bulan[month];
}

class AllEventsPage extends StatefulWidget {
  const AllEventsPage({Key? key}) : super(key: key);

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
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
        title: const Text('Semua Event'),
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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
            child: EventList(
              isFullWidth: true,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}

class EventList extends StatelessWidget {
  final String? kategori;
  final String? sortBy;
  final bool isFullWidth;
  final String searchQuery;

  const EventList({
    Key? key,
    this.kategori,
    this.sortBy,
    this.isFullWidth = false,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
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
            .where((e) => 
                // Filter by category
                (kategori == null || 
                (e.value['kategori']?.toString().toLowerCase() == kategori?.toLowerCase())) &&
                // Filter by search query
                (searchQuery.isEmpty || 
                (e.value['nama']?.toString().toLowerCase().contains(searchQuery) ?? false)))
            .toList();

        if (sortBy != null) {
          items.sort((a, b) {
            if (sortBy == 'createdAt') {
              return (b.value['createdAt'] ?? '').compareTo(a.value['createdAt'] ?? '');
            } else if (sortBy == 'likes') {
              final likesA = (a.value['likes'] ?? 0) as int;
              final likesB = (b.value['likes'] ?? 0) as int;
              return likesB.compareTo(likesA); // Descending order
            }
            return 0;
          });
        }

          if (items.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty 
                  ? 'Tidak ada event yang ditemukan untuk "$searchQuery"'
                  : 'Belum ada event',
            ),
          );
        }

        // Adjust ListView properties based on isFullWidth
        if (isFullWidth) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              final event = items[idx].value;
              final eventKey = items[idx].key;
              return EventCard(
                key: ValueKey(eventKey),
                event: event,
                eventKey: eventKey,
                isFullWidth: true, // Use full width for vertical list
              );
            },
          );
        } else {
          // Wrap horizontal ListView with SizedBox for a fixed height
    return SizedBox(
            height: 435, // Add fixed height for horizontal list
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
              itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, idx) {
                final event = items[idx].value;
                final eventKey = items[idx].key;
                return EventCard(
                  key: ValueKey(eventKey),
                  event: event,
                  eventKey: eventKey,
                  isFullWidth: false,
          );
        },
      ),
    );
        }
      },
    );
  }
}

class EventCard extends StatefulWidget {
  final Map event;
  final String? eventKey;
  final bool isFullWidth;

  const EventCard({
    Key? key,
    required this.event,
    this.eventKey,
    this.isFullWidth = false,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  Stream<DatabaseEvent>? _likeStream;

  @override
  void initState() {
    super.initState();
    if (widget.eventKey != null) {
      _likeStream = FirebaseDatabase.instance
          .ref('item')
          .child(widget.eventKey!)
          .onValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.event['imageUrl'];
    Widget imageWidget;
    final double a4AspectRatio = 1 / 1.414;
    
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageWidget = Image.memory(
        base64Decode(imageUrl),
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.network(
        (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : _defaultImage,
        fit: BoxFit.cover,
      );
    }
    
    final bool isPaid = widget.event['isPaid'] == true || widget.event['isPaid'] == 'true';
    final String? harga = widget.event['harga'];
    
    // Get date range
    final String? waktuMulai = widget.event['waktuMulai'];
    final String? waktuSelesai = widget.event['waktuSelesai'];
    String waktuDisplay = '-';
    if (waktuMulai != null && waktuMulai.isNotEmpty && waktuSelesai != null && waktuSelesai.isNotEmpty) {
      final String formattedStart = _formatTanggal(waktuMulai);
      final String formattedEnd = _formatTanggal(waktuSelesai);
      if (formattedStart == formattedEnd) {
        waktuDisplay = formattedStart;
      } else {
        waktuDisplay = '${formattedStart} - ${formattedEnd}';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailEventPage(event: widget.event, eventKey: widget.eventKey),
          ),
        );
      },
      child: Container(
        width: widget.isFullWidth ? double.infinity : 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
              child: widget.isFullWidth
                  ? AspectRatio(aspectRatio: a4AspectRatio, child: imageWidget)
                  : SizedBox(
                      width: 200,
                      height: 200 / a4AspectRatio,
                      child: imageWidget,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.event['nama'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        waktuDisplay,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                  children: [
                        if (widget.event['kategori'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue),
                      ),
                        child: Text(
                              widget.event['kategori'],
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                        if (isPaid) ...[
                          Text(
                            harga != null && harga.isNotEmpty ? 'Rp$harga' : '-',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Gratis',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                          if (widget.eventKey != null && _likeStream != null)
                            StreamBuilder<DatabaseEvent>(
                              stream: _likeStream,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                                  return const Icon(
                                    Icons.favorite_rounded,
                                    size: 18,
                                    color: Colors.grey,
                                  );
                                }

                                final data = Map<String, dynamic>.from(
                                    snapshot.data!.snapshot.value as Map);
                                final user = FirebaseAuth.instance.currentUser;
                                final List<dynamic> likedBy = data['likedBy'] ?? [];
                                final bool isLiked = user != null && likedBy.contains(user.uid);
                                final int likesCount = data['likes'] ?? 0;

                                return GestureDetector(
                                  onTap: () => _toggleLikeStatus(data, likedBy),
                                  child: Row(
                                    children: [
                                      Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: isLiked ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                                      Text(
                                        '$likesCount',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLikeStatus(Map<String, dynamic> currentData, List<dynamic> currentLikedBy) async {
    if (widget.eventKey == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk melakukan like')),
      );
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref('item').child(widget.eventKey!);
      List<dynamic> newLikedBy = List<dynamic>.from(currentLikedBy);
      
      if (newLikedBy.contains(user.uid)) {
        newLikedBy.remove(user.uid);
      } else {
        newLikedBy.add(user.uid);
      }

      await ref.update({
        'likedBy': newLikedBy,
        'likes': newLikedBy.length,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status like: $e')),
      );
    }
  }
}

// Halaman detail event
class DetailEventPage extends StatefulWidget {
  final Map event;
  final String? eventKey;
  const DetailEventPage({Key? key, required this.event, this.eventKey}) : super(key: key);

  @override
  _DetailEventPageState createState() => _DetailEventPageState();
}

class _DetailEventPageState extends State<DetailEventPage> {
  String? _userStatus;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserStatus();
    _checkRegistrationStatus();
  }

  Future<void> _fetchCurrentUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _userStatus = data['status'];
        });
      }
    }
  }

  Future<void> _checkRegistrationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.eventKey == null) return;

    final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      List<dynamic> registeredEvents = List<dynamic>.from(data['registeredEvents'] ?? []);
      setState(() {
        _isRegistered = registeredEvents.contains(widget.eventKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.event['imageUrl'];
    final bool isPaid = widget.event['isPaid'] == true || widget.event['isPaid'] == 'true';
    final String? harga = widget.event['harga'];
    final String? uploaderUid = widget.event['uploaderUid'];
    
    // Get date range for detail page
    final String? waktuMulai = widget.event['waktuMulai'];
    final String? waktuSelesai = widget.event['waktuSelesai'];
    String waktuDisplay = '-';
    if (waktuMulai != null && waktuMulai.isNotEmpty && waktuSelesai != null && waktuSelesai.isNotEmpty) {
      final String formattedStart = _formatTanggal(waktuMulai);
      final String formattedEnd = _formatTanggal(waktuSelesai);
      if (formattedStart == formattedEnd) {
        waktuDisplay = formattedStart;
      } else {
        waktuDisplay = '${formattedStart} - ${formattedEnd}';
      }
    }
    
    // A4 aspect ratio (approx 1:1.414)
    final double a4AspectRatio = 1 / 1.414;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Kegiatan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: a4AspectRatio,
                    child: imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')
                        ? Image.memory(base64Decode(imageUrl), fit: BoxFit.cover)
                        : Image.network(
                            (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : _defaultImage,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                widget.event['nama'] ?? '-',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              // Organisasi/penyelenggara dengan StreamBuilder
              if (uploaderUid != null)
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('user').child(uploaderUid).onValue,
                  builder: (context, snapshot) {
                    String uploaderName = 'Pengunggah Tidak Dikenal';
                    String? uploaderPhotoUrl;
                    String uploaderStatus = '';

                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                      uploaderName = data['username'] ?? data['nama_organisasi'] ?? 'Pengunggah Tidak Dikenal';
                      uploaderPhotoUrl = data['photoUrl'];
                      uploaderStatus = data['status'] ?? '';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailProfilePage(uploaderUid: uploaderUid),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5BFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: uploaderPhotoUrl != null && uploaderPhotoUrl.isNotEmpty && !uploaderPhotoUrl.startsWith('http')
                                      ? MemoryImage(base64Decode(uploaderPhotoUrl))
                                      : NetworkImage(uploaderPhotoUrl ?? 'https://via.placeholder.com/150') as ImageProvider,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(uploaderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    if (uploaderStatus.isNotEmpty)
                                      Text(
                                        uploaderStatus == 'student' ? 'Student' : 'Ormawa',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.event['kategori'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              widget.event['kategori'],
                              style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
              // Info event
              _infoRow('Waktu', waktuDisplay),
              _infoRow('Tingkat', widget.event['tingkat'] ?? '-'),
              _infoRow('Kategori', widget.event['kategori'] ?? '-'),
              _infoRow('Partisipan', widget.event['partisipan'] ?? '-'),
              _infoRow('Biaya', isPaid ? (harga != null && harga.isNotEmpty ? 'Rp$harga' : '-') : 'Gratis'),
              const SizedBox(height: 16),
              // Tombol daftar / Batalkan Daftar - Conditionally show/enable for students
              if (_userStatus == 'student')
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRegistered ? _cancelRegistration : _registerForEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRegistered ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _isRegistered ? 'Batalkan Daftar' : 'Daftar Sekarang',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              if (_userStatus != null && _userStatus != 'student')
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Hanya akun student yang dapat mendaftar event.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.event['deskripsi'] ?? '-', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(value, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // Update _registerForEvent method
  Future<void> _registerForEvent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mendaftar event.')),
      );
      return;
    }

    if (_userStatus != 'student') {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hanya akun student yang dapat mendaftar event.')),
      );
      return;
    }

    if (widget.eventKey == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat mendaftar untuk event ini (key tidak tersedia).')),
      );
      return;
    }

    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pendaftaran'),
          content: const Text('Apakah Anda yakin ingin mendaftar event ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              child: const Text('Daftar'),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed

    if (!confirm) return; // If user cancels, do nothing

    try {
       final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
       final snapshot = await userRef.get();

       if (snapshot.exists) {
         final data = Map<String, dynamic>.from(snapshot.value as Map);
         List<dynamic> registeredEvents = List<dynamic>.from(data['registeredEvents'] ?? []);
         final eventKey = widget.eventKey!;

         if (registeredEvents.contains(eventKey)) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda sudah terdaftar di event ini.')),
            );
         } else {
            registeredEvents.add(eventKey);
            await userRef.update({'registeredEvents': registeredEvents});
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Berhasil mendaftar event!')),
            );
            setState(() { _isRegistered = true; }); // Update state on success
         }
       } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data user tidak ditemukan.')),
          );
       }

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftar event: $e')),
      );
       print('Error registering for event: $e');
    }
  }

  // New method to handle event cancellation for students
  Future<void> _cancelRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.eventKey == null) return;

     // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text('Apakah Anda yakin ingin membatalkan pendaftaran event ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              child: const Text('Batalkan Pendaftaran'),
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed

    if (!confirm) return; // If user cancels, do nothing

    try {
       final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
       final snapshot = await userRef.get();

       if (snapshot.exists) {
         final data = Map<String, dynamic>.from(snapshot.value as Map);
         List<dynamic> registeredEvents = List<dynamic>.from(data['registeredEvents'] ?? []);
         final eventKey = widget.eventKey!;

         if (registeredEvents.contains(eventKey)) {
            registeredEvents.remove(eventKey);
            await userRef.update({'registeredEvents': registeredEvents});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pendaftaran event berhasil dibatalkan!')),
            );
             setState(() { _isRegistered = false; }); // Update state on success
         } else {
             // Not registered, perhaps show a message or do nothing
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda tidak terdaftar di event ini.')),
            );
         }
       } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data user tidak ditemukan.')),
          );
       }

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan pendaftaran event: $e')),
      );
       print('Error cancelling registration: $e');
    }
  }
}

// Formatter ribuan
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll('.', '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    final int value = int.parse(newText);
    final String formatted = _formatNumber(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      int position = str.length - i;
      buffer.write(str[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }
    final result = buffer.toString();
    return result.endsWith('.') ? result.substring(0, result.length - 1) : result;
  }
}

// Widget terpisah untuk section Event Paling Banyak Di Like
class MostLikedEventsSection extends StatefulWidget {
  const MostLikedEventsSection({Key? key}) : super(key: key);

  @override
  _MostLikedEventsSectionState createState() => _MostLikedEventsSectionState();
}

class _MostLikedEventsSectionState extends State<MostLikedEventsSection> {
  // Replicated helper function for section title (can be refactored if needed)
   Widget _sectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: () {
            // TODO: Implement navigation to All Events filtered by likes
            // This might require passing context or a navigation callback
             print('Lihat Semua Most Liked'); // Placeholder
          },
          child: const Text('Lihat Semuanya', style: TextStyle(color: Color(0xFF2D5BFF))),
        ),
      ],
    );
  }

  // Replicated helper function for event list (partially)
  // Only the sorting logic for 'likes' is needed here.
  Widget _eventListByLikes() {
    return const EventList(
      sortBy: 'likes',
      isFullWidth: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Paling Banyak Di Like'),
        const SizedBox(height: 8),
        _eventListByLikes(),
        const SizedBox(height: 24), // Add bottom spacing
      ],
    );
  }
}

// Update ProfilePage to be a StatefulWidget and fetch/display user data
class ProfilePage extends StatefulWidget {
  // Add an optional userId parameter
  final String? userId;
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  int _totalLikes = 0;
  bool _isLoading = true;
  int _selectedProfileTab = 0;
  String? _currentUserId; // To store the ID of the user whose profile is being viewed

  @override
  void initState() {
    super.initState();
    // Determine whose profile to load
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid; // Use userId if provided, otherwise use current user's uid
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_currentUserId == null) {
      // Handle not logged in state or no user ID provided
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // Fetch user data based on _currentUserId
      final userRef = FirebaseDatabase.instance.ref('user').child(_currentUserId!);
      final userSnapshot = await userRef.get();
      if (userSnapshot.exists) {
        _userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      }

      // Fetch and calculate total likes for user's events
      final eventsRef = FirebaseDatabase.instance.ref('item');
      final eventsSnapshot = await eventsRef.get();

      if (eventsSnapshot.exists) {
        final eventsData = Map<String, dynamic>.from(eventsSnapshot.value as Map);
        int likes = 0;
        eventsData.forEach((key, value) {
          // Calculate likes for events uploaded by _currentUserId
          if (value['uploaderUid'] == _currentUserId) {
            likes += (value['likes'] ?? 0) as int;
          }
        });
        _totalLikes = likes;
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading profile data: $e'); // Log error
      setState(() {
        _isLoading = false;
        // Optionally show an error message to the user
      });
    }
  }

  String _formatJoinDate(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return '${date.day} ${_bulan(date.month)} ${date.year}';
  }

  // This method now builds the full scrollable content of the page body
  Widget _buildFullProfileBody() {
     if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return const Center(child: Text('Gagal memuat data user.'));
    }

    final String status = _userData!['status'] ?? '';
    final String username = _userData!['username'] ?? _userData!['nama_organisasi'] ?? 'User';
    final String photoUrl = _userData!['photoUrl'] ?? 'https://via.placeholder.com/150';
    final String fakultas = _userData!['fakultas'] ?? '';
    final String jurusan = _userData!['jurusan'] ?? '';
    final String joinDate = _formatJoinDate(_userData!['createdAt']);
    final String affiliation = _userData!['organisasi'] ?? '';

    // Define tab labels based on user status
    final List<String> tabLabels = status == 'student'
        ? ['Jadwal', 'Disukai']
        : ['Kegiatan Saya', 'Like'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: GestureDetector(
            onTap: _changeProfileImage,
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _userData!["photoUrl"] != null && _userData!["photoUrl"].toString().isNotEmpty && !_userData!["photoUrl"].toString().startsWith('http')
                  ? MemoryImage(base64Decode(_userData!["photoUrl"]))
                  : NetworkImage(photoUrl) as ImageProvider,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (status.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'student' ? Colors.blue.shade200 : Colors.orange.shade200, // Different color based on status
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Akun ${status.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: status == 'student' ? Colors.blue.shade900 : Colors.orange.shade900, // Different color based on status
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Jumlah Like $_totalLikes',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        if (affiliation.isNotEmpty)
          Text(
            affiliation,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                username,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit',
              onPressed: () => _showEditNameDialog(username, status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (fakultas.isNotEmpty || jurusan.isNotEmpty)
          Text(
            '${fakultas}' + (fakultas.isNotEmpty && jurusan.isNotEmpty ? ' - ' : '') + '${jurusan}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        Text(
          'Tanggal bergabung: ${joinDate}',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        // Tab selection UI
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Use _buildTab and potentially add calendar icon here
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Center content in the expanded area
                  children: [
                    _buildTab(tabLabels[0], 0), // Jadwal or Kegiatan Saya tab button
                    if (status == 'student' && _selectedProfileTab == 0) // Add calendar icon only for student 'Jadwal' tab
                      IconButton(
                        icon: const Icon(Icons.calendar_today_rounded, size: 24), // Smaller icon for tab row
                        color: const Color(0xFF2D5BFF), // Icon color
                         padding: EdgeInsets.zero, // Remove default padding
                         constraints: const BoxConstraints(), // Remove default constraints
                        onPressed: () {
                          // Navigate to Calendar Page, passing registered events keys
                          final List<String> registeredEventKeys = (_userData?['registeredEvents'] as List<dynamic>? ?? [])
                              .map((key) => key.toString()).toList(); // Ensure keys are strings

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CalendarPage(registeredEventKeys: registeredEventKeys),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              _buildTab(tabLabels[1], 1), // Like or Disukai tab button
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Content based on selected tab
        // Removed the Row wrapper as calendar icon is now within the tab UI
        _buildTabContent(status), // Pass status to _buildTabContent
      ],
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedProfileTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProfileTab = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFF6CB6FF),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Update _buildTabContent to handle different tabs based on user status
  Widget _buildTabContent(String userStatus) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login untuk melihat event.'));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('item').onValue, // Stream all events
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('Belum ada event.'));
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        var items = data.entries.toList();

        List<MapEntry<String, dynamic>> filteredItems = [];
        String emptyMessage = '';

        if (userStatus == 'student') {
          if (_selectedProfileTab == 0) { // Jadwal
            final List<dynamic> registeredEvents = _userData?['registeredEvents'] ?? [];
            filteredItems = items.where((e) => registeredEvents.contains(e.key)).toList();
            emptyMessage = 'Anda belum mendaftar event apapun.';
          } else { // Disukai (Same as Like for Ormawa)
             filteredItems = items.where((e) => 
                (e.value['likedBy'] as List<dynamic>?)?.contains(user.uid) ?? false).toList();
            emptyMessage = 'Anda belum menyukai event apapun.';
          }
        } else { // Ormawa
          if (_selectedProfileTab == 0) { // Kegiatan Saya
            filteredItems = items.where((e) => e.value['uploaderUid'] == user.uid).toList();
            emptyMessage = 'Anda belum memposting event.';
          } else { // Like
             filteredItems = items.where((e) => 
                (e.value['likedBy'] as List<dynamic>?)?.contains(user.uid) ?? false).toList();
            emptyMessage = 'Anda belum menyukai event apapun.';
          }
        }
        
        if (filteredItems.isEmpty) {
          return Center(
            child: Text(emptyMessage),
          );
        }

        // Use ListView.separated with ProfileEventListItem for a simple list view
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical padding
          itemCount: filteredItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8), // Smaller separator for list items
          itemBuilder: (context, idx) {
            final event = filteredItems[idx].value;
            final eventKey = filteredItems[idx].key;
            return ProfileEventListItem(
              key: ValueKey(eventKey),
              event: event,
              eventKey: eventKey,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Ya, Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_logged_in', false);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print('Error during logout: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal logout: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
         child: SingleChildScrollView( 
           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
           child: _buildFullProfileBody(),
         ),
      ),
    );
  }

  // Tambahkan pada _ProfilePageState
  void _showEditNameDialog(String currentName, String userStatus) async {
    final controller = TextEditingController(text: currentName);
    final isStudent = userStatus == 'student';
    final label = isStudent ? 'Username' : 'Nama Organisasi';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userData == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Masukkan $label baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
              await userRef.update(isStudent ? {'username': newName} : {'nama_organisasi': newName});
              setState(() {
                if (isStudent) {
                  _userData!['username'] = newName;
                  // update username lokal jika ada
                  if (_userData!['username'] != null) _userData!['username'] = newName;
                } else {
                  _userData!['nama_organisasi'] = newName;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label berhasil diubah!')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Tambahkan pada _ProfilePageState
  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userData == null) return;
      final userRef = FirebaseDatabase.instance.ref('user').child(user.uid);
      await userRef.update({'photoUrl': base64Image});
      setState(() {
        _userData!['photoUrl'] = base64Image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diubah!')),
      );
    }
  }
}

// New widget for simplified event list item in Profile Page
class ProfileEventListItem extends StatelessWidget {
  final Map event;
  final String? eventKey;

  const ProfileEventListItem({
    Key? key,
    required this.event,
    this.eventKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? waktuMulai = event['waktuMulai'];
    final String? waktuSelesai = event['waktuSelesai'];
    String waktuDisplay = '-';
    if (waktuMulai != null && waktuMulai.isNotEmpty && waktuSelesai != null && waktuSelesai.isNotEmpty) {
      final String formattedStart = _formatTanggal(waktuMulai);
      final String formattedEnd = _formatTanggal(waktuSelesai);
      if (formattedStart == formattedEnd) {
        waktuDisplay = formattedStart;
      } else {
        waktuDisplay = '${formattedStart} - ${formattedEnd}';
      }
    }

    final int likesCount = event['likes'] ?? 0;
    final imageUrl = event['imageUrl'];

    Widget imageWidget;
    // Define a small size for the thumbnail
    const double thumbnailSize = 60.0;

    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      // Base64 image
      try {
        imageWidget = Image.memory(
          base64Decode(imageUrl),
          width: thumbnailSize,
          height: thumbnailSize,
          fit: BoxFit.cover,
        );
      } catch (e) {
        // Fallback if base64 decoding fails
        imageWidget = Image.network(
          _defaultImage, // Use default image on error
          width: thumbnailSize,
          height: thumbnailSize,
          fit: BoxFit.cover,
        );
        print('Error decoding base64 image in ProfileEventListItem: $e');
      }
    } else {
      // Network image or default image
      imageWidget = Image.network(
        (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : _defaultImage,
        width: thumbnailSize,
        height: thumbnailSize,
        fit: BoxFit.cover,
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailEventPage(event: event, eventKey: eventKey),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Small Image
            ClipRRect(
               borderRadius: BorderRadius.circular(4), // Slightly rounded corners for image
               child: SizedBox(
                width: thumbnailSize,
                height: thumbnailSize,
                child: imageWidget,
               ),
            ),
            const SizedBox(width: 12), // Spacing between image and text
            // Event Title and Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['nama'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          waktuDisplay,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Like Count
            Row(
              children: [
                 const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                 const SizedBox(width: 4),
                 Text(
                   '$likesCount',
                   style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// New CalendarPage widget
class CalendarPage extends StatefulWidget {
  final List<String> registeredEventKeys; // Receive list of registered event keys

  const CalendarPage({Key? key, required this.registeredEventKeys}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoadingEvents = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _fetchRegisteredEvents();
  }

  Future<void> _fetchRegisteredEvents() async {
    if (widget.registeredEventKeys.isEmpty) {
      setState(() { _isLoadingEvents = false; });
      return;
    }

    try {
      final eventsRef = FirebaseDatabase.instance.ref('item');
      final snapshot = await eventsRef.get();

      if (snapshot.exists) {
        final eventsData = Map<String, dynamic>.from(snapshot.value as Map);
        
        final registeredEventsFullData = eventsData.entries
            .where((entry) => widget.registeredEventKeys.contains(entry.key))
            .map((entry) {
              final eventData = Map<String, dynamic>.from(entry.value as Map);
              eventData['key'] = entry.key;
              return eventData;
            })
            .toList();
        
        final Map<DateTime, List<Map<String, dynamic>>> organizedEvents = {};
        for (var event in registeredEventsFullData) {
          final String? waktuMulai = event['waktuMulai'];
          final String? waktuSelesai = event['waktuSelesai'];

          if (waktuMulai != null && waktuMulai.isNotEmpty && waktuSelesai != null && waktuSelesai.isNotEmpty) {
            try {
              final DateTime startDate = DateTime.parse(waktuMulai).toLocal();
              final DateTime endDate = DateTime.parse(waktuSelesai).toLocal();
              
              // Iterate through the date range and add the event to each day
              for (DateTime d = DateTime(startDate.year, startDate.month, startDate.day);
                   d.isBefore(DateTime(endDate.year, endDate.month, endDate.day).add(const Duration(days: 1)));
                   d = d.add(const Duration(days: 1)))
              {
                final DateTime normalizedDate = DateTime(d.year, d.month, d.day);
                if (!organizedEvents.containsKey(normalizedDate)) {
                  organizedEvents[normalizedDate] = [];
                }
                organizedEvents[normalizedDate]!.add(event);
              }
            } catch (e) {
              print('Error parsing date for event ${event['key']}: $e');
              // Handle invalid date format if necessary
            }
          }
        }

        setState(() {
          _events = organizedEvents;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print('Error fetching registered events: $e');
      setState(() { _isLoadingEvents = false; });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Jadwal Kegiatan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoadingEvents 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFF6CB6FF),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF2D5BFF),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  eventLoader: _getEventsForDay,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ada event',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: _getEventsForDay(_selectedDay).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = _getEventsForDay(_selectedDay)[index];
                      return ProfileEventListItem(
                        event: event,
                        eventKey: event['key'],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class DetailProfilePage extends StatefulWidget {
  final String uploaderUid;
  const DetailProfilePage({Key? key, required this.uploaderUid}) : super(key: key);

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> {
  int _totalLikes = 0;
  bool _isLoading = true;
  int _selectedProfileTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      // Fetch and calculate total likes for user's events
      final eventsRef = FirebaseDatabase.instance.ref('item');
      final eventsSnapshot = await eventsRef.get();

      if (eventsSnapshot.exists) {
        final eventsData = Map<String, dynamic>.from(eventsSnapshot.value as Map);
        int likes = 0;
        eventsData.forEach((key, value) {
          // Calculate likes for events uploaded by uploaderUid
          if (value['uploaderUid'] == widget.uploaderUid) {
            likes += (value['likes'] ?? 0) as int;
          }
        });
        setState(() {
          _totalLikes = likes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatJoinDate(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return '${date.day} ${_bulan(date.month)} ${date.year}';
  }

  Widget _buildFullProfileBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('user').child(widget.uploaderUid).onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('Gagal memuat data user.'));
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final String status = data['status'] ?? '';
        final String username = data['username'] ?? data['nama_organisasi'] ?? 'User';
        final String photoUrl = data['photoUrl'] ?? 'https://via.placeholder.com/150';
        final String fakultas = data['fakultas'] ?? '';
        final String jurusan = data['jurusan'] ?? '';
        final String joinDate = _formatJoinDate(data['createdAt']);
        final String affiliation = data['organisasi'] ?? '';

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: photoUrl.isNotEmpty && !photoUrl.startsWith('http')
                    ? MemoryImage(base64Decode(photoUrl))
                    : NetworkImage(photoUrl) as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            if (status.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'student' ? Colors.blue.shade200 : Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Akun ${status.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: status == 'student' ? Colors.blue.shade900 : Colors.orange.shade900,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Jumlah Like $_totalLikes',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            if (affiliation.isNotEmpty)
              Text(
                affiliation,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            const SizedBox(height: 4),
            Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (fakultas.isNotEmpty || jurusan.isNotEmpty)
              Text(
                '${fakultas}' + (fakultas.isNotEmpty && jurusan.isNotEmpty ? ' - ' : '') + '${jurusan}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Text(
              'Tanggal bergabung: ${joinDate}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            // Langsung tampilkan daftar event yang diupload oleh akun ini
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('item').onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('Belum ada event.'));
                }
                final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                var items = data.entries.where((e) => e.value['uploaderUid'] == widget.uploaderUid).toList();
                if (items.isEmpty) {
                  return const Center(child: Text('Belum memposting event.'));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final event = items[idx].value;
                    final eventKey = items[idx].key;
                    return ProfileEventListItem(
                      key: ValueKey(eventKey),
                      event: event,
                      eventKey: eventKey,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6CB6FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: _buildFullProfileBody(),
        ),
      ),
    );
  }
}
