import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminJobsTable extends StatelessWidget {
  final AdminViewModel viewModel;

  const AdminJobsTable({super.key, required this.viewModel});

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'RAW':
        return const Color(0xFFF1F5F9);
      case 'FILTERED':
      case 'PROCESSING':
        return const Color(0xFFE0F2FE);
      case 'CLASSIFIED':
      case 'PUBLISHED':
        return AppTheme.successLight;
      case 'FAILED':
        return AppTheme.dangerLight;
      default:
        return AppTheme.surfaceMuted;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toUpperCase()) {
      case 'RAW':
        return const Color(0xFF475569);
      case 'FILTERED':
      case 'PROCESSING':
        return const Color(0xFF0284C7);
      case 'CLASSIFIED':
      case 'PUBLISHED':
        return AppTheme.success;
      case 'FAILED':
        return AppTheme.danger;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildStatusBadge(String status) {
    final bg = _getStatusBgColor(status);
    final text = _getStatusTextColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double? confidence) {
    if (confidence == null) {
      return const Text(
        '-',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      );
    }

    final percent = (confidence * 100).toInt();
    final color = confidence >= 0.85
        ? AppTheme.success
        : confidence >= 0.70
        ? AppTheme.warning
        : AppTheme.danger;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: confidence.clamp(0.0, 1.0),
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AdminJobListItem job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Job Record'),
        content: Text(
          'Are you sure you want to permanently delete "${job.rawTitle}" at ${job.companyName}?',
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
              viewModel.deleteJob(job.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Controls Header
          _buildFilterBar(context),
          const Divider(height: 1),

          // Table Content
          Obx(() {
            final isLoading = viewModel.isLoadingJobs.value;
            final items = viewModel.jobs;

            if (isLoading && items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: AppTheme.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No matching jobs found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Try adjusting your status or search filters.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 1050),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppTheme.surfaceMuted,
                      ),
                      headingTextStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
                      horizontalMargin: 20,
                      columnSpacing: 18,
                      columns: const [
                        DataColumn(label: Text('COMPANY & TITLE')),
                        DataColumn(label: Text('SOURCE')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('ROLE & MODE')),
                        DataColumn(label: Text('CONFIDENCE')),
                        DataColumn(label: Text('ATTEMPTS')),
                        DataColumn(label: Text('COST')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: items.map((job) {
                        return DataRow(
                          cells: [
                            // Company & Title
                            DataCell(
                              SizedBox(
                                width: 230,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      job.rawTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      job.companyName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Source ATS
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  job.sourceName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            // Status Badge
                            DataCell(_buildStatusBadge(job.etlStatus)),
                            // Inferred Role & Mode
                            DataCell(
                              SizedBox(
                                width: 170,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      job.inferredRole ?? 'Unclassified',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: job.inferredRole != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${job.inferredWorkMode ?? "-"} • ${job.inferredCity ?? "-"}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Confidence
                            DataCell(
                              _buildConfidenceIndicator(
                                job.classificationConfidence,
                              ),
                            ),
                            // Processing Attempts
                            DataCell(
                              Text(
                                '${job.processingAttempts}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: job.processingAttempts > 1
                                      ? AppTheme.warning
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            // LLM Cost
                            DataCell(
                              Text(
                                job.llmCostUsd != null
                                    ? '\$${job.llmCostUsd!.toStringAsFixed(4)}'
                                    : '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Inspect Details',
                                    icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    color: AppTheme.primary,
                                    onPressed: () =>
                                        viewModel.inspectJob(job.id),
                                  ),
                                  IconButton(
                                    tooltip: 'Retry ETL',
                                    icon: const Icon(
                                      Icons.replay_rounded,
                                      size: 18,
                                    ),
                                    color: AppTheme.warning,
                                    onPressed: () => viewModel.retryFailedJobs(
                                      jobIds: [job.id],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Job',
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    color: AppTheme.danger,
                                    onPressed: () =>
                                        _confirmDelete(context, job),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.5),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),

          const Divider(height: 1),

          // Pagination Controls
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          final statusPills = Obx(() {
            final active = viewModel.selectedStatus.value;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: viewModel.statusOptions.map((status) {
                final isSelected = active == status;
                return ChoiceChip(
                  label: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceMuted,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  onSelected: (_) => viewModel.onStatusChanged(status),
                );
              }).toList(),
            );
          });

          final filterInputs = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Source Dropdown
              Obx(() {
                final sources = viewModel.availableSources;
                final selected = viewModel.selectedSource.value;

                return Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sources.contains(selected) ? selected : 'ALL',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textSecondary,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      items: sources.map((src) {
                        return DropdownMenuItem(
                          value: src,
                          child: Text(src == 'ALL' ? 'All Sources' : src),
                        );
                      }).toList(),
                      onChanged: viewModel.onSourceChanged,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 10),

              // Keyword Search
              SizedBox(
                width: 180,
                height: 38,
                child: TextField(
                  onChanged: viewModel.onSearchChanged,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search jobs...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    filled: true,
                    fillColor: AppTheme.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Low Confidence Toggle
              Obx(() {
                final isLowConf = viewModel.lowConfidenceOnly.value;
                return InkWell(
                  onTap: () => viewModel.toggleLowConfidenceOnly(!isLowConf),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isLowConf
                          ? AppTheme.warningLight
                          : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLowConf ? AppTheme.warning : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLowConf
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: isLowConf
                              ? AppTheme.warning
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Low Conf (<80%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLowConf
                                ? AppTheme.warning
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statusPills,
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: filterInputs,
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [statusPills, filterInputs],
          );
        },
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Obx(() {
      final current = viewModel.currentPage.value;
      final total = viewModel.totalPages.value;
      final totalCount = viewModel.totalJobs.value;
      final pageSize = viewModel.pageSize.value;

      final startItem = totalCount == 0 ? 0 : ((current - 1) * pageSize) + 1;
      final endItem = (current * pageSize) > totalCount
          ? totalCount
          : (current * pageSize);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $startItem–$endItem of $totalCount jobs',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                // Page Size Selector
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Per page: ',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSize,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        items: const [10, 25, 50, 100].map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text('$size'),
                          );
                        }).toList(),
                        onChanged: viewModel.onPageSizeChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Prev / Next Page Buttons
                IconButton(
                  tooltip: 'Previous Page',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: current > 1 ? viewModel.goToPrevPage : null,
                ),
                Text(
                  'Page $current of $total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  tooltip: 'Next Page',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: current < total ? viewModel.goToNextPage : null,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
