import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminControlBar extends StatelessWidget {
  final AdminViewModel viewModel;

  const AdminControlBar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _buildActionsSection(context, wrap: true),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusSection(),
              _buildActionsSection(context, wrap: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSection() {
    return Obx(() {
      final isRunning = viewModel.isBatchRunning;
      final queueDepth = viewModel.llmQueueDepth;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isRunning ? AppTheme.warningLight : AppTheme.successLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRunning
                    ? AppTheme.warning.withValues(alpha: 0.3)
                    : AppTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: isRunning ? AppTheme.warning : AppTheme.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isRunning ? AppTheme.warning : AppTheme.success)
                            .withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isRunning ? 'Batch Running' : 'Pipeline Idle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isRunning ? AppTheme.warning : AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Queue depth badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 15,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'LLM Queue: $queueDepth',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildActionsSection(BuildContext context, {required bool wrap}) {
    return Obx(() {
      final isLoading = viewModel.isActionLoading.value;
      final isAuto = viewModel.isAutoPolling.value;

      final actionWidgets = <Widget>[
        // Auto Polling Switch
        InkWell(
          onTap: viewModel.toggleAutoPolling,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isAuto ? AppTheme.primaryLight : AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAuto
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAuto ? Icons.timer_rounded : Icons.timer_off_outlined,
                  size: 16,
                  color: isAuto ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto (15s)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAuto ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 20,
                  width: 32,
                  child: Switch(
                    value: isAuto,
                    onChanged: (_) => viewModel.toggleAutoPolling(),
                    activeThumbColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Refresh Button
        IconButton(
          tooltip: 'Refresh Dashboard',
          onPressed: isLoading ? null : () => viewModel.refreshAll(),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceMuted,
            foregroundColor: AppTheme.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
        const SizedBox(width: 10),

        // Retry All Failed Button
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => viewModel.retryFailedJobs(),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.warning,
            side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.5)),
            backgroundColor: AppTheme.warningLight.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: const Text(
            'Retry All Failed',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),

        // Run Full Pipeline Button
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => viewModel.triggerPipeline(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.rocket_launch_rounded, size: 18),
          label: const Text(
            'Run Full Pipeline',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ];

      if (wrap) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actionWidgets,
        );
      }

      return Row(mainAxisSize: MainAxisSize.min, children: actionWidgets);
    });
  }
}
