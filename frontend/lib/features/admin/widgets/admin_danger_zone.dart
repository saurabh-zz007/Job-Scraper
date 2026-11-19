import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminDangerZone extends StatelessWidget {
  final AdminViewModel viewModel;

  const AdminDangerZone({super.key, required this.viewModel});

  void _confirmPurgeFailed(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Purge All Failed Jobs'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete all jobs currently marked as FAILED? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.purgeJobs(etlStatus: 'FAILED');
            },
            child: const Text('Purge Failed Jobs'),
          ),
        ],
      ),
    );
  }

  void _confirmPurgeStale(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: AppTheme.danger),
            SizedBox(width: 8),
            Text('Purge Stale Jobs'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete all job listings older than 14 days? This action cannot be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.purgeJobs(olderThanDays: 14);
            },
            child: const Text('Purge Stale Jobs'),
          ),
        ],
      ),
    );
  }

  void _confirmReclassify(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.auto_fix_high_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Reclassify Low-Confidence Jobs'),
          ],
        ),
        content: const Text(
          'This will re-enqueue all jobs with classification confidence below 80% into the LLM pipeline for fresh tagging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              viewModel.reclassifyJobs(maxConfidence: 0.80);
            },
            child: const Text('Reclassify Low Conf'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Maintenance & Danger Zone',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.danger,
                    ),
                  ),
                  Text(
                    'Destructive database maintenance and bulk enrichment triggers.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 750;

              final buttons = [
                // Purge Failed
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    backgroundColor: AppTheme.dangerLight.withValues(
                      alpha: 0.3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _confirmPurgeFailed(context),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text(
                    'Purge All Failed Jobs',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12, height: 12),

                // Purge Stale
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309), // Amber 700
                    side: const BorderSide(color: Color(0xFFD97706)),
                    backgroundColor: AppTheme.warningLight.withValues(
                      alpha: 0.3,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _confirmPurgeStale(context),
                  icon: const Icon(Icons.auto_delete_outlined, size: 18),
                  label: const Text(
                    'Purge Stale Jobs (> 14 Days)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12, height: 12),

                // Reclassify
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    backgroundColor: AppTheme.primaryLight.withValues(
                      alpha: 0.4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _confirmReclassify(context),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Reclassify Low Conf (<80%)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ];

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buttons,
                );
              }

              return Row(
                children: [
                  buttons[0],
                  const SizedBox(width: 12),
                  buttons[2],
                  const SizedBox(width: 12),
                  buttons[4],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
