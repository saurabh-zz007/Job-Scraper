import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/job_model.dart';
import '../viewmodels/jobs_viewmodel.dart';

class JobDetailModal extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onClose;

  const JobDetailModal({
    super.key,
    required this.job,
    this.onClose,
  });

  static Future<void> showAsModal(BuildContext context, JobModel job) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: JobDetailModal(
                job: job,
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<JobsViewModel>();

    // Work Mode Color & Icon
    final workMode = job.workMode.toLowerCase();
    Color workModeBg;
    Color workModeText;
    IconData workModeIcon;

    if (workMode == 'remote') {
      workModeBg = AppTheme.successLight;
      workModeText = AppTheme.success;
      workModeIcon = Icons.wifi_rounded;
    } else if (workMode == 'hybrid') {
      workModeBg = const Color(0xFFEFF6FF);
      workModeText = const Color(0xFF2563EB);
      workModeIcon = Icons.home_work_outlined;
    } else {
      workModeBg = AppTheme.surfaceMuted;
      workModeText = AppTheme.textSecondary;
      workModeIcon = Icons.business_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modal Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
              color: AppTheme.surface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.source_outlined,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Source: ${job.sourceName}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (job.classificationConfidence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.aiBadgeLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.aiBadge.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: AppTheme.aiBadge,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              job.formattedConfidence,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.aiBadge,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: onClose,
                    tooltip: 'Close',
                    splashRadius: 18,
                  ),
              ],
            ),
          ),

          // Scrollable Job Information Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Title and Company Header
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      job.company,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    Text(
                      'Posted ${job.relativePostedDate}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Metadata Badges Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // City / Location
                    _buildPill(
                      icon: Icons.location_on_outlined,
                      label: job.location,
                      bgColor: AppTheme.surfaceMuted,
                      textColor: AppTheme.textSecondary,
                    ),

                    // Work Mode
                    _buildPill(
                      icon: workModeIcon,
                      label: _capitalize(job.workMode),
                      bgColor: workModeBg,
                      textColor: workModeText,
                    ),

                    // Job Type
                    if (job.inferredJobType != null &&
                        job.inferredJobType != 'unknown')
                      _buildPill(
                        icon: Icons.schedule_rounded,
                        label: _capitalize(job.inferredJobType!),
                        bgColor: AppTheme.surfaceMuted,
                        textColor: AppTheme.textSecondary,
                      ),

                    // Experience
                    if (job.inferredExperience != null &&
                        job.inferredExperience != 'unknown')
                      _buildPill(
                        icon: Icons.trending_up_rounded,
                        label: '${_capitalize(job.inferredExperience!)} Level',
                        bgColor: const Color(0xFFFDF4FF),
                        textColor: const Color(0xFF9333EA),
                      ),

                    // Role Category
                    if (job.inferredRole != null)
                      _buildPill(
                        icon: Icons.work_outline_rounded,
                        label: job.inferredRole!,
                        bgColor: AppTheme.primaryLight,
                        textColor: AppTheme.primaryDark,
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Inferred Technical Skills Section
                if (job.skills.isNotEmpty) ...[
                  const Text(
                    'Extracted Technical Skills',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // LLM Pipeline Inspection Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Extraction & Ingestion Pipeline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Model: ${job.llmModel ?? "gpt-4o-mini"} • '
                              'Prompt: ${job.promptVersion ?? "v2.1"} • '
                              'ETL Status: ${job.etlStatus}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Job Description Header
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Styled Description Text
                _buildDescriptionContent(job.description),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Sticky Footer with prominent Apply Now Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  offset: Offset(0, -3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => viewModel.openApplyUrl(job.applyUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Apply on Job Board'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContent(String text) {
    // Render clean formatted markdown-style headers, bullet points and paragraphs
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.replaceFirst('### ', ''),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    bulletText,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Text(
            line,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

