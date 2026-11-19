import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/jobs_viewmodel.dart';

class JobFilterSidebar extends StatelessWidget {
  final VoidCallback? onCloseDrawer;

  const JobFilterSidebar({super.key, this.onCloseDrawer});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.find<JobsViewModel>();

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      final count = viewModel.activeFiltersCount;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                Row(
                  children: [
                    Obx(() {
                      final hasFilters = viewModel.activeFiltersCount > 0;
                      if (!hasFilters) return const SizedBox.shrink();
                      return TextButton(
                        onPressed: viewModel.clearAllFilters,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      );
                    }),
                    if (onCloseDrawer != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onCloseDrawer,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Keyword Search Bar
                _buildSearchInput(viewModel),

                const SizedBox(height: 20),

                // 1. Role Category
                _buildSectionHeader('Role Category'),
                const SizedBox(height: 8),
                Obx(() {
                  final roles = viewModel.availableRoleCategories;
                  if (roles.isEmpty) {
                    return const Text(
                      'No categories available',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    );
                  }
                  return Column(
                    children: roles.map((role) {
                      final isChecked =
                          viewModel.selectedRoleCategories.contains(role);
                      return _buildCheckboxRow(
                        title: role,
                        isSelected: isChecked,
                        onChanged: (_) => viewModel.toggleRoleCategory(role),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 2. Work Mode
                _buildSectionHeader('Work Mode'),
                const SizedBox(height: 8),
                Obx(() {
                  final modes = viewModel.availableWorkModes;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: modes.map((mode) {
                      final isSelected =
                          viewModel.selectedWorkModes.contains(mode);
                      return _buildFilterChip(
                        label: _capitalize(mode),
                        isSelected: isSelected,
                        onSelected: (_) => viewModel.toggleWorkMode(mode),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 3. Job Type
                _buildSectionHeader('Job Type'),
                const SizedBox(height: 8),
                Obx(() {
                  final types = viewModel.availableJobTypes;
                  return Column(
                    children: types.map((type) {
                      final isChecked =
                          viewModel.selectedJobTypes.contains(type);
                      return _buildCheckboxRow(
                        title: _capitalize(type),
                        isSelected: isChecked,
                        onChanged: (_) => viewModel.toggleJobType(type),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 4. Experience Level
                _buildSectionHeader('Experience Level'),
                const SizedBox(height: 8),
                Obx(() {
                  final levels = viewModel.availableExperienceLevels;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: levels.map((lvl) {
                      final isSelected =
                          viewModel.selectedExperienceLevels.contains(lvl);
                      return _buildFilterChip(
                        label: '${_capitalize(lvl)} Level',
                        isSelected: isSelected,
                        onSelected: (_) => viewModel.toggleExperienceLevel(lvl),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 5. City / Location
                _buildSectionHeader('City / Location'),
                const SizedBox(height: 8),
                Obx(() {
                  final cities = viewModel.availableCities;
                  final currentCity = viewModel.selectedCity.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentCity.isEmpty ? null : currentCity,
                        hint: const Text(
                          'All Locations',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              'All Locations',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(
                                city,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => viewModel.setCity(val ?? ''),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 6. Source (ATS)
                _buildSectionHeader('ATS Source'),
                const SizedBox(height: 8),
                Obx(() {
                  final sources = viewModel.availableSources;
                  final currentSource = viewModel.selectedSource.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentSource.isEmpty ? null : currentSource,
                        hint: const Text(
                          'All ATS Boards',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text(
                              'All ATS Boards',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...sources.map((src) {
                            return DropdownMenuItem<String>(
                              value: src,
                              child: Text(
                                src,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) => viewModel.setSource(val ?? ''),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(JobsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Search Keywords'),
        const SizedBox(height: 8),
        TextField(
          controller: viewModel.searchController,
          onChanged: viewModel.setSearchQuery,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Title, company, skill (e.g. Go)...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppTheme.textMuted,
            ),
            suffixIcon: Obx(() {
              if (viewModel.searchQuery.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: viewModel.clearSearch,
                splashRadius: 16,
              );
            }),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String title,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isSelected,
                onChanged: onChanged,
                activeColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppTheme.borderDark, width: 1.2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
      ),
      backgroundColor: AppTheme.surfaceMuted,
      selectedColor: AppTheme.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
          width: 1,
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

