import 'package:flutter/material.dart';

import '../models/towing_delivery.dart';
import '../models/towing_schedule.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import 'delivery_detail_screen.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({super.key, required this.scheduleId});

  final int scheduleId;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  TowingSchedule? _schedule;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule({bool showLoader = true}) async {
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
      final schedule = await _apiService.fetchScheduleDetail(widget.scheduleId);
      if (!mounted) {
        return;
      }

      setState(() {
        _schedule = schedule;
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

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Jadwal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadSchedule(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadSchedule(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _DetailMessageCard(
                title: 'Detail jadwal belum tersedia',
                description: _errorMessage!,
                actionLabel: 'Coba Lagi',
                onPressed: _loadSchedule,
              )
            else if (schedule == null)
              const _DetailMessageCard(
                title: 'Jadwal tidak ditemukan',
                description: 'Data jadwal belum tersedia untuk driver ini.',
              )
            else ...[
              _buildHeaderCard(schedule),
              const SizedBox(height: 16),
              Text(
                'Daftar Unit',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (schedule.deliveries.isEmpty)
                const _DetailMessageCard(
                  title: 'Belum ada unit pada jadwal ini',
                  description:
                      'Pastikan backend mengirim detail delivery di endpoint detail schedule.',
                )
              else
                ...schedule.deliveries.map(_buildDeliveryCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(TowingSchedule schedule) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF122C34), Color(0xFF0F4C5C)],
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
                  'Surat Jalan ${schedule.suratJalanNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(status: schedule.status),
            ],
          ),
          const SizedBox(height: 18),
          _InfoLine(
            icon: Icons.event_rounded,
            label: 'Tanggal Jadwal',
            value: formatDate(schedule.scheduleDate),
            light: true,
          ),
          _InfoLine(
            icon: Icons.local_shipping_rounded,
            label: 'Truck',
            value: schedule.truckLabel,
            light: true,
          ),
          _InfoLine(
            icon: Icons.badge_rounded,
            label: 'Driver',
            value: schedule.driverName,
            light: true,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: schedule.progressValue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0x33FFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF4B942)),
          ),
          const SizedBox(height: 10),
          Text(
            '${schedule.completedDeliveryCount}/${schedule.deliveryCount} unit selesai',
            style: const TextStyle(
              color: Color(0xFFD6E5EB),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(TowingDelivery delivery) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DeliveryDetailScreen(deliveryId: delivery.id),
              ),
            );
            if (!mounted) {
              return;
            }

            await _loadSchedule(showLoader: false);
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusBadge(status: delivery.deliveryStatus),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.route_rounded,
                  label: 'Rute',
                  value: delivery.routeLabel,
                ),
                _InfoLine(
                  icon: Icons.schedule_rounded,
                  label: 'Pickup',
                  value: formatDateTime(delivery.pickupDateTime),
                ),
                _InfoLine(
                  icon: Icons.camera_alt_rounded,
                  label: 'Foto Wajib',
                  value:
                      '${delivery.uploadedRequiredPhotoCount}/${delivery.requiredPhotos.length} lengkap',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final labelColor = light
        ? const Color(0xFFD6E5EB)
        : const Color(0xFF5B6776);
    final valueColor = light ? Colors.white : const Color(0xFF17212B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: labelColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
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

class _DetailMessageCard extends StatelessWidget {
  const _DetailMessageCard({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onPressed,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
