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
          final isCompact = constraints.maxWidth < 650;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderLabel(),
                const SizedBox(height: 12),
                _buildRefreshActions(context),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderLabel(),
              _buildRefreshActions(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.sync_rounded, size: 18, color: AppTheme.primary),
        SizedBox(width: 8),
        Text(
          'Live Telemetry & Controls',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshActions(BuildContext context) {
    return Obx(() {
      final isLoading = viewModel.isLoadingMetrics.value || viewModel.isLoadingJobs.value;
      final isAuto = viewModel.isAutoPolling.value;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

          // Manual Refresh Button
          ElevatedButton.icon(
            onPressed: isLoading ? null : () => viewModel.refreshAll(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Refresh',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    });
  }
}
