import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/utils/money.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../dashboards/dashboard_parts.dart';
import '../widgets/common.dart';
import 'post_job_screen.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final canPost = user.can(Permission.postJobs);

    if (canPost) {
      final myJobs = market.jobsByPoster(user.id);
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Jobs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Post a job',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PostJobScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: myJobs.isEmpty
              ? EmptyState(
                  icon: Icons.work_outline,
                  title: 'No jobs posted yet',
                  message:
                      'Post work for laborers. Your first 2 posts are free.',
                  actionLabel: 'Post a job',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PostJobScreen(),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    if (Money.jobPostingFeesEnabled) ...[
                      FreePostsBanner(
                        remaining: market.freePostsRemaining(user),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...myJobs.map((j) => JobCard(job: j)),
                  ],
                ),
        ),
      );
    }

    // Laborer view — browse and apply.
    final open = market.openJobs();
    final mine = market.applicationsByLaborer(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Work')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SectionHeader('Open Jobs'),
            if (open.isEmpty)
              const EmptyCard(
                icon: Icons.work_off_outlined,
                message: 'No open jobs right now.',
              )
            else
              ...open.map((j) => JobCard(job: j, showApply: true)),
            const SizedBox(height: 20),
            const SectionHeader('My Applications'),
            if (mine.isEmpty)
              const EmptyCard(
                icon: Icons.assignment_outlined,
                message: 'You have not applied to any job yet.',
              )
            else
              ...mine.map((a) => ApplicationCard(application: a)),
          ],
        ),
      ),
    );
  }
}

class FreePostsBanner extends StatelessWidget {
  final int remaining;
  const FreePostsBanner({super.key, required this.remaining});

  @override
  Widget build(BuildContext context) {
    if (remaining > 0) {
      return InfoBanner(
        icon: Icons.card_giftcard,
        message:
            '$remaining free job post${remaining == 1 ? '' : 's'} remaining. '
            'After that each post costs \u20B950.',
      );
    }
    return const InfoBanner(
      icon: Icons.info_outline,
      message: 'Free posts used. Each new job post costs \u20B950.',
    );
  }
}
