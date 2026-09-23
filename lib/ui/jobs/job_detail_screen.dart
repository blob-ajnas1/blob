import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/rbac/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../data/models/enums.dart';
import '../../data/models/job.dart';
import '../../state/marketplace_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user!;
    final market = context.watch<MarketplaceController>();
    final job = market.jobs.where((j) => j.id == jobId).firstOrNull;

    if (job == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job')),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Job not found',
          message: 'This job may have been removed.',
        ),
      );
    }

    final isOwner = job.posterId == user.id;
    final apps = market.applicationsForJob(job.id);
    final myApp = apps.where((a) => a.laborerId == user.id).firstOrNull;
    final canApply =
        user.can(Permission.applyToJobs) &&
        job.status == JobStatus.open &&
        myApp == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted by ${job.posterName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${Money.format(job.wagePerWorkerPaise)} per worker',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total payout ${Money.format(job.totalWagePaise)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.people_outline,
                    label: 'Workers',
                    value: '${job.workersNeeded}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.event_outlined,
                    label: 'Work date',
                    value: DateFormat('d MMM').format(job.workDate),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.flag_outlined,
                    label: 'Status',
                    value: job.status.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Work details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              job.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (canApply)
              ElevatedButton.icon(
                icon: const Icon(Icons.how_to_reg),
                label: const Text('Apply for this job'),
                onPressed: () async {
                  await market.applyToJob(
                    job: job,
                    laborer: user,
                    groupSize: user.laborerType == LaborerType.groupWork
                        ? job.workersNeeded
                        : 1,
                  );
                  if (context.mounted) {
                    showSnack(context, 'Application sent');
                  }
                },
              ),
            if (myApp != null)
              InfoBanner(
                icon: Icons.assignment_turned_in_outlined,
                message: 'Your application status: ${myApp.status.label}',
              ),
            if (myApp != null &&
                myApp.status == ApplicationStatus.assigned) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept this work'),
                onPressed: () async {
                  await market.acceptAssignment(myApp);
                  if (context.mounted) {
                    showSnack(context, 'Work accepted');
                  }
                },
              ),
            ],
            if (isOwner) ...[
              const SizedBox(height: 20),
              SectionHeader('Applicants (${apps.length})'),
              if (apps.isEmpty)
                const Text(
                  'No applications yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ...apps.map((a) => _ApplicantRow(application: a, job: job)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  final JobApplication application;
  final Job job;

  const _ApplicantRow({required this.application, required this.job});

  @override
  Widget build(BuildContext context) {
    final market = context.read<MarketplaceController>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.person, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.laborerName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${application.laborerType.label} · ${application.groupSize} worker(s)',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill.text(application.status.label),
              ],
            ),
            const SizedBox(height: 10),
            if (application.status == ApplicationStatus.applied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: () async {
                    await market.assignApplication(application, job);
                    if (context.mounted) {
                      showSnack(context, 'Worker assigned');
                    }
                  },
                  child: const Text('Assign this worker'),
                ),
              ),
            if (application.status == ApplicationStatus.accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  icon: const Icon(Icons.task_alt, size: 18),
                  label: Text(
                    'Complete & owe '
                    '${Money.format(job.wagePerWorkerPaise * application.groupSize)}',
                  ),
                  onPressed: () async {
                    await market.completeJob(job: job, app: application);
                    if (context.mounted) {
                      showSnack(
                        context,
                        'Job completed. Wage added to your payment tracker.',
                      );
                    }
                  },
                ),
              ),
            if (application.status == ApplicationStatus.completed)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Completed — settle payment in the Payments tab.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
