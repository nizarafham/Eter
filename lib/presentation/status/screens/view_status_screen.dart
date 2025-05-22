import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/models/status_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/status/blocs/status_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Dependensi: cached_network_image
import 'package:timeago/timeago.dart' as timeago; // Dependensi: timeago

// Widget untuk indikator progress di atas story
class StoryProgressIndicator extends AnimatedWidget {
  final int currentIndex;
  final int totalCount;
  final AnimationController controller;
  final VoidCallback onAnimationEnd; // Callback saat animasi selesai

  const StoryProgressIndicator({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    required this.controller,
    required this.onAnimationEnd,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    // Panggil onAnimationEnd setelah frame selesai jika animasi sudah completed
    if (controller.status == AnimationStatus.completed) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         onAnimationEnd();
       });
    }

    return Row(
      children: List.generate(totalCount, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              height: 3.0,
              decoration: BoxDecoration(
                // Warna bar yang sudah lewat atau bar saat ini vs bar yang akan datang
                color: index < currentIndex ? Colors.white : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: index == currentIndex // Hanya bar saat ini yang memiliki LinearProgressIndicator
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: controller.value,
                        backgroundColor: Colors.white.withOpacity(0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 3.0,
                      ),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class ViewStatusScreen extends StatefulWidget {
  final List<StatusModel> userStatuses; // Status diurutkan dari terlama ke terbaru
  final UserModel user;
  final int initialStatusIndex;

  const ViewStatusScreen({
    super.key,
    required this.userStatuses,
    required this.user,
    this.initialStatusIndex = 0,
  });

  @override
  State<ViewStatusScreen> createState() => _ViewStatusScreenState();
}

class _ViewStatusScreenState extends State<ViewStatusScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  final Duration _statusDisplayDuration = const Duration(seconds: 7); // Durasi setiap status

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialStatusIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(vsync: this, duration: _statusDisplayDuration);

    _startCurrentStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startCurrentStatus() {
    if (!mounted) return;
    _markCurrentStatusAsViewed();
    _animationController.stop();
    _animationController.reset();
    _animationController.forward();
  }

  void _markCurrentStatusAsViewed() {
    if (!mounted || _currentIndex >= widget.userStatuses.length) return;

    final currentStatus = widget.userStatuses[_currentIndex];
    final currentAuthUserId = context.read<AuthBloc>().state.user?.id;

    // Hanya tandai sebagai dilihat jika bukan status milik pengguna sendiri
    // dan pengguna saat ini belum melihatnya.
    if (currentAuthUserId != null &&
        currentStatus.userId != currentAuthUserId &&
        !currentStatus.viewedBy.contains(currentAuthUserId)) {
      context.read<StatusBloc>().add(MarkStatusAsViewed(statusId: currentStatus.id));
    }
  }

  void _onAnimationCompleted() {
    _nextStatus();
  }

  void _nextStatus() {
    if (!mounted) return;
    if (_currentIndex < widget.userStatuses.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      // _startCurrentStatus() akan dipanggil oleh _onPageChanged
    } else {
      Navigator.of(context).pop(); // Semua status telah dilihat
    }
  }

  void _previousStatus() {
    if (!mounted) return;
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      // _startCurrentStatus() akan dipanggil oleh _onPageChanged
    } else {
      // Jika di status pertama, restart animasi atau jangan lakukan apa-apa
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
    _startCurrentStatus();
  }

  void _pauseStatusAnimation() => _animationController.stop();
  void _resumeStatusAnimation() => _animationController.forward();

  Color _parseColor(String? hexColor) {
    hexColor = hexColor?.toUpperCase().replaceAll("#", "");
    if (hexColor == null || hexColor.length != 6) {
      return Colors.blueGrey.shade800; // Warna default gelap untuk kontras yang baik
    }
    try {
      return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blueGrey.shade800;
    }
  }

  void _handleDeleteStatus(String statusId) {
     showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text("Hapus Status"),
          content: const Text("Apakah Anda yakin ingin menghapus status ini secara permanen?"),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text("Batal")),
            TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  context.read<StatusBloc>().add(DeleteStatus(statusId: statusId));

                  // Setelah menghapus, logika navigasi atau update UI
                  if (widget.userStatuses.length == 1 || _currentIndex >= widget.userStatuses.length - 1) {
                      if(mounted) Navigator.of(context).pop(); // Keluar jika ini status terakhir/satu-satunya
                  } else {
                     // Jika ada status lain, coba pindah ke status berikutnya (atau sebelumnya jika ini yang terakhir)
                     // Perlu penanganan state yang lebih cermat di sini karena list akan berubah
                     // Untuk sementara, kita hanya pop. StatusFeedScreen akan refresh.
                      if(mounted) Navigator.of(context).pop();
                  }
                },
                child: Text("HAPUS", style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final currentAuthUserId = context.read<AuthBloc>().state.user?.id;
    final bool isMyStatus = widget.user.id == currentAuthUserId;

    if (widget.userStatuses.isEmpty) {
      // Seharusnya tidak terjadi jika navigasi benar, tapi sebagai fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text("Tidak ada status untuk ditampilkan.", style: TextStyle(color: Colors.white))));
    }
    final currentVisibleStatus = widget.userStatuses[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _pauseStatusAnimation(),
        onTapUp: (details) {
          _resumeStatusAnimation();
          final screenWidth = MediaQuery.of(context).size.width;
          // Area tap lebih besar untuk navigasi
          if (details.localPosition.dx < screenWidth * 0.33) {
            _previousStatus();
          } else if (details.localPosition.dx > screenWidth * 0.67) {
            _nextStatus();
          }
        },
        onLongPress: _pauseStatusAnimation,
        onLongPressUp: _resumeStatusAnimation,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.userStatuses.length,
              onPageChanged: _onPageChanged,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final status = widget.userStatuses[index];
                if (status.type == StatusType.image && status.mediaUrl != null) {
                  return InteractiveViewer(
                    panEnabled: false, // Biasanya false untuk story
                    minScale: 1.0,
                    maxScale: 3.0, // Batasi zoom
                    child: CachedNetworkImage(
                      imageUrl: status.mediaUrl!,
                      fit: BoxFit.contain,
                      progressIndicatorBuilder: (context, url, downloadProgress) =>
                          Center(child: CircularProgressIndicator(value: downloadProgress.progress, color: Colors.white60)),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 60)),
                    ),
                  );
                } else if (status.type == StatusType.text) {
                  return Container(
                    color: _parseColor(status.backgroundColor),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60), // Padding agar teks tidak mentok
                    child: Text(
                      status.textContent ?? "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _parseColor(status.backgroundColor).computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                        fontSize: 28, // Ukuran font bisa dinamis berdasarkan panjang teks
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.45), offset: const Offset(1.5,1.5))]
                      ),
                    ),
                  );
                }
                return const Center(child: Text("Format status tidak didukung", style: TextStyle(color: Colors.white)));
              },
            ),
            // Top bar (progress, user info, close button)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8.0,
              right: 8.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StoryProgressIndicator(
                    currentIndex: _currentIndex,
                    totalCount: widget.userStatuses.length,
                    controller: _animationController,
                    onAnimationEnd: _onAnimationCompleted,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(widget.user.avatarUrl!)
                            : null,
                        child: (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
                            ? Text(widget.user.username.isNotEmpty ? widget.user.username[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                        backgroundColor: Colors.grey.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(blurRadius: 2, color:Colors.black87)])),
                            if (_currentIndex < widget.userStatuses.length)
                              Text(
                                timeago.format(widget.userStatuses[_currentIndex].createdAt.toLocal()),
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5, shadows: const [Shadow(blurRadius: 1, color: Colors.black54)]),
                              ),
                          ],
                        ),
                      ),
                      // Tombol aksi hanya jika status milik pengguna saat ini
                       if (isMyStatus && _currentIndex < widget.userStatuses.length) ...[
                          IconButton(
                            icon: Icon(Icons.visibility_rounded, color: Colors.white.withOpacity(0.9)),
                            tooltip: "Dilihat oleh ${currentVisibleStatus.viewedBy.length}",
                            iconSize: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                               _pauseStatusAnimation();
                               // TODO: Tampilkan daftar viewer dalam bottom sheet atau dialog
                               showModalBottomSheet(
                                   context: context,
                                   backgroundColor: Colors.grey[900],
                                   builder: (bsCtx) => Container(
                                     padding: const EdgeInsets.all(16),
                                     height: MediaQuery.of(context).size.height * 0.4,
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text("${currentVisibleStatus.viewedBy.length} Dilihat", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                         const Divider(color: Colors.white30, height: 20),
                                         Expanded(
                                           child: currentVisibleStatus.viewedBy.isEmpty
                                            ? const Center(child: Text("Belum ada yang melihat.", style: TextStyle(color: Colors.white70)))
                                            : ListView.builder( // Anda perlu mengambil detail profil viewer
                                                itemCount: currentVisibleStatus.viewedBy.length,
                                                itemBuilder: (lCtx, i) => ListTile(
                                                  leading: const CircleAvatar(backgroundColor: Colors.white30, child: Icon(Icons.person_outline, color: Colors.white70)),
                                                  title: Text("User ID: ${currentVisibleStatus.viewedBy[i]}", style: const TextStyle(color: Colors.white)),
                                                  // Di aplikasi nyata, Anda akan mengambil UserModel berdasarkan ID ini
                                                )
                                              )
                                         )
                                       ],
                                     )
                                   )
                               ).then((_) => _resumeStatusAnimation());
                            },
                          ),
                         IconButton(
                            icon: Icon(Icons.delete_forever_rounded, color: Colors.white.withOpacity(0.9)),
                            tooltip: "Hapus Status",
                             iconSize: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _pauseStatusAnimation();
                              _handleDeleteStatus(currentVisibleStatus.id);
                            },
                          ),
                       ],
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.95)),
                        tooltip: "Tutup",
                        iconSize: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Caption untuk status gambar
             if (_currentIndex < widget.userStatuses.length &&
                currentVisibleStatus.type == StatusType.image &&
                currentVisibleStatus.textContent != null &&
                currentVisibleStatus.textContent!.isNotEmpty)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 15, // Pertimbangkan safe area
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    currentVisibleStatus.textContent!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
                    maxLines: 3, // Batasi jumlah baris caption
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}