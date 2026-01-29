import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

class ResultScreen extends StatelessWidget {
  final String prediction;
  final double confidence;
  final String riskLevel;
  final String description;
  final String? imagePath;
  final Map<String, dynamic>? quality;
  final List<Map<String, dynamic>>? allPredictions;

  const ResultScreen({
    super.key,
    required this.prediction,
    required this.confidence,
    required this.riskLevel,
    required this.description,
    this.imagePath,
    this.quality,
    this.allPredictions,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.background;
    final surface = AppColors.surface;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;
    final normalizedRisk = riskLevel.trim().toUpperCase();
    final status = _statusLabel(prediction);
    final riskColor = AppColors.riskColors[status] ??
        AppColors.riskColors[normalizedRisk] ??
        AppColors.textSecondary;
    final riskPosition =
        _riskValue(status); // Use status to align with bar labels

    return Scaffold(
        backgroundColor: bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bg,
                AppColors.surface.withValues(alpha: 0.35),
                bg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hasil Analisis', style: AppText.title),
                      const Icon(Icons.shield_rounded,
                          color: AppColors.primary, size: 26),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (imagePath != null)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        image: DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.15),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                  if (imagePath != null) const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status,
                            style: AppText.headline.copyWith(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(prediction,
                            style: AppText.caption.copyWith(
                              color: textSecondary,
                              fontSize: 13,
                            )),
                        const SizedBox(height: 14),
                        _RiskBar(value: riskPosition, color: riskColor),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MetricTile(
                              label: 'Confidence',
                              value: '${confidence.toStringAsFixed(1)}%',
                              expand: true,
                            ),
                            const SizedBox(width: 12),
                            _MetricTile(
                              label: 'Risiko',
                              value: normalizedRisk,
                              color: riskColor,
                              expand: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecor.card(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ringkasan', style: AppText.headline),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            color: textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                        if (allPredictions != null &&
                            allPredictions!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Distribusi probabilitas',
                              style: AppText.caption
                                  .copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ...allPredictions!.map(
                            (p) {
                              final label = p['label']?.toString() ?? 'Unknown';
                              final conf =
                                  (p['confidence'] as num?)?.toDouble() ?? 0.0;
                              return _Bullet(
                                text: "$label: ${conf.toStringAsFixed(2)}%",
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _WarningBox(
                    text:
                        'Penting: ini alat bantu skrining, bukan pengganti konsultasi dokter.',
                  ),
                  const SizedBox(height: 18),
                  AccentOutlineButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Kembali',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                  const SizedBox(height: 14),
                  _BottomNav(
                    activeIndex: 0,
                    background: surface,
                    accent: AppColors.primary,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onHome: () => Navigator.popUntil(context, (r) => r.isFirst),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  String _statusLabel(String prediction) {
    final lower = prediction.toLowerCase().trim();

    // Prefer exact matches to avoid substring conflicts (e.g. "immature" contains "mature").
    if (lower == 'normal') return 'NORMAL';
    if (lower == 'immature') return 'IMMATURE';
    if (lower == 'mature') return 'MATURE';

    // Fallback to word-boundary checks for phrases like "stage: immature".
    bool hasWord(String word) => RegExp('\\b' + word + '\\b').hasMatch(lower);
    if (hasWord('normal')) return 'NORMAL';
    if (hasWord('immature')) return 'IMMATURE';
    if (hasWord('mature')) return 'MATURE';

    // Default to uppercasing the provided prediction.
    return prediction.toUpperCase();
  }

  double _riskValue(String status) {
    switch (status) {
      case 'RENDAH':
      case 'NORMAL':
        return 0.15; // Align with 'Normal' Text
      case 'SEDANG':
      case 'MODERATE':
      case 'MILD':
      case 'IMMATURE':
        return 0.50; // Align with 'Immature' Text
      case 'TINGGI':
      case 'SEVERE':
      case 'MATURE':
        return 0.85; // Align with 'Mature' Text
      default:
        return 0.50;
    }
  }
}

class _RiskBar extends StatelessWidget {
  final double value;
  final Color color;

  const _RiskBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Normal', style: AppText.caption),
            Text('Immature', style: AppText.caption),
            Text('Mature', style: AppText.caption),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface.withValues(alpha: 0.7),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clamped,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: color, // Solid color for clarity
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool expand;

  const _MetricTile(
      {required this.label,
      required this.value,
      this.color,
      this.expand = false});

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (color ?? AppColors.textSecondary).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.headline.copyWith(
              fontSize: 16,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    return expand ? Expanded(child: tile) : tile;
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  final String text;

  const _WarningBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int activeIndex;
  final Color background;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onHome;

  const _BottomNav({
    required this.activeIndex,
    required this.background,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: true,
            onTap: onHome,
            accent: accent,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color accent;
  final Color textSecondary;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.accent,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? accent : textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
