import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminKpiCards extends StatelessWidget {
  final AdminViewModel viewModel;

  const AdminKpiCards({super.key, required this.viewModel});

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    if (amount == 0.0) return '\$0.00';
    if (amount < 0.01) return '\$${amount.toStringAsFixed(4)}';
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final metrics = viewModel.metrics.value;
      final isLoading = viewModel.isLoadingMetrics.value;

      if (isLoading && metrics == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final funnel = metrics?.funnel;
      final econ = metrics?.llmEconomics;
      final quality = metrics?.quality;

      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 1150
              ? 4
              : constraints.maxWidth > 650
              ? 2
              : 1;

          if (crossAxisCount == 4) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFunnelCard(funnel)),
                const SizedBox(width: 14),
                Expanded(child: _buildSpendCard(econ)),
                const SizedBox(width: 14),
                Expanded(child: _buildTokensCard(econ)),
                const SizedBox(width: 14),
                Expanded(child: _buildQualityCard(quality)),
              ],
            );
          } else if (crossAxisCount == 2) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFunnelCard(funnel)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildSpendCard(econ)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTokensCard(econ)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildQualityCard(quality)),
                  ],
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildFunnelCard(funnel),
                const SizedBox(height: 14),
                _buildSpendCard(econ),
                const SizedBox(height: 14),
                _buildTokensCard(econ),
                const SizedBox(height: 14),
                _buildQualityCard(quality),
              ],
            );
          }
        },
      );
    });
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFunnelCard(dynamic funnel) {
    final total = funnel?.totalJobs ?? 0;
    final raw = funnel?.raw ?? 0;
    final filtered = funnel?.filteredPendingLlm ?? 0;
    final classified = funnel?.classified ?? 0;
    final failed = funnel?.failed ?? 0;

    return _buildCardContainer(
      title: 'PIPELINE FUNNEL',
      icon: Icons.filter_alt_outlined,
      iconColor: AppTheme.primary,
      iconBg: AppTheme.primaryLight,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                total.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Total Ingested',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 7,
              child: total == 0
                  ? Container(color: AppTheme.surfaceMuted)
                  : Row(
                      children: [
                        if (classified > 0)
                          Expanded(
                            flex: classified,
                            child: Container(color: AppTheme.success),
                          ),
                        if (filtered > 0)
                          Expanded(
                            flex: filtered,
                            child: Container(color: AppTheme.secondary),
                          ),
                        if (raw > 0)
                          Expanded(
                            flex: raw,
                            child: Container(color: const Color(0xFF94A3B8)),
                          ),
                        if (failed > 0)
                          Expanded(
                            flex: failed,
                            child: Container(color: AppTheme.danger),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // Funnel Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Classified',
                  classified.toString(),
                  AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Pending',
                  filtered.toString(),
                  AppTheme.secondary,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Raw',
                  raw.toString(),
                  const Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Failed',
                  failed.toString(),
                  AppTheme.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendCard(dynamic econ) {
    final totalCost = econ?.totalCostUsd ?? 0.0;
    final cost24h = econ?.costLast24hUsd ?? 0.0;
    final avgCost = econ?.avgCostPerJobUsd ?? 0.0;

    return _buildCardContainer(
      title: 'LLM ECONOMICS',
      icon: Icons.payments_outlined,
      iconColor: const Color(0xFF10B981),
      iconBg: const Color(0xFFECFDF5),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCurrency(totalCost),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Total Spend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 24h',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _formatCurrency(cost24h),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 22, width: 1, color: AppTheme.border),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avg / Job',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _formatCurrency(avgCost),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokensCard(dynamic econ) {
    final inputTokens = econ?.totalInputTokens ?? 0;
    final outputTokens = econ?.totalOutputTokens ?? 0;
    final totalTokens = inputTokens + outputTokens;

    return _buildCardContainer(
      title: 'TOKEN CONSUMPTION',
      icon: Icons.data_usage_rounded,
      iconColor: const Color(0xFF8B5CF6),
      iconBg: const Color(0xFFF5F3FF),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatNumber(totalTokens),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Total Tokens',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Input (Prompt)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _formatNumber(inputTokens),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 22, width: 1, color: AppTheme.border),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Output (Gen)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _formatNumber(outputTokens),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(dynamic quality) {
    final avgConfidence = (quality?.avgConfidence ?? 0.0) as double;
    final lowConfCount = quality?.lowConfidenceJobs ?? 0;
    final staleCount = quality?.staleJobsOver14d ?? 0;
    final confPercent = (avgConfidence * 100).toStringAsFixed(1);

    final qualityColor = avgConfidence >= 0.85
        ? AppTheme.success
        : avgConfidence >= 0.70
        ? AppTheme.warning
        : AppTheme.danger;

    return _buildCardContainer(
      title: 'EXTRACTION QUALITY',
      icon: Icons.verified_outlined,
      iconColor: qualityColor,
      iconBg: qualityColor.withValues(alpha: 0.1),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$confPercent%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: qualityColor,
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Avg Confidence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Low Conf (<80%)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        lowConfCount.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: lowConfCount > 0
                              ? AppTheme.warning
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 22, width: 1, color: AppTheme.border),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stale (>14d)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        staleCount.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: staleCount > 0
                              ? AppTheme.danger
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
