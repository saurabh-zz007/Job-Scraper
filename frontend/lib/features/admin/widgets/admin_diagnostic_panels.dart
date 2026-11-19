import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminDiagnosticPanels extends StatelessWidget {
  final AdminViewModel viewModel;

  const AdminDiagnosticPanels({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final metrics = viewModel.metrics.value;
      if (metrics == null) return const SizedBox.shrink();

      final bySource = metrics.bySource;
      final byPrompt = metrics.byPromptVersion;
      final topErrors = metrics.topErrors;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isSingleCol = constraints.maxWidth < 1000;

          if (isSingleCol) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSourceBreakdownCard(bySource),
                const SizedBox(height: 16),
                _buildModelPromptBreakdownCard(byPrompt),
                const SizedBox(height: 16),
                _buildTopErrorsCard(topErrors),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildSourceBreakdownCard(bySource),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: _buildModelPromptBreakdownCard(byPrompt),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: _buildTopErrorsCard(topErrors),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildPanelContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBreakdownCard(List<dynamic> sources) {
    if (sources.isEmpty) {
      return _buildPanelContainer(
        title: 'Breakdown by Source ATS',
        icon: Icons.hub_outlined,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No source data recorded yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return _buildPanelContainer(
      title: 'Breakdown by Source ATS',
      icon: Icons.hub_outlined,
      child: Column(
        children: sources.map((s) {
          final total = s.total as int;
          final classified = s.classified as int;
          final failed = s.failed as int;
          final avgConf = ((s.avgConfidence as double) * 100).toStringAsFixed(0);
          final successRate = total > 0 ? ((classified / total) * 100).toStringAsFixed(0) : '0';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    s.sourceName.toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.sourceName.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$total Total • $classified Classified • $failed Failed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$successRate% success',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conf: $avgConf%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelPromptBreakdownCard(List<dynamic> promptVersions) {
    if (promptVersions.isEmpty) {
      return _buildPanelContainer(
        title: 'Model & Prompt Performance',
        icon: Icons.psychology_outlined,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No LLM executions logged yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return _buildPanelContainer(
      title: 'Model & Prompt Performance',
      icon: Icons.psychology_outlined,
      child: Column(
        children: promptVersions.map((p) {
          final modelName = p.llmModel ?? 'Default Model';
          final version = p.promptVersion ?? 'v1.0';
          final count = p.jobsProcessed as int;
          final avgConf = ((p.avgConfidence as double) * 100).toStringAsFixed(1);
          final avgCost = (p.avgCostUsd as double) < 0.01
              ? '\$${(p.avgCostUsd as double).toStringAsFixed(4)}'
              : '\$${(p.avgCostUsd as double).toStringAsFixed(2)}';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              modelName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              version,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count jobs processed • $avgCost avg/job',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '$avgConf% Conf',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopErrorsCard(List<dynamic> errors) {
    if (errors.isEmpty) {
      return _buildPanelContainer(
        title: 'Top Ingestion Errors',
        icon: Icons.error_outline_rounded,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          alignment: Alignment.center,
          child: Column(
            children: const [
              Icon(Icons.check_circle_outline, color: AppTheme.success, size: 28),
              SizedBox(height: 8),
              Text(
                'Zero Failures Reported',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pipeline is operating cleanly.',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return _buildPanelContainer(
      title: 'Top Ingestion Errors',
      icon: Icons.error_outline_rounded,
      child: Column(
        children: errors.map((err) {
          final count = err.count as int;
          final errorText = err.error.toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.dangerLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppTheme.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '×$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

