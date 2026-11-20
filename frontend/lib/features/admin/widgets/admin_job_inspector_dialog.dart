import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/admin_models.dart';
import '../../jobs/widgets/formatted_job_description.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminJobInspectorDialog extends StatefulWidget {
  final AdminViewModel viewModel;

  const AdminJobInspectorDialog({super.key, required this.viewModel});

  @override
  State<AdminJobInspectorDialog> createState() =>
      _AdminJobInspectorDialogState();
}

class _AdminJobInspectorDialogState extends State<AdminJobInspectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '$label copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = widget.viewModel.isLoadingDetail.value;
      final job = widget.viewModel.selectedJobDetail.value;

      if (!isLoading && job == null) {
        return const SizedBox.shrink();
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 820,
          height: 720,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : job == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(job),
                    const Divider(height: 1),

                    // Error Banner if present
                    if (job.lastError != null && job.lastError!.isNotEmpty)
                      _buildErrorBanner(job),

                    // Tabs
                    Container(
                      color: AppTheme.surfaceMuted,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        indicatorColor: AppTheme.primary,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Overview & Tags'),
                          Tab(text: 'LLM Audit & Cost'),
                          Tab(text: 'Job Description'),
                          Tab(text: 'Raw JSON Payload'),
                        ],
                      ),
                    ),

                    // Tab View Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(job),
                          _buildLlmAuditTab(job),
                          _buildDescriptionTab(job),
                          _buildRawJsonTab(job),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Footer Actions
                    _buildFooter(job),
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildHeader(AdminJobDetailModel job) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      job.companyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    _buildStatusPill(job.etlStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  job.rawTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${job.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _copyToClipboard(job.id, 'Job ID'),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.viewModel.closeInspector,
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = AppTheme.surfaceMuted;
    Color fg = AppTheme.textSecondary;

    switch (status.toUpperCase()) {
      case 'RAW':
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
      case 'FILTERED':
      case 'PROCESSING':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0284C7);
        break;
      case 'CLASSIFIED':
      case 'PUBLISHED':
        bg = AppTheme.successLight;
        fg = AppTheme.success;
        break;
      case 'FAILED':
        bg = AppTheme.dangerLight;
        fg = AppTheme.danger;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildErrorBanner(AdminJobDetailModel job) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extraction / Processing Error',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  job.lastError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.danger,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminJobDetailModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL Bar
          if (job.sourceUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      job.sourceUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () =>
                        widget.viewModel.openExternalUrl(job.sourceUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Open URL'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Extracted Fields Grid
          const Text(
            'Inferred Attributes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFieldBadge(
                'Role Category',
                job.inferredRole ?? 'Unassigned',
              ),
              _buildFieldBadge(
                'Work Mode',
                job.inferredWorkMode ?? 'Unassigned',
              ),
              _buildFieldBadge('Job Type', job.inferredJobType ?? 'Full-time'),
              _buildFieldBadge(
                'Experience Level',
                job.inferredExperience ?? 'Mid',
              ),
              _buildFieldBadge(
                'Location',
                job.inferredCity ?? job.rawLocation ?? 'Remote',
              ),
              _buildFieldBadge(
                'Confidence',
                job.classificationConfidence != null
                    ? '${(job.classificationConfidence! * 100).toStringAsFixed(1)}%'
                    : 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Inferred Skills
          const Text(
            'Inferred Skills & Tech Stack',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (job.inferredSkills.isEmpty)
            const Text(
              'No inferred skills extracted yet.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.inferredSkills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Audit Timestamps
          const Text(
            'Timestamps',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildTimestampRow('Created At', job.createdAt),
                _buildTimestampRow('Classified At', job.classifiedAt),
                _buildTimestampRow('Last Seen', job.lastSeenAt),
                _buildTimestampRow('Posted At', job.postedAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldBadge(String label, String value) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(String label, DateTime? dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            dt != null ? dt.toLocal().toString() : 'N/A',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLlmAuditTab(AdminJobDetailModel job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LLM Execution & Financial Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  title: 'Model',
                  value: job.llmModel ?? 'None',
                  icon: Icons.psychology_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  title: 'Prompt Version',
                  value: job.promptVersion ?? 'N/A',
                  icon: Icons.code_rounded,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  title: 'Processing Attempts',
                  value: '${job.processingAttempts}',
                  icon: Icons.replay_rounded,
                  color: job.processingAttempts > 1
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  title: 'Input Tokens',
                  value: '${job.llmInputTokens ?? 0}',
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  title: 'Output Tokens',
                  value: '${job.llmOutputTokens ?? 0}',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricBox(
                  title: 'Cost (USD)',
                  value: job.llmCostUsd != null
                      ? '\$${job.llmCostUsd!.toStringAsFixed(4)}'
                      : '\$0.0000',
                  icon: Icons.attach_money_rounded,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab(AdminJobDetailModel job) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        child: FormattedJobDescription(
          description: job.description.isNotEmpty
              ? job.description
              : 'No raw description available.',
        ),
      ),
    );
  }

  Widget _buildRawJsonTab(AdminJobDetailModel job) {
    String formattedJson;
    try {
      if (job.rawPayload != null) {
        const encoder = JsonEncoder.withIndent('  ');
        formattedJson = encoder.convert(job.rawPayload);
      } else {
        formattedJson = '{\n  "status": "No raw payload stored in record"\n}';
      }
    } catch (e) {
      formattedJson = 'Error formatting JSON: $e';
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          formattedJson,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: Color(0xFF38BDF8),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(AdminJobDetailModel job) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete button
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            onPressed: () {
              widget.viewModel.deleteJob(job.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete Job'),
          ),

          Row(
            children: [
              OutlinedButton(
                onPressed: widget.viewModel.closeInspector,
                child: const Text('Close'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  widget.viewModel.retryFailedJobs(jobIds: [job.id]);
                },
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Retry Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
