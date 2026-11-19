import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/jobs_viewmodel.dart';
import '../widgets/job_card.dart';
import '../widgets/job_detail_modal.dart';
import '../widgets/job_filter_sidebar.dart';

class JobsView extends GetView<JobsViewModel> {
  const JobsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isWideDesktop = constraints.maxWidth >= 1200;

        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: !isDesktop
              ? Drawer(
                  backgroundColor: AppTheme.surface,
                  child: SafeArea(
                    child: JobFilterSidebar(
                      onCloseDrawer: () => Navigator.of(context).pop(),
                    ),
                  ),
                )
              : null,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Desktop Left Sidebar (~280px fixed width)
              if (isDesktop)
                Container(
                  width: 290,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(
                      right: BorderSide(color: AppTheme.border, width: 1),
                    ),
                  ),
                  child: const JobFilterSidebar(),
                ),

              // 2. Center Content Area (Scrollable Job Feed)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Feed Header: Results Count, Active Filters, Sort Dropdown & Mobile Filter Button
                    _buildFeedHeader(context, isDesktop),

                    const Divider(height: 1),

                    // Active Removable Filter Chips Bar
                    _buildActiveFiltersChipsBar(),

                    // Feed List / State Views
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return _buildLoadingState();
                        }

                        if (controller.errorMessage.value.isNotEmpty) {
                          return _buildErrorState();
                        }

                        if (controller.filteredJobs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return _buildJobList(context, isWideDesktop);
                      }),
                    ),
                  ],
                ),
              ),

              // 3. Wide Desktop Right Slide-Over Detail Drawer
              if (isWideDesktop)
                Obx(() {
                  final selected = controller.selectedJob.value;
                  if (selected == null) return const SizedBox.shrink();

                  return Container(
                    width: 480,
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      border: Border(
                        left: BorderSide(color: AppTheme.border, width: 1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x06000000),
                          offset: Offset(-4, 0),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: JobDetailModal(
                      job: selected,
                      onClose: () => controller.selectJob(null),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // Feed Header with Match Count and Sort Selector
  Widget _buildFeedHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppTheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Count & Mobile Filter Trigger
          Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    tooltip: 'Open Filters',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surfaceMuted,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Obx(() {
                final count = controller.filteredJobs.length;
                return Row(
                  children: [
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      count == 1 ? 'job listing found' : 'job listings found',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),

          // Right: Sort By Dropdown
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() {
                return Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.sortBy.value,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'newest',
                          child: Text('Newest First'),
                        ),
                        DropdownMenuItem(
                          value: 'confidence',
                          child: Text('Highest AI Match'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.setSortBy(val);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // Active Removable Filter Chips Bar
  Widget _buildActiveFiltersChipsBar() {
    return Obx(() {
      final chips = <Widget>[];

      // Search Query Chip
      if (controller.searchQuery.value.isNotEmpty) {
        chips.add(
          _buildRemovableChip(
            label: 'Search: "${controller.searchQuery.value}"',
            onDeleted: controller.clearSearch,
          ),
        );
      }

      // Role Categories Chips
      for (final role in controller.selectedRoleCategories) {
        chips.add(
          _buildRemovableChip(
            label: role,
            onDeleted: () => controller.toggleRoleCategory(role),
          ),
        );
      }

      // Work Modes Chips
      for (final mode in controller.selectedWorkModes) {
        chips.add(
          _buildRemovableChip(
            label: _capitalize(mode),
            onDeleted: () => controller.toggleWorkMode(mode),
          ),
        );
      }

      // Job Types Chips
      for (final type in controller.selectedJobTypes) {
        chips.add(
          _buildRemovableChip(
            label: _capitalize(type),
            onDeleted: () => controller.toggleJobType(type),
          ),
        );
      }

      // Experience Level Chips
      for (final exp in controller.selectedExperienceLevels) {
        chips.add(
          _buildRemovableChip(
            label: '${_capitalize(exp)} Level',
            onDeleted: () => controller.toggleExperienceLevel(exp),
          ),
        );
      }

      // City Chip
      if (controller.selectedCity.value.isNotEmpty) {
        chips.add(
          _buildRemovableChip(
            label: 'City: ${controller.selectedCity.value}',
            onDeleted: () => controller.setCity(''),
          ),
        );
      }

      // ATS Source Chip
      if (controller.selectedSource.value.isNotEmpty) {
        chips.add(
          _buildRemovableChip(
            label: 'Source: ${controller.selectedSource.value}',
            onDeleted: () => controller.setSource(''),
          ),
        );
      }

      if (chips.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceMuted,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Active filters:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...chips.map(
                      (chip) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: chip,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.clearAllFilters,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRemovableChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // Job Feed List
  Widget _buildJobList(BuildContext context, bool isWideDesktop) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.filteredJobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = controller.filteredJobs[index];
        return Obx(() {
          final isSelected = controller.selectedJob.value?.id == job.id;
          return JobCard(
            job: job,
            isSelected: isSelected,
            onTap: () {
              controller.selectJob(job);
              if (!isWideDesktop) {
                // Open centered modal dialog on non-wide desktop / tablets / mobile
                JobDetailModal.showAsModal(context, job);
              }
            },
          );
        });
      },
    );
  }

  // Loading State (Connecting)
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Connecting to Server...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Fetching live tech jobs from FastAPI backend (http://127.0.0.1:8000)...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Error State (Disconnected)
  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.danger,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Disconnected from Backend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Could not connect to FastAPI server at http://127.0.0.1:8000.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please ensure the backend is running via:\npython -m uvicorn main:app --reload',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.fetchJobs,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State ("No jobs match your filters")
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No jobs match your filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try broadening your search query, selecting different role categories, or clearing active filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: controller.clearAllFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear All Filters'),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

