import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/job_model.dart';
import 'package:frontend/data/repositories/job_repository.dart';
import 'package:frontend/features/jobs/viewmodels/jobs_viewmodel.dart';
import 'package:frontend/features/shell/viewmodels/shell_viewmodel.dart';

class TestJobRepository implements JobRepository {
  final List<JobModel> jobs = [
    JobModel(
      id: 'job-001',
      sourceUrl: 'https://example.com/stripe',
      sourceName: 'Greenhouse',
      companyName: 'Stripe',
      rawTitle: 'Senior Backend Engineer',
      description: 'Stripe backend billing role.',
      contentHash: 'hash1',
      inferredRole: 'Backend Engineer',
      inferredCity: 'San Francisco',
      inferredJobType: 'full-time',
      inferredExperience: 'senior',
      inferredWorkMode: 'hybrid',
      inferredSkills: ['Go', 'PostgreSQL'],
      classificationConfidence: 0.98,
      postedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    JobModel(
      id: 'job-002',
      sourceUrl: 'https://example.com/figma',
      sourceName: 'Lever',
      companyName: 'Figma',
      rawTitle: 'Staff DevOps Engineer',
      description: 'Figma infrastructure role.',
      contentHash: 'hash2',
      inferredRole: 'DevOps / SRE',
      inferredCity: 'Seattle',
      inferredJobType: 'full-time',
      inferredExperience: 'lead',
      inferredWorkMode: 'remote',
      inferredSkills: ['Kubernetes', 'Rust'],
      classificationConfidence: 0.95,
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<JobModel>> getJobs() async => List<JobModel>.from(jobs);

  @override
  Future<JobModel?> getJobById(String id) async {
    try {
      return jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> triggerCollection() async => true;
}

void main() {
  group('JobModel Tests', () {
    test('JobModel fromJson and toJson mirrors backend PostgreSQL schema', () {
      final json = {
        'id': 'test-123',
        'source_url': 'https://jobs.example.com/123',
        'source_name': 'Greenhouse',
        'source_id': 'gh-123',
        'company_name': 'Acme Corp',
        'raw_title': 'Senior Rust Engineer',
        'raw_location': 'San Francisco, CA',
        'description': 'Building next-gen systems.',
        'content_hash': 'abc123hash',
        'inferred_role': 'Backend Engineer',
        'inferred_city': 'San Francisco',
        'inferred_job_type': 'full-time',
        'inferred_experience': 'senior',
        'inferred_work_mode': 'remote',
        'inferred_skills': ['Rust', 'PostgreSQL', 'Docker'],
        'classification_confidence': 0.97,
        'llm_model': 'gpt-4o-mini',
        'prompt_version': 'v2.1',
        'etl_status': 'PUBLISHED',
        'processing_attempts': 1,
        'llm_input_tokens': 500,
        'llm_output_tokens': 80,
        'llm_cost_usd': 0.00012,
        'posted_at': '2026-11-19T10:00:00.000Z',
      };

      final job = JobModel.fromJson(json);

      expect(job.id, 'test-123');
      expect(job.company, 'Acme Corp');
      expect(job.title, 'Senior Rust Engineer');
      expect(job.applyUrl, 'https://jobs.example.com/123');
      expect(job.inferredWorkMode, 'remote');
      expect(job.inferredSkills, ['Rust', 'PostgreSQL', 'Docker']);

      final serialized = job.toJson();
      expect(serialized['id'], 'test-123');
      expect(serialized['company_name'], 'Acme Corp');
      expect(serialized['raw_title'], 'Senior Rust Engineer');
      expect(serialized['source_url'], 'https://jobs.example.com/123');
      expect(serialized['classification_confidence'], 0.97);
    });

    test(
      'JobModel fromJson handles Decimal strings and numbers for llm_cost_usd safely',
      () {
        final json = {
          'id': 'test-456',
          'source_url': 'https://jobs.example.com/456',
          'source_name': 'Lever',
          'company_name': 'Figma',
          'raw_title': 'Staff Engineer',
          'description': 'Staff role.',
          'content_hash': 'hash456',
          'classification_confidence': '0.98',
          'llm_cost_usd': '0.00028300',
        };

        final job = JobModel.fromJson(json);
        expect(job.classificationConfidence, 0.98);
        expect(job.llmCostUsd, 0.000283);
      },
    );
  });

  group('JobsViewModel Reactive Filtering & Sorting Tests', () {
    late JobsViewModel viewModel;
    late TestJobRepository repository;

    setUp(() async {
      repository = TestJobRepository();
      viewModel = JobsViewModel(repository: repository);
      viewModel.onInit();
      await viewModel.fetchJobs();
    });

    tearDown(() {
      viewModel.onClose();
    });

    test('Initial fetch loads all jobs into allJobs and filteredJobs', () {
      expect(viewModel.allJobs.length, 2);
      expect(viewModel.filteredJobs.length, 2);
      expect(viewModel.isLoading.value, false);
      expect(viewModel.errorMessage.value, '');
    });

    test('Keyword search filters jobs across title, company, or skills', () {
      viewModel.setSearchQuery('Stripe');
      expect(viewModel.filteredJobs.length, 1);
      expect(viewModel.filteredJobs.first.company, 'Stripe');

      viewModel.setSearchQuery('Rust');
      expect(viewModel.filteredJobs.length, 1);
      expect(viewModel.filteredJobs.first.company, 'Figma');

      viewModel.clearSearch();
      expect(viewModel.filteredJobs.length, 2);
    });

    test('Work mode filter reactively filters listings', () {
      viewModel.toggleWorkMode('remote');
      expect(viewModel.filteredJobs.length, 1);
      expect(viewModel.filteredJobs.first.inferredWorkMode, 'remote');

      viewModel.toggleWorkMode('remote');
      expect(viewModel.filteredJobs.length, 2);
    });

    test('City and ATS source single-select filters work', () {
      viewModel.setCity('San Francisco');
      expect(viewModel.filteredJobs.length, 1);
      expect(viewModel.filteredJobs.first.inferredCity, 'San Francisco');

      viewModel.setSource('Greenhouse');
      expect(viewModel.filteredJobs.length, 1);
      expect(viewModel.filteredJobs.first.sourceName, 'Greenhouse');
    });

    test(
      'Sort by confidence orders jobs by classification confidence descending',
      () {
        viewModel.setSortBy('confidence');
        final first = viewModel.filteredJobs[0].classificationConfidence!;
        final second = viewModel.filteredJobs[1].classificationConfidence!;
        expect(first >= second, true);
      },
    );

    test('clearAllFilters resets all search, filters, and sort options', () {
      viewModel.setSearchQuery('Go');
      viewModel.toggleWorkMode('remote');
      viewModel.setCity('Seattle');
      viewModel.setSortBy('confidence');

      expect(viewModel.activeFiltersCount > 0, true);

      viewModel.clearAllFilters();

      expect(viewModel.searchQuery.value, '');
      expect(viewModel.selectedRoleCategories.isEmpty, true);
      expect(viewModel.selectedWorkModes.isEmpty, true);
      expect(viewModel.selectedCity.value, '');
      expect(viewModel.sortBy.value, 'newest');
      expect(viewModel.filteredJobs.length, 2);
    });
  });

  group('ShellViewModel Tests', () {
    test('ShellViewModel changes tabs properly', () {
      final shell = ShellViewModel();
      expect(shell.currentTabIndex.value, 0);

      shell.changeTab(1);
      expect(shell.currentTabIndex.value, 1);

      shell.changeTab(0);
      expect(shell.currentTabIndex.value, 0);
    });
  });
}
