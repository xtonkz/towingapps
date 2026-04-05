import 'package:flutter/material.dart';

import '../models/mobile_user.dart';
import '../models/towing_schedule.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/status_badge.dart';
import 'login_screen.dart';
import 'schedule_detail_screen.dart';

enum ScheduleFilter { today, all }

class ScheduleListScreen extends StatefulWidget {
  const ScheduleListScreen({super.key});

  @override
  State<ScheduleListScreen> createState() => _ScheduleListScreenState();
}

class _ScheduleListScreenState extends State<ScheduleListScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;
  MobileUser? _user;
  List<TowingSchedule> _schedules = const [];
  ScheduleFilter _filter = ScheduleFilter.today;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage({bool showLoader = true}) async {
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
      final user = await _apiService.me();
      final schedules = await _apiService.fetchSchedules(
        date: _filter == ScheduleFilter.today ? DateTime.now() : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _schedules = schedules;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('sesi login')) {
        await _apiService.clearToken();
        if (!mounted) {
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _apiService.logout();
      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Logout server gagal, tetapi sesi lokal sudah dibersihkan.',
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  int get _totalDeliveries =>
      _schedules.fold<int>(0, (sum, schedule) => sum + schedule.deliveryCount);

  int get _completedDeliveries => _schedules.fold<int>(
    0,
    (sum, schedule) => sum + schedule.completedDeliveryCount,
  );

  int get _activeSchedules =>
      _schedules.where((schedule) => !schedule.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jadwal Driver',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : () => _loadPage(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ErrorStateCard(message: _errorMessage!, onRetry: _loadPage)
            else if (_schedules.isEmpty)
              const _EmptyStateCard(
                title: 'Belum ada jadwal driver',
                description:
                    'Jadwal akan muncul di sini setelah backend mengirim penugasan ke akun driver Anda.',
              )
            else
              ..._schedules.map(_buildScheduleCard),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _user?.displayName ?? 'Driver';
    final identity = _user?.identityLabel ?? 'Akun driver aktif';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C5C), Color(0xFF1B6678)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $userName',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            identity,
            style: const TextStyle(color: Color(0xFFD6E5EB), height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Jadwal Aktif',
                  value: '$_activeSchedules',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Unit Selesai',
                  value: '$_completedDeliveries/$_totalDeliveries',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ChoiceChip(
          label: const Text('Jadwal Hari Ini'),
          selected: _filter == ScheduleFilter.today,
          onSelected: (_) {
            if (_filter == ScheduleFilter.today) {
              return;
            }

            setState(() {
              _filter = ScheduleFilter.today;
            });
            _loadPage();
          },
        ),
        ChoiceChip(
          label: const Text('Semua Jadwal'),
          selected: _filter == ScheduleFilter.all,
          onSelected: (_) {
            if (_filter == ScheduleFilter.all) {
              return;
            }

            setState(() {
              _filter = ScheduleFilter.all;
            });
            _loadPage();
          },
        ),
      ],
    );
  }

  Widget _buildScheduleCard(TowingSchedule schedule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleDetailScreen(scheduleId: schedule.id),
              ),
            );
            if (!mounted) {
              return;
            }

            await _loadPage(showLoader: false);
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Surat Jalan ${schedule.suratJalanNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${formatDate(schedule.scheduleDate)} • ${schedule.truckLabel}',
                            style: const TextStyle(
                              color: Color(0xFF5B6776),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: schedule.status),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: schedule.progressValue,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: const Color(0xFFE4EAF2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF4B942),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${schedule.completedDeliveryCount}/${schedule.deliveryCount} unit selesai',
                  style: const TextStyle(
                    color: Color(0xFF5B6776),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD6E5EB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal belum bisa dimuat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF5B6776), height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 34,
                color: Color(0xFF5B6776),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5B6776), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
