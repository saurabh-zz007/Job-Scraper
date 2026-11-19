import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/job_model.dart';

class JobCard extends StatefulWidget {
  final JobModel job;
  final bool isSelected;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isSelected = widget.isSelected;

    // Work Mode Color & Label
    final workMode = job.workMode.toLowerCase();
    Color workModeBg;
    Color workModeText;
    IconData workModeIcon;

    if (workMode == 'remote') {
      workModeBg = AppTheme.successLight;
      workModeText = AppTheme.success;
      workModeIcon = Icons.wifi_rounded;
    } else if (workMode == 'hybrid') {
      workModeBg = const Color(0xFFEFF6FF); // Blue 50
      workModeText = const Color(0xFF2563EB); // Blue 600
      workModeIcon = Icons.home_work_outlined;
    } else {
      workModeBg = AppTheme.surfaceMuted;
      workModeText = AppTheme.textSecondary;
      workModeIcon = Icons.business_outlined;
    }

    // Display skills (limit to 4)
    const maxSkills = 4;
    final visibleSkills = job.skills.take(maxSkills).toList();
    final remainingSkillsCount = job.skills.length - maxSkills;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryLight.withValues(alpha: 0.35)
                : (_isHovered ? Colors.white : AppTheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary
                  : (_isHovered ? AppTheme.borderDark : AppTheme.border),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Company, Source ATS, and Relative Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Avatar / Initial
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCompanyColor(job.company),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      job.company.isNotEmpty ? job.company[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Company & Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.company,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ATS Source Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                job.sourceName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppTheme.primaryDark
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Relative Date
                  Text(
                    job.relativePostedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Badges Row: Location, Work Mode, Job Type, Experience
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // City / Location Badge
                  _buildBadge(
                    icon: Icons.location_on_outlined,
                    label: job.location,
                    bgColor: AppTheme.surfaceMuted,
                    textColor: AppTheme.textSecondary,
                  ),

                  // Work Mode Badge
                  _buildBadge(
                    icon: workModeIcon,
                    label: _capitalize(job.workMode),
                    bgColor: workModeBg,
                    textColor: workModeText,
                  ),

                  // Job Type Badge
                  if (job.inferredJobType != null &&
                      job.inferredJobType != 'unknown')
                    _buildBadge(
                      icon: Icons.schedule_rounded,
                      label: _capitalize(job.inferredJobType!),
                      bgColor: AppTheme.surfaceMuted,
                      textColor: AppTheme.textSecondary,
                    ),

                  // Experience Badge
                  if (job.inferredExperience != null &&
                      job.inferredExperience != 'unknown')
                    _buildBadge(
                      icon: Icons.trending_up_rounded,
                      label: '${_capitalize(job.inferredExperience!)} Level',
                      bgColor: const Color(0xFFFDF4FF), // Purple 50
                      textColor: const Color(0xFF9333EA), // Purple 600
                    ),
                ],
              ),

              // Inferred Skills Chips
              if (job.skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...visibleSkills.map(
                      (skill) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9), // Slate 100
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                    if (remainingSkillsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$remainingSkillsCount more',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _getCompanyColor(String company) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFF97316), // Orange
    ];
    final hash = company.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }
}

