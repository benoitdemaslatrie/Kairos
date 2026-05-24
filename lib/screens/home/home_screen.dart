import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../services/activity_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildGreeting(),
                  _buildDivider(),
                  _buildTodaySummary(),
                  _buildDivider(),
                  _buildActivityList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDivider() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.45)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Kairos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: KairosColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KairosColors.surfaceContainerHigh,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Icon(Icons.person_outline, size: 20, color: KairosColors.onSurface),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(now);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w300,
                color: KairosColors.onSurface,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KairosColors.onSurfaceVariant,
                letterSpacing: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTodaySummary() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ValueListenableBuilder(
          valueListenable: ActivityStore.instance,
          builder: (context, activities, _) {
            final today = DateTime.now();
            final todayActivities = activities.where((a) {
              final d = a.createdAt;
              return d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
            }).toList();

            return GlassCard(
              showCyanBorder: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    count: todayActivities.length,
                    label: 'Activités\naujourd\'hui',
                    icon: Icons.bolt_outlined,
                  ),
                  Container(width: 1, height: 48, color: Colors.white.withOpacity(0.15)),
                  _SummaryItem(
                    count: todayActivities
                        .where((a) => a.type == ActivityType.voice)
                        .length,
                    label: 'Par\ndictée',
                    icon: Icons.mic_none_outlined,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildActivityList() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aujourd\'hui',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: KairosColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: ActivityStore.instance,
              builder: (context, all, _) {
                final today = DateTime.now();
                final activities = all.where((a) {
                  final d = a.createdAt;
                  return d.year == today.year &&
                      d.month == today.month &&
                      d.day == today.day;
                }).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (activities.isEmpty) {
                  return _EmptyState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityTile(activity: activity);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const _SummaryItem({
    required this.count,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: KairosColors.cyan),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: KairosColors.onSurface,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: KairosColors.onSurfaceVariant,
            letterSpacing: 0.05,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Activity activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: KairosColors.cyanBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: KairosColors.cyanBright.withOpacity(0.3),
              ),
            ),
            child: Icon(
              activity.type == ActivityType.voice
                  ? Icons.mic_none_outlined
                  : Icons.edit_outlined,
              size: 18,
              color: KairosColors.cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: KairosColors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(activity.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KairosColors.onSurfaceVariant,
                    letterSpacing: 0.05,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.bolt_outlined,
            size: 56,
            color: KairosColors.onSurfaceVariant.withOpacity(0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune activité aujourd\'hui',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: KairosColors.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Utilisez la dictée pour en ajouter',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: KairosColors.onSurfaceVariant.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
