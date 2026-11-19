import 'package:get/get.dart';

import '../../../data/repositories/job_repository.dart';
import '../viewmodels/jobs_viewmodel.dart';

class JobsBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(() => ApiJobRepository());
    }
    Get.lazyPut<JobsViewModel>(() => JobsViewModel());
  }
}

