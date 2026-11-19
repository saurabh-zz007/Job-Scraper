import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/job_model.dart';
import '../../../data/repositories/job_repository.dart';

class JobsViewModel extends GetxController {
  final JobRepository _repository;

  JobsViewModel({JobRepository? repository})
      : _repository = repository ?? Get.find<JobRepository>();

  // Observables
  final RxList<JobModel> allJobs = <JobModel>[].obs;
  final RxList<JobModel> filteredJobs = <JobModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<JobModel> selectedJob = Rxn<JobModel>();

  // Filter Observables
  final RxString searchQuery = ''.obs;
  final RxSet<String> selectedRoleCategories = <String>{}.obs;
  final RxSet<String> selectedWorkModes = <String>{}.obs;
  final RxSet<String> selectedJobTypes = <String>{}.obs;
  final RxSet<String> selectedExperienceLevels = <String>{}.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedSource = ''.obs;
  final RxString sortBy = 'newest'.obs; // "newest" vs "confidence"

  // Text controller for search input
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // React to any filter or sort changes
    everAll([
      searchQuery,
      selectedRoleCategories,
      selectedWorkModes,
      selectedJobTypes,
      selectedExperienceLevels,
      selectedCity,
      selectedSource,
      sortBy,
    ], (_) => _applyFiltersAndSort());

    fetchJobs();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Fetch Jobs from repository
  Future<void> fetchJobs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final jobs = await _repository.getJobs();
      allJobs.assignAll(jobs);
      _applyFiltersAndSort();
    } catch (e) {
      allJobs.clear();
      filteredJobs.clear();
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> triggerCollection() async {
    final ok = await _repository.triggerCollection();
    if (ok) {
      Future.delayed(const Duration(seconds: 2), fetchJobs);
    }
    return ok;
  }

  // Dynamic filter options derived from allJobs
  List<String> get availableRoleCategories {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.inferredRole != null && job.inferredRole!.isNotEmpty) {
        set.add(job.inferredRole!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableWorkModes {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.inferredWorkMode != null && job.inferredWorkMode!.isNotEmpty) {
        set.add(job.inferredWorkMode!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableJobTypes {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.inferredJobType != null && job.inferredJobType!.isNotEmpty) {
        set.add(job.inferredJobType!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableExperienceLevels {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.inferredExperience != null && job.inferredExperience!.isNotEmpty) {
        set.add(job.inferredExperience!);
      }
    }
    // Preferred order: intern, entry, mid, senior, lead
    const order = ['intern', 'entry', 'mid', 'senior', 'lead'];
    final list = set.toList()
      ..sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return a.compareTo(b);
      });
    return list;
  }

  List<String> get availableCities {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.inferredCity != null && job.inferredCity!.isNotEmpty) {
        set.add(job.inferredCity!);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get availableSources {
    final set = <String>{};
    for (final job in allJobs) {
      if (job.sourceName.isNotEmpty) {
        set.add(job.sourceName);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  // Active filters count
  int get activeFiltersCount {
    var count = 0;
    if (searchQuery.value.trim().isNotEmpty) count++;
    count += selectedRoleCategories.length;
    count += selectedWorkModes.length;
    count += selectedJobTypes.length;
    count += selectedExperienceLevels.length;
    if (selectedCity.value.isNotEmpty) count++;
    if (selectedSource.value.isNotEmpty) count++;
    return count;
  }

  // Filter & Sort Pipeline
  void _applyFiltersAndSort() {
    final query = searchQuery.value.trim().toLowerCase();

    final filtered = allJobs.where((job) {
      // 1. Search Query (title, company, inferredSkills)
      if (query.isNotEmpty) {
        final titleMatch = job.title.toLowerCase().contains(query);
        final companyMatch = job.company.toLowerCase().contains(query);
        final skillsMatch = job.inferredSkills.any(
          (s) => s.toLowerCase().contains(query),
        );
        if (!titleMatch && !companyMatch && !skillsMatch) {
          return false;
        }
      }

      // 2. Role Category
      if (selectedRoleCategories.isNotEmpty) {
        if (job.inferredRole == null ||
            !selectedRoleCategories.contains(job.inferredRole)) {
          return false;
        }
      }

      // 3. Work Mode
      if (selectedWorkModes.isNotEmpty) {
        if (job.inferredWorkMode == null ||
            !selectedWorkModes.contains(job.inferredWorkMode)) {
          return false;
        }
      }

      // 4. Job Type
      if (selectedJobTypes.isNotEmpty) {
        if (job.inferredJobType == null ||
            !selectedJobTypes.contains(job.inferredJobType)) {
          return false;
        }
      }

      // 5. Experience Level
      if (selectedExperienceLevels.isNotEmpty) {
        if (job.inferredExperience == null ||
            !selectedExperienceLevels.contains(job.inferredExperience)) {
          return false;
        }
      }

      // 6. City / Location
      if (selectedCity.value.isNotEmpty) {
        if (job.inferredCity != selectedCity.value) {
          return false;
        }
      }

      // 7. Source (ATS)
      if (selectedSource.value.isNotEmpty) {
        if (job.sourceName != selectedSource.value) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    if (sortBy.value == 'confidence') {
      filtered.sort((a, b) {
        final confA = a.classificationConfidence ?? 0.0;
        final confB = b.classificationConfidence ?? 0.0;
        return confB.compareTo(confA);
      });
    } else {
      // 'newest' is default
      filtered.sort((a, b) {
        final dateA = a.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    }

    filteredJobs.assignAll(filtered);

    // If selected job is no longer in filtered list, or if selected job was null, keep it synced
    if (selectedJob.value != null) {
      final updated = filtered.firstWhereOrNull((j) => j.id == selectedJob.value!.id);
      selectedJob.value = updated;
    }
  }

  // Filter actions
  void toggleRoleCategory(String role) {
    if (selectedRoleCategories.contains(role)) {
      selectedRoleCategories.remove(role);
    } else {
      selectedRoleCategories.add(role);
    }
    _applyFiltersAndSort();
  }

  void toggleWorkMode(String mode) {
    if (selectedWorkModes.contains(mode)) {
      selectedWorkModes.remove(mode);
    } else {
      selectedWorkModes.add(mode);
    }
    _applyFiltersAndSort();
  }

  void toggleJobType(String type) {
    if (selectedJobTypes.contains(type)) {
      selectedJobTypes.remove(type);
    } else {
      selectedJobTypes.add(type);
    }
    _applyFiltersAndSort();
  }

  void toggleExperienceLevel(String level) {
    if (selectedExperienceLevels.contains(level)) {
      selectedExperienceLevels.remove(level);
    } else {
      selectedExperienceLevels.add(level);
    }
    _applyFiltersAndSort();
  }

  void setCity(String city) {
    selectedCity.value = city;
    _applyFiltersAndSort();
  }

  void setSource(String source) {
    selectedSource.value = source;
    _applyFiltersAndSort();
  }

  void setSortBy(String sort) {
    sortBy.value = sort;
    _applyFiltersAndSort();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFiltersAndSort();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _applyFiltersAndSort();
  }

  void clearAllFilters() {
    searchController.clear();
    searchQuery.value = '';
    selectedRoleCategories.clear();
    selectedWorkModes.clear();
    selectedJobTypes.clear();
    selectedExperienceLevels.clear();
    selectedCity.value = '';
    selectedSource.value = '';
    sortBy.value = 'newest';
    _applyFiltersAndSort();
  }

  void selectJob(JobModel? job) {
    selectedJob.value = job;
  }

  // Open apply url with url_launcher
  Future<void> openApplyUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          _showErrorSnackbar('Could not open URL: $url');
        }
      } else {
        _showErrorSnackbar('Unable to open URL: $url');
      }
    } catch (e) {
      _showErrorSnackbar('Error launching application link: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'External Link',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline, color: Colors.amberAccent),
    );
  }
}

