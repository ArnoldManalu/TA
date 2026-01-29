import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class UploadFrame extends StatelessWidget {
  final File? imageFile;
  final VoidCallback? onClear;

  const UploadFrame({super.key, this.imageFile, this.onClear});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface.withValues(alpha: 0.95),
              AppColors.background.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageFile == null
            ? _EmptyState()
            : _ImagePreview(imageFile: imageFile!, onClear: onClear),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_back,
            color: AppColors.primary.withValues(alpha: 0.95),
            size: 52,
          ),
          const SizedBox(height: 12),
          Text(
            'Pilih Gambar',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fokuskan lensa mata, hindari blur',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File imageFile;
  final VoidCallback? onClear;

  const _ImagePreview({required this.imageFile, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'Gagal memuat gambar',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClear,
              tooltip: 'Hapus gambar',
            ),
          ),
        ),
      ],
    );
  }
}
