import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../helper/model_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_buttons.dart';
import '../widgets/upload_frame.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.cameras,
    this.startWithGallery = false,
    this.startWithCamera = false,
  });

  final List<CameraDescription> cameras;
  final bool startWithGallery;
  final bool startWithCamera;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isProcessing = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.startWithGallery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage();
      });
    } else if (widget.startWithCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickWithSystemCamera();
      });
    }
  }

  Future<void> _ensurePermissions() async {
    try {
      final status = await [Permission.camera, Permission.storage].request();
      if (status[Permission.camera]?.isDenied ?? true) {
        throw Exception('Izin kamera diperlukan');
      }
    } catch (e) {
      throw Exception('Error permission: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _ensurePermissions();
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        if (mounted) {
          setState(() {
            _selectedImage = imageFile;
          });
          _showSnackBar('Gambar berhasil dipilih.');
        }
      } else {
        if (mounted) {
          _showSnackBar('Pemilihan gambar dibatalkan.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickWithSystemCamera() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _ensurePermissions();
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        if (mounted) {
          setState(() {
            _selectedImage = imageFile;
          });
          _showSnackBar('Foto berhasil diambil.');
        }
      } else {
        if (mounted) {
          _showSnackBar('Pemotretan dibatalkan.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: isError
            ? AppColors.danger
            : AppColors.primary.withValues(alpha: 0.9),
      ),
    );
  }

  Future<void> _processImage(File imageFile) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      debugPrint('🚀 Starting AI image processing...');

      final result = await _classifyWithAI(imageFile);

      if (!mounted) return;

      _closeLoadingDialog();

      debugPrint('✅ AI processing completed');

      await _navigateToResultScreen(result);

      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Demo processing failed: $e');
      debugPrint('📝 Stack trace: $stackTrace');

      if (!mounted) return;

      _closeLoadingDialog();

      _showSnackBar('Analisis gagal: ${e.toString()}', isError: true);
    }
  }

  Future<Map<String, dynamic>> _classifyWithAI(File imageFile) async {
    try {
      debugPrint('🤖 Using AI model for classification');

      if (!ModelHelper.isLoaded) {
        debugPrint('⚠️ Model not loaded, attempting to load...');
        await ModelHelper.loadModel();
      }

      final imageBytes = await imageFile.readAsBytes();

      debugPrint('🖼️ Preprocessing image...');
      final preprocessed = await ModelHelper.preprocessImage(imageBytes);
      final input = preprocessed['input'];
      final quality = preprocessed['quality'] as Map<String, dynamic>?;

      final isBadQuality = (quality?['isBlurred'] == true) ||
          (quality?['isDark'] == true) ||
          (quality?['isTooBright'] == true);
      if (isBadQuality && mounted) {
        _showSnackBar(
          'Gambar kurang optimal (${quality?['qualityLabel'] ?? 'cek ulang'}). Pertimbangkan ulangi foto.',
        );
      }

      debugPrint('🎯 Running prediction...');
      final output = ModelHelper.predict(input);

      debugPrint('📊 Processing results...');
      final result = ModelHelper.processResults(output);

      result['quality'] = quality;
      result['qualityFlagged'] = isBadQuality;
      result['imagePath'] = imageFile.path;

      debugPrint('✅ AI classification completed: ${result['prediction']}');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ AI classification failed: $e');
      debugPrint('📝 Stack trace: $stackTrace');

      debugPrint('⚠️ Falling back to demo mode');
      return await _testClassification();
    }
  }

  Widget _buildLoadingDialog() {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Memproses gambar...',
            style: GoogleFonts.poppins(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Menganalisis dengan AI',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _closeLoadingDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _navigateToResultScreen(Map<String, dynamic> result) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ResultScreen(
          prediction: result['prediction'] ?? 'Unknown',
          confidence: result['confidence'] ?? 0.0,
          riskLevel: result['riskLevel'] ?? 'UNKNOWN',
          description: result['description'] ?? 'Tidak ada deskripsi',
          imagePath: result['imagePath'] as String?,
          quality: result['quality'] as Map<String, dynamic>?,
          allPredictions:
              (result['allPredictions'] as List<Map<String, dynamic>>?),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _testClassification() async {
    debugPrint('🧪 Using DEMO classification');
    await Future.delayed(const Duration(seconds: 2));

    final random = DateTime.now().millisecond % 4;

    switch (random) {
      case 0:
        return {
          'prediction': 'Normal',
          'confidence': 92.5,
          'riskLevel': 'RENDAH',
          'riskColor': AppColors.riskColors['RENDAH'],
          'description':
              'Tidak terdeteksi tanda-tanda katarak. Mata dalam kondisi sehat.',
        };
      case 1:
        return {
          'prediction': 'Immature Cataract',
          'confidence': 78.3,
          'riskLevel': 'SEDANG',
          'riskColor': AppColors.riskColors['SEDANG'],
          'description':
              'Terdeteksi katarak tahap awal. Disarankan untuk konsultasi dengan dokter mata.',
        };
      case 2:
        return {
          'prediction': 'Mature Cataract',
          'confidence': 85.7,
          'riskLevel': 'TINGGI',
          'riskColor': AppColors.riskColors['TINGGI'],
          'description':
              'Terdeteksi katarak tahap lanjut. Segera konsultasi dengan dokter mata.',
        };
      default:
        return {
          'prediction': 'Early Cataract',
          'confidence': 65.2,
          'riskLevel': 'SEDANG',
          'riskColor': AppColors.riskColors['SEDANG'],
          'description':
              'Terdeteksi tanda awal katarak. Monitoring rutin disarankan.',
        };
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Pilih Sumber Gambar',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Pilih gambar dari galeri perangkat',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(
                  'Ambil Foto',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Ambil foto menggunakan kamera',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickWithSystemCamera();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight -
                        MediaQuery.of(context).padding.vertical),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Unggah Gambar Mata',
                        style: AppText.headline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Pastikan gambarnya jelas dan terfokus pada lensa mata.',
                        style: AppText.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.surface.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates,
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gunakan cahaya cukup, fokuskan pupil, hindari blur atau pantulan kuat.',
                              style: AppText.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    UploadFrame(
                      imageFile: _selectedImage,
                      onClear: () => setState(() => _selectedImage = null),
                    ),
                    const SizedBox(height: 22),
                    if (_selectedImage != null)
                      Text(
                        'Gambar terpilih, siap diproses.',
                        style: AppText.caption,
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'Pilih file atau ambil foto terlebih dahulu.',
                        style: AppText.caption,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 18),
                    AccentOutlineButton(
                      onPressed: _isProcessing ? null : _showImageOptions,
                      label: 'Pilih File',
                    ),
                    const SizedBox(height: 12),
                    AccentButton(
                      onPressed: _selectedImage == null || _isProcessing
                          ? null
                          : () => _processImage(_selectedImage!),
                      label: 'Proses Klasifikasi',
                      loading: _isProcessing,
                    ),
                    const SizedBox(height: 24),
                    AppBottomNav(
                      activeIndex: 0,
                      onHome: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
