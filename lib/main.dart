// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Meskipun provider utama di app.dart, import ini mungkin masih berguna untuk SimpleBlocObserver
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/app.dart'; // Impor widget ChatApp dari app.dart
import 'package:chat_app/core/di/service_locator.dart' as di; // Alias 'di' untuk service locator

Future<void> main() async {
  // Pastikan semua binding Flutter sudah siap sebelum menjalankan kode asinkron.
  WidgetsFlutterBinding.ensureInitialized();

  // Muat environment variables dari file .env (misalnya untuk Supabase URL dan Key).
  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase.
  // Pastikan SUPABASE_URL dan SUPABASE_ANON_KEY ada di file .env Anda.
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  } catch (e) {
    // Tangani error jika variabel env tidak ada atau inisialisasi gagal
    // print("Error inisialisasi Supabase: $e");
    // Anda mungkin ingin menampilkan pesan error atau keluar dari aplikasi.
    // Untuk sekarang, kita biarkan berlanjut, tapi di produksi ini perlu penanganan.
  }


  // Inisialisasi dependency injection (GetIt).
  await di.init(); // Panggil fungsi init dari service_locator.dart

  // Jalankan aplikasi utama.
  runApp(const ChatApp()); // Jalankan widget ChatApp dari app.dart
}