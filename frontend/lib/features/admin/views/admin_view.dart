import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../widgets/admin_control_bar.dart';
import '../widgets/admin_danger_zone.dart';
import '../widgets/admin_diagnostic_panels.dart';
import '../widgets/admin_job_inspector_dialog.dart';
import '../widgets/admin_jobs_table.dart';
import '../widgets/admin_kpi_cards.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<AdminViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Main Scrollable Admin Dashboard
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Title & Description
                    _buildPageHeader(viewModel),
                    const SizedBox(height: 20),

                    // Disconnected Error Alert (if backend unreachable)
                    Obx(() {
                      final error = viewModel.errorMessage.value;
                      if (error != null && viewModel.metrics.value == null) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: AppTheme.danger, size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Disconnected from Backend Server',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      error,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.danger,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () => viewModel.refreshAll(),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // 1. Top Control Bar
                    AdminControlBar(viewModel: viewModel),
                    const SizedBox(height: 20),

                    // 2. 4-Grid KPI Summary Cards
                    AdminKpiCards(viewModel: viewModel),
                    const SizedBox(height: 20),

                    // 3. Diagnostic Breakdown Panels
                    AdminDiagnosticPanels(viewModel: viewModel),
                    const SizedBox(height: 20),

                    // 4. Interactive Jobs Table & Filters
                    AdminJobsTable(viewModel: viewModel),
                    const SizedBox(height: 24),

                    // 5. Danger Zone / Maintenance Controls
                    AdminDangerZone(viewModel: viewModel),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Modal Overlay for Job Inspector
          Obx(() {
            final showInspector = viewModel.selectedJobDetail.value != null ||
                viewModel.isLoadingDetail.value;

            if (!showInspector) return const SizedBox.shrink();

            return Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: AdminJobInspectorDialog(viewModel: viewModel),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPageHeader(AdminViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Admin Operations Console',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Real-time ingestion monitoring, LLM token unit economics, and data classification pipeline controls.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
