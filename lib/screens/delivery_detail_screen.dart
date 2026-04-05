import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/towing_delivery.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';

class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final int deliveryId;

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  TowingDelivery? _delivery;
  final Set<String> _uploadingTypes = <String>{};

  @override
  void initState() {
    super.initState();
    _loadDelivery();
  }

  Future<void> _loadDelivery({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      final delivery = await _apiService.fetchDeliveryDetail(widget.deliveryId);
      if (!mounted) {
        return;
      }

      setState(() {
        _delivery = delivery;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startDelivery() async {
    final delivery = _delivery;
    if (delivery == null) {
      return;
    }

    await _runAction(
      action: () => _apiService.startDelivery(delivery.id),
      successMessage: 'Pengiriman berhasil dimulai.',
    );
  }

  Future<void> _completeDelivery() async {
    final delivery = _delivery;
    if (delivery == null) {
      return;
    }

    if (!delivery.hasAllRequiredPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi dulu 3 foto wajib sebelum menyelesaikan report.',
          ),
        ),
      );
      return;
    }

    await _runAction(
      action: () => _apiService.completeDelivery(delivery.id),
      successMessage: 'Report pengiriman berhasil dikirim.',
    );
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await action();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _loadDelivery(showLoader: false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _captureRequiredPhoto(String photoType) async {
    final delivery = _delivery;
    if (delivery == null) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1800,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _uploadingTypes.add(photoType);
    });

    try {
      await _apiService.uploadDeliveryPhoto(
        deliveryId: delivery.id,
        photoType: photoType,
        file: pickedFile,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto berhasil diunggah.')));
      await _loadDelivery(showLoader: false);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingTypes.remove(photoType);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _delivery;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Delivery',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadDelivery(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: delivery == null || _isLoading
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (delivery.canStart) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _startDelivery,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Mulai Pengiriman'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting || delivery.isCompleted
                            ? null
                            : _completeDelivery,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C5C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded),
                        label: Text(
                          delivery.isCompleted
                              ? 'Pengiriman Sudah Selesai'
                              : delivery.hasAllRequiredPhotos
                              ? 'Selesaikan Pengiriman'
                              : 'Lengkapi 3 Foto Wajib',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: () => _loadDelivery(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _SectionCard(
                child: _MessageState(
                  title: 'Detail delivery belum tersedia',
                  description: _errorMessage!,
                  buttonLabel: 'Coba Lagi',
                  onPressed: _loadDelivery,
                ),
              )
            else if (delivery == null)
              const _SectionCard(
                child: _MessageState(
                  title: 'Delivery tidak ditemukan',
                  description:
                      'Data delivery belum tersedia di endpoint mobile.',
                ),
              )
            else ...[
              _buildSummaryCard(delivery),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'Informasi Unit'),
                    const SizedBox(height: 14),
                    _DetailLine(
                      icon: Icons.directions_car_filled_rounded,
                      label: 'Unit',
                      value: delivery.unitLabel,
                    ),
                    _DetailLine(
                      icon: Icons.route_rounded,
                      label: 'Rute',
                      value: delivery.routeLabel,
                    ),
                    _DetailLine(
                      icon: Icons.assignment_rounded,
                      label: 'Tujuan',
                      value: delivery.deliveryPurpose.isEmpty
                          ? '-'
                          : delivery.deliveryPurpose,
                    ),
                    _DetailLine(
                      icon: Icons.map_rounded,
                      label: 'Kategori Rute',
                      value: delivery.routeCategory.isEmpty
                          ? '-'
                          : delivery.routeCategory,
                    ),
                    _DetailLine(
                      icon: Icons.schedule_rounded,
                      label: 'Pickup',
                      value: formatDateTime(delivery.pickupDateTime),
                    ),
                    _DetailLine(
                      icon: Icons.task_alt_rounded,
                      label: 'Selesai Aktual',
                      value: formatDateTime(delivery.deliveryDateTime),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'Dokumentasi Wajib'),
                    const SizedBox(height: 6),
                    const Text(
                      'Driver wajib mengunggah 3 foto sebelum report pengiriman bisa diselesaikan.',
                      style: TextStyle(color: Color(0xFF5B6776), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ...delivery.requiredPhotos.map(
                      (photo) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PhotoRequirementCard(
                          photo: photo,
                          isUploading: _uploadingTypes.contains(photo.type),
                          onCapture: () => _captureRequiredPhoto(photo.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TowingDelivery delivery) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF1B6678)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  delivery.unitLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(status: delivery.deliveryStatus),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            delivery.routeLabel,
            style: const TextStyle(color: Color(0xFFD6E5EB), height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.camera_alt_rounded, color: Color(0xFFF4B942)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${delivery.uploadedRequiredPhotoCount}/${delivery.requiredPhotos.length} foto wajib sudah lengkap',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5B6776)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF5B6776),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoRequirementCard extends StatelessWidget {
  const _PhotoRequirementCard({
    required this.photo,
    required this.isUploading,
    required this.onCapture,
  });

  final DeliveryPhotoRequirement photo;
  final bool isUploading;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      photo.hasPhoto ? 'Sudah terunggah' : 'Belum ada foto',
                      style: TextStyle(
                        color: photo.hasPhoto
                            ? const Color(0xFF177245)
                            : const Color(0xFFB3261E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: isUploading ? null : onCapture,
                icon: isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        photo.hasPhoto
                            ? Icons.refresh_rounded
                            : Icons.camera_alt_rounded,
                      ),
                label: Text(photo.hasPhoto ? 'Ulangi' : 'Ambil Foto'),
              ),
            ],
          ),
          if (photo.hasPhoto) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  photo.url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE8EEF4),
                      alignment: Alignment.center,
                      child: const Text(
                        'Preview foto tidak bisa ditampilkan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF5B6776),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String description;
  final String? buttonLabel;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: Color(0xFF5B6776), height: 1.5),
        ),
        if (buttonLabel != null && onPressed != null) ...[
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel!)),
        ],
      ],
    );
  }
}
