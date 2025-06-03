import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class EditEventPage extends StatefulWidget {
  final Map event;
  final String eventKey;
  const EditEventPage({Key? key, required this.event, required this.eventKey}) : super(key: key);

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _hargaController;
  late TextEditingController _tingkatLainController;
  late TextEditingController _partisipanController;
  DateTimeRange? _selectedDateRange;
  String? _selectedCategory;
  bool _isLoading = false;
  File? _selectedImage;
  String? _base64Image;
  bool _isPaid = false;
  String? _selectedTingkat;

  final List<String> _categories = [
    'Lomba', 'Recruitment', 'Seminar', 'Workshop', 'Konser', 'Pameran', 'Kegiatan Mahasiswa', 'Lainnya'
  ];
  final List<String> _tingkatList = [
    'Internasional', 'Nasional', 'Lembaga', 'Fakultas', 'Jurusan', 'Lain-lain'
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _namaController = TextEditingController(text: event['nama'] ?? '');
    _deskripsiController = TextEditingController(text: event['deskripsi'] ?? '');
    _hargaController = TextEditingController(text: event['harga'] ?? '');
    _tingkatLainController = TextEditingController(text: event['tingkat'] ?? '');
    _partisipanController = TextEditingController(text: event['partisipan'] ?? '');
    _selectedCategory = event['kategori'];
    _isPaid = event['isPaid'] == true || event['isPaid'] == 'true';
    _selectedTingkat = _tingkatList.contains(event['tingkat']) ? event['tingkat'] : (_tingkatList.contains('Lain-lain') ? 'Lain-lain' : null);
    if (_selectedTingkat == 'Lain-lain') {
      _tingkatLainController.text = event['tingkat'] ?? '';
    }
    if (event['waktuMulai'] != null && event['waktuSelesai'] != null) {
      _selectedDateRange = DateTimeRange(
        start: DateTime.tryParse(event['waktuMulai']) ?? DateTime.now(),
        end: DateTime.tryParse(event['waktuSelesai']) ?? DateTime.now(),
      );
    }
    _base64Image = event['imageUrl'];
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
    }
  }

  Future<void> _updateEvent() async {
    setState(() { _isLoading = true; });
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
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('item').child(widget.eventKey);
      await ref.update({
        'nama': _namaController.text,
        'waktuMulai': _selectedDateRange!.start.toIso8601String(),
        'waktuSelesai': _selectedDateRange!.end.toIso8601String(),
        'kategori': _selectedCategory ?? '',
        'deskripsi': _deskripsiController.text,
        'imageUrl': _base64Image ?? '',
        'isPaid': _isPaid,
        'harga': _isPaid ? _unformatHarga(_hargaController.text) : null,
        'tingkat': _selectedTingkat == 'Lain-lain' ? _tingkatLainController.text : _selectedTingkat,
        'partisipan': _partisipanController.text,
      });
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event berhasil diupdate!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali dan trigger refresh
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update event: $e'), backgroundColor: Colors.redAccent),
      );
    }
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

  String _formatTanggal(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    const bulan = [ '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des' ];
    return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month]} ${date.year}';
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
        title: const Text('Edit Event', style: TextStyle(color: Colors.white)),
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
                  child: _base64Image != null && _base64Image!.isNotEmpty
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
                  'Klik gambar untuk mengubah foto',
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
                _buildTingkatDropdown(),
                if (_selectedTingkat == 'Lain-lain')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: _buildInput(_tingkatLainController, 'Masukkan tingkat event'),
                  ),
                const SizedBox(height: 16),
                _buildInput(_partisipanController, 'Partisipan (misal: Mahasiswa FTK Semester 2-6)'),
                const SizedBox(height: 16),
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
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateEvent,
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
                            'Simpan',
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
} 