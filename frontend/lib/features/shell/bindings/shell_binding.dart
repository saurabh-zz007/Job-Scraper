import 'package:get/get.dart';

import '../../../data/repositories/admin_repository.dart';
import '../../../data/repositories/job_repository.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import '../../jobs/viewmodels/jobs_viewmodel.dart';
import '../viewmodels/shell_viewmodel.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<JobRepository>()) {
      Get.lazyPut<JobRepository>(() => ApiJobRepository());
    }
    if (!Get.isRegistered<AdminRepository>()) {
      Get.lazyPut<AdminRepository>(() => ApiAdminRepository());
    }
    Get.lazyPut<JobsViewModel>(() => JobsViewModel());
    Get.lazyPut<AdminViewModel>(() => AdminViewModel());
    Get.lazyPut<ShellViewModel>(() => ShellViewModel());
  }
}
