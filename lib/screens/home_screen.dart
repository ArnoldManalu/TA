import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_buttons.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key, required this.cameras, required this.modelLoaded});

  final List<CameraDescription> cameras;
  final bool modelLoaded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surface.withValues(alpha: 0.4),
              AppColors.background,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deteksi Katarak', style: AppText.title),
                        const SizedBox(height: 6),
                        Text('AI screening cepat dan intuitif',
                            style: AppText.caption),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.surface.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: AppDecor.circleFrame(borderAlpha: 0.35),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.remove_red_eye,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Siap memindai',
                                style: AppText.headline.copyWith(fontSize: 18)),
                            const SizedBox(height: 6),
                            Text(
                              'Unggah foto mata, cek kualitas, lalu dapatkan skor risiko katarak.',
                              style: AppText.caption,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _TagChip(
                                  label: modelLoaded
                                      ? 'Model siap'
                                      : 'Model memuat',
                                  color: modelLoaded
                                      ? AppColors.secondary
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 15),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Aksi cepat', style: AppText.headline),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AccentButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                cameras: cameras,
                                startWithCamera: true,
                              ),
                            ),
                          );
                        },
                        label: 'Ambil Foto',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AccentOutlineButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                cameras: cameras,
                                startWithGallery: true,
                              ),
                            ),
                          );
                        },
                        label: 'Upload / Galeri',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecor.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tips hasil akurat', style: AppText.headline),
                          const Icon(Icons.tips_and_updates,
                              color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TipRow(text: 'Pastikan mata terfokus dan tidak blur'),
                      const SizedBox(height: 6),
                      _TipRow(text: 'Pencahayaan cukup, tanpa cahaya belakang'),
                      const SizedBox(height: 6),
                      _TipRow(
                          text: 'Isi frame dengan lensa mata, minim bayangan'),
                    ],
                  ),
                ),
                const Spacer(),
                AppBottomNav(
                  activeIndex: 0,
                  onHome: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.secondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.body,
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
