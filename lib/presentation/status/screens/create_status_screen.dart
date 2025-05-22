import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/presentation/status/blocs/status_bloc.dart';
import 'package:chat_app/core/utils/image_helper.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Dependensi: flutter_colorpicker

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textStatusController = TextEditingController();
  final TextEditingController _imageCaptionController = TextEditingController();
  File? _selectedImageFile;
  Color _selectedBackgroundColor = Colors.deepPurpleAccent; // Warna default untuk status teks
  final ImageHelper _imageHelper = sl<ImageHelper>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { // Untuk mengubah warna AppBar berdasarkan tab
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() { setState(() {});});
    _tabController.dispose();
    _textStatusController.dispose();
    _imageCaptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imageHelper.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImageFile = image;
      });
    }
  }

  void _postStatus() {
    final statusBloc = context.read<StatusBloc>();
    if (_tabController.index == 0) { // Tab Status Teks
      if (_textStatusController.text.trim().isNotEmpty) {
        // Konversi Color ke string hex RRGGBB
        final hexColor = '#${_selectedBackgroundColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
        statusBloc.add(PostTextStatus(
          textContent: _textStatusController.text.trim(),
          backgroundColor: hexColor,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status teks tidak boleh kosong.")));
      }
    } else { // Tab Status Gambar
      if (_selectedImageFile != null) {
        statusBloc.add(PostImageStatus(
          imageFile: _selectedImageFile!,
          caption: _imageCaptionController.text.trim().isNotEmpty ? _imageCaptionController.text.trim() : null,
        ));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan pilih gambar terlebih dahulu.")));
      }
    }
  }

  void _openColorPicker() {
    Color pickerColor = _selectedBackgroundColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih warna latar!'),
        content: SingleChildScrollView(
          child: ColorPicker( // Menggunakan ColorPicker dasar
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false, // Nonaktifkan alpha jika hanya ingin RRGGBB
            labelTypes: const [], // Sembunyikan label jika diinginkan
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('PILIH'),
            onPressed: () {
              setState(() => _selectedBackgroundColor = pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // StatusBloc diasumsikan disediakan oleh StatusFeedScreen atau lebih tinggi.
    // Jika layar ini bisa diakses langsung, Anda mungkin perlu provide StatusBloc di sini.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Status"),
        elevation: _tabController.index == 0 ? 0 : AppBarTheme.of(context).elevation ?? 4.0, // Hilangkan shadow jika tab teks
        backgroundColor: _tabController.index == 0 ? _selectedBackgroundColor : AppBarTheme.of(context).backgroundColor,
        foregroundColor: _tabController.index == 0 && _selectedBackgroundColor.computeLuminance() < 0.5
            ? Colors.white
            : AppBarTheme.of(context).foregroundColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _tabController.index == 0 && _selectedBackgroundColor.computeLuminance() < 0.5
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          labelColor: _tabController.index == 0 && _selectedBackgroundColor.computeLuminance() < 0.5
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          unselectedLabelColor: _tabController.index == 0 && _selectedBackgroundColor.computeLuminance() < 0.5
              ? Colors.white70
              : Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: "Teks"),
            Tab(icon: Icon(Icons.image_search_rounded), text: "Gambar"),
          ],
        ),
      ),
      body: BlocListener<StatusBloc, StatusState>(
        listener: (context, state) {
          if (state is StatusLoaded && state.successMessage != null && state.successMessage!.contains("posted")) {
             ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green));
            context.read<StatusBloc>().emit(state.copyWith(clearSuccessMessage: true));
            if (Navigator.canPop(context)) Navigator.pop(context, true); // Kembali dan beri sinyal sukses
          } else if (state is StatusError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Cegah swipe antar tab jika diinginkan
          children: [
            _buildTextStatusCreator(),
            _buildImageStatusCreator(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BlocBuilder<StatusBloc, StatusState>(
        builder: (context, state) {
          if (state is StatusPosting) {
            return FloatingActionButton(
              onPressed: null, // Nonaktifkan saat posting
              tooltip: "Posting...",
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            );
          }
          return FloatingActionButton.extended(
            onPressed: _postStatus,
            icon: const Icon(Icons.send_rounded),
            label: const Text("Posting Status"),
            tooltip: "Posting Status",
          );
        },
      ),
    );
  }

  Widget _buildTextStatusCreator() {
    final bool isDarkBackground = _selectedBackgroundColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black87;
    final Color hintColor = isDarkBackground ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: _openColorPicker, // Tap background untuk ganti warna
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _selectedBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0), // Padding lebih
        child: Center(
          child: TextField(
            controller: _textStatusController,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              color: textColor,
              fontWeight: FontWeight.bold,
              shadows: [
                 Shadow(
                    blurRadius: isDarkBackground ? 3.0 : 1.0,
                    color: isDarkBackground ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                    offset: const Offset(1, 1),
                ),
              ]
            ),
            maxLines: 7, // Batas maksimal baris
            minLines: 1,
            autofocus: true,
            cursorColor: textColor,
            decoration: InputDecoration(
              hintText: "Ketik status Anda...",
              border: InputBorder.none, // Hilangkan border
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ),
    );
  }

  Widget _buildImageStatusCreator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1.5)
                ),
                alignment: Alignment.center,
                child: _selectedImageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10.5),
                        child: Image.file(_selectedImageFile!, fit: BoxFit.contain)
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 70, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          Text("Ketuk untuk memilih gambar", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _imageCaptionController,
            decoration: InputDecoration(
              hintText: "Tambahkan keterangan (opsional)...",
              prefixIcon: const Icon(Icons.subtitles_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
           const SizedBox(height: 80), // Spasi untuk FAB
        ],
      ),
    );
  }
}